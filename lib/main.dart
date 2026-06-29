import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

// Mimari Paket İçe Aktarmaları (YENİ)
import 'theme/app_theme.dart';
import 'models/app_models.dart';
import 'services/notification_service.dart';
import 'views/timer_view.dart';
import 'views/tasks_view.dart';
import 'views/stats_view.dart';
import 'views/tags_view.dart';
import 'views/settings_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  
  final prefs = await SharedPreferences.getInstance();
  int savedThemeIndex = prefs.getInt('selected_theme_index') ?? 0;
  if (savedThemeIndex >= 0 && savedThemeIndex < appThemes.length) {
    currentTheme.value = appThemes[savedThemeIndex];
  }

  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: currentTheme,
      builder: (context, theme, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Deep Focus',
          theme: ThemeData(
            brightness: theme.brightness,
            scaffoldBackgroundColor: theme.background, 
            primaryColor: theme.primary, 
            fontFamily: 'Roboto',
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: theme.surface, 
              selectedItemColor: theme.primary, 
              unselectedItemColor: theme.textSecondary, 
              type: BottomNavigationBarType.fixed, 
              elevation: 20,
            ),
          ),
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<PomodoroRecord> history = [];
  List<Tag> tags = []; 
  List<DailyTask> dailyTasks = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    Permission.notification.request();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? historyJson = prefs.getString('pomodoro_history');
    if (historyJson != null) {
      List<dynamic> decoded = jsonDecode(historyJson);
      history = decoded.map((item) => PomodoroRecord.fromMap(item)).toList();
    }
    
    final String? tagsJson = prefs.getString('pomodoro_tags_v2');
    if (tagsJson != null) {
      List<dynamic> decoded = jsonDecode(tagsJson);
      tags = decoded.map((item) => Tag.fromMap(item)).toList();
    }
    if (!tags.any((t) => t.name == "General")) {
      tags.insert(0, Tag(name: "General", colorValue: currentTheme.value.primary.value));
      _saveTags();
    }

    final String? tasksJson = prefs.getString('pomodoro_daily_tasks');
    if (tasksJson != null) {
      List<dynamic> decoded = jsonDecode(tasksJson);
      dailyTasks = decoded.map((item) => DailyTask.fromMap(item)).toList();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pomodoro_history', jsonEncode(history.map((e) => e.toMap()).toList()));
  }

  Future<void> _saveTags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pomodoro_tags_v2', jsonEncode(tags.map((e) => e.toMap()).toList()));
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pomodoro_daily_tasks', jsonEncode(dailyTasks.map((e) => e.toMap()).toList()));
  }

  void _addPomodoro(int durationMinutes, String tagName) {
    setState(() => history.add(PomodoroRecord(DateTime.now(), durationMinutes, tagName: tagName)));
    _saveHistory();
  }

  void _addTag(Tag newTag) {
    if (tags.any((t) => t.name == "General")) return;
    setState(() => tags.add(newTag));
    _saveTags();
  }

  void _editTag(Tag oldTag, Tag newTag) {
    if (oldTag.name == "General") return; 
    setState(() {
      int index = tags.indexWhere((t) => t.name == oldTag.name);
      if (index != -1) tags[index] = newTag;
      for (var i = 0; i < history.length; i++) {
        if (history[i].tagName == oldTag.name) history[i] = PomodoroRecord(history[i].date, history[i].durationInMinutes, tagName: newTag.name);
      }
    });
    _saveTags(); _saveHistory();
  }

  void _deleteTag(String tagName) {
    if(tagName == "General") return; 
    setState(() => tags.removeWhere((t) => t.name == tagName));
    _saveTags();
  }

  void _addTask(DailyTask task) {
    setState(() => dailyTasks.add(task));
    _saveTasks();
  }

  void _deleteTask(String taskId) {
    setState(() => dailyTasks.removeWhere((t) => t.id == taskId));
    _saveTasks();
  }

  void _clearAllHistory() async {
    setState(() => history.clear());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pomodoro_history');
  }

  @override
  Widget build(BuildContext context) {
    final theme = currentTheme.value;
    if (_isLoading) return Scaffold(backgroundColor: theme.background, body: Center(child: CircularProgressIndicator(color: theme.primary)));
    final safeTags = tags.isEmpty ? [Tag(name: "General", colorValue: theme.primary.value)] : tags;
    
    final List<Widget> pages = [
      TimerView(onPomodoroComplete: _addPomodoro, tags: safeTags, history: history),
      TasksView(tasks: dailyTasks, history: history, tags: safeTags, onAddTask: _addTask, onDeleteTask: _deleteTask), 
      StatsView(history: history, tags: safeTags), 
      TagsManageView(tags: safeTags, onAddTag: _addTag, onDeleteTag: _deleteTag, onEditTag: _editTag), 
      SettingsView(onClearHistory: _clearAllHistory), 
    ];

    return Scaffold(
      backgroundColor: theme.background,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.textSecondary.withOpacity(0.1), width: 1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex, 
          onTap: (index) => setState(() => _selectedIndex = index), 
          selectedFontSize: 12,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.timer_rounded), label: 'Focus'), 
            BottomNavigationBarItem(icon: Icon(Icons.task_alt_rounded), label: 'Tasks'), 
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: 'Stats'), 
            BottomNavigationBarItem(icon: Icon(Icons.label_rounded), label: 'Tags'), 
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings')
          ]
        ),
      ),
    );
  }
}