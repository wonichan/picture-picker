import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/image_picker_provider.dart';
import 'screens/main_screen.dart';

/// Entry point - Professional Picture Picker Application
/// Built with Linus-level quality standards!
void main() {
  runApp(const PicturePickerApp());
}

class PicturePickerApp extends StatelessWidget {
  const PicturePickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ImagePickerProvider(),
      child: MaterialApp(
        title: 'Picture Picker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          // Professional font for better readability
          fontFamily: 'Roboto',
        ),
        home: const MainScreen(),
      ),
    );
  }
}
