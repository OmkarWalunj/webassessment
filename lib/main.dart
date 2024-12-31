import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[200],
        body: Center(
          child: Dock(
            items: const [
              DockItem(icon: Icons.person, label: "Contacts"),
              DockItem(icon: Icons.message, label: "Messages"),
              DockItem(icon: Icons.call, label: "Phone"),
              DockItem(icon: Icons.camera, label: "Camera"),
              DockItem(icon: Icons.photo, label: "Photos"),
            ],
            builder: (item) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.primaries[item.icon.hashCode % Colors.primaries.length],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(child: Icon(item.icon, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DockItem {
  final IconData icon;
  final String label;

  const DockItem({required this.icon, required this.label});
}

class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  final List<T> items;
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T> extends State<Dock<T>> with TickerProviderStateMixin {
  late final List<T> _items = widget.items.toList();
  int? _draggedIndex;
  Offset? _dragPosition;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  int? _lastDroppedIndex;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              
              return DragTarget<int>(
                onWillAccept: (data) => true,
                onAccept: (draggedIndex) {
                  final draggedItem = _items[draggedIndex];
                  setState(() {
                    _items.removeAt(draggedIndex);
                    _items.insert(index, draggedItem);
                    _lastDroppedIndex = index;
                  });
                  _bounceController.forward(from: 0);
                },
                builder: (context, candidates, rejects) {
                  return Draggable<int>(
                    data: index,
                    feedback: Material(
                      color: Colors.transparent,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grabbing,
                        child: widget.builder(item),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.5,
                      child: widget.builder(item),
                    ),
                    onDragStarted: () {
                      setState(() => _draggedIndex = index);
                    },
                    onDragEnd: (details) {
                      setState(() => _draggedIndex = null);
                    },
                    onDragUpdate: (details) {
                      setState(() => _dragPosition = details.globalPosition);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Tooltip(
                        message: (item as DockItem).label,
                        child: AnimatedBuilder(
                          animation: _bounceAnimation,
                          builder: (context, child) {
                            double scale = _calculateScale(index);
                            if (_lastDroppedIndex == index) {
                              scale *= _bounceAnimation.value;
                            }
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: widget.builder(item),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
        // Reflection effect
        Transform.scale(
          scaleY: -0.3,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _items.map((item) {
                return Opacity(
                  opacity: 0.3,
                  child: widget.builder(item),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateScale(int index) {
    if (_dragPosition == null || _draggedIndex == null) return 1.0;

    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(_dragPosition!);
    final itemWidth = box.size.width / _items.length;
    final itemCenter = (index + 0.5) * itemWidth;
    final distance = (localPosition.dx - itemCenter).abs();
    
    // Parabolic scaling effect
    if (distance < itemWidth * 2) {
      final scale = 1.0 + (1 - (distance / (itemWidth * 2))) * 0.5;
      return scale;
    }
    
    return 1.0;
  }
}

// Window animation mixin (example implementation)
mixin WindowAnimation<T extends StatefulWidget> on State<T> {
  AnimationController? _windowController;
  Animation<double>? _windowAnimation;
  
  void setupWindowAnimation() {
    _windowController = AnimationController(
      vsync: this as TickerProvider,
      duration: const Duration(milliseconds: 300),
    );
    
    _windowAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _windowController!,
      curve: Curves.easeInOut,
    ));
  }
  
  void minimizeWindow(Offset targetPosition) {
    _windowController?.forward();
  }
  
  void maximizeWindow() {
    _windowController?.reverse();
  }
  
  @override
  void dispose() {
    _windowController?.dispose();
    super.dispose();
  }
}