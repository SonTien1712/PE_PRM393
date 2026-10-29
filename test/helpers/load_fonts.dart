import 'package:flutter/services.dart';

Future<void> loadAppFonts() async {
  final vietnamese = FontLoader('BeVietnamPro');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    vietnamese.addFont(
      rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'),
    );
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([vietnamese.load(), icons.load()]);
}
