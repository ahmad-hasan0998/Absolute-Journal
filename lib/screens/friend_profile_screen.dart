// lib/screens/friend_profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/database_service.dart';
import '../locator.dart';
class FriendProfileScreen extends StatefulWidget {
  final String uid;
  const FriendProfileScreen({super.key, required this.uid});
  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}
class _FriendProfileScreenState extends State<FriendProfileScreen> {
  String _top5Filter = 'Movie';
  ImageProvider? _getAvatarProvider(String? pic) {
    if (pic == null || pic.isEmpty) return null;
    if (pic.startsWith('base64,')) return MemoryImage(base64Decode(pic.substring(7)));
    return NetworkImage(pic);
  }
  Widget _buildTopFiveSlot(MediaItem? item, BuildContext context) {
    double slotWidth = MediaQuery.of(context).size.width * 0.23;
    return Container(
      width: slotWidth, height: slotWidth * 1.5,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))], image: item?.posterUrl != null ? DecorationImage(image: NetworkImage(item!.posterUrl!), fit: BoxFit.cover) : null),
      child: item == null ? const Center(child: Icon(Icons.movie, color: Colors.black12, size: 24)) : null,
    );
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
        future: locator<DatabaseService>().getUserProfile(widget.uid),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Scaffold(backgroundColor: Color(0xFFF0F4F8), body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))));
          var user = userSnapshot.data!;
          String friendName = user['username'] ?? 'User';
          var rankData = DatabaseService.getRankVisuals(user['rank'] ?? 'Iron Novice');
          return Scaffold(
            backgroundColor: const Color(0xFFF0F4F8),
            appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0A2463)), onPressed: () => Navigator.pop(context)), title: Text(friendName.toUpperCase(), style: const TextStyle(fontFamily: 'Impact', fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 24, color: Color(0xFF0A2463))), backgroundColor: Colors.transparent, elevation: 0),
            body: FutureBuilder<List<MediaItem>>(
                future: locator<DatabaseService>().getJournalByUid(widget.uid),
                builder: (context, journalSnapshot) {
                  if (!journalSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)));
                  var allMedia = journalSnapshot.data!;
                  final completedItems = allMedia.where((item) => item.completedCount > 0 || item.status == 'Completed').toList();
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]), boxShadow: [BoxShadow(color: const Color(0xFFFF6B00).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]), child: Padding(padding: const EdgeInsets.all(3.0), child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, image: _getAvatarProvider(user['profileUrl']) != null ? DecorationImage(image: _getAvatarProvider(user['profileUrl'])!, fit: BoxFit.cover) : null), child: (user['profileUrl'] == null || user['profileUrl'].isEmpty) ? const Icon(Icons.person_rounded, size: 50, color: Color(0xFF0A2463)) : null))),
                            const SizedBox(height: 16),
                            Text(friendName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                            const SizedBox(height: 12),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: rankData['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: rankData['color'].withOpacity(0.5))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(rankData['icon'], color: rankData['color'], size: 16), const SizedBox(width: 6), Text(user['rank'] ?? '', style: TextStyle(color: rankData['color'], fontWeight: FontWeight.bold, fontSize: 13))])),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.bolt_rounded, color: Color(0xFFFFC300), size: 18), Text(' ${user['xp_score']} XP Score', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))]),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: StatefulBuilder(
                                  builder: (context, setTop5State) {
                                    final topMedia = allMedia.where((item) => item.type == _top5Filter && item.isTop5 == true).toList();
                                    return Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('$friendName\'s Top 5', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
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
                                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildTopFiveSlot(topMedia.isNotEmpty ? topMedia[0] : null, context), const SizedBox(width: 16), _buildTopFiveSlot(topMedia.length > 1 ? topMedia[1] : null, context), const SizedBox(width: 16), _buildTopFiveSlot(topMedia.length > 2 ? topMedia[2] : null, context)]),
                                        const SizedBox(height: 16),
                                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildTopFiveSlot(topMedia.length > 3 ? topMedia[3] : null, context), const SizedBox(width: 16), _buildTopFiveSlot(topMedia.length > 4 ? topMedia[4] : null, context)]),
                                        const SizedBox(height: 40),
                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Completed Archive', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                                              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FriendCompletedMediaScreen(items: completedItems, friendName: friendName))), child: const Text('See All', style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold))),
                                            ]
                                        ),
                                      ],
                                    );
                                  }
                              ),
                            )
                          ],
                        ),
                      ),
                      completedItems.isEmpty
                          ? SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 20), child: Center(child: Text("$friendName hasn't completed anything.", style: const TextStyle(color: Colors.black38, fontSize: 16)))))
                          : SliverPadding(
                        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.65, crossAxisSpacing: 12, mainAxisSpacing: 12),
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final item = completedItems.take(4).toList()[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: Stack(clipBehavior: Clip.none, children: [Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))], image: item.posterUrl != null ? DecorationImage(image: NetworkImage(item.posterUrl!), fit: BoxFit.cover) : null, color: Colors.grey[200])), if (item.completedCount > 1) Positioned(top: -6, right: -6, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: Text('x${item.completedCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 8))))])),
                                  const SizedBox(height: 6),
                                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0A2463)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              );
                            },
                            childCount: completedItems.length > 4 ? 4 : completedItems.length,
                          ),
                        ),
                      ),
                    ],
                  );
                }
            ),
          );
        }
    );
  }
}
class FriendCompletedMediaScreen extends StatefulWidget {
  final List<MediaItem> items;
  final String friendName;
  const FriendCompletedMediaScreen({super.key, required this.items, required this.friendName});
  @override
  State<FriendCompletedMediaScreen> createState() => _FriendCompletedMediaScreenState();
}
class _FriendCompletedMediaScreenState extends State<FriendCompletedMediaScreen> {
  String _filter = 'All';
  @override
  Widget build(BuildContext context) {
    var displayItems = widget.items;
    if (_filter == 'Movies') displayItems = displayItems.where((i) => i.type == 'Movie').toList();
    if (_filter == 'Shows') displayItems = displayItems.where((i) => i.type == 'Show').toList();
    return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0A2463)), onPressed: () => Navigator.pop(context)), title: Text('${widget.friendName}\'s Archive', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0A2463))), backgroundColor: Colors.transparent, elevation: 0),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['All', 'Movies', 'Shows'].map((f) => GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: _filter == f ? const Color(0xFF0A2463) : Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                      child: Text(f, style: TextStyle(color: _filter == f ? Colors.white : Colors.black45, fontWeight: FontWeight.bold)),
                    )
                )).toList(),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.65, crossAxisSpacing: 16, mainAxisSpacing: 16),
                itemCount: displayItems.length,
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Stack(clipBehavior: Clip.none, children: [Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))], image: item.posterUrl != null ? DecorationImage(image: NetworkImage(item.posterUrl!), fit: BoxFit.cover) : null, color: Colors.grey[200])), if (item.completedCount > 1) Positioned(top: -6, right: -6, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: Text('x${item.completedCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10))))])),
                      const SizedBox(height: 8),
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0A2463)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  );
                },
              ),
            )
          ],
        )
    );
  }
}