import 'package:flutter/material.dart';

///Developed by Bikramaditya Meher.

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorder able [items].
class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// AnimatedItem Widget that hold both [Draggable] and [dragTarget] widget for reorder
class AnimateItem extends StatefulWidget {
  /// This is the common animation duration for animations.
  final int animationDuration;

  /// This is the main widget for [dock].
  final Widget icon;

  /// This will hold position of a specific [dock] Item.
  final int index;

  ///  [draggedIndex] Value will get where item should removed and replace to new index.
  ///  [replaceIndex] This will give exact index to be replaced.
  /// [onAcceptWithDetails].
  final Function(int draggedIndex, int replaceIndex)? onAcceptWithDetails;

  const AnimateItem(
      {super.key,
      required this.icon,
      this.animationDuration = 200,
      required this.index,
      this.onAcceptWithDetails});

  @override
  State<AnimateItem> createState() => _AnimateItemState();
}

class _AnimateItemState extends State<AnimateItem> {
  final GlobalKey _widgetKey = GlobalKey();

  /// 0=center,1=left,2=right,-1=none
  /// This value indicate the sliding animation for which site to give space for
  /// draggable item.
  int side = 0;

  /// After drag canceled by user it will give a bounce effect;
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (receivedIcon) {
        /// Will get the dragged item index as [receivedIconIndex]
        /// if index of draggable item and dragTarget match we can so the widget.
        int receivedIconIndex = receivedIcon.data;
        if (widget.index == receivedIconIndex) {
          setState(() {
            side = 0;
          });
        }
        return true;
      },
      onAcceptWithDetails: (receivedIcon) {
        /// This will called by main stateless widget to change the
        /// position of the dock's items.
        /// [shouldIncrease] determine that index should increase or not as per
        /// slide animation
        if (widget.onAcceptWithDetails != null) {
          int replaceIndex = widget.index;
          if (receivedIcon.data > widget.index) {
            if (side == 2) {
              /// If right side we need to increase the index so that
              /// it can placed to correct index as slide space is on right '2'
              /// side.
              replaceIndex = replaceIndex + 1;
            }
          } else {
            if (side == 1) {
              /// If left side then we need to decrease the index
              replaceIndex = replaceIndex - 1;
              if (replaceIndex < 0) {
                replaceIndex = 0;
              }
            }
            // shouldIncrease = (side == 2);
          }
          widget.onAcceptWithDetails!(receivedIcon.data, replaceIndex);
        }
      },
      onLeave: (e) {
        /// While Leaving one DragTarget we need to remove all the spaces.
        /// If drag Item and drag Target are same we can remove the item too.
        /// So we need to set side as '-1' so the item space will removed.
        if (widget.index == e) {
          setState(() {
            side = -1;
          });
        } else {
          setState(() {
            side = 0;
          });
        }
      },
      onMove: (e) {
        /// Use the GlobalKey to get the RenderBox of the widget.
        final RenderBox renderBox =
            _widgetKey.currentContext?.findRenderObject() as RenderBox;

        /// Get the widget's offset relative to the screen.
        final Offset offset = renderBox.localToGlobal(Offset.zero);
        final d = e.offset;

        /// Here we will check if the drag item wants to go left or right of that drag Target
        /// We need to give space and animate to that direction.
        if (widget.index != e.data) {
          if ((offset.dx / d.dx) > 1) {
            setState(() {
              side = 1;
            });
          } else {
            setState(() {
              side = 2;
            });
          }
        }
      },
      builder: (context, acceptedData, rejectedData) {
        /// Global Key used to get offset to make animation
        return Row(
          key: _widgetKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Left side space.
            AnimatedSize(
              duration: Duration(milliseconds: widget.animationDuration),
              child: side == 1
                  ? Opacity(
                      opacity: 0,
                      child: widget.icon,
                    )
                  : const SizedBox.shrink(),
            ),
            Draggable<int>(
                data: widget.index,

                /// This scale animation used while user holding the drag item.
                feedback: AnimatedScale(
                  scale: 1.2,
                  duration: Duration(milliseconds: widget.animationDuration),
                  curve: Curves.bounceInOut,
                  child: widget.icon,
                ),
                childWhenDragging: Opacity(
                  opacity: 0,
                  child: AnimatedSize(
                    duration: Duration(milliseconds: widget.animationDuration),
                    child: side != -1 ? widget.icon : const SizedBox.shrink(),
                  ),
                ),
                onDraggableCanceled: (velocity, offset) {
                  /// On Drag canceled we need to make an animation so we can give here one bounce effect.
                  setState(() {
                    scale = 1.1;
                  });
                  Future.delayed(
                      Duration(milliseconds: widget.animationDuration ~/ 3),
                      () {
                    setState(() {
                      scale = 1.0;
                    });
                  });
                },
                child: AnimatedScale(
                  scale: scale,
                  duration: Duration(milliseconds: widget.animationDuration),
                  curve: Curves.bounceInOut,
                  child: widget.icon,
                  onEnd: () {
                    if (scale != 1.0) {
                      setState(() {
                        scale = 1.0;
                      });
                    }
                  },
                )),

            /// Right side space.
            AnimatedSize(
              duration: Duration(milliseconds: widget.animationDuration),
              child: side == 2
                  ? Opacity(
                      opacity: 0,
                      child: widget.icon,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  /// This will hold the position of the dragged item.
  int? receivedIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(_items.length, (index) {
            /// Here we are using one [GlobalKey] to make sure state management
            /// work correctly other wise reflection
            /// will stay there for that item.
            return AnimateItem(
              key: receivedIndex != null && receivedIndex == index
                  ? GlobalKey()
                  : null,
              icon: widget.builder(_items[index]),
              index: index,
              onAcceptWithDetails: (
                draggedIndex,
                replaceIndex,
              ) {
                /// Will check if it is space for right side we need to insert
                /// the dragged item we need to place the dragged item after the dragTarget widget.
                this.receivedIndex = index;
                var receivedIconWidget = _items[draggedIndex];
                setState(() {
                  _items.removeAt(draggedIndex);
                  _items.insert(replaceIndex, receivedIconWidget);
                });
              },
            );
          }),
        ],
      ),
    );
  }
}
