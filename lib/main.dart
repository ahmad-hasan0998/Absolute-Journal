import 'package:flutter/material.dart';
import 'api_service.dart'; // Imports your master API file

void main() {
  runApp(const MediaJournalApp());
}

class MediaJournalApp extends StatelessWidget {
  const MediaJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Journal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// --- Data Model ---
class MediaItem {
  String title;
  String type;
  String status;
  int progress;
  int total;
  String lastUpdated;
  bool? isLiked;
  bool isWatchLater;
  String? posterUrl;

  MediaItem({
    required this.title,
    required this.type,
    required this.status,
    this.progress = 0,
    this.total = 1,
    required this.lastUpdated,
    this.isLiked,
    this.isWatchLater = false,
    this.posterUrl,
  });
}

// --- Main Navigation Structure ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  List<MediaItem> activeItems = [];

  void _openQuickAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SearchApiDialog(
        onItemAdded: (newItem) {
          setState(() {
            activeItems.insert(0, newItem);
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(activeItems: activeItems);
      case 1:
        return const VaultScreen();
      case 2:
        return const ScheduleScreen();
      default:
        return const Center(child: Text('Error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openQuickAddDialog(context),
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.archive), label: 'Vault'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Schedule'),
        ],
      ),
    );
  }
}

// --- API Search Dialog ---
class SearchApiDialog extends StatefulWidget {
  final Function(MediaItem) onItemAdded;
  const SearchApiDialog({super.key, required this.onItemAdded});

  @override
  State<SearchApiDialog> createState() => _SearchApiDialogState();
}

class _SearchApiDialogState extends State<SearchApiDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _selectedCategory = 'Movie';

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isAdding = false;
  String _errorMessage = '';

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await _apiService.searchMedia(query, _selectedCategory);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addMediaToDashboard(Map<String, dynamic> apiItem) async {
    setState(() { _isAdding = true; });

    int finalTotal = apiItem['total'];

    // Only traditional TV shows need the secondary TMDB call to get episode counts.
    // Anime (Jikan), Books, and Games already provide their totals directly!
    if (apiItem['type'] == 'Show') {
      finalTotal = await _apiService.getTMDBTotalEpisodes(apiItem['id']);
    }

    MediaItem newItem = MediaItem(
      title: apiItem['title'],
      type: apiItem['type'],
      status: 'Active',
      total: finalTotal,
      lastUpdated: 'Just now',
      posterUrl: apiItem['posterUrl'],
    );

    widget.onItemAdded(newItem);
    if (mounted) Navigator.pop(context);
  }

  Widget _buildCategoryButton(IconData icon, String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = label);
        if (_searchController.text.isNotEmpty) _performSearch(_searchController.text);
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isSelected ? Colors.deepPurpleAccent : Colors.grey[800],
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
              color: isSelected ? Colors.deepPurpleAccent : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 11
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Media', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),

            // All 5 Category Selectors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryButton(Icons.movie, 'Movie'),
                _buildCategoryButton(Icons.tv, 'Show'),
                _buildCategoryButton(Icons.animation, 'Anime'),
                _buildCategoryButton(Icons.gamepad, 'Game'),
                _buildCategoryButton(Icons.menu_book, 'Book'),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _searchController,
              autofocus: true,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search $_selectedCategory...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 300,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
                  : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center))
                  : _searchResults.isEmpty
                  ? Center(child: Text('Type a title and hit Enter.', style: TextStyle(color: Colors.grey[500])))
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];

                  return ListTile(
                    leading: item['posterUrl'] != null
                        ? Image.network(item['posterUrl'], width: 40, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.grey))
                        : Container(width: 40, color: Colors.grey[800], child: const Icon(Icons.image, color: Colors.grey)),
                    title: Text(item['title'], style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${item['type']} • ${item['year']}', style: TextStyle(color: Colors.grey[400])),
                    trailing: _isAdding
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent))
                        : IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.deepPurpleAccent),
                      onPressed: () => _addMediaToDashboard(item),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- Dashboard Screen ---
class DashboardScreen extends StatefulWidget {
  final List<MediaItem> activeItems;
  const DashboardScreen({super.key, required this.activeItems});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  void _markMovieCompleted(MediaItem item) {
    setState(() { item.status = 'Completed'; item.lastUpdated = 'Just now'; });
  }

  void _incrementProgress(MediaItem item) {
    setState(() {
      if (item.progress < item.total) {
        item.progress++;
        item.lastUpdated = 'Just now';
        if (item.progress == item.total) item.status = 'Completed';
      }
    });
  }

  void _updateManualProgress(MediaItem item, int newProgress) {
    setState(() {
      item.progress = newProgress.clamp(0, item.total);
      item.lastUpdated = 'Just now';
      if (item.progress == item.total) {
        item.status = 'Completed';
      } else {
        item.status = 'Active';
      }
    });
  }

  void _showProgressDropdownDialog(BuildContext context, MediaItem item) {
    List<int> remainingOptions = [];
    for (int i = item.progress + 1; i <= item.total; i++) {
      remainingOptions.add(i);
    }
    if (remainingOptions.isEmpty) return;

    int selectedValue = remainingOptions.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.grey[900],
                title: Text('Update ${item.title}', style: const TextStyle(color: Colors.white)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Jump to specific point:", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedValue,
                          dropdownColor: Colors.grey[800],
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurpleAccent),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          items: remainingOptions.map((int value) {
                            String unit = 'Ch/Level';
                            if (item.type == 'Show' || item.type == 'Anime') unit = 'Episode';
                            if (item.type == 'Game') unit = '%';
                            if (item.type == 'Book') unit = 'Page';
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$unit $value'),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            setDialogState(() => selectedValue = newValue!);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        _updateManualProgress(item, selectedValue);
                        Navigator.pop(context);
                      },
                      child: const Text('Update Progress', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.greenAccent), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        _updateManualProgress(item, item.total);
                        Navigator.pop(context);
                      },
                      child: Text('Complete Entire ${item.type}', style: const TextStyle(color: Colors.greenAccent)),
                    ),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  void _showCardFocusDialog(BuildContext context, MediaItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              double completionRatio = item.total > 0 ? (item.progress / item.total) : 0;
              int percentage = (completionRatio * 100).toInt();

              return Dialog(
                backgroundColor: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(item.type, style: TextStyle(color: Colors.grey[400])),
                      const SizedBox(height: 24),

                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: completionRatio,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey[800],
                              color: item.status == 'Completed' ? Colors.green : Colors.deepPurpleAccent,
                            ),
                          ),
                          Text('$percentage%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(item.isLiked == true ? Icons.thumb_up : Icons.thumb_up_outlined),
                            color: item.isLiked == true ? Colors.greenAccent : Colors.grey,
                            iconSize: 32,
                            onPressed: () {
                              setDialogState(() => item.isLiked = (item.isLiked == true) ? null : true);
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: Icon(item.isLiked == false ? Icons.thumb_down : Icons.thumb_down_outlined),
                            color: item.isLiked == false ? Colors.redAccent : Colors.grey,
                            iconSize: 32,
                            onPressed: () {
                              setDialogState(() => item.isLiked = (item.isLiked == false) ? null : false);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 8),

                      ListTile(
                        leading: Icon(item.isWatchLater ? Icons.bookmark : Icons.bookmark_border, color: Colors.deepPurpleAccent),
                        title: const Text('Watch Later', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          setDialogState(() => item.isWatchLater = !item.isWatchLater);
                          setState(() {});
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.history, color: Colors.redAccent),
                        title: const Text('Mark Unwatched / Reset', style: TextStyle(color: Colors.redAccent)),
                        onTap: () {
                          _updateManualProgress(item, 0);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildTrailingWidget(MediaItem item) {
    if (item.status == 'Completed') return const Icon(Icons.check_circle, color: Colors.green, size: 32);
    if (item.type == 'Movie') return IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.deepPurpleAccent, size: 32), onPressed: () => _markMovieCompleted(item));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () => _incrementProgress(item),
        onLongPress: () => _showProgressDropdownDialog(context, item),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.add_circle, color: Colors.deepPurpleAccent, size: 36),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Activity')),
      body: widget.activeItems.isEmpty
          ? const Center(child: Text('Hit the + button to search and add media!', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.activeItems.length,
        itemBuilder: (context, index) {
          final item = widget.activeItems[index];
          return GestureDetector(
            onLongPress: () => _showCardFocusDialog(context, item),
            child: Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: item.isWatchLater ? Colors.deepPurpleAccent : Colors.transparent, width: 1),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 55,
                  height: 80,
                  decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(4)),
                  clipBehavior: Clip.antiAlias,
                  child: item.posterUrl != null
                      ? Image.network(item.posterUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey))
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${item.type} • ${item.lastUpdated}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    if (item.type != 'Movie' && item.status != 'Completed') ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: item.progress / item.total,
                        backgroundColor: Colors.grey[800],
                        color: Colors.deepPurpleAccent,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Text('${item.progress} / ${item.total}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ]
                  ],
                ),
                trailing: _buildTrailingWidget(item),
              ),
            ),
          );
        },
      ),
    );
  }
}

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});
  @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('The Vault')), body: const Center(child: Text('History goes here.', style: TextStyle(color: Colors.grey)))); }
}
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});
  @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Release Schedule')), body: const Center(child: Text('Calendar goes here.', style: TextStyle(color: Colors.grey)))); }
}