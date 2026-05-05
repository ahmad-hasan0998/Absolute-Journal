import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';

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
  String _errorMessage = '';

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final results = await _apiService.searchMedia(query, _selectedCategory);
      setState(() { _searchResults = results; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  void _addMediaWithOptions(Map<String, dynamic> apiItem, String action) async {
    // Show a loading indicator in the bottom sheet while fetching TMDB episodes
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))));

    int finalTotal = apiItem['total'] ?? 1;
    if (apiItem['type'] == 'Show') {
      finalTotal = await _apiService.getTMDBTotalEpisodes(apiItem['id']);
    }

    Navigator.pop(context); // Pop loading

    MediaItem newItem = MediaItem(
      title: apiItem['title'],
      type: apiItem['type'],
      status: action == 'Completed' ? 'Completed' : 'Active',
      progress: action == 'Completed' ? finalTotal : 0,
      total: finalTotal,
      lastUpdated: 'Just now',
      posterUrl: apiItem['posterUrl'],
      isWatchLater: action == 'WatchLater',
      completedCount: action == 'Completed' ? 1 : 0,
    );

    widget.onItemAdded(newItem);
    if (mounted) Navigator.pop(context); // Pop the original dialog
  }

  // --- FIX: SLEEK BOTTOM SHEET MENU ---
  void _showAddMenu(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Where to add "${item['title']}"?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0A2463)), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.dashboard_rounded, color: Color(0xFFFF6B00), size: 28),
                title: const Text('Dashboard (Watching Now)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A2463))),
                onTap: () { Navigator.pop(context); _addMediaWithOptions(item, 'Active'); },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_rounded, color: Color(0xFF0A2463), size: 28),
                title: const Text('Watch Later List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A2463))),
                onTap: () { Navigator.pop(context); _addMediaWithOptions(item, 'WatchLater'); },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                title: const Text('Mark as Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A2463))),
                onTap: () { Navigator.pop(context); _addMediaWithOptions(item, 'Completed'); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(IconData icon, String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = label);
        if (_searchController.text.isNotEmpty) _performSearch(_searchController.text);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A2463) : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0A2463).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black45, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black45, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add Media', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0A2463)), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCategoryButton(Icons.movie_rounded, 'Movie'),
                const SizedBox(width: 16),
                _buildCategoryButton(Icons.tv_rounded, 'Show'),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search for a title...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0A2463)),
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
                  : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center))
                  : _searchResults.isEmpty
                  ? const Center(child: Text('Type a title and hit Enter', style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold)))
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  // --- FIX: NO MORE PLUS BUTTON. ROW IS TAPPABLE ---
                  return GestureDetector(
                    onTap: () => _showAddMenu(context, item),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(24)),
                      child: ListTile(
                        leading: Container(
                          width: 45, height: 65,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: item['posterUrl'] != null ? DecorationImage(image: NetworkImage(item['posterUrl']), fit: BoxFit.cover) : null, color: Colors.grey[200]),
                        ),
                        title: Text(item['title'], style: const TextStyle(color: Color(0xFF0A2463), fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${item['year']}', style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
                      ),
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