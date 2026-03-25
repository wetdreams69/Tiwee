import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DpadFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  
  const DpadFocusable({
    Key? key, 
    required this.child, 
    required this.onPressed
  }) : super(key: key);

  @override
  State<DpadFocusable> createState() => _DpadFocusableState();
}

class _DpadFocusableState extends State<DpadFocusable> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select || 
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: _isFocused ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent,
              width: _isFocused ? 3 : 0,
            ),
            boxShadow: _isFocused
                ? [
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
