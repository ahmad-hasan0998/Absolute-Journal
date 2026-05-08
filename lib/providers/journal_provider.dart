import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/models/media_item.dart';
import 'package:final_project/models/history_log.dart';
import 'package:final_project/services/database_service.dart';
import 'package:final_project/locator.dart';

class JournalProvider extends ChangeNotifier {
  List<MediaItem> activeItems = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  bool hasMore = true;
  DocumentSnapshot? _lastDoc;

  final DatabaseService _db = locator<DatabaseService>();

  Future<void> loadJournal() async {
    isLoading = true;
    hasMore = true;
    _lastDoc = null;
    notifyListeners();

    await _db.syncGamification();
    var fetched = await _db.getUserJournal(limit: 50);
    activeItems = fetched;

    if (fetched.isNotEmpty) {
      _lastDoc = fetched.last.snapshot;
    }
    if (fetched.length < 50) hasMore = false;

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreJournal() async {
    if (!hasMore || isFetchingMore) return;
    isFetchingMore = true;
    notifyListeners();

    var newItems = await _db.getUserJournal(startAfter: _lastDoc, limit: 50);
    if (newItems.isEmpty) {
      hasMore = false;
    } else {
      activeItems.addAll(newItems);
      _lastDoc = newItems.last.snapshot;
      if (newItems.length < 50) hasMore = false;
    }

    isFetchingMore = false;
    notifyListeners();
  }

  Future<void> reorderTop5(int oldIndex, int newIndex) async {
    final top5 = activeItems.where((item) => item.isTop5).toList();
    top5.sort((a, b) => a.top5Order.compareTo(b.top5Order));

    if (oldIndex >= top5.length) return;
    if (newIndex >= top5.length) newIndex = top5.length - 1;

    final item = top5.removeAt(oldIndex);
    top5.insert(newIndex, item);

    for (int i = 0; i < top5.length; i++) {
      top5[i].top5Order = i;
      await _db.updateMedia(top5[i]);
    }
    notifyListeners();
  }

  Future<void> addMedia(MediaItem item) async {
    item.timestamp = DateTime.now();
    if (item.isTop5) {
      int currentTop5Count = activeItems.where((i) => i.isTop5).length;
      item.top5Order = currentTop5Count;
    }

    activeItems.insert(0, item);
    notifyListeners();
    String? newId = await _db.addMediaToJournal(item);
    item.id = newId;
    if (item.status == 'Completed') {
      String actionStr = item.type == 'Movie'
          ? 'Watched Movie'
          : 'Completed Show';
      await _db.addHistoryLog(
        HistoryLog(
          mediaId: item.id!,
          title: item.title,
          type: item.type,
          action: actionStr,
          timestamp: item.timestamp!,
          posterUrl: item.posterUrl,
          isLiked: item.isLiked,
        ),
      );
    }
  }

  Future<void> removeMedia(MediaItem item) async {
    activeItems.removeWhere((element) => element.id == item.id);
    notifyListeners();

    if (item.id != null) {
      await _db.deleteMedia(item.id!);
    }
  }

  Future<void> updateExistingMedia(MediaItem item) async {
    item.timestamp = DateTime.now();
    int index = activeItems.indexWhere((element) => element.id == item.id);
    if (index != -1) activeItems[index] = item;
    notifyListeners();
    await _db.updateMedia(item);
  }

  Future<void> completeEntireShow(MediaItem item) async {
    if (item.status != 'Completed') item.completedCount++;
    int remainingEpisodes = item.total - item.progress;
    int xpEarned = (remainingEpisodes * 10) + 50;
    item.status = 'Completed';
    item.timestamp = DateTime.now();
    item.progress = item.total;
    notifyListeners();
    await _db.addXP(xpEarned);
    String actionStr = item.type == 'Movie'
        ? 'Watched Movie'
        : 'Completed Show';
    await _db.addHistoryLog(
      HistoryLog(
        mediaId: item.id!,
        title: item.title,
        type: item.type,
        action: actionStr,
        timestamp: item.timestamp!,
        posterUrl: item.posterUrl,
        isLiked: item.isLiked,
      ),
    );
    await _db.updateMedia(item);
  }

  Future<void> incrementProgress(MediaItem item, int amount) async {
    if (item.status == 'Completed') return;
    int oldProgress = item.progress;
    item.progress = (item.progress + amount).clamp(0, item.total);
    int episodesWatched = item.progress - oldProgress;
    item.timestamp = DateTime.now();
    bool completedNow = false;
    if (item.progress == item.total) {
      item.status = 'Completed';
      item.completedCount++;
      completedNow = true;
    }
    notifyListeners();
    if (episodesWatched > 0) {
      int xpEarned = episodesWatched * 10;
      if (completedNow) xpEarned += 50;
      await _db.updateMedia(item);
      await _db.addXP(xpEarned);
      for (int i = 1; i <= episodesWatched; i++) {
        int epNum = oldProgress + i;
        await _db.addHistoryLog(
          HistoryLog(
            mediaId: item.id!,
            title: item.title,
            type: item.type,
            action: 'Watched Episode $epNum',
            timestamp: item.timestamp!,
            posterUrl: item.posterUrl,
            isLiked: item.isLiked,
          ),
        );
      }
    }
  }

  Future<void> updateManualProgress(MediaItem item, int newProgress) async {
    if (item.status == 'Completed' && newProgress == item.total) return;
    bool wasCompleted = item.status == 'Completed';
    int oldProgress = item.progress;
    item.progress = newProgress.clamp(0, item.total);
    item.timestamp = DateTime.now();
    if (item.progress == item.total) {
      if (!wasCompleted) {
        item.status = 'Completed';
        item.completedCount++;
      }
    } else {
      item.status = 'Active';
    }
    notifyListeners();
    if (item.progress > oldProgress) {
      int episodesWatched = item.progress - oldProgress;
      int xpEarned = episodesWatched * 10;
      if (item.progress == item.total && !wasCompleted) xpEarned += 50;
      await _db.addXP(xpEarned);
      for (int i = 1; i <= episodesWatched; i++) {
        int epNum = oldProgress + i;
        await _db.addHistoryLog(
          HistoryLog(
            mediaId: item.id!,
            title: item.title,
            type: item.type,
            action: 'Watched Episode $epNum',
            timestamp: item.timestamp!,
            posterUrl: item.posterUrl,
            isLiked: item.isLiked,
          ),
        );
      }
    }
    await _db.updateMedia(item);
  }

  void clear() {
    activeItems = [];
    _lastDoc = null;
    hasMore = true;
    notifyListeners();
  }
}
