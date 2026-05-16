// app/lib/presentation/providers/language_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple notifier for language state
class LanguageNotifier extends Notifier<String> {
  @override
  String build() => 'vi'; // Mặc định là tiếng Việt

  void setLanguage(String lang) {
    state = lang;
  }
  
  void toggle() {
    state = state == 'vi' ? 'en' : 'vi';
  }
}

// Provider for language
final languageProvider = NotifierProvider<LanguageNotifier, String>(
  () => LanguageNotifier(),
);