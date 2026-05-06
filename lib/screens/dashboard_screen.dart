import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/media_item.dart';
import '../providers/journal_provider.dart';
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  void _showMultiAddDialog(BuildContext context, MediaItem item) {
    int selectedAmount = 1;
    showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Log Episodes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                        const SizedBox(height: 8),
                        Text(item.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 40),
                        SizedBox(
                          height: 240, width: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: List.generate(10, (index) {
                              int value = index + 1;
                              double angle = (index * (math.pi * 2) / 10) - (math.pi / 2);
                              double radius = 100;
                              double x = radius * math.cos(angle);
                              double y = radius * math.sin(angle);
                              bool isSelected = value <= selectedAmount;
                              return Transform.translate(
                                offset: Offset(x, y),
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => selectedAmount = value),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: isSelected ? 44 : 32, height: isSelected ? 44 : 32,
                                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: isSelected ? const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]) : null, color: isSelected ? null : Colors.grey[100], boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFF6B00).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : []),
                                    child: Center(child: Text('$value', style: TextStyle(color: isSelected ? Colors.white : Colors.black38, fontWeight: FontWeight.w900, fontSize: isSelected ? 18 : 14))),
                                  ),
                                ),
                              );
                            })..add(Column(mainAxisSize: MainAxisSize.min, children: [const Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black38)), Text('$selectedAmount', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Color(0xFF0A2463), height: 1.0))])),
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 10, shadowColor: const Color(0xFFFF6B00).withOpacity(0.5)),
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                          label: const Text('Add to Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          onPressed: () { context.read<JournalProvider>().incrementProgress(item, selectedAmount); Navigator.pop(context); },
                        ),
                        const SizedBox(height: 16),
                        TextButton(onPressed: () { context.read<JournalProvider>().completeEntireShow(item); Navigator.pop(context); }, child: const Text('Complete Entire Show', style: TextStyle(color: Color(0xFF0A2463), fontWeight: FontWeight.bold, fontSize: 16)))
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }
  void _showCardFocusDialog(BuildContext context, MediaItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              double completionRatio = item.total > 0 ? (item.progress / item.total) : 0;
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                      const SizedBox(height: 8),
                      Text(item.type, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 32),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(width: 120, height: 120, child: CircularProgressIndicator(value: completionRatio, strokeWidth: 12, backgroundColor: Colors.grey[300], color: item.status == 'Completed' ? Colors.greenAccent[400] : const Color(0xFFFF6B00))),
                          Text('${(completionRatio * 100).toInt()}%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0A2463))),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () { item.isLiked = (item.isLiked == true) ? null : true; context.read<JournalProvider>().updateExistingMedia(item); setDialogState((){}); },
                            child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: item.isLiked == true ? const Color(0xFF0A2463) : Colors.grey[100], shape: BoxShape.circle), child: Icon(Icons.thumb_up_rounded, color: item.isLiked == true ? Colors.white : Colors.black38)),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () { item.isLiked = (item.isLiked == false) ? null : false; context.read<JournalProvider>().updateExistingMedia(item); setDialogState((){}); },
                            child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: item.isLiked == false ? const Color(0xFFFF6B00) : Colors.grey[100], shape: BoxShape.circle), child: Icon(Icons.thumb_down_rounded, color: item.isLiked == false ? Colors.white : Colors.black38)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      ListTile(
                        leading: Icon(item.isWatchLater ? Icons.bookmark : Icons.bookmark_border_rounded, color: const Color(0xFF0A2463)),
                        title: Text(item.isWatchLater ? 'Remove from Watch Later' : 'Move to Watch Later', style: const TextStyle(color: Color(0xFF0A2463), fontWeight: FontWeight.bold)),
                        onTap: () { item.isWatchLater = !item.isWatchLater; context.read<JournalProvider>().updateExistingMedia(item); Navigator.pop(context); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.refresh_rounded, color: Colors.redAccent),
                        title: const Text('Reset Progress', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        onTap: () { context.read<JournalProvider>().updateManualProgress(item, 0); Navigator.pop(context); },
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
  Widget _buildTrailingWidget(BuildContext context, MediaItem item) {
    if (item.type == 'Movie') {
      return GestureDetector(
        onTap: () => context.read<JournalProvider>().completeEntireShow(item),
        child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!, width: 2), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.grey, size: 28)),
      );
    }
    return GestureDetector(
      onTap: () => context.read<JournalProvider>().incrementProgress(item, 1),
      onLongPress: () => _showMultiAddDialog(context, item),
      child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]), boxShadow: [BoxShadow(color: const Color(0xFFFF6B00).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))], shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 28)),
    );
  }
  @override
  Widget build(BuildContext context) {
    final activeItems = context.watch<JournalProvider>().activeItems;
    final dashboardItems = activeItems.where((item) => item.status != 'Completed' && !item.isWatchLater).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('ABSOLUTE JOURNAL', style: TextStyle(fontFamily: 'Impact', fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 24, color: Color(0xFF0A2463)))),
      body: dashboardItems.isEmpty
          ? const Center(child: Text('Your dashboard is empty.\nTap the giant + to add media.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black38, fontSize: 18, height: 1.5)))
          : ListView.builder(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
        itemCount: dashboardItems.length,
        itemBuilder: (context, index) {
          final item = dashboardItems[index];
          return GestureDetector(
            onLongPress: () => _showCardFocusDialog(context, item),
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 12))]),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(width: 75, height: 110, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))], image: item.posterUrl != null ? DecorationImage(image: NetworkImage(item.posterUrl!), fit: BoxFit.cover) : null), child: item.posterUrl == null ? const Icon(Icons.movie_creation_rounded, color: Colors.black12, size: 32) : null),
                      if (item.completedCount > 0)
                        Positioned(top: -8, right: -8, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: const Color(0xFFFF6B00).withOpacity(0.5), blurRadius: 8)]), child: Text('x${item.completedCount + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11))))
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0A2463)), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text('${item.type} • ${item.lastUpdated}', style: const TextStyle(color: Colors.black45, fontSize: 13, fontWeight: FontWeight.bold)),
                        if (item.type != 'Movie') ...[
                          const SizedBox(height: 16),
                          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: item.progress / item.total, backgroundColor: Colors.grey[200], color: const Color(0xFFFFC300), minHeight: 8)),
                          const SizedBox(height: 8),
                          Text('${item.progress} / ${item.total} Episodes', style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildTrailingWidget(context, item),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}