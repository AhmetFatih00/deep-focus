import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';

class TasksView extends StatelessWidget {
  final List<DailyTask> tasks;
  final List<PomodoroRecord> history;
  final List<Tag> tags;
  final Function(DailyTask) onAddTask;
  final Function(String) onDeleteTask;

  const TasksView({super.key, required this.tasks, required this.history, required this.tags, required this.onAddTask, required this.onDeleteTask});


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: currentTheme,
      builder: (context, theme, child) {
        List<BoxShadow> cardShadow = theme.brightness == Brightness.light ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] : [];
        Map<String, int> todayStats = _getStatsForToday();

        return SafeArea(
          child: Scaffold(
            backgroundColor: theme.background,
            floatingActionButton: FloatingActionButton(
              backgroundColor: theme.primary, 
              child: const Icon(Icons.add, color: Colors.white), 
              onPressed: () => _showAddTaskDialog(context)
            ),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("DAILY GOALS", style: TextStyle(color: theme.textSecondary, letterSpacing: 2, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text("Your Tasks", style: TextStyle(color: theme.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: tasks.isEmpty 
                      ? Center(child: Text("No daily tasks yet. Tap + to create one.", style: TextStyle(color: theme.textSecondary)))
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            
                            int totalTarget = 0;
                            int totalDone = 0;
                            for (var sub in task.subItems) {
                              int done = todayStats[sub.tagName] ?? 0;
                              totalTarget += sub.targetMinutes;
                              totalDone += done > sub.targetMinutes ? sub.targetMinutes : done;
                            }
                            double overallProgress = totalTarget > 0 ? totalDone / totalTarget : 0.0;
                            bool isTaskCompleted = overallProgress >= 1.0;

                            return Dismissible(
                              key: Key(task.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => onDeleteTask(task.id),
                              background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isTaskCompleted ? Colors.green.withOpacity(0.05) : theme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isTaskCompleted ? Colors.green : theme.textSecondary.withOpacity(0.1), width: isTaskCompleted ? 2 : 1),
                                  boxShadow: cardShadow
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(task.title, style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, decoration: isTaskCompleted ? TextDecoration.lineThrough : null)),
                                        const Spacer(),
                                        Text("${(overallProgress * 100).toInt()}%", style: TextStyle(color: isTaskCompleted ? Colors.green : theme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: overallProgress,
                                        minHeight: 8,
                                        backgroundColor: theme.textSecondary.withOpacity(0.1),
                                        color: isTaskCompleted ? Colors.green : theme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Divider(color: theme.textSecondary.withOpacity(0.1)),
                                    ...task.subItems.map((sub) {
                                      int done = todayStats[sub.tagName] ?? 0;
                                      double subProgress = sub.targetMinutes > 0 ? (done / sub.targetMinutes).clamp(0.0, 1.0) : 0.0;
                                      bool isSubCompleted = subProgress >= 1.0;
                                      
                                      Color tagColor = theme.textSecondary;
                                      try { tagColor = tags.firstWhere((t) => t.name == sub.tagName).color; } catch (_) {}

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(backgroundColor: tagColor, radius: 5),
                                                const SizedBox(width: 8),
                                                Text(sub.tagName, style: TextStyle(color: theme.textSecondary, fontSize: 14, decoration: isSubCompleted ? TextDecoration.lineThrough : null)),
                                                const Spacer(),
                                                Text("$done/${sub.targetMinutes}m", style: TextStyle(color: isSubCompleted ? Colors.green : theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: subProgress,
                                                minHeight: 5,
                                                backgroundColor: theme.textSecondary.withOpacity(0.06),
                                                color: tagColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Renamed internal helper function signature helper to avoid conflicts
  Map<String, int> _getStatsForToday() {
    Map<String, int> stats = {};
    DateTime now = DateTime.now();
    for (var r in history) {
      if (r.date.year == now.year && r.date.month == now.month && r.date.day == now.day) {
        stats[r.tagName] = (stats[r.tagName] ?? 0) + r.durationInMinutes;
      }
    }
    return stats;
  }

  void _showAddTaskDialog(BuildContext context) {
    final theme = currentTheme.value;
    TextEditingController titleController = TextEditingController();
    List<TaskSubItem> tempSubItems = [];
    Tag? selectedTag = tags.isNotEmpty ? tags.first : null;
    TextEditingController minController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( 
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: theme.surface, 
            title: Text("New Daily Task", style: TextStyle(color: theme.textPrimary)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  TextField(controller: titleController, style: TextStyle(color: theme.textPrimary), decoration: InputDecoration(hintText: "Task Title", hintStyle: const TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primary)))), 
                  const SizedBox(height: 20), 
                  
                  if (tempSubItems.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: theme.background, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: tempSubItems.map((sub) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [Text(sub.tagName, style: TextStyle(color: theme.textPrimary)), const Spacer(), Text("${sub.targetMinutes}m", style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold))]),
                        )).toList(),
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButton<Tag>(
                          isExpanded: true,
                          value: selectedTag, 
                          dropdownColor: theme.surface, 
                          style: TextStyle(color: theme.textPrimary),
                          onChanged: (Tag? newValue) { setState(() => selectedTag = newValue!); },
                          items: tags.map<DropdownMenuItem<Tag>>((Tag value) { return DropdownMenuItem<Tag>(value: value, child: Text(value.name, overflow: TextOverflow.ellipsis)); }).toList(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextField(controller: minController, keyboardType: TextInputType.number, style: TextStyle(color: theme.textPrimary), decoration: InputDecoration(hintText: "Min", hintStyle: const TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primary)))),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: theme.primary),
                        onPressed: () {
                          int? m = int.tryParse(minController.text);
                          if (selectedTag != null && m != null && m > 0) {
                            setState(() {
                              tempSubItems.add(TaskSubItem(tagName: selectedTag!.name, targetMinutes: m));
                              minController.clear();
                            });
                          }
                        }
                      )
                    ],
                  )
                ]
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: TextStyle(color: theme.textSecondary))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: theme.primary), 
                onPressed: () { 
                  if (titleController.text.isNotEmpty && tempSubItems.isNotEmpty) { 
                    DailyTask newTask = DailyTask(id: DateTime.now().millisecondsSinceEpoch.toString(), title: titleController.text, subItems: tempSubItems);
                    onAddTask(newTask);
                    Navigator.pop(ctx); 
                  } 
                }, 
                child: const Text("CREATE", style: TextStyle(color: Colors.white))
              )
            ],
          );
        },
      ),
    );
  }
}