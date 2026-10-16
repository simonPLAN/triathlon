import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/main.dart';

void main() {
  testWidgets('TriathlonApp smoke test', (WidgetTester tester) async {
    expect(const TriathlonApp(), isNotNull);
  });
}
