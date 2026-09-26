import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final success = await auth.sendPasswordReset(_emailController.text.trim());
    if (!mounted) return;
    if (success) {
      setState(() => _sent = true);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _sent
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mark_email_read_outlined,
                            size: 56, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'If an account exists for ${_emailController.text.trim()}, '
                          'a password reset link has been sent.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Back to login',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Enter your account email and we will send you a link to '
                            'reset your password.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          AppTextField(
                            label: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            textInputAction: TextInputAction.done,
                            validator: Validators.email,
                            onFieldSubmitted: (_) => _submit(auth),
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Send reset link',
                            isLoading: auth.isSubmitting,
                            onPressed: () => _submit(auth),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
