import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final Color background;
  final Color surface;
  final Color primary;
  final Color textPrimary; 
  final Color textSecondary;
  final Brightness brightness;

  AppTheme({
    required this.name,
    required this.background,
    required this.surface,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.brightness,
  });
}

final List<AppTheme> appThemes = [
  AppTheme(
    name: "Clean Light", 
    background: const Color(0xFFF4F5F7), 
    surface: const Color(0xFFFFFFFF), 
    primary: const Color(0xFF2854C3), 
    textPrimary: const Color(0xFF1E293B), 
    textSecondary: const Color(0xFF64748B), 
    brightness: Brightness.light,
  ),
  AppTheme(
    name: "Deep Ocean", 
    background: const Color(0xFF0F172A), surface: const Color(0xFF1E293B), primary: const Color(0xFF2DD4BF), 
    textPrimary: Colors.white, textSecondary: const Color(0xFF94A3B8), brightness: Brightness.dark,
  ),
  AppTheme(
    name: "Midnight", 
    background: const Color(0xFF000000), surface: const Color(0xFF121212), primary: const Color(0xFF3B82F6), 
    textPrimary: Colors.white, textSecondary: const Color(0xFF6B7280), brightness: Brightness.dark,
  ),
  AppTheme(
    name: "Forest", 
    background: const Color(0xFF051F1A), surface: const Color(0xFF0D362E), primary: const Color(0xFF10B981), 
    textPrimary: Colors.white, textSecondary: const Color(0xFF6EE7B7), brightness: Brightness.dark,
  ),
];

final ValueNotifier<AppTheme> currentTheme = ValueNotifier(appThemes[0]);