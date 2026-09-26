import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../employee/presentation/screens/employee_list_screen.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const EmployeeListScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
