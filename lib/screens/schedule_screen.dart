// lib/screens/schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}
class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _currentDate = DateTime(2026, 5, 1);
  final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Map<int, List<String>> mockSchedule = {
    4: ['https://image.tmdb.org/t/p/w500/1XyB11YDP9N1V7kmbG9c1xSGEaW.jpg', 'https://image.tmdb.org/t/p/w500/mY7SeH4HFFxW1hiI6cWuwCRX7nB.jpg'],
    6: ['https://image.tmdb.org/t/p/w500/hFWP5HkbVEe40hrptcgHQLe2nUC.jpg', 'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg'],
    12: ['https://image.tmdb.org/t/p/w500/mY7SeH4HFFxW1hiI6cWuwCRX7nB.jpg'],
    13: ['https://image.tmdb.org/t/p/w500/1XyB11YDP9N1V7kmbG9c1xSGEaW.jpg', 'https://image.tmdb.org/t/p/w500/hFWP5HkbVEe40hrptcgHQLe2nUC.jpg'],
    20: ['https://image.tmdb.org/t/p/w500/1XyB11YDP9N1V7kmbG9c1xSGEaW.jpg', 'https://image.tmdb.org/t/p/w500/hFWP5HkbVEe40hrptcgHQLe2nUC.jpg'],
    22: ['https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg', 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg'],
    27: ['https://image.tmdb.org/t/p/w500/hFWP5HkbVEe40hrptcgHQLe2nUC.jpg'],
  };
  void _changeMonth(int offset) {
    setState(() { _currentDate = DateTime(_currentDate.year, _currentDate.month + offset, 1); });
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
        actions: [IconButton(icon: const Icon(Icons.search_rounded, color: Color(0xFF0A2463)), onPressed: () {})],
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
                Column(children: [Text(DateFormat('yyyy').format(_currentDate), style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold, fontSize: 12)), Text(DateFormat('MMMM').format(_currentDate), style: const TextStyle(color: Color(0xFF0A2463), fontWeight: FontWeight.w900, fontSize: 24))]),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF0A2463)), onPressed: () => _changeMonth(1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: weekdays.map((day) => Expanded(child: Center(child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black45, fontSize: 12))))).toList()),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.65, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemCount: gridCount,
              itemBuilder: (context, index) {
                int day = index - blankDays + 1;
                bool isCurrentMonth = day > 0 && day <= daysInMonth;
                List<String> dailyPosters = isCurrentMonth && _currentDate.year == 2026 && _currentDate.month == 5 ? (mockSchedule[day] ?? []) : [];
                return Container(
                  decoration: BoxDecoration(color: isCurrentMonth ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8), border: isCurrentMonth ? Border.all(color: Colors.grey[200]!) : null, boxShadow: isCurrentMonth ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))] : []),
                  child: !isCurrentMonth ? null : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.only(left: 6.0, top: 4.0), child: Text('$day', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A2463), fontSize: 12))),
                      if (dailyPosters.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 2, mainAxisSpacing: 2, childAspectRatio: 0.65),
                              itemCount: dailyPosters.length > 4 ? 4 : dailyPosters.length,
                              itemBuilder: (context, imgIndex) => ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(dailyPosters[imgIndex], fit: BoxFit.cover)),
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