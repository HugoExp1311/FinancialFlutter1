import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_providers.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  void _checkSession() {
    final supabase = ref.read(supabaseProvider);
    _user = supabase.auth.currentUser;
    setState(() => _isLoading = false);

    supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _user = data.session?.user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Nếu chưa đăng nhập, hiển thị Login Screen
    if (_user == null) {
      return const LoginScreen();
    }

    // Nếu đã đăng nhập, vào thẳng App chính
    return const MainNavigationScreen();
  }
}
