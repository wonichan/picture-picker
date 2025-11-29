// Basic widget test for Picture Picker
import 'package:flutter_test/flutter_test.dart';
import 'package:picture_picker/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const PicturePickerApp());

    // Verify that the app title is displayed
    expect(
      find.text('Picture Picker - Professional Image Classifier'),
      findsOneWidget,
    );

    // Verify the Select Folder button exists
    expect(find.text('Select Folder'), findsOneWidget);
  });
}
