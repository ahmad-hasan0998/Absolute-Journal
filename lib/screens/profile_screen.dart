import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../models/friend.dart';
import 'friend_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final List<MediaItem> activeItems;
  const ProfileScreen({super.key, required this.activeItems});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _top5Filter = 'Movie'; // Toggles between Movie / Show

  // Local state to handle adding/removing friends immediately
  List<Friend> myNetwork = MockNetwork.friends;

  // --- FIX: THE FRIENDS DIRECTORY POPUP ---
  void _showFriendsDirectory() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    height: 500,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Your Network', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A2463)), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search friends...',
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0A2463)),
                            filled: true, fillColor: Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: myNetwork.length,
                            itemBuilder: (context, index) {
                              final friend = myNetwork[index];
                              return ListTile(
                                leading: const CircleAvatar(backgroundColor: Color(0xFF0A2463), child: Icon(Icons.person, color: Colors.white)),
                                title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A2463))),
                                subtitle: Text('${friend.xp} XP', style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 12)),
                                trailing: TextButton(
                                  style: TextButton.styleFrom(backgroundColor: friend.isAdded ? Colors.grey[200] : const Color(0xFF0A2463)),
                                  onPressed: () {
                                    setDialogState(() => friend.isAdded = !friend.isAdded);
                                    setState(() {}); // Update the background counter too
                                  },
                                  child: Text(friend.isAdded ? 'Remove' : 'Add', style: TextStyle(color: friend.isAdded ? Colors.black54 : Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: friend)));
                                },
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

  Widget _buildTopFiveSlot(MediaItem? item) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 2),
        image: item?.posterUrl != null ? DecorationImage(image: NetworkImage(item!.posterUrl!), fit: BoxFit.cover) : null,
      ),
      child: item == null ? const Center(child: Icon(Icons.add_rounded, color: Colors.black26, size: 32)) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    int friendCount = myNetwork.where((f) => f.isAdded).length;

    // --- FIX: REAL TOP 5 FROM YOUR DATA ---
    final topMedia = widget.activeItems.where((item) => item.type == _top5Filter).toList();
    // Sort them so completed stuff or things with high progress show first
    topMedia.sort((a, b) => b.completedCount.compareTo(a.completedCount));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          // --- FIX: REMOVED IMPACT FONT ---
          title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF0A2463))),
          actions: [IconButton(icon: const Icon(Icons.settings_rounded), onPressed: () {})],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]),
                              boxShadow: [BoxShadow(color: const Color(0xFFFF6B00).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: const Icon(Icons.person_rounded, size: 50, color: Color(0xFF0A2463))),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ahmad Hasan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                                const SizedBox(height: 4),
                                // --- FIX: TAPPABLE FRIENDS COUNT ---
                                GestureDetector(
                                  onTap: _showFriendsDirectory,
                                  child: Text('$friendCount Friends', style: const TextStyle(color: Color(0xFF0A2463), fontWeight: FontWeight.bold, fontSize: 14, decoration: TextDecoration.underline)),
                                ),
                                const SizedBox(height: 8),
                                const Row(children: [Icon(Icons.bolt_rounded, color: Color(0xFFFFC300), size: 18), Text(' 1,420 XP Score', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))]),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Top 5 Showcase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _top5Filter = 'Movie'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(color: _top5Filter == 'Movie' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(16), boxShadow: _top5Filter == 'Movie' ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : []),
                                    child: Text('Movies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _top5Filter == 'Movie' ? const Color(0xFF0A2463) : Colors.black45)),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _top5Filter = 'Show'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(color: _top5Filter == 'Show' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(16), boxShadow: _top5Filter == 'Show' ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : []),
                                    child: Text('Shows', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _top5Filter == 'Show' ? const Color(0xFF0A2463) : Colors.black45)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              MediaItem? item = index < topMedia.length ? topMedia[index] : null;
                              return _buildTopFiveSlot(item);
                            }
                        ),
                      ),
                    ],
                  ),
                ),
              ),
               SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: Color(0xFFFF6B00), indicatorWeight: 4, labelColor: Color(0xFF0A2463),
                    labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 16), unselectedLabelColor: Colors.black38,
                    tabs: [Tab(text: 'Leaderboard'), Tab(text: 'Recent Feed')],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // TAB 1: Leaderboard (Moved to front)
              ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 120),
                itemCount: myNetwork.length + 1,
                itemBuilder: (context, index) {
                  bool isMe = index == 2; // Inject user artificially for prototype
                  Friend? friend = isMe ? null : myNetwork[index > 2 ? index - 1 : index];

                  return GestureDetector(
                    onTap: () {
                      if (!isMe) Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: friend!)));
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFFF6B00).withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isMe ? Border.all(color: const Color(0xFFFF6B00), width: 2) : null,
                        boxShadow: !isMe ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))] : [],
                      ),
                      child: ListTile(
                        leading: Text('#${index + 1}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isMe ? const Color(0xFFFF6B00) : Colors.black26)),
                        title: Text(isMe ? 'Ahmad Hasan' : friend!.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A2463))),
                        trailing: Text('${1500 - (index * 50)} XP', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFFC300))),
                      ),
                    ),
                  );
                },
              ),

              // TAB 2: Friends Activity Feed
              ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 120),
                itemCount: myNetwork.length,
                itemBuilder: (context, index) {
                  final friend = myNetwork[index];
                  if (friend.allMedia.isEmpty) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 12))]),
                    child: Row(
                      children: [
                        Container(
                          width: 70, height: 100,
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16), image: DecorationImage(image: NetworkImage(friend.allMedia.first.posterUrl!), fit: BoxFit.cover)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(friend.allMedia.first.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A2463)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('${friend.allMedia.first.type} • Watched', style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(friend.allMedia.first.lastUpdated, style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)])),
                              child: const CircleAvatar(radius: 20, backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFF0A2463), size: 24)),
                            ),
                            const SizedBox(height: 6),
                            Text(friend.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF0A2463))),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) { return Container(color: const Color(0xFFF0F4F8), child: _tabBar); }
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}