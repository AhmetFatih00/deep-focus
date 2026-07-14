import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback onClearHistory;
  const SettingsView({super.key, required this.onClearHistory});
  @override State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _vibrationEnabled = true;

  @override void initState() { super.initState(); _loadSettings(); }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _vibrationEnabled = prefs.getBool('setting_vibration') ?? true;
    });
  }

  Future<void> _saveVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_vibration', value);
    setState(() => _vibrationEnabled = value);
  }



  void _changeTheme(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_theme_index', index);
    currentTheme.value = appThemes[index]; 
  }



  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: currentTheme,
      builder: (context, theme, child) {
    List<BoxShadow> cardShadow = theme.brightness == Brightness.light ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] : [];

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.background,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SETTINGS", style: TextStyle(color: theme.textSecondary, letterSpacing: 2, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text("Control Center", style: TextStyle(color: theme.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              Text("THEMES", style: TextStyle(color: theme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(height: 80, decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
                child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), itemCount: appThemes.length, itemBuilder: (context, index) { final itemTheme = appThemes[index]; final isSelected = theme.name == itemTheme.name; return GestureDetector(onTap: () => _changeTheme(index), child: Container(width: 50, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: itemTheme.background, shape: BoxShape.circle, border: isSelected ? Border.all(color: theme.primary, width: 3) : Border.all(color: theme.textSecondary.withOpacity(0.3), width: 1)), child: Center(child: Container(width: 20, height: 20, decoration: BoxDecoration(color: itemTheme.primary, shape: BoxShape.circle))))); }),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
                child: SwitchListTile(
                  title: Text("Vibration", style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
                  subtitle: Text("Vibrate when timer ends", style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                  value: _vibrationEnabled,
                  activeColor: theme.primary,
                  onChanged: _saveVibration,
                ),
              ),
              const SizedBox(height: 30),
              Container(decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow), child: ListTile(leading: const Icon(Icons.delete_forever, color: Color(0xFFEF4444)), title: const Text("Clear All History", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)), subtitle: Text("This action cannot be undone", style: TextStyle(color: theme.textSecondary, fontSize: 12)), onTap: () => _showDeleteConfirmDialog(context))),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    final theme = currentTheme.value;
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: theme.surface, title: Text("Are you sure?", style: TextStyle(color: theme.textPrimary)), content: Text("All your stats and history will be permanently deleted.", style: TextStyle(color: theme.textSecondary)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: TextStyle(color: theme.textSecondary))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)), onPressed: () { widget.onClearHistory(); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("History cleared 🗑️"))); }, child: const Text("YES, DELETE", style: TextStyle(color: Colors.white)))]));
  }
}