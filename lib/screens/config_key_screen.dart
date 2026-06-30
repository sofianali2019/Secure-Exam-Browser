import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam_config.dart';
import '../providers/app_provider.dart';

class ConfigKeyScreen extends StatefulWidget {
  const ConfigKeyScreen({super.key});

  @override
  State<ConfigKeyScreen> createState() => _ConfigKeyScreenState();
}

class _ConfigKeyScreenState extends State<ConfigKeyScreen> {
  final _keyController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isProcessing = false;
  ExamConfig? _decodedConfig;
  String? _error;

  @override
  void dispose() {
    _keyController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _decodeKey() async {
    final configKey = _keyController.text.trim();
    if (configKey.isEmpty) {
      setState(() => _error = 'Please enter a configuration key');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
      _decodedConfig = null;
    });

    try {
      final provider = context.read<AppProvider>();

      // Try the platform channel decode first
      ExamConfig? config;
      try {
        config = await provider.configService.decodeConfigKey(configKey);
      } catch (_) {
        // Platform channel may fail on desktop — fall through
      }

      // Fallback: try local base64 decode (for desktop or when platform channel is unavailable)
      config ??= _localDecode(configKey);

      if (config != null && mounted) {
        setState(() {
          _decodedConfig = config;
          _isProcessing = false;
        });
      } else if (mounted) {
        // If we have a URL, try fetching remote config
        final url = _urlController.text.trim();
        if (url.isNotEmpty) {
          final remoteConfig = await provider.configService.fetchRemoteConfig(url);
          if (remoteConfig.isNotEmpty) {
            final parsed =
                await provider.configService.parseSebConfig(
              jsonEncode(remoteConfig),
            );
            if (parsed != null && mounted) {
              setState(() {
                _decodedConfig = parsed;
                _isProcessing = false;
              });
              return;
            }
          }
        }

        setState(() {
          _error = 'Failed to decode config key. Try entering a config URL instead.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isProcessing = false;
        });
      }
    }
  }

  /// Fallback local base64 decode for config keys when platform channel is
  /// unavailable (e.g. desktop builds).
  ExamConfig? _localDecode(String key) {
    try {
      // Try base64 decode (URL-safe variant first, then standard)
      String decoded;
      try {
        decoded = utf8.decode(base64Url.decode(key));
      } catch (_) {
        decoded = utf8.decode(base64.decode(key));
      }

      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) {
        return ExamConfig.fromJson(json);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _startExam() async {
    if (_decodedConfig == null) return;

    try {
      final provider = context.read<AppProvider>();
      await provider.startExam(_decodedConfig!);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/exam');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start exam: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151B60),
        title: const Text(
          'Enter Config Key',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration Key',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the exam configuration key provided by your instructor, '
              'or paste a configuration URL below.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                hintText: 'Paste config key here',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFF1A237E)),
              ),
              style: const TextStyle(color: Color(0xFF1A237E)),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 16),
            Text(
              'Or Config URL (optional)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://example.com/exam-config.json',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF1A237E)),
              ),
              style: const TextStyle(color: Color(0xFF1A237E)),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _decodeKey,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1A237E),
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(_isProcessing ? 'Decoding...' : 'Decode Config'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
            if (_decodedConfig != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Configuration Loaded',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoRow('Exam', _decodedConfig!.examTitle ?? 'Untitled'),
                    const SizedBox(height: 4),
                    _infoRow('Duration', '${_decodedConfig!.examDurationMinutes} minutes'),
                    const SizedBox(height: 4),
                    _infoRow(
                      'Proctoring',
                      _decodedConfig!.proctoringEnabled ? 'Enabled' : 'Disabled',
                    ),
                    const SizedBox(height: 4),
                    _infoRow('URL', _decodedConfig!.moodleUrl),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _startExam,
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text('Start Exam'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: const Color(0xFF1A237E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
