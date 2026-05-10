import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:final_project/models/media_item.dart';
import 'package:final_project/services/database_service.dart';
import 'package:final_project/locator.dart';

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
    if (pic.startsWith('base64,')) {
      return MemoryImage(base64Decode(pic.substring(7)));
    }
    return CachedNetworkImageProvider(pic);
  }

  Widget _buildSafeAvatar(String? pic, double size) {
    if (pic == null || pic.isEmpty) {
      return Icon(Icons.person, color: Colors.white, size: size / 2);
    }
    if (pic.startsWith('base64,')) {
      return Image.memory(
        base64Decode(pic.substring(7)),
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    }
    return CachedNetworkImage(
      imageUrl: pic,
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorWidget: (context, url, error) =>
          Icon(Icons.person, color: Colors.white, size: size / 2),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Block User?',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'They will be removed from your friends list and you will no longer see their activity or profile.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent),
                ),
              );
              await locator<DatabaseService>().blockUser(widget.uid);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User has been blocked.')),
                );
              }
            },
            child: const Text(
              'Block',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFiveSlot(MediaItem? item, BuildContext context) {
    double slotWidth = MediaQuery.of(context).size.width * 0.23;
    return Container(
      width: slotWidth,
      height: slotWidth * 1.5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: item == null
          ? const Center(
              child: Icon(Icons.movie, color: Colors.black12, size: 24),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.posterUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.black26,
                  ),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: locator<DatabaseService>().getUserProfile(widget.uid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF0F4F8),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
            ),
          );
        }
        var user = userSnapshot.data!;
        String friendProfileName =
            user['profileName'] ?? user['username'] ?? 'User';
        String friendUsername = user['username'] ?? 'user';
        var rankData = DatabaseService.getRankVisuals(
          user['rank'] ?? 'Iron Novice',
        );
        String? profilePic = user['profileUrl'];

        return Scaffold(
          backgroundColor: const Color(0xFFF0F4F8),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0A2463),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              friendProfileName.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Impact',
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 24,
                color: Color(0xFF0A2463),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF0A2463),
                ),
                onSelected: (value) {
                  if (value == 'remove') {
                    locator<DatabaseService>().toggleFriend(widget.uid, false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Removed from friends.')),
                    );
                  } else if (value == 'block') {
                    _showBlockDialog();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_remove_rounded,
                          color: Color(0xFF0A2463),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Remove Friend',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block_rounded, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text(
                          'Block User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: FutureBuilder<List<MediaItem>>(
            future: locator<DatabaseService>().getJournalByUid(widget.uid),
            builder: (context, journalSnapshot) {
              if (!journalSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                );
              }
              var allMedia = journalSnapshot.data!;
              final completedItems = allMedia
                  .where(
                    (item) =>
                        item.completedCount > 0 || item.status == 'Completed',
                  )
                  .toList();
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B00), Color(0xFFFFC300)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF6B00,
                                ).withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: ClipOval(
                                child: _buildSafeAvatar(profilePic, 94),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<int>(
                          future: locator<DatabaseService>().getUserPrevRank(
                            widget.uid,
                          ),
                          builder: (context, rankSnapshot) {
                            int prevRank = rankSnapshot.data ?? 999;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  friendProfileName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0A2463),
                                  ),
                                ),
                                if (prevRank <= 3) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 28,
                                    color: prevRank == 1
                                        ? const Color(0xFFFFC300)
                                        : (prevRank == 2
                                              ? const Color(0xFFBDBDBD)
                                              : const Color(0xFF8D6E63)),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$friendUsername',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: rankData['color'].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: rankData['color'].withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                rankData['icon'],
                                color: rankData['color'],
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user['rank'] ?? '',
                                style: TextStyle(
                                  color: rankData['color'],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFFFFC300),
                              size: 18,
                            ),
                            Text(
                              ' ${user['xp_score']} XP ',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFFF6B00),
                              size: 18,
                            ),
                            Text(
                              ' ${user['streak'] ?? 0} Streak',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: StatefulBuilder(
                            builder: (context, setTop5State) {
                              var topMediaList = allMedia
                                  .where(
                                    (item) =>
                                        item.type == _top5Filter &&
                                        item.isTop5 == true,
                                  )
                                  .toList();
                              topMediaList.sort(
                                (a, b) => a.top5Order.compareTo(b.top5Order),
                              );
                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Fix: Wrapped the text in Expanded to prevent overflow
                                      Expanded(
                                        child: Text(
                                          '$friendProfileName\'s Top 5',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0A2463),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => setTop5State(
                                                () => _top5Filter = 'Movie',
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _top5Filter == 'Movie'
                                                      ? Colors.white
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow:
                                                      _top5Filter == 'Movie'
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                            blurRadius: 4,
                                                          ),
                                                        ]
                                                      : [],
                                                ),
                                                child: Icon(
                                                  Icons.movie_rounded,
                                                  size: 20,
                                                  color: _top5Filter == 'Movie'
                                                      ? const Color(0xFF0A2463)
                                                      : Colors.black45,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => setTop5State(
                                                () => _top5Filter = 'Show',
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _top5Filter == 'Show'
                                                      ? Colors.white
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow:
                                                      _top5Filter == 'Show'
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                            blurRadius: 4,
                                                          ),
                                                        ]
                                                      : [],
                                                ),
                                                child: Icon(
                                                  Icons.tv_rounded,
                                                  size: 20,
                                                  color: _top5Filter == 'Show'
                                                      ? const Color(0xFF0A2463)
                                                      : Colors.black45,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildTopFiveSlot(
                                        topMediaList.isNotEmpty
                                            ? topMediaList[0]
                                            : null,
                                        context,
                                      ),
                                      const SizedBox(width: 16),
                                      _buildTopFiveSlot(
                                        topMediaList.length > 1
                                            ? topMediaList[1]
                                            : null,
                                        context,
                                      ),
                                      const SizedBox(width: 16),
                                      _buildTopFiveSlot(
                                        topMediaList.length > 2
                                            ? topMediaList[2]
                                            : null,
                                        context,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildTopFiveSlot(
                                        topMediaList.length > 3
                                            ? topMediaList[3]
                                            : null,
                                        context,
                                      ),
                                      const SizedBox(width: 16),
                                      _buildTopFiveSlot(
                                        topMediaList.length > 4
                                            ? topMediaList[4]
                                            : null,
                                        context,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 40),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Completed Archive',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0A2463),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                FriendCompletedMediaScreen(
                                                  items: completedItems,
                                                  friendName: friendProfileName,
                                                ),
                                          ),
                                        ),
                                        child: const Text(
                                          'See All',
                                          style: TextStyle(
                                            color: Color(0xFFFF6B00),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  completedItems.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Center(
                              child: Text(
                                "$friendProfileName hasn't completed anything.",
                                style: const TextStyle(
                                  color: Colors.black38,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: 40,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = completedItems
                                    .take(4)
                                    .toList()[index];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                              color: Colors.grey[200],
                                            ),
                                            child: item.posterUrl == null
                                                ? const Center(
                                                    child: Icon(
                                                      Icons.movie,
                                                      color: Colors.white54,
                                                    ),
                                                  )
                                                : ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    child: CachedNetworkImage(
                                                      imageUrl: item.posterUrl!,
                                                      fit: BoxFit.cover,
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .broken_image_rounded,
                                                              color: Colors
                                                                  .black26,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                          ),
                                          if (item.completedCount > 1)
                                            Positioned(
                                              top: -6,
                                              right: -6,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xFFFF6B00),
                                                          Color(0xFFFFC300),
                                                        ],
                                                      ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Text(
                                                  'x${item.completedCount}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Color(0xFF0A2463),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                );
                              },
                              childCount: completedItems.length > 4
                                  ? 4
                                  : completedItems.length,
                            ),
                          ),
                        ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class FriendCompletedMediaScreen extends StatefulWidget {
  final List<MediaItem> items;
  final String friendName;
  const FriendCompletedMediaScreen({
    super.key,
    required this.items,
    required this.friendName,
  });
  @override
  State<FriendCompletedMediaScreen> createState() =>
      _FriendCompletedMediaScreenState();
}

class _FriendCompletedMediaScreenState
    extends State<FriendCompletedMediaScreen> {
  String _typeFilter = 'All';
  String _ratingFilter = 'All';
  @override
  Widget build(BuildContext context) {
    var displayItems = widget.items;
    // Apply Type Filter
    if (_typeFilter == 'Movies') {
      displayItems = displayItems.where((i) => i.type == 'Movie').toList();
    }
    if (_typeFilter == 'Shows') {
      displayItems = displayItems.where((i) => i.type == 'Show').toList();
    }

    // Apply Rating Filter
    if (_ratingFilter == 'Liked') {
      displayItems = displayItems.where((i) => i.isLiked == true).toList();
    }
    if (_ratingFilter == 'Disliked') {
      displayItems = displayItems.where((i) => i.isLiked == false).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0A2463),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.friendName}\'s Archive',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Color(0xFF0A2463),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 12.0,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      [
                            {'val': 'All', 'icon': Icons.grid_view_rounded},
                            {'val': 'Movies', 'icon': Icons.movie_rounded},
                            {'val': 'Shows', 'icon': Icons.tv_rounded},
                          ]
                          .map(
                            (f) => GestureDetector(
                              onTap: () => setState(
                                () => _typeFilter = f['val'] as String,
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _typeFilter == f['val']
                                      ? const Color(0xFF0A2463)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  f['icon'] as IconData,
                                  size: 20,
                                  color: _typeFilter == f['val']
                                      ? Colors.white
                                      : Colors.black45,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      [
                            {
                              'val': 'All',
                              'icon': Icons.thumbs_up_down_rounded,
                            },
                            {'val': 'Liked', 'icon': Icons.thumb_up_rounded},
                            {
                              'val': 'Disliked',
                              'icon': Icons.thumb_down_rounded,
                            },
                          ]
                          .map(
                            (f) => GestureDetector(
                              onTap: () => setState(
                                () => _ratingFilter = f['val'] as String,
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _ratingFilter == f['val']
                                      ? const Color(0xFFFF6B00)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  f['icon'] as IconData,
                                  size: 20,
                                  color: _ratingFilter == f['val']
                                      ? Colors.white
                                      : Colors.black45,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                final item = displayItems[index];
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              color: Colors.grey[200],
                            ),
                            child: item.posterUrl == null
                                ? const Center(
                                    child: Icon(
                                      Icons.movie,
                                      color: Colors.black12,
                                      size: 24,
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CachedNetworkImage(
                                      imageUrl: item.posterUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          const Center(
                                            child: Icon(
                                              Icons.broken_image_rounded,
                                              color: Colors.black26,
                                            ),
                                          ),
                                    ),
                                  ),
                          ),
                          if (item.completedCount > 1)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B00),
                                      Color(0xFFFFC300),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  'x${item.completedCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF0A2463),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
