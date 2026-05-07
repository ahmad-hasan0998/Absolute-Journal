import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/media_item.dart';
import '../models/history_log.dart';
import '../providers/journal_provider.dart';
import '../services/database_service.dart';
import '../locator.dart';
import 'friend_profile_screen.dart';
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});
  ImageProvider? _getAvatarProvider(String? pic) {
    if (pic == null || pic.isEmpty) return null;
    if (pic.startsWith('base64,')) return MemoryImage(base64Decode(pic.substring(7)));
    return NetworkImage(pic);
  }
  void _showArchiveOptions(BuildContext context, MediaItem item) {
    showDialog(
        context: context, barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 10, shadowColor: const Color(0xFFFF6B00).withOpacity(0.5)),
                    icon: const Icon(Icons.replay_rounded, color: Colors.white), label: const Text('Rewatch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () { item.status = 'Active'; item.progress = 0; context.read<JournalProvider>().updateExistingMedia(item); Navigator.pop(context); },
                  ),
                ],
              ),
            ),
          );
        }
    );
  }
  void _showRankInfoDialog(BuildContext context, int currentXp, String currentRank) {
    final ranks = [
      {'name': 'Iron Novice', 'xp': 0, 'icon': Icons.shield_rounded, 'color': const Color(0xFF607D8B)},
      {'name': 'Bronze Watcher', 'xp': 500, 'icon': Icons.military_tech_rounded, 'color': const Color(0xFF8D6E63)},
      {'name': 'Silver Binger', 'xp': 2000, 'icon': Icons.military_tech_rounded, 'color': const Color(0xFF9E9E9E)},
      {'name': 'Gold Cinephile', 'xp': 5000, 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFFFFC107)},
      {'name': 'Platinum Tracker', 'xp': 10000, 'icon': Icons.diamond_rounded, 'color': const Color(0xFF4DD0E1)},
      {'name': 'Diamond Master', 'xp': 20000, 'icon': Icons.ac_unit_rounded, 'color': const Color(0xFF7C4DFF)},
      {'name': 'Absolute Legend', 'xp': 50000, 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFFF5252)},
    ];
    showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        builder: (context) {
          return DraggableScrollableSheet(
              expand: false, initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                    controller: scrollController, padding: const EdgeInsets.all(24.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                          const SizedBox(height: 24),
                          const Text('How to Rank Up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A2463)), textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('🎯 The Rules', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A2463), fontSize: 18)),
                                const SizedBox(height: 16),
                                _buildRuleRow(Icons.play_circle_filled_rounded, '+10 XP', 'Per episode watched'),
                                _buildRuleRow(Icons.check_circle_rounded, '+50 XP', 'Finishing a show or movie'),
                                _buildRuleRow(Icons.local_fire_department_rounded, '+50 XP', 'Daily streak bonus'),
                                _buildRuleRow(Icons.star_rounded, '+500 XP', '7-day perfect streak'),
                                _buildRuleRow(Icons.trending_down_rounded, '-50 XP', 'Per day missed (after 24h grace period)'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text('🏆 The Ranks', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A2463), fontSize: 18)),
                          const SizedBox(height: 16),
                          ...ranks.map((r) {
                            String rName = r['name'] as String;
                            int rXp = r['xp'] as int;
                            IconData rIcon = r['icon'] as IconData;
                            Color rColor = r['color'] as Color;
                            bool isCurrent = rName == currentRank;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: isCurrent ? rColor.withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(20), border: isCurrent ? Border.all(color: rColor, width: 2) : Border.all(color: Colors.grey[200]!)),
                              child: Row(
                                children: [
                                  Icon(rIcon, color: rColor, size: 36),
                                  const SizedBox(width: 16),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(rName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isCurrent ? rColor : const Color(0xFF0A2463))), Text('$rXp+ XP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black45))])),
                                  if (isCurrent) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: rColor, borderRadius: BorderRadius.circular(20)), child: const Text('YOU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)))
                                ],
                              ),
                            );
                          }),
                        ]
                    )
                );
              }
          );
        }
    );
  }
  Widget _buildRuleRow(IconData icon, String pts, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFFFF6B00)),
          const SizedBox(width: 12),
          SizedBox(width: 75, child: Text(pts, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF6B00), fontSize: 15))),
          Expanded(child: Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13))),
        ],
      ),
    );
  }
  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))]),
          child: Column(children: [Icon(icon, color: color, size: 32), const SizedBox(height: 12), Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)), const SizedBox(height: 4), Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)]),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final allItems = context.watch<JournalProvider>().activeItems;
    final completedItems = allItems.where((item) => item.completedCount > 0).toList();
    int totalMovies = completedItems.where((i) => i.type == 'Movie').fold<int>(0, (sum, item) => sum + item.completedCount);
    int totalShows = completedItems.where((i) => i.type == 'Show').fold<int>(0, (sum, item) => sum + item.completedCount);
    return StreamBuilder<DocumentSnapshot>(
        stream: locator<DatabaseService>().getUserProfileStream(),
        builder: (context, snapshot) {
          var userData = snapshot.hasData ? (snapshot.data!.data() as Map<String, dynamic>? ?? {}) : {};
          List<dynamic> friendsList = userData['friends'] ?? [];
          int xpScore = userData['xp_score'] ?? 0;
          String rank = userData['rank'] ?? 'Iron Novice';
          var rankData = DatabaseService.getRankVisuals(rank);
          return DefaultTabController(
              length: 3,
              child: Scaffold(
                  appBar: AppBar(
                    title: const Text('Activity', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                    bottom: const TabBar(indicatorColor: Color(0xFFFF6B00), indicatorWeight: 4, labelColor: Color(0xFF0A2463), labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 14), unselectedLabelColor: Colors.black38, tabs: [Tab(text: 'Archive'), Tab(text: 'Leaderboard'), Tab(text: 'Feed')]),
                  ),
                  body: TabBarView(
                    children: [
                      CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('All-Time Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _buildStatCard('Movies', totalMovies.toString(), Icons.movie_rounded, const Color(0xFF0A2463), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(filterType: 'Movie')))),
                                      const SizedBox(width: 16),
                                      _buildStatCard('Shows', totalShows.toString(), Icons.tv_rounded, const Color(0xFFFF6B00), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(filterType: 'Show')))),
                                      const SizedBox(width: 16),
                                      _buildStatCard(rank, xpScore.toString(), rankData['icon'], rankData['color'], () => _showRankInfoDialog(context, xpScore, rank)),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A2463), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), minimumSize: const Size(double.infinity, 50)),
                                    icon: const Icon(Icons.bookmark_rounded, color: Colors.white), label: const Text('Watch Later List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchLaterScreen())),
                                  ),
                                  const SizedBox(height: 32),
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Completed Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                                        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedMediaScreen())), child: const Text('See All', style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold))),
                                      ]
                                  )
                                ],
                              ),
                            ),
                          ),
                          completedItems.isEmpty
                              ? const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text("You haven't completed anything yet.", style: TextStyle(color: Colors.black38, fontSize: 16)))))
                              : SliverPadding(
                            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.65, crossAxisSpacing: 12, mainAxisSpacing: 12),
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                  final item = completedItems.take(4).toList()[index];
                                  return GestureDetector(
                                    onTap: () => _showArchiveOptions(context, item),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: Stack(clipBehavior: Clip.none, children: [Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))], image: item.posterUrl != null ? DecorationImage(image: NetworkImage(item.posterUrl!), fit: BoxFit.cover) : null, color: Colors.grey[200]), child: item.posterUrl == null ? const Center(child: Icon(Icons.movie, color: Colors.white54)) : null), if (item.completedCount > 1) Positioned(top: -6, right: -6, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: Text('x${item.completedCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 8))))])),
                                        const SizedBox(height: 6),
                                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0A2463)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  );
                                },
                                childCount: completedItems.length > 4 ? 4 : completedItems.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                      FutureBuilder<List<Map<String, dynamic>>>(
                          future: locator<DatabaseService>().getFriendsLeaderboard(friendsList),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)));
                            var users = snapshot.data!;
                            return ListView.builder(
                              padding: const EdgeInsets.only(top: 16, bottom: 0),
                              itemCount: users.length + 1,
                              itemBuilder: (context, index) {
                                if (index == users.length) {
                                  final lastMonthTop3 = List<Map<String, dynamic>>.from(users)..sort((a, b) => (a['prev_rank'] ?? 999).compareTo(b['prev_rank'] ?? 999));
                                  final top3 = lastMonthTop3.where((u) => u['prev_rank'] != null && u['prev_rank'] <= 3).toList();
                                  if (top3.isEmpty) return const SizedBox(height: 120);
                                  return Padding(
                                      padding: const EdgeInsets.only(top: 32, bottom: 120),
                                      child: Column(
                                          children: [
                                            const Text("🏆 LAST MONTH'S CHAMPIONS 🏆", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A2463), letterSpacing: 1.2, fontSize: 16)),
                                            const SizedBox(height: 16),
                                            ...top3.map((u) {
                                              int pRank = u['prev_rank'];
                                              Color badgeColor = pRank == 1 ? const Color(0xFFFFC300) : (pRank == 2 ? const Color(0xFFBDBDBD) : const Color(0xFF8D6E63));
                                              Color textColor = pRank == 2 ? const Color(0xFF757575) : badgeColor;
                                              return Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                                                decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: badgeColor, width: 1.5)),
                                                child: ListTile(
                                                  leading: Icon(Icons.workspace_premium_rounded, color: badgeColor, size: 32),
                                                  title: Text(u['username'] ?? 'Unknown User', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                                  trailing: Text('${u['last_month_xp'] ?? 0} XP', style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
                                                ),
                                              );
                                            })
                                          ]
                                      )
                                  );
                                }
                                var user = users[index];
                                bool isMe = user['uid'] == locator<DatabaseService>().currentUserId;
                                var uRankData = DatabaseService.getRankVisuals(user['rank'] ?? 'Iron Novice');
                                return GestureDetector(
                                  onTap: () { if (!isMe) Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(uid: user['uid']))); },
                                  child: Container(margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), decoration: BoxDecoration(color: isMe ? const Color(0xFFFF6B00).withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(16), border: isMe ? Border.all(color: const Color(0xFFFF6B00), width: 2) : null, boxShadow: !isMe ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))] : []), child: ListTile(leading: Text('#${index + 1}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isMe ? const Color(0xFFFF6B00) : Colors.black26)), title: Row(children: [Flexible(child: Text(user['username'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A2463)), maxLines: 1, overflow: TextOverflow.ellipsis)), if (user['prev_rank'] != null && user['prev_rank'] <= 3) ...[const SizedBox(width: 6), Icon(Icons.workspace_premium_rounded, size: 18, color: user['prev_rank'] == 1 ? const Color(0xFFFFC300) : (user['prev_rank'] == 2 ? const Color(0xFFBDBDBD) : const Color(0xFF8D6E63)))]]), subtitle: Row(children: [Icon(uRankData['icon'], color: uRankData['color'], size: 14), const SizedBox(width: 4), Text(user['rank'] ?? '', style: TextStyle(color: uRankData['color'], fontWeight: FontWeight.bold, fontSize: 11))]), trailing: Text('${user['xp_score'] ?? 0} XP', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFFC300))))),
                                );
                              },
                            );
                          }
                      ),
                      FutureBuilder<List<Map<String, dynamic>>>(
                          future: locator<DatabaseService>().getFriendsFeed(friendsList),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)));
                            var feed = snapshot.data!;
                            if (feed.isEmpty) return const Center(child: Text("Add friends to see their activity here!", style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)));
                            return ListView.builder(
                              padding: const EdgeInsets.only(top: 16, bottom: 120),
                              itemCount: feed.length,
                              itemBuilder: (context, index) {
                                var post = feed[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 12))]),
                                  child: Row(
                                    children: [
                                      Container(width: 50, height: 75, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), image: post['posterUrl'] != null ? DecorationImage(image: NetworkImage(post['posterUrl']), fit: BoxFit.cover) : null)),
                                      const SizedBox(width: 16),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(post['title'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A2463)), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text('${post['type']} • Watched', style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(post['lastUpdated'] ?? '', style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 11, fontWeight: FontWeight.bold))])),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () { if (post['uid'] != null) Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(uid: post['uid']))); },
                                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 20, backgroundColor: const Color(0xFF0A2463), backgroundImage: _getAvatarProvider(post['friendPic']), child: (post['friendPic'] == null || post['friendPic'].isEmpty) ? const Icon(Icons.person, color: Colors.white, size: 20) : null), const SizedBox(height: 6), Text(post['friendName'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF0A2463)))]),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                      ),
                    ],
                  )
              )
          );
        }
    );
  }
}
class HistoryScreen extends StatefulWidget {
  final String filterType;
  const HistoryScreen({super.key, required this.filterType});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}
class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<HistoryLog>> _historyFuture;
  @override
  void initState() {
    super.initState();
    _historyFuture = locator<DatabaseService>().getHistoryLogs(widget.filterType);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0A2463)), onPressed: () => Navigator.pop(context)), title: Text('${widget.filterType} History', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF0A2463))), backgroundColor: Colors.transparent, elevation: 0),
        body: FutureBuilder<List<HistoryLog>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text(snapshot.error.toString(), style: const TextStyle(color: Colors.red)));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)));
              var historyItems = snapshot.data!;
              if (historyItems.isEmpty) return Center(child: Text("You haven't watched any ${widget.filterType.toLowerCase()}s yet.", style: const TextStyle(color: Colors.black38, fontSize: 16)));
              Map<String, List<HistoryLog>> grouped = {};
              for (var item in historyItems) {
                String dateStr = DateFormat('MMMM d, yyyy').format(item.timestamp);
                grouped.putIfAbsent(dateStr, () => []).add(item);
              }
              return ListView.builder(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
                itemCount: grouped.keys.length,
                itemBuilder: (context, index) {
                  String date = grouped.keys.elementAt(index);
                  List<HistoryLog> items = grouped[date]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.symmetric(vertical: 16.0), child: Text(date, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A2463)))),
                      ...items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(width: 45, height: 65, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: item.posterUrl != null ? DecorationImage(image: NetworkImage(item.posterUrl!), fit: BoxFit.cover) : null, color: Colors.grey[200])),
                          title: Text(item.title, style: const TextStyle(color: Color(0xFF0A2463), fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Row(
                              children: [
                                Text(item.action, style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(width: 8),
                                Text(DateFormat('h:mm a').format(item.timestamp), style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold, fontSize: 12)),
                              ]
                          ),
                          trailing: item.isLiked == true ? const Icon(Icons.thumb_up_rounded, color: Color(0xFF0A2463)) : (item.isLiked == false ? const Icon(Icons.thumb_down_rounded, color: Color(0xFFFF6B00)) : null),
                        ),
                      ))
                    ],
                  );
                },
              );
            }
        )
    );
  }
}
class WatchLaterScreen extends StatelessWidget {
  const WatchLaterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final watchLaterItems = context.watch<JournalProvider>().activeItems.where((item) => item.isWatchLater && item.status != 'Completed').toList();
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0A2463)), onPressed: () => Navigator.pop(context)), title: const Text('Watch Later', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF0A2463))), backgroundColor: Colors.transparent, elevation: 0),
      body: watchLaterItems.isEmpty
          ? const Center(child: Text("Your Watch Later list is empty.", style: TextStyle(color: Colors.black38, fontSize: 16)))
          : ListView.builder(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
        itemCount: watchLaterItems.length,
        itemBuilder: (context, index) {
          final item = watchLaterItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))]),
            child: ListTile(contentPadding: EdgeInsets.zero, leading: Container(width: 50, height: 75, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: item.posterUrl != null ? DecorationImage(image: NetworkImage(item.posterUrl!), fit: BoxFit.cover) : null, color: Colors.grey[200])), title: Text(item.title, style: const TextStyle(color: Color(0xFF0A2463), fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text('Progress: ${item.progress}/${item.total}', style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)), trailing: IconButton(icon: const Icon(Icons.settings_backup_restore_rounded, color: Color(0xFFFF6B00)), tooltip: 'Restore to Dashboard', onPressed: () { item.isWatchLater = false; context.read<JournalProvider>().updateExistingMedia(item); })),
          );
        },
      ),
    );
  }
}
class CompletedMediaScreen extends StatefulWidget {
  const CompletedMediaScreen({super.key});
  @override
  State<CompletedMediaScreen> createState() => _CompletedMediaScreenState();
}
class _CompletedMediaScreenState extends State<CompletedMediaScreen> {
  String _filter = 'All';
  void _showArchiveOptions(BuildContext context, MediaItem item) {
    showDialog(
        context: context, barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 10, shadowColor: const Color(0xFFFF6B00).withOpacity(0.5)),
                    icon: const Icon(Icons.replay_rounded, color: Colors.white), label: const Text('Rewatch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () { item.status = 'Active'; item.progress = 0; context.read<JournalProvider>().updateExistingMedia(item); Navigator.pop(context); },
                  ),
                ],
              ),
            ),
          );
        }
    );
  }
  @override
  Widget build(BuildContext context) {
    final allItems = context.watch<JournalProvider>().activeItems;
    var completedItems = allItems.where((item) => item.completedCount > 0).toList();
    if (_filter == 'Movies') completedItems = completedItems.where((i) => i.type == 'Movie').toList();
    if (_filter == 'Shows') completedItems = completedItems.where((i) => i.type == 'Show').toList();
    return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0A2463)), onPressed: () => Navigator.pop(context)), title: const Text('Archive', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF0A2463))), backgroundColor: Colors.transparent, elevation: 0),
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
                itemCount: completedItems.length,
                itemBuilder: (context, index) {
                  final item = completedItems[index];
                  return GestureDetector(
                    onTap: () => _showArchiveOptions(context, item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Stack(clipBehavior: Clip.none, children: [Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))], image: item.posterUrl != null ? DecorationImage(image: NetworkImage(item.posterUrl!), fit: BoxFit.cover) : null, color: Colors.grey[200])), if (item.completedCount > 1) Positioned(top: -6, right: -6, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: Text('x${item.completedCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10))))])),
                        const SizedBox(height: 8),
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0A2463)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        )
    );
  }
}