// app/lib/presentation/providers/language_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mặc định là tiếng Việt ('vi')
final languageProvider = StateProvider<String>((ref) => 'vi');