import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';

enum StatsTimeRange { day, week, month, year }

class StatsView extends StatefulWidget {
  final List<PomodoroRecord> history;
  final List<Tag> tags;
  const StatsView({super.key, required this.history, required this.tags});
  @override State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  StatsTimeRange _selectedRange = StatsTimeRange.day;
  DateTime _focusedDate = DateTime.now();
  int _touchedIndex = -1;

  String get _dateTitle {
    final now = DateTime.now();
    if (_touchedIndex != -1) {
      switch (_selectedRange) {
        case StatsTimeRange.day:
          final date = _focusedDate.subtract(Duration(days: (6 - _touchedIndex)));
          if (date.year == now.year && date.month == now.month && date.day == now.day) return "Today";
          return "${date.day}/${date.month}/${date.year}";
        case StatsTimeRange.week:
          final currentWeekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
          final targetWeekStart = currentWeekStart.subtract(Duration(days: (4 - _touchedIndex) * 7));
          final targetWeekEnd = targetWeekStart.add(const Duration(days: 6));
          return "${targetWeekStart.day}/${targetWeekStart.month} - ${targetWeekEnd.day}/${targetWeekEnd.month}";
        case StatsTimeRange.month:
          const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
          if (_touchedIndex < months.length) return "${months[_touchedIndex]} ${_focusedDate.year}";
          return "${_focusedDate.year}";
        case StatsTimeRange.year:
          final year = _focusedDate.year - (4 - _touchedIndex);
          return "$year";
      }
    }
    switch (_selectedRange) {
      case StatsTimeRange.day:
        if (_focusedDate.year == now.year && _focusedDate.month == now.month && _focusedDate.day == now.day) return "Today";
        return "${_focusedDate.day}/${_focusedDate.month}/${_focusedDate.year}";
      case StatsTimeRange.week:
        final start = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return "${start.day}/${start.month} - ${end.day}/${end.month}";
      case StatsTimeRange.month:
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return "${months[_focusedDate.month - 1]} ${_focusedDate.year}";
      case StatsTimeRange.year:
        return "${_focusedDate.year}";
    }
  }

  void _moveDate(int direction) {
    setState(() {
      switch (_selectedRange) {
        case StatsTimeRange.day: _focusedDate = _focusedDate.add(Duration(days: direction)); break;
        case StatsTimeRange.week: _focusedDate = _focusedDate.add(Duration(days: direction * 7)); break;
        case StatsTimeRange.month: _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + direction, 1); break;
        case StatsTimeRange.year: _focusedDate = DateTime(_focusedDate.year + direction, 1, 1); break;
      }
      _touchedIndex = -1;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDuration(int minutes) {
    int h = minutes ~/ 60;
    int m = minutes % 60;
    if (h > 0) return "${h}h ${m}m";
    return "${m}m";
  }

  Map<String, dynamic> _getChartData(Color defaultColor) {
    List<BarChartGroupData> groups = [];
    int itemCount = 0;
    switch (_selectedRange) {
      case StatsTimeRange.day: itemCount = 7; break;
      case StatsTimeRange.week: itemCount = 5; break;
      case StatsTimeRange.month: itemCount = 12; break;
      case StatsTimeRange.year: itemCount = 5; break;
    }

    double maxBarValue = 0; 

    for (int i = 0; i < itemCount; i++) {
      DateTime dateForBar;
      List<PomodoroRecord> recordsForBar = [];

      if (_selectedRange == StatsTimeRange.day) {
        dateForBar = _focusedDate.subtract(Duration(days: (itemCount - 1) - i));
        recordsForBar = widget.history.where((r) => _isSameDay(r.date, dateForBar)).toList();
      } else if (_selectedRange == StatsTimeRange.week) {
        final currentWeekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
        final weekStart = currentWeekStart.subtract(Duration(days: ((itemCount - 1) - i) * 7));
        final weekEnd = weekStart.add(const Duration(days: 6));
        dateForBar = weekStart;
        recordsForBar = widget.history.where((r) => r.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) && r.date.isBefore(weekEnd.add(const Duration(seconds: 1)))).toList();
      } else if (_selectedRange == StatsTimeRange.month) {
        dateForBar = DateTime(_focusedDate.year, i + 1, 1);
        recordsForBar = widget.history.where((r) => r.date.year == _focusedDate.year && r.date.month == (i + 1)).toList();
      } else {
        int year = _focusedDate.year - ((itemCount - 1) - i);
        dateForBar = DateTime(year, 1, 1);
        recordsForBar = widget.history.where((r) => r.date.year == year).toList();
      }

      double totalY = 0;
      List<BarChartRodStackItem> stackItems = [];
      
      if (_selectedRange == StatsTimeRange.day) {
        Map<String, int> tagDurations = {};
        for (var rec in recordsForBar) tagDurations[rec.tagName] = (tagDurations[rec.tagName] ?? 0) + rec.durationInMinutes;
        
        double currentY = 0;
        tagDurations.forEach((tagName, duration) {
          Color barColor = defaultColor;
          try {
            var foundTag = widget.tags.firstWhere((t) => t.name == tagName, orElse: () => widget.tags.firstWhere((t) => t.name == "General"));
            barColor = foundTag.color;
          } catch (_) {}
          double value = duration.toDouble();
          if (value > 0) {
            stackItems.add(BarChartRodStackItem(currentY, currentY + value, barColor));
            currentY += value;
          }
        });
        totalY = currentY;
      } else {
        int totalMinutes = recordsForBar.fold(0, (sum, item) => sum + item.durationInMinutes);
        totalY = totalMinutes.toDouble();
        stackItems.add(BarChartRodStackItem(0, totalY, defaultColor));
      }

      if (totalY > maxBarValue) maxBarValue = totalY;

      groups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: totalY, color: Colors.transparent, rodStackItems: stackItems, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]));
    }
    
    return {'groups': groups, 'maxY': maxBarValue};
  }

  Widget _buildRankCard(AppTheme theme, int totalMinutes) {
    String rankName = "Novice";
    IconData rankIcon = Icons.local_florist; 
    int nextTarget = 300; 
    double progress = 0;

    if (totalMinutes >= 6000) { 
      rankName = "Grandmaster";
      rankIcon = Icons.workspace_premium;
      nextTarget = totalMinutes; 
      progress = 1.0;
    } else if (totalMinutes >= 3000) { 
      rankName = "Master";
      rankIcon = Icons.self_improvement;
      nextTarget = 6000;
      progress = (totalMinutes - 3000) / (6000 - 3000);
    } else if (totalMinutes >= 1200) { 
      rankName = "Specialist";
      rankIcon = Icons.science;
      nextTarget = 3000;
      progress = (totalMinutes - 1200) / (3000 - 1200);
    } else if (totalMinutes >= 300) { 
      rankName = "Apprentice";
      rankIcon = Icons.construction;
      nextTarget = 1200;
      progress = (totalMinutes - 300) / (1200 - 300);
    } else {
      progress = totalMinutes / 300;
    }

    List<BoxShadow> cardShadow = theme.brightness == Brightness.light 
      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      : [];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textSecondary.withOpacity(0.1), width: 1),
        boxShadow: cardShadow
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(rankIcon, color: theme.primary, size: 40),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CURRENT RANK", style: TextStyle(color: theme.textSecondary, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  Text(rankName, style: TextStyle(color: theme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Total Time", style: TextStyle(color: theme.textSecondary, fontSize: 10)),
                  Text(_formatDuration(totalMinutes), style: TextStyle(color: theme.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.textSecondary.withOpacity(0.2),
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Next Rank", style: TextStyle(color: theme.textSecondary, fontSize: 10)),
              Text(rankName == "Grandmaster" ? "Max Level" : "${nextTarget - totalMinutes}m to go", style: TextStyle(color: theme.textSecondary, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = currentTheme.value;
    int totalAllTimeMinutes = widget.history.fold(0, (sum, item) => sum + item.durationInMinutes);

    List<PomodoroRecord> filteredList = widget.history.where((r) {
      if (_selectedRange == StatsTimeRange.day) return _isSameDay(r.date, _focusedDate);
      return true; 
    }).toList();

    if (_touchedIndex != -1 && _selectedRange == StatsTimeRange.day) {
       DateTime targetDate = _focusedDate.subtract(Duration(days: (6 - _touchedIndex)));
       filteredList = widget.history.where((r) => _isSameDay(r.date, targetDate)).toList();
    }

    Map<String, int> detailStats = {};
    int totalDurationInView = 0;
    for (var r in filteredList) { 
      detailStats[r.tagName] = (detailStats[r.tagName] ?? 0) + r.durationInMinutes;
      totalDurationInView += r.durationInMinutes;
    }

    final chartData = _getChartData(theme.primary);
    final List<BarChartGroupData> barGroups = chartData['groups'];
    final double calculatedMaxY = (chartData['maxY'] as double);
    final double effectiveMaxY = calculatedMaxY == 0 ? 60 : calculatedMaxY * 1.1; 

    List<BoxShadow> cardShadow = theme.brightness == Brightness.light 
      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      : [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildRankCard(theme, totalAllTimeMinutes),
            Container(
              padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(12), boxShadow: cardShadow),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: StatsTimeRange.values.map((range) {
                  bool isSelected = _selectedRange == range;
                  return Expanded(child: GestureDetector(onTap: () => setState(() { _selectedRange = range; _focusedDate = DateTime.now(); _touchedIndex = -1; }), child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: isSelected ? theme.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text(range.name.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : theme.textSecondary)))));
                }).toList()),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), color: theme.textSecondary, onPressed: () => _moveDate(-1)), Column(children: [Text(_dateTitle, style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)), Text("In View: ${_formatDuration(totalDurationInView)}", style: TextStyle(color: theme.primary, fontSize: 12, fontWeight: FontWeight.bold))]), IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18), color: theme.textSecondary, onPressed: () => _moveDate(1))]),
            const SizedBox(height: 20),
            SizedBox(
              height: 200, 
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround, 
                  maxY: effectiveMaxY, 
                  barTouchData: BarTouchData(
                    enabled: true, 
                    touchCallback: (FlTouchEvent event, barTouchResponse) { 
                      setState(() {
                        if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                          _touchedIndex = -1; 
                          return;
                        }
                        _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                      });
                    }, 
                    touchTooltipData: BarTouchTooltipData(getTooltipColor: (group) => theme.primary, getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem('${rod.toY.round()} min', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
                  ), 
                  titlesData: FlTitlesData(
                    show: true, 
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (double value, TitleMeta meta) { 
                      String text = ""; 
                      if (_selectedRange == StatsTimeRange.day) { DateTime d = _focusedDate.subtract(Duration(days: (6 - value.toInt()))); text = "${d.day}"; } 
                      else if (_selectedRange == StatsTimeRange.month) { text = "${value.toInt() + 1}"; } 
                      else if (_selectedRange == StatsTimeRange.year) { text = "${_focusedDate.year - (4 - value.toInt())}"; } 
                      return SideTitleWidget(meta: meta, space: 4, child: Text(text, style: TextStyle(color: value.toInt() == _touchedIndex ? theme.primary : theme.textSecondary, fontSize: 10))); 
                    }))
                  ), 
                  gridData: FlGridData(show: false), 
                  borderData: FlBorderData(show: false), 
                  barGroups: barGroups 
                )
              )
            ),
            const SizedBox(height: 20),
            Text("DETAILS", style: TextStyle(color: theme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(child: detailStats.isEmpty ? Center(child: Text("No activity recorded.", style: TextStyle(color: theme.textSecondary))) : ListView(children: detailStats.entries.map((entry) { Color tagColor = theme.textSecondary; try { tagColor = widget.tags.firstWhere((t) => t.name == entry.key).color; } catch (_) {} return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: tagColor, width: 4)), boxShadow: cardShadow), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(entry.key, style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)), Text("${entry.value} min", style: TextStyle(color: tagColor, fontWeight: FontWeight.bold))])); }).toList())),
          ],
        ),
      ),
    );
  }
}