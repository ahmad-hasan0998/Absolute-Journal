import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/media_item.dart';

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

  Future<String?> addMediaToJournal(MediaItem item) async {
    if (currentUserId == null) return null;
    var docRef = await _db.collection('users').doc(currentUserId).collection('my_journal').add({
      'title': item.title,
      'type': item.type,
      'status': item.status,
      'progress': item.progress,
      'total': item.total,
      'lastUpdated': item.lastUpdated,
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
    if (currentUserId == null) return [];
    var snapshot = await _db.collection('users').doc(currentUserId).collection('my_journal').orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) {
      var data = doc.data();
      return MediaItem(
        id: doc.id,
        title: data['title'] ?? 'Unknown',
        type: data['type'] ?? 'Movie',
        status: data['status'] ?? 'Active',
        progress: data['progress'] ?? 0,
        total: data['total'] ?? 1,
        lastUpdated: data['lastUpdated'] ?? 'Just now',
        posterUrl: data['posterUrl'],
        isWatchLater: data['isWatchLater'] == true,
        isTop5: data['isTop5'] == true,
        completedCount: data['completedCount'] ?? 0,
        isLiked: data['isLiked'],
      );
    }).toList();
  }

  Future<void> updateMedia(MediaItem item) async {
    if (currentUserId == null || item.id == null) return;
    await _db.collection('users').doc(currentUserId).collection('my_journal').doc(item.id).update({
      'progress': item.progress,
      'status': item.status,
      'completedCount': item.completedCount,
      'isWatchLater': item.isWatchLater,
      'isTop5': item.isTop5,
      'isLiked': item.isLiked,
      'lastUpdated': item.lastUpdated,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMedia(String mediaId) async {
    if (currentUserId == null) return;
    await _db.collection('users').doc(currentUserId).collection('my_journal').doc(mediaId).delete();
  }

  Future<void> uploadProfilePicture(XFile file) async {
    if (currentUserId == null) return;
    try {
      List<int> imageBytes = await file.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      await _db.collection('users').doc(currentUserId).update({'profileUrl': 'base64,$base64Image'});
    } catch (e) {
      throw Exception('Failed to save profile picture.');
    }
  }

  Stream<DocumentSnapshot> getUserProfileStream() {
    return _db.collection('users').doc(currentUserId).snapshots();
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    var doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return {'uid': doc.id, ...doc.data()!};
    return null;
  }

  Future<List<MediaItem>> getJournalByUid(String uid) async {
    var snapshot = await _db.collection('users').doc(uid).collection('my_journal').orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) {
      var data = doc.data();
      return MediaItem(
        id: doc.id,
        title: data['title'] ?? 'Unknown',
        type: data['type'] ?? 'Movie',
        status: data['status'] ?? 'Active',
        progress: data['progress'] ?? 0,
        total: data['total'] ?? 1,
        lastUpdated: data['lastUpdated'] ?? 'Just now',
        posterUrl: data['posterUrl'],
        isWatchLater: data['isWatchLater'] == true,
        isTop5: data['isTop5'] == true,
        completedCount: data['completedCount'] ?? 0,
        isLiked: data['isLiked'],
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    var snapshot = await _db.collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    return snapshot.docs.where((doc) => doc.id != currentUserId).map((doc) => {'uid': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getFriendsProfiles(List<dynamic> uids) async {
    if (uids.isEmpty) return [];
    List<Map<String, dynamic>> friends = [];
    for (String uid in uids) {
      var doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) friends.add({'uid': doc.id, ...doc.data()!});
    }
    return friends;
  }

  Future<void> toggleFriend(String friendUid, bool isAdding) async {
    if (currentUserId == null) return;
    if (isAdding) {
      await _db.collection('users').doc(currentUserId).update({'friends': FieldValue.arrayUnion([friendUid])});
    } else {
      await _db.collection('users').doc(currentUserId).update({'friends': FieldValue.arrayRemove([friendUid])});
    }
  }

  Future<List<Map<String, dynamic>>> getFriendsFeed(List<dynamic> friendIds) async {
    if (friendIds.isEmpty) return [];
    List<Map<String, dynamic>> feed = [];
    for (String uid in friendIds) {
      var userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) continue;
      String friendName = userDoc.data()?['username'] ?? 'Unknown';
      String friendPic = userDoc.data()?['profileUrl'] ?? '';

      var journal = await _db.collection('users').doc(uid).collection('my_journal').orderBy('timestamp', descending: true).limit(3).get();
      for (var doc in journal.docs) {
        var data = doc.data();
        data['friendName'] = friendName;
        data['friendPic'] = friendPic;
        data['timestamp_sort'] = data['timestamp'];
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
    if (currentUserId == null) return [];
    List<String> idsToFetch = [currentUserId!, ...friendIds.map((e) => e.toString())];
    List<Map<String, dynamic>> leaderboard = [];
    for (String uid in idsToFetch) {
      var doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) leaderboard.add({'uid': doc.id, ...doc.data()!});
    }
    leaderboard.sort((a, b) => (b['xp_score'] ?? 0).compareTo(a['xp_score'] ?? 0));
    return leaderboard;
  }

  Future<void> addXP(int amount) async {
    if (currentUserId == null) return;
    DocumentReference userRef = _db.collection('users').doc(currentUserId);
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;
      int currentXp = snapshot.get('xp_score') ?? 0;
      int newXp = currentXp + amount;
      transaction.update(userRef, {'xp_score': newXp, 'rank': _calculateRank(newXp)});
    });
  }

  String _calculateRank(int xp) {
    if (xp < 100) return 'Iron Novice';
    if (xp < 500) return 'Bronze Watcher';
    if (xp < 1500) return 'Silver Binger';
    if (xp < 3000) return 'Gold Cinephile';
    if (xp < 5000) return 'Platinum Tracker';
    if (xp < 10000) return 'Diamond Master';
    return 'Absolute Legend';
  }
}