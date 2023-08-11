import 'package:flutter/material.dart';

class CustomTooltip extends StatefulWidget {
  final Widget child;
  final String message;

  const CustomTooltip({super.key, required this.child, required this.message});

  @override
  State<CustomTooltip> createState() => _CustomTooltipState();
}

class _CustomTooltipState extends State<CustomTooltip> {
  bool _isTooltipVisible = false;
  late OverlayEntry _overlayEntry;

  @override
  void initState() {
    super.initState();
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          child: _isTooltipVisible ? _buildTooltip() : Container(),
        );
      },
    );
  }

  @override
  void dispose() {
    _overlayEntry.remove();
    super.dispose();
  }

  Widget _buildTooltip() {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isTooltipVisible = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isTooltipVisible = false;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.all(8.0),
        child: Text(
          widget.message,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Overlay(
          initialEntries: [_overlayEntry],
        ),
      ],
    );
  }
}
