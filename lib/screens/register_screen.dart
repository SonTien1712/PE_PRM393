import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/responsive_body.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _usernameError;
  bool _obscure = true;
  bool _submitting = false;
  bool _createdWithoutSession = false;

  Future<void> _register() async {
    if (_submitting ||
        _createdWithoutSession ||
        !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    try {
      final ok = await auth.register(
        _username.text,
        _password.text,
        _name.text,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
      } else {
        final message =
            auth.errorMessage ?? 'Không thể đăng ký. Vui lòng thử lại.';
        final created = auth.registrationCreated;
        auth.clearError();
        if (message == 'Tên đăng nhập đã tồn tại') {
          setState(() => _usernameError = message);
          _form.currentState!.validate();
        } else {
          setState(() => _createdWithoutSession = created);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _username, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _submitting || context.watch<AuthProvider>().isBusy;
    final disabled = busy || _createdWithoutSession;
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: ResponsiveBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 44,
                  color: AppTheme.teal,
                ),
                const SizedBox(height: 20),
                Text(
                  'Bắt đầu sổ thu chi của bạn',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tạo tài khoản để theo dõi thu nhập và chi tiêu trên thiết bị này.',
                  style: TextStyle(color: AppTheme.muted),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _name,
                  enabled: !disabled,
                  validator: validateDisplayName,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _username,
                  enabled: !disabled,
                  validator: (value) =>
                      _usernameError ?? validateUsername(value),
                  onChanged: (_) {
                    if (_usernameError != null) {
                      setState(() => _usernameError = null);
                    }
                  },
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Tên đăng nhập',
                    helperText: '3–30 ký tự: chữ, số, dấu gạch dưới',
                    helperMaxLines: 2,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  enabled: !disabled,
                  validator: validatePassword,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    helperText: 'Ít nhất 6 ký tự, gồm chữ và số',
                    helperMaxLines: 2,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                      onPressed: disabled
                          ? null
                          : () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirm,
                  enabled: !disabled,
                  validator: (value) =>
                      validateConfirmPassword(value, _password.text),
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: const InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                if (_createdWithoutSession)
                  FilledButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
                    child: const Text('Đăng nhập ngay'),
                  )
                else
                  FilledButton(
                    onPressed: busy ? null : _register,
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Đăng ký'),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: const Text('Đã có tài khoản? Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
