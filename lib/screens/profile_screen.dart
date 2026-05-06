// lib/screens/profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/media_item.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/search_api_dialog.dart';
import '../providers/journal_provider.dart';
import '../locator.dart';
import 'friend_profile_screen.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  String _top5Filter = 'Movie';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _userSearchResults = [];
  bool _isSearching = false;
  ImageProvider? _getAvatarProvider(String? pic) {
    if (pic == null || pic.isEmpty) return null;
    if (pic.startsWith('base64,')) return MemoryImage(base64Decode(pic.substring(7)));
    return NetworkImage(pic);
  }
  void _showFriendsDirectory(List<dynamic> currentFriendIds) async {
    _searchController.clear();
    _userSearchResults.clear();
    setState(() => _isSearching = true);
    List<Map<String, dynamic>> loadedFriends = await locator<DatabaseService>().getFriendsProfiles(currentFriendIds);
    bool isShowingSearch = false;
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setDialogState) {
                List<Map<String, dynamic>> displayList = isShowingSearch ? _userSearchResults : loadedFriends;
                return Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(isShowingSearch ? 'Search Results' : 'Your Friends', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A2463)), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: (val) { if (val.isEmpty) setDialogState(() => isShowingSearch = false); },
                          onSubmitted: (val) async {
                            if (val.isEmpty) return;
                            setDialogState(() { isShowingSearch = true; _isSearching = true; });
                            var res = await locator<DatabaseService>().searchUsers(val);
                            setDialogState(() { _userSearchResults = res; _isSearching = false; });
                          },
                          decoration: InputDecoration(hintText: 'Search username...', prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0A2463)), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _isSearching && isShowingSearch
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
                              : displayList.isEmpty
                              ? Center(child: Text(isShowingSearch ? 'No users found.' : 'You have no friends yet.', style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)))
                              : ListView.builder(
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              var u = displayList[index];
                              bool isAdded = currentFriendIds.contains(u['uid']);
                              String pic = u['profileUrl'] ?? '';
                              var rankData = DatabaseService.getRankVisuals(u['rank'] ?? 'Beginner Tracker');
                              return ListTile(
                                leading: CircleAvatar(backgroundColor: const Color(0xFF0A2463), backgroundImage: _getAvatarProvider(pic), child: pic.isEmpty ? const Icon(Icons.person, color: Colors.white) : null),
                                title: Text(u['username'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A2463))),
                                subtitle: Row(children: [Icon(rankData['icon'], color: rankData['color'], size: 14), const SizedBox(width: 4), Text('${u['xp_score']} XP', style: TextStyle(color: rankData['color'], fontWeight: FontWeight.bold, fontSize: 12))]),
                                trailing: TextButton(
                                  style: TextButton.styleFrom(backgroundColor: isAdded ? Colors.grey[200] : const Color(0xFF0A2463)),
                                  onPressed: () async {
                                    await locator<DatabaseService>().toggleFriend(u['uid'], !isAdded);
                                    setDialogState(() {
                                      if (isAdded) { currentFriendIds.remove(u['uid']); if (!isShowingSearch) loadedFriends.removeWhere((f) => f['uid'] == u['uid']); } else { currentFriendIds.add(u['uid']); }
                                    });
                                    setState(() {});
                                  },
                                  child: Text(isAdded ? 'Remove' : 'Add', style: TextStyle(color: isAdded ? Colors.black54 : Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(uid: u['uid']))); },
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 200, maxHeight: 200, imageQuality: 70);
    if (image != null) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))));
      try { await locator<DatabaseService>().uploadProfilePicture(image); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
      if (mounted) Navigator.pop(context);
    }
  }
  Widget _buildTopFiveSlot(MediaItem? item, BuildContext context, Function setLocalState) {
    double slotWidth = MediaQuery.of(context).size.width * 0.23;
    return GestureDetector(
      onTap: () {
        if (item == null) {
          showDialog(
            context: context, barrierColor: Colors.black.withOpacity(0.6),
            builder: (context) => SearchApiDialog(
              isForTop5: true,
              onItemAdded: (newItem) async {
                newItem.type = _top5Filter;
                await context.read<JournalProvider>().addMedia(newItem);
                setLocalState((){});
              },
            ),
          );
        } else {
          showDialog(context: context, builder: (context) => AlertDialog(
              title: const Text('Remove from Top 5?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(onPressed: () { item.isTop5 = false; context.read<JournalProvider>().updateExistingMedia(item); setLocalState((){}); Navigator.pop(context); }, child: const Text('Remove', style: TextStyle(color: Colors.redAccent))),
              ]
          ));
        }
      },
      child: Container(
        width: slotWidth, height: slotWidth * 1.5,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))], image: item?.posterUrl != null ? DecorationImage(image: NetworkImage(item!.posterUrl!), fit: BoxFit.cover) : null),
        child: item == null ? const Center(child: Icon(Icons.add_rounded, color: Colors.black26, size: 24)) : null,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final activeItems = context.watch<JournalProvider>().activeItems;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF0A2463))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          StreamBuilder<DocumentSnapshot>(
              stream: locator<DatabaseService>().getUserProfileStream(),
              builder: (context, snapshot) {
                List<dynamic> friendsList = snapshot.hasData ? (snapshot.data!.data() as Map<String, dynamic>? ?? {})['friends'] ?? [] : [];
                return IconButton(icon: const Icon(Icons.person_add_rounded, color: Color(0xFF0A2463)), onPressed: () => _showFriendsDirectory(friendsList));
              }
          ),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFF0A2463)), onPressed: () async { await locator<AuthService>().signOut(); if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false); })
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
          stream: locator<DatabaseService>().getUserProfileStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)));
            var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            String username = userData['username'] ?? 'User';
            String rank = userData['rank'] ?? 'Iron Novice';
            int xpScore = userData['xp_score'] ?? 0;
            String? profileUrl = userData['profileUrl'];
            var rankData = DatabaseService.getRankVisuals(rank);
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]), boxShadow: [BoxShadow(color: const Color(0xFFFF6B00).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]), child: Padding(padding: const EdgeInsets.all(3.0), child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, image: profileUrl != null && profileUrl.isNotEmpty ? DecorationImage(image: _getAvatarProvider(profileUrl)!, fit: BoxFit.cover) : null), child: profileUrl == null || profileUrl.isEmpty ? const Icon(Icons.person_rounded, size: 50, color: Color(0xFF0A2463)) : null))),
                        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF0A2463), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white))
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: rankData['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: rankData['color'].withOpacity(0.5))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(rankData['icon'], color: rankData['color'], size: 16), const SizedBox(width: 6), Text(rank, style: TextStyle(color: rankData['color'], fontWeight: FontWeight.bold, fontSize: 13))])),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.bolt_rounded, color: Color(0xFFFFC300), size: 18), Text(' $xpScore XP Score', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))]),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: StatefulBuilder(
                        builder: (context, setTop5State) {
                          final topMedia = activeItems.where((item) => item.type == _top5Filter && item.isTop5 == true).toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Top 5 Showcase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                                  Container(
                                    padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                                    child: Row(
                                      children: [
                                        GestureDetector(onTap: () => setTop5State(() => _top5Filter = 'Movie'), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: _top5Filter == 'Movie' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(16), boxShadow: _top5Filter == 'Movie' ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : []), child: Text('Movies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _top5Filter == 'Movie' ? const Color(0xFF0A2463) : Colors.black45)))),
                                        GestureDetector(onTap: () => setTop5State(() => _top5Filter = 'Show'), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: _top5Filter == 'Show' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(16), boxShadow: _top5Filter == 'Show' ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : []), child: Text('Shows', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _top5Filter == 'Show' ? const Color(0xFF0A2463) : Colors.black45)))),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildTopFiveSlot(topMedia.isNotEmpty ? topMedia[0] : null, context, setTop5State), const SizedBox(width: 16), _buildTopFiveSlot(topMedia.length > 1 ? topMedia[1] : null, context, setTop5State), const SizedBox(width: 16), _buildTopFiveSlot(topMedia.length > 2 ? topMedia[2] : null, context, setTop5State)]),
                              const SizedBox(height: 16),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildTopFiveSlot(topMedia.length > 3 ? topMedia[3] : null, context, setTop5State), const SizedBox(width: 16), _buildTopFiveSlot(topMedia.length > 4 ? topMedia[4] : null, context, setTop5State)]),
                            ],
                          );
                        }
                    ),
                  )
                ],
              ),
            );
          }
      ),
    );
  }
}