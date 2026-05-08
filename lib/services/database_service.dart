import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/media_item.dart';
import '../models/history_log.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  static Map<String, dynamic> getRankVisuals(String rank) {
    switch (rank) {
      case 'Iron Novice': return {'icon': Icons.shield_rounded, 'color': const Color(0xFF607D8B)};
      case 'Bronze Watcher': return {'icon': Icons.military_tech_rounded, 'color': const Color(0xFF8D6E63)};
      case 'Silver Binger': return {'icon': Icons.military_tech_rounded, 'color': const Color(0xFF9E9E9E)};
      case 'Gold Cinephile': return {'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFFFFC107)};
      case 'Platinum Tracker': return {'icon': Icons.diamond_rounded, 'color': const Color(0xFF4DD0E1)};
      case 'Diamond Master': return {'icon': Icons.ac_unit_rounded, 'color': const Color(0xFF7C4DFF)};
      case 'Absolute Legend': return {'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFFF5252)};
      default: return {'icon': Icons.star_rounded, 'color': const Color(0xFFFF6B00)};
    }
  }

  static String formatTimeAgo(DateTime? dt) {
    if (dt == null) return 'Just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return DateFormat('MMM d, yyyy').format(dt);
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Future<void> debugSetLastActivity(int daysAgo) async {
    final uid = currentUserId;
    if (uid == null) return;
    DateTime past = DateTime.now().subtract(Duration(days: daysAgo));
    await _db.collection('users').doc(uid).update({'last_activity_date': Timestamp.fromDate(past)});
  }

  Future<void> debugSetLastReset(int daysAgo) async {
    final uid = currentUserId;
    if (uid == null) return;
    DateTime past = DateTime.now().subtract(Duration(days: daysAgo));
    await _db.collection('users').doc(uid).update({'last_reset_date': Timestamp.fromDate(past)});
  }

  Future<void> syncGamification() async {
    final uid = currentUserId;
    if (uid == null) return;
    var doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return;
    var data = doc.data()!;
    int xp = data['xp_score'] ?? 0;
    int streak = data['streak'] ?? 0;
    Timestamp? lastActivityTs = data['last_activity_date'];
    Timestamp? lastResetTs = data['last_reset_date'];
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime lastActivity = lastActivityTs != null ? lastActivityTs.toDate() : today;
    DateTime lastActivityDay = DateTime(lastActivity.year, lastActivity.month, lastActivity.day);
    DateTime lastReset = lastResetTs != null ? lastResetTs.toDate() : today;
    bool needsUpdate = false;
    Map<String, dynamic> updates = {};

    if (now.year > lastReset.year || now.month > lastReset.month) {
      updates['last_month_xp'] = xp;
      xp = 0;
      streak = 0;
      updates['last_reset_date'] = FieldValue.serverTimestamp();
      needsUpdate = true;
    }

    int daysMissed = today.difference(lastActivityDay).inDays;
    if (daysMissed > 1 && xp > 0 && !needsUpdate) {
      int penalty = (daysMissed - 1) * 50;
      xp = (xp - penalty).clamp(0, 999999);
      streak = 0;
      updates['last_activity_date'] = FieldValue.serverTimestamp();
      needsUpdate = true;
    }

    if (needsUpdate) {
      updates['xp_score'] = xp;
      updates['streak'] = streak;
      updates['rank'] = _calculateRank(xp);
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  Future<String?> addMediaToJournal(MediaItem item) async {
    final uid = currentUserId;
    if (uid == null) return null;
    var docRef = await _db.collection('users').doc(uid).collection('my_journal').add({
      'tmdbId': item.tmdbId,
      'title': item.title,
      'type': item.type,
      'status': item.status,
      'progress': item.progress,
      'total': item.total,
      'posterUrl': item.posterUrl,
      'isWatchLater': item.isWatchLater,
      'isTop5': item.isTop5,
      'completedCount': item.completedCount,
      'isLiked': item.isLiked,
      'timestamp': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<List<MediaItem>> getUserJournal() async {
    final uid = currentUserId;
    if (uid == null) return [];
    var snapshot = await _db.collection('users').doc(uid).collection('my_journal').orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) {
      var data = doc.data();
      Timestamp? ts = data['timestamp'] as Timestamp?;
      return MediaItem(
        id: doc.id,
        tmdbId: data['tmdbId'],
        title: data['title'] ?? 'Unknown',
        type: data['type'] ?? 'Movie',
        status: data['status'] ?? 'Active',
        progress: data['progress'] ?? 0,
        total: data['total'] ?? 1,
        lastUpdated: 'Just now',
        timestamp: ts?.toDate() ?? DateTime.now(),
        posterUrl: data['posterUrl'],
        isWatchLater: data['isWatchLater'] == true,
        isTop5: data['isTop5'] == true,
        completedCount: data['completedCount'] ?? 0,
        isLiked: data['isLiked'],
      );
    }).toList();
  }

  Future<void> updateMedia(MediaItem item) async {
    final uid = currentUserId;
    if (uid == null || item.id == null) return;
    await _db.collection('users').doc(uid).collection('my_journal').doc(item.id).update({
      'progress': item.progress,
      'status': item.status,
      'completedCount': item.completedCount,
      'isWatchLater': item.isWatchLater,
      'isTop5': item.isTop5,
      'isLiked': item.isLiked,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMedia(String mediaId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('my_journal').doc(mediaId).delete();
  }

  Future<void> addHistoryLog(HistoryLog log) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('history_logs').add({
      'mediaId': log.mediaId,
      'title': log.title,
      'type': log.type,
      'action': log.action,
      'timestamp': Timestamp.fromDate(log.timestamp),
      'posterUrl': log.posterUrl,
      'isLiked': log.isLiked,
    });
  }

  Future<List<HistoryLog>> getHistoryLogs(String type) async {
    final uid = currentUserId;
    if (uid == null) return [];
    var snapshot = await _db.collection('users').doc(uid).collection('history_logs').orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) {
      var data = doc.data();
      return HistoryLog(
          id: doc.id,
          mediaId: data['mediaId'] ?? '',
          title: data['title'] ?? 'Unknown',
          type: data['type'] ?? 'Movie',
          action: data['action'] ?? '',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          posterUrl: data['posterUrl'],
          isLiked: data['isLiked']
      );
    }).where((log) => log.type == type).toList();
  }

  Future<void> uploadProfilePicture(XFile file) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      List<int> imageBytes = await file.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      await _db.collection('users').doc(uid).update({'profileUrl': 'base64,$base64Image'});
    } catch (e) {
      throw Exception('Failed to save profile picture.');
    }
  }

  Stream<DocumentSnapshot> getUserProfileStream() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<Map<String, dynamic>?> getUserProfile(String targetUid) async {
    var doc = await _db.collection('users').doc(targetUid).get();
    if (doc.exists) return {'uid': doc.id, ...doc.data()!};
    return null;
  }

  Future<List<MediaItem>> getJournalByUid(String targetUid) async {
    var snapshot = await _db.collection('users').doc(targetUid).collection('my_journal').orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) {
      var data = doc.data();
      Timestamp? ts = data['timestamp'] as Timestamp?;
      return MediaItem(
          id: doc.id,
          tmdbId: data['tmdbId'],
          title: data['title'] ?? 'Unknown',
          type: data['type'] ?? 'Movie',
          status: data['status'] ?? 'Active',
          progress: data['progress'] ?? 0,
          total: data['total'] ?? 1,
          lastUpdated: 'Just now',
          timestamp: ts?.toDate() ?? DateTime.now(),
          posterUrl: data['posterUrl'],
          isWatchLater: data['isWatchLater'] == true,
          isTop5: data['isTop5'] == true,
          completedCount: data['completedCount'] ?? 0,
          isLiked: data['isLiked']
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final uid = currentUserId;
    var snapshot = await _db.collection('users').where('username', isGreaterThanOrEqualTo: query).where('username', isLessThanOrEqualTo: '$query\uf8ff').get();
    return snapshot.docs.where((doc) => doc.id != uid).map((doc) => {'uid': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getFriendsProfiles(List<dynamic> uids) async {
    if (uids.isEmpty) return [];
    List<Map<String, dynamic>> friends = [];
    for (String targetUid in uids) {
      var doc = await _db.collection('users').doc(targetUid).get();
      if (doc.exists) friends.add({'uid': doc.id, ...doc.data()!});
    }
    return friends;
  }

  Future<void> toggleFriend(String friendUid, bool isAdding) async {
    final uid = currentUserId;
    if (uid == null) return;
    if (isAdding) {
      await _db.collection('users').doc(uid).update({'friends': FieldValue.arrayUnion([friendUid])});
    } else {
      await _db.collection('users').doc(uid).update({'friends': FieldValue.arrayRemove([friendUid])});
    }
  }

  Future<List<Map<String, dynamic>>> getFriendsFeed(List<dynamic> friendIds) async {
    if (friendIds.isEmpty) return [];
    List<Map<String, dynamic>> feed = [];
    for (String targetUid in friendIds) {
      var userDoc = await _db.collection('users').doc(targetUid).get();
      if (!userDoc.exists) continue;
      String friendName = userDoc.data()?['username'] ?? 'Unknown';
      String friendPic = userDoc.data()?['profileUrl'] ?? '';
      var journal = await _db.collection('users').doc(targetUid).collection('my_journal').orderBy('timestamp', descending: true).limit(3).get();
      for (var doc in journal.docs) {
        var data = doc.data();
        Timestamp? ts = data['timestamp'] as Timestamp?;
        data['uid'] = targetUid;
        data['friendName'] = friendName;
        data['friendPic'] = friendPic;
        data['timestamp_sort'] = ts;
        data['lastUpdated'] = formatTimeAgo(ts?.toDate());
        feed.add(data);
      }
    }
    feed.sort((a, b) {
      Timestamp t1 = a['timestamp_sort'] ?? Timestamp.now();
      Timestamp t2 = b['timestamp_sort'] ?? Timestamp.now();
      return t2.compareTo(t1);
    });
    return feed;
  }

  Future<List<Map<String, dynamic>>> getFriendsLeaderboard(List<dynamic> friendIds) async {
    final uid = currentUserId;
    if (uid == null) return [];
    List<String> idsToFetch = [uid, ...friendIds.map((e) => e.toString())];
    List<Map<String, dynamic>> leaderboard = [];
    for (String targetUid in idsToFetch) {
      var doc = await _db.collection('users').doc(targetUid).get();
      if (doc.exists) leaderboard.add({'uid': doc.id, ...doc.data()!});
    }
    List<Map<String, dynamic>> lastMonthStandings = List.from(leaderboard);
    lastMonthStandings.sort((a, b) => (b['last_month_xp'] ?? 0).compareTo(a['last_month_xp'] ?? 0));
    for (var user in leaderboard) {
      int lastMonthXp = user['last_month_xp'] ?? 0;
      if (lastMonthXp > 0) {
        int index = lastMonthStandings.indexWhere((u) => u['uid'] == user['uid']);
        user['prev_rank'] = index + 1;
      } else {
        user['prev_rank'] = 999;
      }
    }
    leaderboard.sort((a, b) => (b['xp_score'] ?? 0).compareTo(a['xp_score'] ?? 0));
    return leaderboard;
  }

  Future<int> getUserPrevRank(String targetUid) async {
    final uid = currentUserId;
    if (uid == null) return 999;
    var myDoc = await _db.collection('users').doc(uid).get();
    List<dynamic> myFriends = myDoc.data()?['friends'] ?? [];
    List<String> idsToFetch = [uid, ...myFriends.map((e) => e.toString())];
    if (!idsToFetch.contains(targetUid)) return 999;

    List<int> lastMonthXps = [];
    int targetXp = 0;
    for (String id in idsToFetch) {
      var doc = await _db.collection('users').doc(id).get();
      if (doc.exists) {
        int xp = doc.data()!['last_month_xp'] ?? 0;
        lastMonthXps.add(xp);
        if (id == targetUid) targetXp = xp;
      }
    }

    if (targetXp == 0) return 999;
    lastMonthXps.sort((a, b) => b.compareTo(a));
    return lastMonthXps.indexOf(targetXp) + 1;
  }

  Future<void> addXP(int amount) async {
    final uid = currentUserId;
    if (uid == null) return;
    DocumentReference userRef = _db.collection('users').doc(uid);
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;
      var data = snapshot.data() as Map<String, dynamic>;
      int currentXp = data['xp_score'] ?? 0;
      int streak = data['streak'] ?? 0;
      Timestamp? lastActivityTs = data['last_activity_date'];
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime lastActivity = lastActivityTs != null ? lastActivityTs.toDate() : today;
      DateTime lastActivityDay = DateTime(lastActivity.year, lastActivity.month, lastActivity.day);
      int daysDiff = today.difference(lastActivityDay).inDays;

      if (daysDiff == 1) {
        streak += 1;
        amount += 50;
        if (streak % 7 == 0) amount += 500;
      } else if (daysDiff > 1) {
        streak = 1;
      } else if (daysDiff == 0 && lastActivityTs == null) {
        streak = 1;
      }

      int newXp = currentXp + amount;
      transaction.update(userRef, {
        'xp_score': newXp,
        'streak': streak,
        'rank': _calculateRank(newXp),
        'last_activity_date': FieldValue.serverTimestamp()
      });
    });
  }

  String _calculateRank(int xp) {
    if (xp < 500) return 'Iron Novice';
    if (xp < 2000) return 'Bronze Watcher';
    if (xp < 5000) return 'Silver Binger';
    if (xp < 10000) return 'Gold Cinephile';
    if (xp < 20000) return 'Platinum Tracker';
    if (xp < 50000) return 'Diamond Master';
    return 'Absolute Legend';
  }
}