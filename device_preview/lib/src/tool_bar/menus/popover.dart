import 'package:device_preview/src/utilities/media_query_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

import 'package:device_preview/device_preview.dart';
import 'package:device_preview/src/utilities/position.dart';

typedef PopoverContentBuilder = Widget Function(
    BuildContext context, GestureTapCallback onClose);

class Popover extends StatefulWidget {
  final Widget child;
  final String title;
  final IconData icon;
  final Size size;
  final PopoverContentBuilder builder;
  final GestureTapCallback onClose;

  const Popover({
    Key key,
    this.size,
    @required this.title,
    @required this.icon,
    @required this.child,
    @required this.builder,
    @required this.onClose,
  }) : super(key: key);

  static void open(BuildContext context) {
    final state = context.findAncestorStateOfType<_PopoverState>();
    state.open();
  }

  static void close(BuildContext context) {
    final state = context.findAncestorStateOfType<_PopoverState>();
    state.close();
  }

  // void closePopup(BuildContext context) {
  //   _popoverState.close();
  // }

  @override
  _PopoverState createState() => _PopoverState();
}

class _PopoverState extends State<Popover> {
  final _key = GlobalKey(debugLabel: '${_PopoverState}.${math.Random().nextInt(100)}');
  List<OverlayEntry> _overlayEntries = [];
  bool _isOpen = false;

  void open() {
    final previewState = DevicePreview.of(context);
    if (!_isOpen) {
      final barrier = OverlayEntry(
        opaque: false,
        builder: (context) => _PopOverBarrier(
          () => close(),
          key: Key('PopoverBarrier${widget.title}Close')
        ),
      );

      final popover = OverlayEntry(
        opaque: false,
        builder: (context) => MediaQueryObserver(
          child: DevicePreviewProvider(
            availableDevices: previewState.availableDevices,
            data: previewState.data,
            mediaQuery: previewState.mediaQuery,
            child: _PopOverContainer(
              title: widget.title,
              icon: widget.icon,
              child: widget.builder(context, close),
              size: widget.size ?? Size(280, 420),
              startPosition: _key.absolutePosition,
              onClose: () => close()
            ),
          ),
        ),
      );

      _overlayEntries.add(barrier);
      _overlayEntries.add(popover);
      Overlay.of(context).insertAll(_overlayEntries);
      _isOpen = true;
    }
  }

  void close() {
    if (_isOpen) {
      for (var item in _overlayEntries) {
        item.remove();
      }
      _overlayEntries.clear();
      _isOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _key,
      child: widget.child,
    );
  }
}

class _PopOverContainer extends StatefulWidget {
  final Rect startPosition;
  final Size size;
  final Widget child;
  final String title;
  final IconData icon;
  final GestureTapCallback onClose;

  _PopOverContainer({
    @required this.title,
    @required this.icon,
    @required this.child,
    @required this.startPosition,
    @required this.size,
    @required this.onClose
  });

  @override
  __PopOverContainerState createState() => __PopOverContainerState();
}

class __PopOverContainerState extends State<_PopOverContainer>
    with WidgetsBindingObserver {
  bool _isStarted;
  Offset _translate;

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  @override
  void initState() {
    // Centered bottom
    _translate = Offset.zero;
    _isStarted = false;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        _isStarted = true;
      });
    });
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = const Duration(milliseconds: 80);
    final toolBarStyle = DevicePreviewTheme.of(context).toolBar;
    final media = MediaQuery.of(context);

    var bounds = widget.startPosition;

    final isHorizontal =
        toolBarStyle.position == DevicePreviewToolBarPosition.top ||
            toolBarStyle.position == DevicePreviewToolBarPosition.bottom;

    if (_isStarted) {
      if (widget.startPosition.top > media.size.height / 2) {
        final bottom = isHorizontal ? bounds.top : bounds.bottom;
        if (widget.startPosition.left > media.size.width / 2) {
          // Bottom-Right of the screen
          final right = isHorizontal ? bounds.right : bounds.left;
          bounds = Rect.fromLTRB(
            right - widget.size.width,
            bottom - widget.size.height,
            right,
            bottom,
          );
        } else {
          // Bottom-Left of the screen
          final left = isHorizontal ? bounds.left : bounds.right;
          bounds = Rect.fromLTRB(
            left,
            bottom - widget.size.height,
            left + widget.size.width,
            bottom,
          );
        }
      } else {
        final top = isHorizontal ? bounds.bottom : bounds.top;
        if (widget.startPosition.left > media.size.width / 2) {
          // Top-Right of the screen
          final right = isHorizontal ? bounds.right : bounds.left;
          bounds = Rect.fromLTRB(
            right - widget.size.width,
            top,
            right,
            top + widget.size.height,
          );
        } else {
          // Top-Left of the screen
          final left = isHorizontal ? bounds.left : bounds.right;
          bounds = Rect.fromLTRB(
            left,
            top,
            left + widget.size.width,
            top + widget.size.height,
          );
        }
      }
    }

    if (bounds.bottom > media.size.height - media.padding.bottom) {
      bounds = Offset(bounds.left,
              media.size.height - media.padding.bottom - bounds.size.height) &
          bounds.size;
    }
    if (bounds.top < media.padding.top) {
      bounds = Offset(bounds.left, media.padding.top) & bounds.size;
    }

    return AnimatedPositioned(
      key: Key('PopUp'),
      duration: duration,
      left: bounds.left + _translate.dx,
      top: bounds.top - media.viewInsets.bottom + _translate.dy,
      width: bounds.width,
      height: math.min(
          bounds.height,
          media.size.height -
              media.viewInsets.vertical -
              media.viewPadding.vertical),
      child: AnimatedOpacity(
        duration: duration,
        opacity: _isStarted ? 1.0 : 0.0,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          transform: (_isStarted
              ? Matrix4.identity()
              : Matrix4.translationValues(0, 6.0, 0)),
          decoration: BoxDecoration(
            color: toolBarStyle.buttonBackgroundColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Column(
            children: <Widget>[
              GestureDetector(
                onPanUpdate: (u) {
                  setState(() => _translate += u.delta);
                },
                child: _PopOverHeader(
                  title: widget.title,
                  icon: widget.icon,
                  onTap: widget.onClose,
                ),
              ),
              Expanded(
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopOverBarrier extends StatelessWidget {
  final GestureTapCallback onTap;

  _PopOverBarrier(this.onTap, { key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTap,
        child: Container(color: const Color(0x06000000)),
      ),
    );
  }
}

class _PopOverHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final GestureTapCallback onTap;

  _PopOverHeader({
    @required this.title,
    @required this.icon,
    @required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final toolBarStyle = DevicePreviewTheme.of(context).toolBar;
    print('$this.title: $title');
    return Container(
      decoration: BoxDecoration(
        color: toolBarStyle.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6.0),
          topRight: Radius.circular(6.0),
        ),
      ),
      padding: EdgeInsets.all(10.0),
      child: Stack(
        fit: StackFit.loose,
        alignment: Alignment.topCenter,
        children: <Widget>[
            Row(// child: 
            children: <Widget>[
              Icon(
                icon,
                size: 12.0,
                color: toolBarStyle.foregroundColor,
              ),
              SizedBox(
                width: 6.0,
              ),
              Text(
                title,
                style: TextStyle(
                  color: toolBarStyle.foregroundColor,
                ),
              )
            ]
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              // Container(
              //   width: 40, 
              //   height: 20,
              //   child: FlatButton(
              //     key: Key('${title}CloseButton'),
              //     child: Icon(
              //       Icons.close,                    
              //       semanticLabel: '${title}CloseButton',
              //       color: toolBarStyle.foregroundColor,
              //       size: 20,
              //     ),
              //     onPressed: () { onTap(); },
              //   )
              // )
              PopoverCloseButton(
                onTap,
                size: 20.0,
                key: Key('${title}CloseButton'),
                semanticLabel: 'PopoverCloseButton',
                color: toolBarStyle.foregroundColor
              )
            ]
          )
        ],
      ),
      // child: Row(
      //   crossAxisAlignment: CrossAxisAlignment.end,
      //   children: <Widget>[
      //     Row(// child: 
      //       children: <Widget>[
      //         Icon(
      //           icon,
      //           size: 12.0,
      //           color: toolBarStyle.foregroundColor,
      //         ),
      //         SizedBox(
      //           width: 6.0,
      //         ),
      //         Text(
      //           title,
      //           style: TextStyle(
      //             color: toolBarStyle.foregroundColor,
      //           ),
      //         )
      //       ]
      //     ),
      //     SizedBox(
      //         width: 175,
      //     ),
      //     PopoverCloseButton(
      //       onTap,
      //       size: 20.0,
      //       key: Key('PopoverHeaderCloseButton'),
      //       semanticLabel: 'PopoverCloseButton',
      //       color: toolBarStyle.foregroundColor
      //     )
      //   ]
      // )
    );
  }
}

class PopoverCloseButton extends GestureDetector {
  final Color color;
  final double size;
  final String semanticLabel;
  final TextDirection textDirection;

  PopoverCloseButton(onTap, {
    Key key,
    this.color,
    this.size,
    this.semanticLabel,
    this.textDirection,
  }) : super(
    // key: key,
    key: key,
    onTap: onTap,
    child: Icon(
      Icons.close,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
      textDirection: textDirection
    )
  );
}


              // SizedBox(
              //   width: 46,
              // ),
              // FlatButton(
              //   key: Key('PopOverHeaderCloseButton'),
              //   padding: EdgeInsets.all(0.0),
              //   clipBehavior: Clip.hardEdge,
              //   child: Icon(
              //     Icons.close,
              //     size: 12.0,
              //     color: toolBarStyle.foregroundColor,
              //   ),
              //   onPressed: onTap,
              // )
              // FlatButton.icon(
              //   key: Key('PopOverHeaderCloseButton'),
              //   // width: 12.0,
              //   icon: Icon(
              //     Icons.close,
              //     color: toolBarStyle.foregroundColor,
              //   ),
              //   tooltip: 'Close popover',
              //   onPressed: () { close(context); },
              // )
              // Icon(
              //   Icons.close,
              //   size: 12.0,
              //   color: toolBarStyle.foregroundColor,
              // )
              // SizedBox(
              //     width: 1.0,
              // ),
              // IconButton(
              //   key: Key('PopOverHeaderCloseButton'),
              //   icon: Icon(
              //     Icons.close,
              //     size: 12.0,
              //     color: toolBarStyle.foregroundColor,
              //   ),
              //   tooltip: 'Close popover',
              //   onPressed: () { close(context); },
              // )