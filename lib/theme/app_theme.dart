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
    name: "Sunset Peach", 
    background: const Color(0xFFFFF8F5), 
    surface: const Color(0xFFFFFFFF), 
    primary: const Color(0xFFFF7E67), 
    textPrimary: const Color(0xFF4A3733), 
    textSecondary: const Color(0xFF8A7671), 
    brightness: Brightness.light,
  ),
  AppTheme(
    name: "Soft Mint", 
    background: const Color(0xFFF0F9F6), 
    surface: const Color(0xFFFFFFFF), 
    primary: const Color(0xFF38B2AC), 
    textPrimary: const Color(0xFF234E52), 
    textSecondary: const Color(0xFF4A5568), 
    brightness: Brightness.light,
  ),
  AppTheme(
    name: "Lavender Haze", 
    background: const Color(0xFFF8F5FF), 
    surface: const Color(0xFFFFFFFF), 
    primary: const Color(0xFF805AD5), 
    textPrimary: const Color(0xFF2D3748), 
    textSecondary: const Color(0xFF718096), 
    brightness: Brightness.light,
  ),
  AppTheme(
    name: "Midnight Red", 
    background: const Color(0xFF000000), 
    surface: const Color(0xFF121212), 
    primary: const Color(0xFFFF3B30), 
    textPrimary: Colors.white, 
    textSecondary: const Color(0xFF8E8E93), 
    brightness: Brightness.dark,
  ),
];

final ValueNotifier<AppTheme> currentTheme = ValueNotifier<AppTheme>(appThemes[0]);