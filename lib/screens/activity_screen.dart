import 'package:flutter/material.dart';
import '../models/media_item.dart';

class ActivityScreen extends StatefulWidget {
  final List<MediaItem> allItems;
  final VoidCallback onUpdate;
  const ActivityScreen({super.key, required this.allItems, required this.onUpdate});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {

  void _showArchiveOptions(BuildContext context, MediaItem item) {
    showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 10,
                      shadowColor: const Color(0xFFFF6B00).withOpacity(0.5),
                    ),
                    icon: const Icon(Icons.replay_rounded, color: Colors.white),
                    label: const Text('Rewatch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () {
                      item.status = 'Active';
                      item.progress = 0;
                      widget.onUpdate();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0A2463), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.history_rounded, color: Color(0xFF0A2463)),
                    label: const Text('View History', style: TextStyle(color: Color(0xFF0A2463), fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History logs coming soon!'), backgroundColor: Color(0xFF0A2463)));
                    },
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  // --- NEW: Stat cards are now buttons with an onTap function! ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final watchLaterItems = widget.allItems.where((item) => item.isWatchLater && item.status != 'Completed').toList();
    final completedItems = widget.allItems.where((item) => item.completedCount > 0).toList();

    int totalMovies = completedItems.where((i) => i.type == 'Movie').fold<int>(0, (sum, item) => sum + item.completedCount);
    int totalShows = completedItems.where((i) => i.type == 'Show').fold<int>(0, (sum, item) => sum + item.completedCount);

    // --- BUG FIXED: We filter out 'Movie' types before doing the episode math! ---
    int totalEpisodes = widget.allItems.where((i) => i.type != 'Movie').fold<int>(0, (sum, item) {
      int pastEps = item.total * item.completedCount;
      int currentEps = item.status != 'Completed' ? item.progress : 0;
      return sum + pastEps + currentEps;
    });

    return DefaultTabController(
      length: 2,
      // --- NEW: Swapped the order of the tabs so Archive is the default opening tab ---
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFF6B00),
            indicatorWeight: 4,
            labelColor: Color(0xFF0A2463),
            labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            unselectedLabelColor: Colors.black38,
            tabs: [
              Tab(text: 'Archive'),
              Tab(text: 'Watch Later'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: ARCHIVE & STATS (Moved to the front)
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
                            _buildStatCard('Movies', totalMovies.toString(), Icons.movie_rounded, const Color(0xFF0A2463), () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Movies History Tab coming soon!'), backgroundColor: Color(0xFF0A2463)));
                            }),
                            const SizedBox(width: 16),
                            _buildStatCard('Shows', totalShows.toString(), Icons.tv_rounded, const Color(0xFFFF6B00), () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shows History Tab coming soon!'), backgroundColor: Color(0xFF0A2463)));
                            }),
                            const SizedBox(width: 16),
                            _buildStatCard('Episodes', totalEpisodes.toString(), Icons.layers_rounded, const Color(0xFFFFC300), () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Episodes History Tab coming soon!'), backgroundColor: Color(0xFF0A2463)));
                            }),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text('Completed Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                      ],
                    ),
                  ),
                ),
                completedItems.isEmpty
                    ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text("You haven't completed anything yet.", style: TextStyle(color: Colors.black38, fontSize: 16))),
                  ),
                )
                    : SliverPadding(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, childAspectRatio: 0.65, crossAxisSpacing: 16, mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final item = completedItems[index];
                        return GestureDetector(
                          onLongPress: () => _showArchiveOptions(context, item),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                                        image: item.posterUrl != null ? DecorationImage(image: NetworkImage(item.posterUrl!), fit: BoxFit.cover) : null,
                                        color: Colors.grey[200],
                                      ),
                                      child: item.posterUrl == null ? const Center(child: Icon(Icons.movie, color: Colors.white54)) : null,
                                    ),
                                    if (item.completedCount > 1)
                                      Positioned(
                                        top: -6, right: -6,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [BoxShadow(color: const Color(0xFFFF6B00).withOpacity(0.5), blurRadius: 8)],
                                          ),
                                          child: Text('x${item.completedCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                                        ),
                                      )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0A2463)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        );
                      },
                      childCount: completedItems.length,
                    ),
                  ),
                ),
              ],
            ),

            // TAB 2: WATCH LATER (Moved to the back)
            watchLaterItems.isEmpty
                ? const Center(child: Text("Your Watch Later list is empty.", style: TextStyle(color: Colors.black38, fontSize: 16)))
                : ListView.builder(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
              itemCount: watchLaterItems.length,
              itemBuilder: (context, index) {
                final item = watchLaterItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))]),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 50, height: 75,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: item.posterUrl != null ? DecorationImage(image: NetworkImage(item.posterUrl!), fit: BoxFit.cover) : null, color: Colors.grey[200]),
                    ),
                    title: Text(item.title, style: const TextStyle(color: Color(0xFF0A2463), fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Progress: ${item.progress}/${item.total}', style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.settings_backup_restore_rounded, color: Color(0xFFFF6B00)),
                      tooltip: 'Restore to Dashboard',
                      onPressed: () { item.isWatchLater = false; widget.onUpdate(); },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}