import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy drop data mapping the day of the month to a media title and color
    final Map<int, List<Map<String, dynamic>>> mockDrops = {
      4: [{'title': 'Absolute Batman #1', 'color': Colors.grey[800]}],
      5: [{'title': 'UFC Fight Night', 'color': Colors.red[800]}],
      12: [{'title': 'New Anime Ep', 'color': Colors.blue[800]}],
      15: [{'title': 'Movie Premiere', 'color': Colors.purple[800]}],
      22: [{'title': 'Game Release', 'color': Colors.green[800]}],
    };

    final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SCHEDULE', style: TextStyle(fontFamily: 'Impact', fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 24, color: Color(0xFF0A2463))),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Month Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF0A2463)), onPressed: () {}),
                const Column(
                  children: [
                    Text('2026', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('May', style: TextStyle(color: Color(0xFF0A2463), fontWeight: FontWeight.w900, fontSize: 24)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF0A2463)), onPressed: () {}),
              ],
            ),
          ),

          // Days of Week
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays.map((day) => Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black45))).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Calendar Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.55, // Tall rectangles for posters
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: 35, // 5 weeks
              itemBuilder: (context, index) {
                // May 2026 starts on Friday (index 4)
                int day = index - 3;
                bool isCurrentMonth = day > 0 && day <= 31;

                return Container(
                  decoration: BoxDecoration(
                    color: isCurrentMonth ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrentMonth ? Border.all(color: Colors.grey[200]!) : null,
                  ),
                  child: !isCurrentMonth ? null : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text('$day', style: TextStyle(fontWeight: FontWeight.bold, color: day == 5 ? const Color(0xFFFF6B00) : const Color(0xFF0A2463), fontSize: 12)),
                      ),
                      if (mockDrops.containsKey(day))
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: mockDrops[day]![0]['color'],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(child: Icon(Icons.movie_creation_rounded, color: Colors.white54, size: 16)),
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