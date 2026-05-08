import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/journal_provider.dart';
import '../services/api_service.dart';
import '../locator.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _currentDate = DateTime.now();
  final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
    var data = await locator<ApiService>().getPersonalizedSchedule(_currentDate.year, _currentDate.month, activeItems);

    if (mounted) {
      setState(() {
        _monthlyData = data;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + offset, 1);
    });
    _fetchPersonalizedSchedule();
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateUtils.getDaysInMonth(_currentDate.year, _currentDate.month);
    int firstWeekday = DateTime(_currentDate.year, _currentDate.month, 1).weekday;
    int blankDays = firstWeekday - 1;
    int totalCells = blankDays + daysInMonth;
    int gridCount = (totalCells / 7).ceil() * 7;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('SCHEDULE', style: TextStyle(fontFamily: 'Impact', fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 24, color: Color(0xFF0A2463))),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF0A2463)), onPressed: () => _changeMonth(-1)),
                const SizedBox(width: 16),
                Column(
                    children: [
                      Text(DateFormat('yyyy').format(_currentDate), style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(DateFormat('MMMM').format(_currentDate), style: const TextStyle(color: Color(0xFF0A2463), fontWeight: FontWeight.w900, fontSize: 24)),
                    ]
                ),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF0A2463)), onPressed: () => _changeMonth(1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays.map((day) => Expanded(child: Center(child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black45, fontSize: 12))))).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
                : GridView.builder(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.55,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: gridCount,
              itemBuilder: (context, index) {
                int day = index - blankDays + 1;
                bool isCurrentMonth = day > 0 && day <= daysInMonth;
                List<Map<String, dynamic>> dailyDrops = isCurrentMonth ? (_monthlyData[day] ?? []) : [];

                return Container(
                  decoration: BoxDecoration(
                    color: isCurrentMonth ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrentMonth ? Border.all(color: Colors.grey[200]!) : null,
                    boxShadow: isCurrentMonth ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))] : [],
                  ),
                  child: !isCurrentMonth ? null : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0, top: 4.0),
                        child: Text('$day', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A2463), fontSize: 12)),
                      ),
                      if (dailyDrops.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                  childAspectRatio: 0.65,
                                ),
                                itemCount: dailyDrops.length > 2 ? 2 : dailyDrops.length,
                                itemBuilder: (context, imgIndex) {
                                  var item = dailyDrops[imgIndex];
                                  return Tooltip(
                                    message: item['title'],
                                    triggerMode: TooltipTriggerMode.tap,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: item['posterUrl'] != null
                                          ? Image.network(item['posterUrl'], fit: BoxFit.cover)
                                          : Container(color: Colors.grey[300], child: const Icon(Icons.movie, size: 10, color: Colors.black26)),
                                    ),
                                  );
                                }
                            ),
                          ),
                        )
                    ],
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