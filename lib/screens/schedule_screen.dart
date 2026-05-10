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
  int? _selectedDay;
  final List<String> weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
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

    // MASSIVE OPTIMIZATION: Only search the calendar for items you haven't finished yet!
    var activeItems = context.read<JournalProvider>().activeItems
        .where((item) => item.status != 'Completed')
        .toList();

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
      _selectedDay = null; // Clear selection on month change
    });
    _fetchPersonalizedSchedule();
  }

  Widget _buildDayDropsList() {
    List<Map<String, dynamic>> drops = _monthlyData[_selectedDay] ?? [];

    if (drops.isEmpty) {
      return const Center(
        child: Text(
          "No media dropping on this day.",
          style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 140, left: 16, right: 16),
      itemCount: drops.length,
      itemBuilder: (context, index) {
        var item = drops[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
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
                  color: item['type'] == 'Movie' ? const Color(0xFF0A2463) : const Color(0xFFFF6B00),
                ),
                const SizedBox(width: 4),
                Text(
                  item['title'].toString().contains('\n')
                      ? item['title'].toString().split('\n').last
                      : 'Release',
                  style: TextStyle(
                    color: item['type'] == 'Movie' ? const Color(0xFF0A2463) : const Color(0xFFFF6B00),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      resizeToAvoidBottomInset: false,
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
              ),
            )
          else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: gridCount,
              itemBuilder: (context, index) {
                int day = index - blankDays + 1;
                bool isCurrentMonth = day > 0 && day <= daysInMonth;
                if (!isCurrentMonth) return const SizedBox.shrink();
                List<Map<String, dynamic>> dailyDrops = _monthlyData[day] ?? [];
                bool isSelected = _selectedDay == day;
                bool isToday = day == DateTime.now().day &&
                    _currentDate.month == DateTime.now().month &&
                    _currentDate.year == DateTime.now().year;

                // Extract dot colors based on drops
                List<Color> dotColors = [];
                for(var drop in dailyDrops) {
                  if (drop['type'] == 'Movie' && !dotColors.contains(const Color(0xFF0A2463))) {
                    dotColors.add(const Color(0xFF0A2463));
                  } else if (drop['type'] == 'Show' && !dotColors.contains(const Color(0xFFFF6B00))) {
                    dotColors.add(const Color(0xFFFF6B00));
                  }
                }

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDay = day);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF6B00).withValues(alpha: 0.15) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected ? Border.all(color: const Color(0xFFFF6B00), width: 1.5) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected ? const Color(0xFFFF6B00) : const Color(0xFF0A2463),
                            fontSize: 16,
                          ),
                        ),
                        if (dotColors.isNotEmpty)
                          const SizedBox(height: 4),
                        if (dotColors.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dotColors.map((c) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                              ),
                            )).toList(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const Divider(height: 1, color: Colors.black12),

            Expanded(
              child: _selectedDay == null
                  ? const Center(
                  child: Text(
                      "Select a day to see drops",
                      style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold)
                  )
              )
                  : _buildDayDropsList(),
            )
          ]
        ],
      ),
    );
  }
}