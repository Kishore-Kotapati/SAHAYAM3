
import 'package:flutter/material.dart';

class MissionTaskTile extends StatelessWidget {
  final String title;
  final bool done;
  final ValueChanged<bool> onChanged;
  const MissionTaskTile({super.key, required this.title, required this.done, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(value: done, onChanged: (v)=> onChanged(v ?? false)),
      title: Text(title, style: TextStyle(decoration: done ? TextDecoration.lineThrough : null)),
      tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
