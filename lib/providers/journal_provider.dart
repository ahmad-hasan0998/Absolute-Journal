import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/database_service.dart';
import '../locator.dart';
class JournalProvider extends ChangeNotifier {
  List<MediaItem> activeItems = [];
  bool isLoading = true;
  final DatabaseService _db = locator<DatabaseService>();
  Future<void> loadJournal() async {
    isLoading = true;
    notifyListeners();
    activeItems = await _db.getUserJournal();
    isLoading = false;
    notifyListeners();
  }
  Future<void> addMedia(MediaItem item) async {
    String? newId = await _db.addMediaToJournal(item);
    item.id = newId;
    activeItems.insert(0, item);
    notifyListeners();
  }
  Future<void> updateExistingMedia(MediaItem item) async {
    await _db.updateMedia(item);
    int index = activeItems.indexWhere((element) => element.id == item.id);
    if (index != -1) {
      activeItems[index] = item;
      notifyListeners();
    }
  }
  void triggerRebuild() {
    notifyListeners();
  }
  Future<void> completeEntireShow(MediaItem item) async {
    if (item.status != 'Completed') item.completedCount++;
    int remainingEpisodes = item.total - item.progress;
    int xpEarned = (remainingEpisodes * 10) + 50;
    await _db.addXP(xpEarned);
    item.status = 'Completed';
    item.lastUpdated = 'Just now';
    item.progress = item.total;
    await _db.updateMedia(item);
    notifyListeners();
  }
  Future<void> incrementProgress(MediaItem item, int amount) async {
    if (item.status == 'Completed') return;
    int oldProgress = item.progress;
    item.progress = (item.progress + amount).clamp(0, item.total);
    int episodesWatched = item.progress - oldProgress;
    int xpEarned = episodesWatched * 10;
    item.lastUpdated = 'Just now';
    if (item.progress == item.total) {
      item.status = 'Completed';
      item.completedCount++;
      xpEarned += 50;
    }
    await _db.addXP(xpEarned);
    await _db.updateMedia(item);
    notifyListeners();
  }
  Future<void> updateManualProgress(MediaItem item, int newProgress) async {
    if (item.status == 'Completed' && newProgress == item.total) return;
    bool wasCompleted = item.status == 'Completed';
    int oldProgress = item.progress;
    item.progress = newProgress.clamp(0, item.total);
    if (item.progress > oldProgress) {
      int episodesWatched = item.progress - oldProgress;
      int xpEarned = episodesWatched * 10;
      if (item.progress == item.total && !wasCompleted) xpEarned += 50;
      await _db.addXP(xpEarned);
    }
    item.lastUpdated = 'Just now';
    if (item.progress == item.total) {
      if (!wasCompleted) {
        item.status = 'Completed';
        item.completedCount++;
      }
    } else {
      item.status = 'Active';
    }
    await _db.updateMedia(item);
    notifyListeners();
  }
}