import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../models/media_item.dart';

class FriendProfileScreen extends StatefulWidget {
  final Friend friend;
  const FriendProfileScreen({super.key, required this.friend});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  String _top5Filter = 'Movie';

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
      child: item == null ? const Center(child: Icon(Icons.movie, color: Colors.black12, size: 32)) : null,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Stat Logic applied directly to friend's media
    final completedItems = widget.friend.allMedia.where((item) => item.completedCount > 0).toList();
    int totalMovies = completedItems.where((i) => i.type == 'Movie').fold<int>(0, (sum, item) => sum + item.completedCount);
    int totalShows = completedItems.where((i) => i.type == 'Show').fold<int>(0, (sum, item) => sum + item.completedCount);
    int totalEpisodes = widget.friend.allMedia.where((i) => i.type != 'Movie').fold<int>(0, (sum, item) {
      int pastEps = item.total * item.completedCount;
      int currentEps = item.status != 'Completed' ? item.progress : 0;
      return sum + pastEps + currentEps;
    });

    final topMedia = widget.friend.allMedia.where((item) => item.type == _top5Filter).toList();
    topMedia.sort((a, b) => b.completedCount.compareTo(a.completedCount));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)),
        title: Text(widget.friend.name.toUpperCase(), style: const TextStyle(fontFamily: 'Impact', fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 24, color: Color(0xFF0A2463))),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 90, height: 90,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0A2463)),
                        child: const Icon(Icons.person_rounded, size: 50, color: Colors.white),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.friend.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                            const SizedBox(height: 4),
                            Text('Global Rank: #${widget.friend.rank}', style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Top 5 Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${widget.friend.name}\'s Top 5', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
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

                  // Top 5 Images
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
                  const SizedBox(height: 40),

                  // Friend Stats
                  const Align(alignment: Alignment.centerLeft, child: Text('All-Time Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A2463)))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard('Movies', totalMovies.toString(), Icons.movie_rounded, const Color(0xFF0A2463)),
                      const SizedBox(width: 16),
                      _buildStatCard('Shows', totalShows.toString(), Icons.tv_rounded, const Color(0xFFFF6B00)),
                      const SizedBox(width: 16),
                      _buildStatCard('Episodes', totalEpisodes.toString(), Icons.layers_rounded, const Color(0xFFFFC300)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Align(alignment: Alignment.centerLeft, child: Text('Completed Archive', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A2463)))),
                ],
              ),
            ),
          ),

          // Friend Archive Grid
          completedItems.isEmpty
              ? SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(child: Text("${widget.friend.name} hasn't completed anything.", style: const TextStyle(color: Colors.black38, fontSize: 16))),
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
                  return Column(
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
                  );
                },
                childCount: completedItems.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}