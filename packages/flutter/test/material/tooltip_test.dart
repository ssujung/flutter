// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

// This file uses "as dynamic" in a few places to defeat the static
// analysis. In general you want to avoid using this style in your
// code, as it will cause the analyzer to be unable to help you catch
// errors.
//
// In this case, we do it because we are trying to call internal
// methods of the tooltip code in order to test it. Normally, the
// state of a tooltip is a private class, but by using a GlobalKey we
// can get a handle to that object and by using "as dynamic" we can
// bypass the analyzer's type checks and call methods that we aren't
// supposed to be able to know about.
//
// It's ok to do this in tests, but you really don't want to do it in
// production code.

const String tooltipText = 'TIP';

void main() {
  testWidgets('Does tooltip end up in the right place - center', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 300.0,
                      top: 0.0,
                      child: Tooltip(
                        key: key,
                        message: tooltipText,
                        height: 20.0,
                        padding: const EdgeInsets.all(5.0),
                        verticalOffset: 20.0,
                        preferBelow: false,
                        child: Container(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *      o            * y=0
     *      |            * }- 20.0 vertical offset, of which 10.0 is in the screen edge margin
     *   +----+          * \- (5.0 padding in height)
     *   |    |          * |- 20 height
     *   +----+          * /- (5.0 padding in height)
     *                   *
     *********************/

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent.parent.parent.parent.parent;

    final Offset tipInGlobal = tip.localToGlobal(tip.size.topCenter(Offset.zero));
    // The exact position of the left side depends on the font the test framework
    // happens to pick, so we don't test that.
    expect(tipInGlobal.dx, 300.0);
    expect(tipInGlobal.dy, 20.0);
  });

  testWidgets('Does tooltip end up in the right place - top left', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0.0,
                      top: 0.0,
                      child: Tooltip(
                        key: key,
                        message: tooltipText,
                        height: 20.0,
                        padding: const EdgeInsets.all(5.0),
                        verticalOffset: 20.0,
                        preferBelow: false,
                        child: Container(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *o                  * y=0
     *|                  * }- 20.0 vertical offset, of which 10.0 is in the screen edge margin
     *+----+             * \- (5.0 padding in height)
     *|    |             * |- 20 height
     *+----+             * /- (5.0 padding in height)
     *                   *
     *********************/

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent.parent.parent.parent.parent;
    expect(tip.size.height, equals(24.0)); // 14.0 height + 5.0 padding * 2 (top, bottom)
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)), equals(const Offset(10.0, 20.0)));
  }, skip: isBrowser);

  testWidgets('Does tooltip end up in the right place - center prefer above fits', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 400.0,
                      top: 300.0,
                      child: Tooltip(
                        key: key,
                        message: tooltipText,
                        height: 100.0,
                        padding: const EdgeInsets.all(0.0),
                        verticalOffset: 100.0,
                        preferBelow: false,
                        child: Container(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *        ___        * }- 10.0 margin
     *       |___|       * }-100.0 height
     *         |         * }-100.0 vertical offset
     *         o         * y=300.0
     *                   *
     *                   *
     *                   *
     *********************/

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(100.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(100.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(200.0));
  });

  testWidgets('Does tooltip end up in the right place - center prefer above does not fit', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 400.0,
                      top: 299.0,
                      child: Tooltip(
                        key: key,
                        message: tooltipText,
                        height: 190.0,
                        padding: const EdgeInsets.all(0.0),
                        verticalOffset: 100.0,
                        preferBelow: false,
                        child: Container(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    // we try to put it here but it doesn't fit:
    /********************* 800x600 screen
     *        ___        * }- 10.0 margin
     *       |___|       * }-190.0 height (starts at y=9.0)
     *         |         * }-100.0 vertical offset
     *         o         * y=299.0
     *                   *
     *                   *
     *                   *
     *********************/

    // so we put it here:
    /********************* 800x600 screen
     *                   *
     *                   *
     *         o         * y=299.0
     *        _|_        * }-100.0 vertical offset
     *       |___|       * }-190.0 height
     *                   * }- 10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(190.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(399.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(589.0));
  });

  testWidgets('Does tooltip end up in the right place - center prefer below fits', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 400.0,
                      top: 300.0,
                      child: Tooltip(
                        key: key,
                        message: tooltipText,
                        height: 190.0,
                        padding: const EdgeInsets.all(0.0),
                        verticalOffset: 100.0,
                        preferBelow: true,
                        child: Container(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *                   *
     *                   *
     *         o         * y=300.0
     *        _|_        * }-100.0 vertical offset
     *       |___|       * }-190.0 height
     *                   * }- 10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(190.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(400.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(590.0));
  });

  testWidgets('Does tooltip end up in the right place - way off to the right', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 1600.0,
                      top: 300.0,
                      child: Tooltip(
                        key: key,
                        message: tooltipText,
                        height: 10.0,
                        padding: const EdgeInsets.all(0.0),
                        verticalOffset: 10.0,
                        preferBelow: true,
                        child: Container(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *                   *
     *                   *
     *                   * y=300.0;   target -->   o
     *              ___| * }-10.0 vertical offset
     *             |___| * }-10.0 height
     *                   *
     *                   * }-10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(14.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(310.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dx, equals(790.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(324.0));
  }, skip: isBrowser);

  testWidgets('Does tooltip end up in the right place - near the edge', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 780.0,
                      top: 300.0,
                      child: Tooltip(
                        key: key,
                        message: tooltipText,
                        height: 10.0,
                        padding: const EdgeInsets.all(0.0),
                        verticalOffset: 10.0,
                        preferBelow: true,
                        child: Container(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *                   *
     *                   *
     *                o  * y=300.0
     *              __|  * }-10.0 vertical offset
     *             |___| * }-10.0 height
     *                   *
     *                   * }-10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(14.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(310.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dx, equals(790.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(324.0));
  }, skip: isBrowser);

  testWidgets('Default tooltip message textStyle - light', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Tooltip(
        key: key,
        message: tooltipText,
        child: Container(
          width: 100.0,
          height: 100.0,
          color: Colors.green[500],
        ),
      ),
    ));
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final TextStyle textStyle = tester.widget<Text>(find.text(tooltipText)).style;
    expect(textStyle.color, Colors.white);
    expect(textStyle.fontFamily, 'Roboto');
    expect(textStyle.decoration, TextDecoration.none);
    expect(textStyle.debugLabel, '((englishLike body1 2014).merge(blackMountainView body1)).copyWith');
  });

  testWidgets('Default tooltip message textStyle - dark', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: Tooltip(
        key: key,
        message: tooltipText,
        child: Container(
          width: 100.0,
          height: 100.0,
          color: Colors.green[500],
        ),
      ),
    ));
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final TextStyle textStyle = tester.widget<Text>(find.text(tooltipText)).style;
    expect(textStyle.color, Colors.black);
    expect(textStyle.fontFamily, 'Roboto');
    expect(textStyle.decoration, TextDecoration.none);
    expect(textStyle.debugLabel, '((englishLike body1 2014).merge(whiteMountainView body1)).copyWith');
  });

  testWidgets('Custom tooltip message textStyle', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Tooltip(
        key: key,
        textStyle: const TextStyle(
          color: Colors.orange,
          decoration: TextDecoration.underline
        ),
        message: tooltipText,
        child: Container(
          width: 100.0,
          height: 100.0,
          color: Colors.green[500],
        ),
      ),
    ));
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final TextStyle textStyle = tester.widget<Text>(find.text(tooltipText)).style;
    expect(textStyle.color, Colors.orange);
    expect(textStyle.fontFamily, null);
    expect(textStyle.decoration, TextDecoration.underline);
  });

  testWidgets('Does tooltip end up with the right default size, shape, and color', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Tooltip(
                  key: key,
                  message: tooltipText,
                  child: Container(
                    width: 0.0,
                    height: 0.0,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent.parent.parent.parent;

    expect(tip.size.height, equals(32.0));
    expect(tip.size.width, equals(74.0));
    expect(tip, paints..rrect(
      rrect: RRect.fromRectAndRadius(tip.paintBounds, const Radius.circular(4.0)),
      color: const Color(0xe6616161),
    ));
  }, skip: isBrowser);

  testWidgets('Can tooltip decoration be customized', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    const Decoration customDecoration = ShapeDecoration(
      shape: StadiumBorder(),
      color: Color(0x80800000),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Tooltip(
                  key: key,
                  decoration: customDecoration,
                  message: tooltipText,
                  child: Container(
                    width: 0.0,
                    height: 0.0,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    (key.currentState as dynamic).ensureTooltipVisible(); // Before using "as dynamic" in your code, see note at the top of the file.
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final RenderBox tip = tester.renderObject(find.text(tooltipText)).parent.parent.parent.parent;

    expect(tip.size.height, equals(32.0));
    expect(tip.size.width, equals(74.0));
    expect(tip, paints..path(
      color: const Color(0x80800000),
    ));
  }, skip: isBrowser);

  testWidgets('Tooltip stays after long press', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Tooltip(
            message: tooltipText,
            child: Container(
              width: 100.0,
              height: 100.0,
              color: Colors.green[500],
            ),
          ),
        ),
      )
    );

    final Finder tooltip = find.byType(Tooltip);
    TestGesture gesture = await tester.startGesture(tester.getCenter(tooltip));

    // long press reveals tooltip
    await tester.pump(kLongPressTimeout);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsOneWidget);
    await gesture.up();

    // tap (down, up) gesture hides tooltip, since its not
    // a long press
    await tester.tap(tooltip);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsNothing);

    // long press once more
    gesture = await tester.startGesture(tester.getCenter(tooltip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(tooltipText), findsNothing);

    await tester.pump(kLongPressTimeout);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsOneWidget);

    // keep holding the long press, should still show tooltip
    await tester.pump(kLongPressTimeout);
    expect(find.text(tooltipText), findsOneWidget);
    gesture.up();
  });

  testWidgets('Tooltip shows/hides when hovered', (WidgetTester tester) async {
    const Duration waitDuration = Duration(milliseconds: 0);
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Tooltip(
            message: tooltipText,
            waitDuration: waitDuration,
            child: Container(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      )
    );

    final Finder tooltip = find.byType(Tooltip);
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    // Wait for it to appear.
    await tester.pump(waitDuration);
    expect(find.text(tooltipText), findsOneWidget);

    // Wait a looong time to make sure that it doesn't go away if the mouse is
    // still over the widget.
    await tester.pump(const Duration(days: 1));
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsOneWidget);

    await gesture.moveTo(Offset.zero);
    await tester.pump();

    // Wait for it to disappear.
    await tester.pumpAndSettle();
    await gesture.removePointer();
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Does tooltip contribute semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 780.0,
                      top: 300.0,
                      child: Tooltip(
                        key: key,
                        message: tooltipText,
                        child: Container(width: 10.0, height: 10.0),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );

    final TestSemantics expected = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          label: 'TIP',
          textDirection: TextDirection.ltr,
        ),
      ]
    );

    expect(semantics, hasSemantics(expected, ignoreTransform: true, ignoreRect: true));

    // Before using "as dynamic" in your code, see note at the top of the file.
    (key.currentState as dynamic).ensureTooltipVisible(); // this triggers a rebuild of the semantics because the tree changes

    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    expect(semantics, hasSemantics(expected, ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('Tooltip overlay does not update', (WidgetTester tester) async {
    Widget buildApp(String text) {
      return MaterialApp(
        home: Center(
          child: Tooltip(
            message: text,
            child: Container(
              width: 100.0,
              height: 100.0,
              color: Colors.green[500],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(tooltipText));
    await tester.longPress(find.byType(Tooltip));
    expect(find.text(tooltipText), findsOneWidget);
    await tester.pumpWidget(buildApp('NEW'));
    expect(find.text(tooltipText), findsOneWidget);
    await tester.tapAt(const Offset(5.0, 5.0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(tooltipText), findsNothing);
    await tester.longPress(find.byType(Tooltip));
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Tooltip text scales with textScaleFactor', (WidgetTester tester) async {
    Widget buildApp(String text, { double textScaleFactor }) {
      return MediaQuery(
        data: MediaQueryData(textScaleFactor: textScaleFactor),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                builder: (BuildContext context) {
                  return Center(
                    child: Tooltip(
                      message: text,
                      child: Container(
                        width: 100.0,
                        height: 100.0,
                        color: Colors.green[500],
                      ),
                    ),
                  );
                }
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(tooltipText, textScaleFactor: 1.0));
    await tester.longPress(find.byType(Tooltip));
    expect(find.text(tooltipText), findsOneWidget);
    expect(tester.getSize(find.text(tooltipText)), equals(const Size(42.0, 14.0)));
    RenderBox tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(32.0));

    await tester.pumpWidget(buildApp(tooltipText, textScaleFactor: 4.0));
    await tester.longPress(find.byType(Tooltip));
    expect(find.text(tooltipText), findsOneWidget);
    expect(tester.getSize(find.text(tooltipText)), equals(const Size(168.0, 56.0)));
    tip = tester.renderObject(find.text(tooltipText)).parent;
    expect(tip.size.height, equals(56.0));
  }, skip: isBrowser);

  testWidgets('Haptic feedback', (WidgetTester tester) async {
    final FeedbackTester feedback = FeedbackTester();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Tooltip(
            message: 'Foo',
            child: Container(
              width: 100.0,
              height: 100.0,
              color: Colors.green[500],
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(Tooltip));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(feedback.hapticCount, 1);

    feedback.dispose();
  });

  testWidgets('Semantics included', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Tooltip(
            message: 'Foo',
            child: Text('Bar'),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
              children: <TestSemantics>[
                TestSemantics(
                  label: 'Foo\nBar',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
      ],
    ), ignoreRect: true, ignoreId: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('Semantics excluded', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Tooltip(
            message: 'Foo',
            child: Text('Bar'),
            excludeFromSemantics: true,
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
              children: <TestSemantics>[
                TestSemantics(
                  label: 'Bar',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
      ],
    ), ignoreRect: true, ignoreId: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('has semantic events', (WidgetTester tester) async {
    final List<dynamic> semanticEvents = <dynamic>[];
    SystemChannels.accessibility.setMockMessageHandler((dynamic message) async {
      semanticEvents.add(message);
    });
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Tooltip(
            message: 'Foo',
            child: Container(
              width: 100.0,
              height: 100.0,
              color: Colors.green[500],
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(Tooltip));
    final RenderObject object = tester.firstRenderObject(find.byType(Tooltip));

    expect(semanticEvents, unorderedEquals(<dynamic>[
      <String, dynamic>{
        'type': 'longPress',
        'nodeId': findDebugSemantics(object).id,
        'data': <String, dynamic>{},
      },
      <String, dynamic>{
        'type': 'tooltip',
        'data': <String, dynamic>{
          'message': 'Foo',
        },
      },
    ]));
    semantics.dispose();
    SystemChannels.accessibility.setMockMessageHandler(null);
  });
  testWidgets('default Tooltip debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    const Tooltip(message: 'message',).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      '"message"',
    ]);
  });
  testWidgets('Tooltip implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    // Not checking controller, inputFormatters, focusNode
    const Tooltip(
      key: ValueKey<String>('foo'),
      message: 'message',
      decoration: BoxDecoration(),
      waitDuration: Duration(seconds: 1),
      showDuration: Duration(seconds: 2),
      padding: EdgeInsets.zero,
      height: 100.0,
      excludeFromSemantics: true,
      preferBelow: false,
      verticalOffset: 50.0,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      '"message"',
      'height: 100.0',
      'padding: EdgeInsets.zero',
      'vertical offset: 50.0',
      'position: above',
      'semantics: excluded',
      'wait duration: 0:00:01.000000',
      'show duration: 0:00:02.000000',
    ]);
  });
}

SemanticsNode findDebugSemantics(RenderObject object) {
  if (object.debugSemantics != null)
    return object.debugSemantics;
  return findDebugSemantics(object.parent);
}
