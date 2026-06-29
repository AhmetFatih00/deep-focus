import 'package:flutter/material.dart';

class Tag {
  final String name;
  final int colorValue; 
  Tag({required this.name, required this.colorValue});
  Map<String, dynamic> toMap() => {'name': name, 'color': colorValue};
  factory Tag.fromMap(Map<String, dynamic> map) => Tag(name: map['name'], colorValue: map['color']);
  Color get color => Color(colorValue);
  @override bool operator ==(Object other) => other is Tag && other.name == name;
  @override int get hashCode => name.hashCode;
}

class PomodoroRecord {
  final DateTime date;
  final int durationInMinutes;
  final String tagName; 
  PomodoroRecord(this.date, this.durationInMinutes, {required this.tagName});
  Map<String, dynamic> toMap() => {'date': date.toIso8601String(), 'duration': durationInMinutes, 'tagName': tagName};
  factory PomodoroRecord.fromMap(Map<String, dynamic> map) => PomodoroRecord(DateTime.parse(map['date']), map['duration'], tagName: map['tagName'] ?? 'General');
}

class TaskSubItem {
  final String tagName;
  final int targetMinutes;
  TaskSubItem({required this.tagName, required this.targetMinutes});
  Map<String, dynamic> toMap() => {'tagName': tagName, 'targetMinutes': targetMinutes};
  factory TaskSubItem.fromMap(Map<String, dynamic> map) => TaskSubItem(tagName: map['tagName'], targetMinutes: map['targetMinutes']);
}

class DailyTask {
  final String id;
  final String title;
  final List<TaskSubItem> subItems;
  DailyTask({required this.id, required this.title, required this.subItems});
  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'subItems': subItems.map((e) => e.toMap()).toList()};
  factory DailyTask.fromMap(Map<String, dynamic> map) => DailyTask(id: map['id'], title: map['title'], subItems: (map['subItems'] as List).map((e) => TaskSubItem.fromMap(e)).toList());
}