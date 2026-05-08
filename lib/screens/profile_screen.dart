import 'dart:async';
import 'dart:convert';
import 'package:final_project/services/seed_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:final_project/models/media_item.dart';
import 'package:final_project/services/database_service.dart';
import 'package:final_project/services/auth_service.dart';
import 'package:final_project/widgets/search_api_dialog.dart';
import 'package:final_project/providers/journal_provider.dart';
import 'package:final_project/locator.dart';
import 'package:final_project/screens/friend_profile_screen.dart';

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
  Timer? _debounce; // ADDED DEBOUNCE TIMER

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

  void _showDebugMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Admin Console',
          style: TextStyle(
            color: Color(0xFF0A2463),
            fontWeight: FontWeight.w900,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'Simulate Yesterday (Streak)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              leading: const Icon(
                Icons.history_rounded,
                color: Color(0xFFFF6B00),
              ),
              onTap: () async {
                await locator<DatabaseService>().debugSetLastActivity(1);
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(
                'Simulate Decay',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              leading: const Icon(
                Icons.trending_down_rounded,
                color: Colors.orange,
              ),
              onTap: () async {
                await locator<DatabaseService>().debugSetLastActivity(4);
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(
                'Simulate Month Reset',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              leading: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF0A2463),
              ),
              onTap: () async {
                await locator<DatabaseService>().debugSetLastReset(35);
                if (mounted) Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Force Gamification Sync',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.green,
                ),
              ),
              leading: const Icon(Icons.sync_rounded, color: Colors.green),
              onTap: () async {
                await locator<DatabaseService>().syncGamification();
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Sync complete!')));
              },
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Inject 5 Dummy Users',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.redAccent,
                ),
              ),
              leading: const Icon(
                Icons.people_alt_rounded,
                color: Colors.redAccent,
              ),
              onTap: () async {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  ),
                );
                await SeedService.injectDummyData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '5 Dummy Users Injected! Go search for them.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendsDirectory(List<dynamic> currentFriendIds) async {
    _searchController.clear();
    _userSearchResults.clear();
    setState(() => _isSearching = true);
    List<Map<String, dynamic>> loadedFriends = await locator<DatabaseService>()
        .getFriendsProfiles(currentFriendIds);
    bool isShowingSearch = false;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<Map<String, dynamic>> displayList = isShowingSearch
                ? _userSearchResults
                : loadedFriends;
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isShowingSearch ? 'Search Results' : 'Your Friends',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0A2463),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        if (val.isEmpty) {
                          setDialogState(() {
                            isShowingSearch = false;
                            _userSearchResults.clear();
                          });
                          return;
                        }

                        // DEBOUNCE LOGIC FOR SEARCH AS YOU TYPE
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 500),
                          () async {
                            setDialogState(() {
                              isShowingSearch = true;
                              _isSearching = true;
                            });
                            var res = await locator<DatabaseService>()
                                .searchUsers(val);
                            setDialogState(() {
                              _userSearchResults = res;
                              _isSearching = false;
                            });
                          },
                        );
                      },
                      onSubmitted: (val) async {
                        if (val.isEmpty) return;
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        setDialogState(() {
                          isShowingSearch = true;
                          _isSearching = true;
                        });
                        var res = await locator<DatabaseService>().searchUsers(
                          val,
                        );
                        setDialogState(() {
                          _userSearchResults = res;
                          _isSearching = false;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search username...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF0A2463),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isSearching && isShowingSearch
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF6B00),
                              ),
                            )
                          : displayList.isEmpty
                          ? Center(
                              child: Text(
                                isShowingSearch
                                    ? 'No users found.'
                                    : 'You have no friends yet.',
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: displayList.length,
                              itemBuilder: (context, index) {
                                var u = displayList[index];
                                bool isAdded = currentFriendIds.contains(
                                  u['uid'],
                                );
                                String pic = u['profileUrl'] ?? '';
                                String pName =
                                    u['profileName'] ?? u['username'] ?? 'User';
                                String uName = u['username'] ?? 'user';
                                var rankData = DatabaseService.getRankVisuals(
                                  u['rank'] ?? 'Iron Novice',
                                );
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF0A2463),
                                    child: ClipOval(
                                      child: _buildSafeAvatar(pic, 40),
                                    ),
                                  ),
                                  title: Text(
                                    pName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0A2463),
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        '@$uName',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        rankData['icon'],
                                        color: rankData['color'],
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${u['xp_score']} XP',
                                        style: TextStyle(
                                          color: rankData['color'],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: isAdded
                                          ? Colors.grey[200]
                                          : const Color(0xFF0A2463),
                                    ),
                                    onPressed: () async {
                                      await locator<DatabaseService>()
                                          .toggleFriend(u['uid'], !isAdded);
                                      setDialogState(() {
                                        if (isAdded) {
                                          currentFriendIds.remove(u['uid']);
                                          if (!isShowingSearch) {
                                            loadedFriends.removeWhere(
                                              (f) => f['uid'] == u['uid'],
                                            );
                                          }
                                        } else {
                                          currentFriendIds.add(u['uid']);
                                        }
                                      });
                                      setState(() {});
                                    },
                                    child: Text(
                                      isAdded ? 'Remove' : 'Add',
                                      style: TextStyle(
                                        color: isAdded
                                            ? Colors.black54
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            FriendProfileScreen(uid: u['uid']),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
      imageQuality: 70,
    );
    if (image != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
      );
      try {
        await locator<DatabaseService>().uploadProfilePicture(image);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
      if (mounted) Navigator.pop(context);
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF0A2463),
                fontWeight: FontWeight.bold,
              ),
            ),
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
              await locator<AuthService>().deleteAccount();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
              }
            },
            child: const Text(
              'Delete',
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

  Widget _buildDraggableTopFiveSlot(
    int index,
    List<MediaItem> topMediaList,
    BuildContext context,
    Function setTop5State,
  ) {
    MediaItem? item = index < topMediaList.length ? topMediaList[index] : null;
    double slotWidth = MediaQuery.of(context).size.width * 0.23;

    Widget slotContent = Container(
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
              child: Icon(Icons.add_rounded, color: Colors.black26, size: 24),
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

    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        context.read<JournalProvider>().reorderTop5(details.data, index);
        setTop5State(() {});
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            if (item == null) {
              showDialog(
                context: context,
                barrierColor: Colors.black.withValues(alpha: 0.6),
                builder: (context) => SearchApiDialog(
                  isForTop5: true,
                  onItemAdded: (newItem) async {
                    newItem.type = _top5Filter;
                    await context.read<JournalProvider>().addMedia(newItem);
                    setTop5State(() {});
                  },
                ),
              );
            } else {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Remove from Top 5?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        item.isTop5 = false;
                        context.read<JournalProvider>().updateExistingMedia(
                          item,
                        );
                        setTop5State(() {});
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
          child: item == null
              ? slotContent
              : LongPressDraggable<int>(
                  data: index,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(opacity: 0.8, child: slotContent),
                  ),
                  childWhenDragging: Opacity(opacity: 0.3, child: slotContent),
                  child: slotContent,
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeItems = context.watch<JournalProvider>().activeItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Color(0xFF0A2463),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bug_report_rounded,
              color: Color(0xFF0A2463),
            ),
            onPressed: _showDebugMenu,
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: locator<DatabaseService>().getUserProfileStream(),
            builder: (context, snapshot) {
              List<dynamic> friendsList = snapshot.hasData
                  ? (snapshot.data!.data() as Map<String, dynamic>? ??
                            {})['friends'] ??
                        []
                  : [];
              return IconButton(
                icon: const Icon(
                  Icons.person_add_rounded,
                  color: Color(0xFF0A2463),
                ),
                onPressed: () => _showFriendsDirectory(friendsList),
              );
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF0A2463)),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Padding(
        padding: const EdgeInsets.only(bottom: 90.0, top: 20.0),
        child: Drawer(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              bottomLeft: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A2463),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.language_rounded,
                    color: Colors.black54,
                  ),
                  title: const Text(
                    'Change Language',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Coming Soon'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(
                    Icons.dark_mode_rounded,
                    color: Colors.black54,
                  ),
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Coming Soon'),
                  onTap: () {},
                ),
                const Spacer(),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFF0A2463),
                  ),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A2463),
                    ),
                  ),
                  onTap: () async {
                    context.read<JournalProvider>().clear();
                    await locator<AuthService>().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: _confirmDeleteAccount,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: locator<DatabaseService>().getUserProfileStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String profileName =
              userData['profileName'] ?? userData['username'] ?? 'User';
          String username = userData['username'] ?? 'user';
          String rank = userData['rank'] ?? 'Iron Novice';
          int xpScore = userData['xp_score'] ?? 0;
          int streak = userData['streak'] ?? 0;
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
                              color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
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
                              child: _buildSafeAvatar(profileUrl, 94),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A2463),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<int>(
                  future: locator<DatabaseService>().getUserPrevRank(
                    locator<DatabaseService>().currentUserId!,
                  ),
                  builder: (context, rankSnapshot) {
                    int prevRank = rankSnapshot.data ?? 999;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          profileName,
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
                  '@$username',
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
                        rank,
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
                      ' $xpScore XP ',
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
                      ' $streak Streak',
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
                      var topMediaList = activeItems
                          .where(
                            (item) =>
                                item.type == _top5Filter && item.isTop5 == true,
                          )
                          .toList();
                      topMediaList.sort(
                        (a, b) => a.top5Order.compareTo(b.top5Order),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Top 5 Showcase',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0A2463),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => setTop5State(
                                        () => _top5Filter = 'Movie',
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _top5Filter == 'Movie'
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: _top5Filter == 'Movie'
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _top5Filter == 'Show'
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: _top5Filter == 'Show'
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
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
                              _buildDraggableTopFiveSlot(
                                0,
                                topMediaList,
                                context,
                                setTop5State,
                              ),
                              const SizedBox(width: 16),
                              _buildDraggableTopFiveSlot(
                                1,
                                topMediaList,
                                context,
                                setTop5State,
                              ),
                              const SizedBox(width: 16),
                              _buildDraggableTopFiveSlot(
                                2,
                                topMediaList,
                                context,
                                setTop5State,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDraggableTopFiveSlot(
                                3,
                                topMediaList,
                                context,
                                setTop5State,
                              ),
                              const SizedBox(width: 16),
                              _buildDraggableTopFiveSlot(
                                4,
                                topMediaList,
                                context,
                                setTop5State,
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
          );
        },
      ),
    );
  }
}
