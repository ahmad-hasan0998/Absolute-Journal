import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:final_project/models/media_item.dart';
import 'package:final_project/providers/journal_provider.dart';
import 'package:final_project/services/api_service.dart';
import 'package:final_project/locator.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _currentDate = DateTime.now();
  final List<String> weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  Map<int, List<Map<String, dynamic>>> _monthlyData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPersonalizedSchedule();
    });
  }

  Future<void> _fetchPersonalizedSchedule() async {
    setState(() => _isLoading = true);
    var activeItems = context.read<JournalProvider>().activeItems;
    var data = await locator<ApiService>().getPersonalizedSchedule(
      _currentDate.year,
      _currentDate.month,
      activeItems,
    );

    if (mounted) {
      setState(() {
        _monthlyData = data;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentDate = DateTime(
        _currentDate.year,
        _currentDate.month + offset,
        1,
      );
    });
    _fetchPersonalizedSchedule();
  }

  void _addMediaWithOptions(
    Map<String, dynamic> apiItem,
    String action, {
    bool? liked,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
      ),
    );
    int finalTotal = apiItem['total'] ?? 1;
    if (apiItem['type'] == 'Show') {
      finalTotal = await locator<ApiService>().getTMDBTotalEpisodes(
        apiItem['id'],
      );
    }
    if (mounted) Navigator.pop(context);

    MediaItem newItem = MediaItem(
      tmdbId: apiItem['id'],
      title: apiItem['title'],
      type: apiItem['type'],
      status: action == 'Completed' ? 'Completed' : 'Active',
      progress: action == 'Completed' ? finalTotal : 0,
      total: finalTotal,
      lastUpdated: 'Just now',
      timestamp: DateTime.now(),
      posterUrl: apiItem['posterUrl'],
      isWatchLater: action == 'WatchLater',
      isTop5: false,
      completedCount: action == 'Completed' ? 1 : 0,
      isLiked: liked,
    );

    if (mounted) {
      context.read<JournalProvider>().addMedia(newItem);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${apiItem['title']} Added!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0A2463),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRatingDialogAndComplete(Map<String, dynamic> item) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Rate "${item['title']}"',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0A2463),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'How did you feel about it?',
          textAlign: TextAlign.center,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.thumb_up_rounded,
                  color: Color(0xFF0A2463),
                  size: 40,
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(
                  Icons.thumb_down_rounded,
                  color: Color(0xFFFF6B00),
                  size: 40,
                ),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    ).then((liked) {
      if (liked != null) {
        _addMediaWithOptions(item, 'Completed', liked: liked);
      }
    });
  }

  void _showAddMenu(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item['title'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A2463),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(
                  Icons.dashboard_rounded,
                  color: Color(0xFFFF6B00),
                  size: 28,
                ),
                title: const Text(
                  'Add to Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0A2463),
                  ),
                ),
                onTap: () => _addMediaWithOptions(item, 'Active'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.bookmark_rounded,
                  color: Color(0xFF0A2463),
                  size: 28,
                ),
                title: const Text(
                  'Add to Watch Later',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0A2463),
                  ),
                ),
                onTap: () => _addMediaWithOptions(item, 'WatchLater'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 28,
                ),
                title: const Text(
                  'Mark as Completed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0A2463),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRatingDialogAndComplete(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayDetails(int day, List<Map<String, dynamic>> items) {
    String dateStr = DateFormat(
      'MMMM d, yyyy',
    ).format(DateTime(_currentDate.year, _currentDate.month, day));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A2463),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...items.map(
                (item) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showAddMenu(context, item);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 45,
                        height: 65,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: item['posterUrl'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: item['posterUrl'],
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.movie, color: Colors.black26),
                      ),
                      title: Text(
                        item['title'].toString().split('\n').first,
                        style: const TextStyle(
                          color: Color(0xFF0A2463),
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            item['type'] == 'Movie'
                                ? Icons.movie_rounded
                                : Icons.tv_rounded,
                            size: 12,
                            color: const Color(0xFFFF6B00),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['title'].toString().contains('\n')
                                ? item['title'].toString().split('\n').last
                                : 'Release',
                            style: const TextStyle(
                              color: Color(0xFFFF6B00),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (items.isEmpty)
                const Center(
                  child: Text(
                    "Nothing dropping today.",
                    style: TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateUtils.getDaysInMonth(
      _currentDate.year,
      _currentDate.month,
    );
    int firstWeekday = DateTime(
      _currentDate.year,
      _currentDate.month,
      1,
    ).weekday;
    int blankDays = firstWeekday - 1;
    int totalCells = blankDays + daysInMonth;
    int gridCount = (totalCells / 7).ceil() * 7;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'SCHEDULE',
          style: TextStyle(
            fontFamily: 'Impact',
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 24,
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
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF0A2463),
                  ),
                  onPressed: () => _changeMonth(-1),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Text(
                      DateFormat('yyyy').format(_currentDate),
                      style: const TextStyle(
                        color: Colors.black45,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM').format(_currentDate),
                      style: const TextStyle(
                        color: Color(0xFF0A2463),
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF0A2463),
                  ),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 120,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                    itemCount: gridCount,
                    itemBuilder: (context, index) {
                      int day = index - blankDays + 1;
                      bool isCurrentMonth = day > 0 && day <= daysInMonth;
                      List<Map<String, dynamic>> dailyDrops = isCurrentMonth
                          ? (_monthlyData[day] ?? [])
                          : [];

                      return GestureDetector(
                        onTap: () {
                          if (isCurrentMonth) _showDayDetails(day, dailyDrops);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrentMonth
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isCurrentMonth
                                ? Border.all(color: Colors.grey[200]!)
                                : null,
                            boxShadow: isCurrentMonth
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: !isCurrentMonth
                              ? null
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 6.0,
                                        top: 4.0,
                                      ),
                                      child: Text(
                                        '$day',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0A2463),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (dailyDrops.isNotEmpty)
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: GridView.builder(
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 1,
                                                  crossAxisSpacing: 2,
                                                  mainAxisSpacing: 2,
                                                  childAspectRatio: 0.65,
                                                ),
                                            itemCount: dailyDrops.length > 2
                                                ? 2
                                                : dailyDrops.length,
                                            itemBuilder: (context, imgIndex) {
                                              var item = dailyDrops[imgIndex];
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: item['posterUrl'] != null
                                                    ? CachedNetworkImage(
                                                        imageUrl:
                                                            item['posterUrl'],
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(
                                                          Icons.movie,
                                                          size: 10,
                                                          color: Colors.black26,
                                                        ),
                                                      ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
