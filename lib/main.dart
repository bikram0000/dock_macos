import 'package:flutter/material.dart';

///Developed by Bikramaditya Meher.
///Mac os Dock

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

/// [AnimatedItem] Widget that hold both [Draggable] and [dragTarget] widget for reorder
/// It is the Items for the dock.
class AnimateItem extends StatefulWidget {
  /// This is the common animation duration for animations.
  final int animationDuration;

  /// This is the main widget for [dock].
  final Widget Function(int index) builder;

  /// This will hold position of a specific [dock] Item.
  final int index;

  ///  [onAcceptWithDetails] is the call back function when space item accepted the dragged item.
  ///
  ///  [draggedIndex] Value will get where item should removed and replace to new index.
  ///  [replaceIndex] This will give exact index to be replaced.
  final Function(int draggedIndex, int replaceIndex)? onAcceptWithDetails;

  const AnimateItem({
    super.key,
    required this.builder,
    this.animationDuration = 200,
    required this.index,
    this.onAcceptWithDetails,
  });

  @override
  State<AnimateItem> createState() => _AnimateItemState();
}

class _AnimateItemState extends State<AnimateItem> {
  final GlobalKey _widgetKey = GlobalKey();
  final GlobalKey _rowkey = GlobalKey();
  OverlayPortalController overlayPortalController = OverlayPortalController();

  /// 0=center,1=left,2=right,-1=none, 3 = it should show overlay, 4= it will show place for dragged item
  /// [side] value indicate the sliding animation for which site to give space for
  /// draggable item.
  int side = 0;

  /// After drag canceled by user it will give a bounce effect;
  double scale = 1.0;
  Offset overLayOffset = Offset(0, 0);
  late Widget overLayWidget;
  late Widget childWidget;

  int? receiveIndex;

  int? replaceIndex;

  @override
  void initState() {
    super.initState();
    overLayWidget = widget.builder(widget.index);
    childWidget = widget.builder(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (receivedIcon) {
        /// Will get the dragged item index as [receivedIconIndex]
        /// if index of draggable item and dragTarget match we can show the widget.
        int receivedIconIndex = receivedIcon.data;
        if (widget.index == receivedIconIndex) {
          setState(() {
            side = 0;
          });
        }
        return true;
      },
      onAcceptWithDetails: (receivedIcon) {
        /// Use the GlobalKey to get the RenderBox of the widget.
        final RenderBox renderBox =
            _widgetKey.currentContext?.findRenderObject() as RenderBox;

        /// Get the widget's offset relative to the screen.
        Offset offset = renderBox.localToGlobal(Offset.zero);

        /// This will called by main stateless widget to change the
        /// position of the dock's items.
        /// [shouldIncrease] determine that index should increase or not as per
        /// slide animation
        if (widget.onAcceptWithDetails != null) {
          if (side == 1) {
            offset = Offset(offset.dx - (renderBox.size.width * 1), offset.dy);
          } else {
            offset = Offset(offset.dx + (renderBox.size.width * 1), offset.dy);
          }
          replaceIndex = widget.index;
          receiveIndex = receivedIcon.data;
          if (receivedIcon.data > widget.index) {
            if (side == 2) {
              /// If right side we need to increase the index so that
              /// it can placed to correct index as slide space is on right '2'
              /// side.
              replaceIndex = replaceIndex! + 1;
            }
          } else {
            if (side == 1) {
              /// If left side then we need to decrease the index
              replaceIndex = replaceIndex! - 1;
              if (replaceIndex! < 0) {
                replaceIndex = 0;
              }
            }
          }

          setState(() {
            overLayWidget = widget.builder(receivedIcon.data);
            scale = 1.3;
            overLayOffset = receivedIcon.offset;
          });
          overlayPortalController.show();
          //
          Future.delayed(Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                overLayOffset = offset;
                scale = 1.0;
              });
            }
          });
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
        final d = e.offset;

        /// Use the GlobalKey to get the RenderBox of the widget.
        final RenderBox renderBox =
            _rowkey.currentContext?.findRenderObject() as RenderBox;

        /// Get the widget's offset relative to the screen.
        final Offset offset = renderBox.localToGlobal(Offset.zero);

        /// Here we will check if the drag item wants to go left or right of that drag Target
        /// We need to give space and animate to that direction.
        if (widget.index != e.data) {
          var one = offset.dx;
          var two = d.dx;
          one += (renderBox.size.width / 4);

          if (one > two) {
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
          key: _rowkey,
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Left side space.
            AnimatedSize(
              duration: Duration(milliseconds: widget.animationDuration),
              child: side == 1
                  ? Opacity(
                      opacity: 0,
                      child: childWidget,
                    )
                  : const SizedBox.shrink(),
            ),
            Draggable<int>(
              data: widget.index,
              key: _widgetKey,

              /// This scale animation used while user holding the drag item.
              feedback: AnimatedScale(
                scale: 1.3,
                duration: Duration(milliseconds: widget.animationDuration),
                curve: Curves.bounceInOut,
                child: childWidget,
              ),
              onDragStarted: () {
                /// Use the GlobalKey to get the RenderBox of the widget.
                final RenderBox renderBox =
                    _widgetKey.currentContext?.findRenderObject() as RenderBox;

                /// Get the widget's offset relative to the screen.
                overLayOffset = renderBox.localToGlobal(Offset.zero);
              },
              childWhenDragging: Opacity(
                opacity: 0,
                child: AnimatedSize(
                  duration: Duration(milliseconds: widget.animationDuration),
                  child: side != -1 ? childWidget : const SizedBox.shrink(),
                ),
              ),
              onDragCompleted: () {},
              onDragEnd: (d) {
                if (d.wasAccepted) {
                  setState(() {
                    side = 3;
                  });
                  return;
                }

                var dd = overLayOffset;
                setState(() {
                  side = 3;
                  scale = 1.3;
                  overLayOffset = d.offset;
                });

                overlayPortalController.show();

                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    setState(() {
                      overLayOffset = dd;
                      side = 4;
                      scale = 1.0;
                    });
                  }
                });
              },
              child: OverlayPortal(
                controller: overlayPortalController,
                overlayChildBuilder: (c) {
                  return AnimatedPositioned(
                    left: overLayOffset.dx,
                    top: overLayOffset.dy,
                    duration: Duration(milliseconds: widget.animationDuration),
                    child: AnimatedScale(
                      scale: scale,
                      duration:
                          Duration(milliseconds: widget.animationDuration),
                      child: overLayWidget,
                    ),
                    onEnd: () {
                      setState(() {
                        scale = 1.0;
                        if (receiveIndex == null) {
                          side = 0;
                          overlayPortalController.hide();
                        } else {
                          widget.onAcceptWithDetails!(
                              receiveIndex!, replaceIndex!);
                        }
                      });
                    },
                  );
                },
                child: side > 2
                    ? AnimatedSize(
                        duration:
                            Duration(milliseconds: widget.animationDuration),
                        child: side == 4
                            ? Opacity(
                                opacity: 0,
                                child: overLayWidget,
                              )
                            : const SizedBox.shrink(),
                      )
                    : childWidget,
              ),
            ),

            /// Right side space.
            AnimatedSize(
              duration: Duration(milliseconds: widget.animationDuration),
              child: side == 2
                  ? Opacity(
                      opacity: 0,
                      child: childWidget,
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
            /// work correctly other wise reflection will stay there for that item.
            return AnimateItem(
              key: UniqueKey(),
              builder: (i) => widget.builder(_items[i]),
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
