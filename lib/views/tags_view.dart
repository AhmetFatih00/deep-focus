import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';

class TagsManageView extends StatelessWidget {
  final List<Tag> tags;
  final Function(Tag) onAddTag;
  final Function(String) onDeleteTag;
  final Function(Tag, Tag) onEditTag;
  const TagsManageView({super.key, required this.tags, required this.onAddTag, required this.onDeleteTag, required this.onEditTag});

  @override
  Widget build(BuildContext context) {
    final theme = currentTheme.value;
    List<BoxShadow> cardShadow = theme.brightness == Brightness.light ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] : [];
    
    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.background,
        floatingActionButton: FloatingActionButton(backgroundColor: theme.primary, child: const Icon(Icons.add, color: Colors.white), onPressed: () => _showTagDialog(context, null)),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("TAGS", style: TextStyle(color: theme.textSecondary, letterSpacing: 2, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text("Manage Categories", style: TextStyle(color: theme.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    final isGeneral = tag.name == "General";
                    return Dismissible(
                      key: Key(tag.name), direction: isGeneral ? DismissDirection.none : DismissDirection.endToStart,
                      confirmDismiss: (direction) async { return !isGeneral; }, onDismissed: (_) => onDeleteTag(tag.name),
                      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
                      child: GestureDetector(
                        onTap: () { if (isGeneral) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("General tag cannot be edited 🔒"))); } else { _showTagDialog(context, tag); } },
                        child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.textSecondary.withOpacity(0.1)), boxShadow: cardShadow), child: Row(children: [CircleAvatar(backgroundColor: tag.color, radius: 10), const SizedBox(width: 16), Text(tag.name, style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.w500)), const Spacer(), if (isGeneral) Icon(Icons.lock, color: Colors.grey, size: 20) else Icon(Icons.edit, color: theme.textSecondary, size: 20)])),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTagDialog(BuildContext context, Tag? existingTag) {
    final theme = currentTheme.value;
    TextEditingController nameController = TextEditingController(text: existingTag?.name ?? "");
    Color selectedColor = existingTag?.color ?? Colors.blue; 
    bool isEdit = existingTag != null;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( 
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: theme.surface, title: Text(isEdit ? "Edit Tag" : "New Tag", style: TextStyle(color: theme.textPrimary)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameController, style: TextStyle(color: theme.textPrimary), decoration: InputDecoration(hintText: "Tag Name", hintStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primary)))), const SizedBox(height: 20), const Text("Select Color", style: TextStyle(color: Colors.grey)), const SizedBox(height: 10), Wrap(spacing: 10, children: [Colors.red, Colors.orange, Colors.amber, Colors.green, Colors.teal, Colors.blue, Colors.indigo, Colors.purple, Colors.pink].map((color) { return GestureDetector(onTap: () => setState(() => selectedColor = color), child: CircleAvatar(backgroundColor: color, radius: 14, child: selectedColor == color ? const Icon(Icons.check, size: 16, color: Colors.white) : null)); }).toList())]),
            actions: [
              if (isEdit && existingTag.name != "General") TextButton(onPressed: () { onDeleteTag(existingTag.name); Navigator.pop(ctx); }, child: const Text("DELETE", style: TextStyle(color: Color(0xFFEF4444)))),
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: TextStyle(color: theme.textSecondary))),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: theme.primary), onPressed: () { if (nameController.text.isNotEmpty) { Tag newTag = Tag(name: nameController.text, colorValue: selectedColor.value); if (isEdit) { onEditTag(existingTag, newTag); } else { onAddTag(newTag); } Navigator.pop(ctx); } }, child: Text(isEdit ? "SAVE" : "ADD", style: const TextStyle(color: Colors.white)))
            ],
          );
        },
      ),
    );
  }
}