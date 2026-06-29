import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class TimerView extends StatefulWidget {
  final Function(int, String) onPomodoroComplete;
  final List<Tag> tags;
  final List<PomodoroRecord> history; 

  const TimerView({super.key, required this.onPomodoroComplete, required this.tags, required this.history});
  @override State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> with WidgetsBindingObserver {
  int initialTime = 25 * 60;
  late int secondsRemaining;
  bool isRunning = false;
  Timer? timer;
  Tag? _selectedTag; 
  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    secondsRemaining = initialTime;
    _loadDefaultDuration();
    subscription = notificationStream.stream.listen((command) {
      if (command == 'pause_timer') stopTimer(updateNotification: true);
      else if (command == 'resume_timer') startTimer();
      else if (command == 'stop_timer') resetTimer();
    });
  }

  Tag get activeTag {
    if (_selectedTag == null || !widget.tags.contains(_selectedTag)) return widget.tags.firstWhere((t) => t.name == "General", orElse: () => widget.tags.first);
    return _selectedTag!;
  }

  int _calculateStreak() {
    if (widget.history.isEmpty) return 0;
    final uniqueDays = <String>{};
    for (var record in widget.history) {
      uniqueDays.add("${record.date.year}-${record.date.month}-${record.date.day}");
    }
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    bool isTodayActive = uniqueDays.contains(todayStr);

    int streak = 0;
    DateTime checkDate = now.subtract(const Duration(days: 1));
    while (true) {
      String checkStr = "${checkDate.year}-${checkDate.month}-${checkDate.day}";
      if (uniqueDays.contains(checkStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break; 
      }
    }
    if (isTodayActive) streak++;
    return streak;
  }

  bool _isTodayActive() {
    if (widget.history.isEmpty) return false;
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    return widget.history.any((r) => "${r.date.year}-${r.date.month}-${r.date.day}" == todayStr);
  }

  @override void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) _loadDefaultDuration(); }

  Future<void> _loadDefaultDuration() async {
    if (isRunning) return;
    final prefs = await SharedPreferences.getInstance();
    int defaultMins = prefs.getInt('setting_default_time') ?? 25;
    if (secondsRemaining == initialTime) setState(() { initialTime = defaultMins * 60; secondsRemaining = initialTime; });
  }

  @override void dispose() { timer?.cancel(); subscription?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }

  void startTimer() {
    if (timer != null) timer!.cancel();
    setState(() => isRunning = true);
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (secondsRemaining > 0) {
          secondsRemaining--;
          if (secondsRemaining % 5 == 0 || secondsRemaining < 10) NotificationService.showTimerNotification(secondsRemaining: secondsRemaining, totalSeconds: initialTime, isRunning: true, currentTag: activeTag.name);
        } else { completeTimer(); }
      });
    });
  }

  void stopTimer({bool updateNotification = false}) {
    timer?.cancel();
    setState(() => isRunning = false);
    if (updateNotification) NotificationService.showTimerNotification(secondsRemaining: secondsRemaining, totalSeconds: initialTime, isRunning: false, currentTag: activeTag.name);
  }

  void toggleTimer() => isRunning ? stopTimer(updateNotification: true) : startTimer();

  void completeTimer() async {
    timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    bool vibrateEnabled = prefs.getBool('setting_vibration') ?? true;
    if (vibrateEnabled && (await Vibration.hasVibrator() ?? false)) Vibration.vibrate(duration: 500);
    int duration = initialTime ~/ 60;
    widget.onPomodoroComplete(duration == 0 ? 1 : duration, activeTag.name);
    NotificationService.showCompleteNotification(duration == 0 ? 1 : duration, activeTag.name);
    setState(() { isRunning = false; secondsRemaining = initialTime; });
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    final theme = currentTheme.value;
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: theme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: Icon(Icons.check_circle, color: theme.primary, size: 50), content: Text("${activeTag.name} session completed!", textAlign: TextAlign.center, style: TextStyle(color: theme.textPrimary)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text("GREAT", style: TextStyle(color: theme.primary)))]));
  }

  void resetTimer() async {
    timer?.cancel();
    NotificationService.cancelTimerNotification();
    final prefs = await SharedPreferences.getInstance();
    int defaultMins = prefs.getInt('setting_default_time') ?? 25;
    setState(() { isRunning = false; initialTime = defaultMins * 60; secondsRemaining = initialTime; });
  }

  void setDuration(int minutes) {
    stopTimer();
    NotificationService.cancelTimerNotification();
    setState(() { initialTime = minutes * 60; secondsRemaining = initialTime; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = currentTheme.value;
    int streak = _calculateStreak();
    bool todayActive = _isTodayActive();
    
    List<BoxShadow> cardShadow = theme.brightness == Brightness.light 
      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
      : [];

    double progressValue = 1 - (secondsRemaining / initialTime);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: todayActive ? Colors.orange.withOpacity(0.1) : theme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: todayActive ? Colors.orange : theme.textSecondary.withOpacity(0.3), width: 1),
                  boxShadow: cardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, color: todayActive ? Colors.orange : theme.textSecondary, size: 20),
                    const SizedBox(width: 6),
                    Text("$streak", style: TextStyle(color: todayActive ? Colors.orange : theme.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: activeTag.color, width: 2), boxShadow: cardShadow),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Tag>(
                  value: activeTag, dropdownColor: theme.surface, icon: Icon(Icons.arrow_drop_down, color: theme.textSecondary), style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
                  onChanged: isRunning ? null : (Tag? newValue) { setState(() => _selectedTag = newValue!); },
                  items: widget.tags.map<DropdownMenuItem<Tag>>((Tag value) { return DropdownMenuItem<Tag>(value: value, child: Row(children: [CircleAvatar(backgroundColor: value.color, radius: 6), const SizedBox(width: 10), Text(value.name)])); }).toList(),
                ),
              ),
            ),
            const Spacer(),
            
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 280, 
                height: 280, 
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: progressValue, end: progressValue),
                  duration: Duration(milliseconds: isRunning ? 1000 : 300), 
                  curve: Curves.linear,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value, strokeWidth: 12, 
                      backgroundColor: activeTag.color.withOpacity(0.15), 
                      valueColor: AlwaysStoppedAnimation<Color>(activeTag.color),
                    );
                  }
                )
              ), 
              GestureDetector(
                onTap: () => _showDurationPicker(context),
                child: Container(
                  width: 240, height: 240, 
                  decoration: BoxDecoration(color: theme.surface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: theme.brightness == Brightness.light ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]), 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Text('${(secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(secondsRemaining % 60).toString().padLeft(2, '0')}', style: TextStyle(fontSize: 70, fontWeight: FontWeight.w800, color: theme.textPrimary, letterSpacing: -2)), 
                      if (!isRunning) Text("Tap to Adjust", style: TextStyle(color: theme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500))
                    ]
                  )
                ),
              ),
            ]),

            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildControlButton(icon: isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, label: isRunning ? "PAUSE" : "START", color: activeTag.color, textColor: Colors.white, onTap: toggleTimer), const SizedBox(width: 20), _buildControlButton(icon: Icons.refresh_rounded, label: "RESET", color: theme.surface, textColor: theme.textPrimary, onTap: resetTimer)]),
            const SizedBox(height: 40),
            Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(20), boxShadow: cardShadow), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildQuickSelect("Focus", 25), _buildQuickSelect("Short Break", 5), _buildQuickSelect("Long Break", 15)])),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required String label, required Color color, required Color textColor, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(30), child: Container(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(children: [Icon(icon, color: textColor), const SizedBox(width: 8), Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16))])));
  }

  Widget _buildQuickSelect(String label, int minutes) { 
    final theme = currentTheme.value; 
    return GestureDetector(onTap: () => setDuration(minutes), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Column(children: [Text("$minutes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textPrimary)), Text(label, style: TextStyle(fontSize: 10, color: theme.textSecondary))]))); 
  }

  void _showDurationPicker(BuildContext context) { 
    final theme = currentTheme.value;
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: theme.surface, title: Text("Time (min)", style: TextStyle(color: theme.textPrimary)), content: TextField(keyboardType: TextInputType.number, style: TextStyle(color: theme.textPrimary), decoration: InputDecoration(enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primary)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primary, width: 2))), onSubmitted: (val) { int? v = int.tryParse(val); if(v != null) { setDuration(v); Navigator.pop(ctx); }}), )); 
  }
}