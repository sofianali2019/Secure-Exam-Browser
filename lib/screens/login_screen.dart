import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isUrlValid = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _urlController.text = provider.moodleBaseUrl;
    _isUrlValid = _isValidUrl(provider.moodleBaseUrl);
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final valid = _isValidUrl(_urlController.text.trim());
    if (valid != _isUrlValid) {
      setState(() => _isUrlValid = valid);
    }
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme && uri.hasAuthority && uri.scheme == 'https';
  }

  Future<void> _handleLogin(AppProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    await provider.setLmsUrl(_urlController.text.trim());
    if (!mounted) return;
    await provider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (provider.authState.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final authState = provider.authState;
    final isLoading = provider.isLoginInProgress;
    final error = provider.errorMessage ?? authState.error;

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Secure Exam Browser',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your LMS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LMS URL',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            hintText: 'https://your-moodle-instance.com',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(
                              Icons.link,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          style: const TextStyle(color: Color(0xFF1A237E)),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your LMS URL';
                            }
                            if (!_isValidUrl(value.trim())) {
                              return 'Must be a valid HTTPS URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                provider.setLmsUrl(_urlController.text.trim());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('LMS URL saved'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Save URL'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.greenAccent.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'LMS: ${provider.moodleBaseUrl}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Username',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    autocorrect: false,
                    style: const TextStyle(color: Color(0xFF1A237E)),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Color(0xFF1A237E),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF1A237E),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    style: const TextStyle(color: Color(0xFF1A237E)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (isLoading || authState.isAuthenticated)
                          ? null
                          : () => _handleLogin(provider),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1A237E),
                              ),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        isLoading
                            ? 'Signing in...'
                            : authState.isAuthenticated
                                ? 'Signed In'
                                : 'Sign In',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A237E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
