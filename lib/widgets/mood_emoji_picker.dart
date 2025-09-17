import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MoodChoice {
  final String label;
  final String emoji;
  final Color color;
  MoodChoice(this.label, this.emoji, this.color);
}

class MoodEmojiPicker extends StatefulWidget {
  final void Function(MoodChoice) onSelected;
  const MoodEmojiPicker({super.key, required this.onSelected});

  @override
  State<MoodEmojiPicker> createState() => _MoodEmojiPickerState();
}

class _MoodEmojiPickerState extends State<MoodEmojiPicker> with TickerProviderStateMixin {
  final moods = <MoodChoice>[
    MoodChoice('Anger', '😡', const Color(0xFFE53935)),
    MoodChoice('Depressed', '😔', const Color(0xFF3949AB)),
    MoodChoice('Sad', '😢', const Color(0xFF42A5F5)),
    MoodChoice('Tired', '🥱', const Color(0xFF8D6E63)),
    MoodChoice('Anxious', '😰', const Color(0xFF26A69A)),
    MoodChoice('Okay', '🙂', const Color(0xFF7E57C2)),
    MoodChoice('Happy', '😄', const Color(0xFFFFA726)),
    MoodChoice('Chill', '🧘', const Color(0xFF26C6DA)),
  ];

  int? _selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: moods.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: .85,
      ),
      itemBuilder: (context, i) {
        final m = moods[i];
        final selected = _selected == i;

        return _MoodTile(
          mood: m,
          selected: selected,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selected = i);
            widget.onSelected(m);
          },
          onLongPress: () {
            HapticFeedback.vibrate();
            _showPeek(context, m);
          },
          borderColor: selected ? m.color : cs.outlineVariant.withOpacity(.25),
        );
      },
    );
  }

  void _showPeek(BuildContext context, MoodChoice m) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.35),
      builder: (_) => Dialog(
        backgroundColor: cs.surface,
        insetAnimationCurve: Curves.easeOutBack,
        insetAnimationDuration: const Duration(milliseconds: 320),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(m.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                m.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: m.color,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _moodAffirmation(m.label),
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              FilledButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(m.color),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _selected = moods.indexOf(m));
                  widget.onSelected(m);
                },
                child: const Text('Select This Mood'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _moodAffirmation(String label) {
    switch (label) {
      case 'Anger':
        return 'Anger is energy. We’ll channel it into movement + breath.';
      case 'Depressed':
        return 'You’re not alone. Gentle steps and tiny wins today.';
      case 'Sad':
        return 'It’s okay to feel. We’ll lift you with warmth + care.';
      case 'Tired':
        return 'We’ll pace the day and refill your battery smartly.';
      case 'Anxious':
        return 'We’ll slow the breath and ground the senses.';
      case 'Okay':
        return 'Let’s keep it steady and add a small joy.';
      case 'Happy':
        return 'Awesome! We’ll reinforce the good vibes.';
      case 'Chill':
        return 'Float mode. Light, restorative suggestions coming up.';
      default:
        return 'We’ll tailor the flow to your vibe.';
    }
  }
}

class _MoodTile extends StatefulWidget {
  final MoodChoice mood;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Color borderColor;

  const _MoodTile({
    required this.mood,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.borderColor,
  });

  @override
  State<_MoodTile> createState() => _MoodTileState();
}

class _MoodTileState extends State<_MoodTile> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final Animation<double> _scale =
      Tween(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override
  void didUpdateWidget(covariant _MoodTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // subtle pulse when selection changes
    if (oldWidget.selected != widget.selected && widget.selected) {
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.reverse(),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.borderColor, width: 1.2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [widget.mood.color.withOpacity(.22), widget.mood.color.withOpacity(.08)]
                  : [Colors.white, const Color(0xFFF6F7FB)],
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: widget.mood.color.withOpacity(.28),
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: selected ? 'm-hero-${widget.mood.label}' : 'm-hero-${widget.mood.label}-silent',
                child: Text(widget.mood.emoji, style: const TextStyle(fontSize: 34)),
              ),
              const SizedBox(height: 8),
              Text(
                widget.mood.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? widget.mood.color : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
