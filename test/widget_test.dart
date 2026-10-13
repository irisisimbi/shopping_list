import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list/main.dart';

Future<void> addItem(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.tap(find.text('Add'));
  await tester.pump();
}

void main() {
  testWidgets('empty list, empty item refused, item added and bought',
      (tester) async {
    await tester.pumpWidget(const ShoppingListApp());
    expect(find.text('Your list is empty'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('Type an item first'), findsOneWidget);

    await addItem(tester, 'Milk');
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Your list is empty'), findsNothing);

    await tester.tap(find.text('Milk'));
    await tester.pump();
    final text = tester.widget<Text>(find.text('Milk'));
    expect(text.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('duplicate raises quantity instead of adding a row',
      (tester) async {
    await tester.pumpWidget(const ShoppingListApp());
    await addItem(tester, 'Milk');
    await addItem(tester, '  mILK ');
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
