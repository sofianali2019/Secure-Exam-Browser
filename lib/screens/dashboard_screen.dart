import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final authState = provider.authState;
    final userInfo = provider.authService.userInfo;
    final isAdmin = userInfo?.isSiteAdmin ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151B60),
        title: const Text(
          'Secure Exam Browser',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign out',
            onPressed: () async {
              await provider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userInfo != null
                  ? 'Welcome, ${userInfo.fullName}'
                  : 'Welcome',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              authState.isAuthenticated
                  ? 'Signed in to ${provider.moodleBaseUrl}'
                  : 'Not signed in',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            if (isAdmin)
              _buildCard(
                icon: Icons.admin_panel_settings,
                title: 'Administrator',
                subtitle: 'You have full access to site settings and exam management',
                onTap: () => Navigator.pushNamed(context, '/admin-panel'),
              ),
            if (isAdmin) const SizedBox(height: 16),
            _buildCard(
              icon: Icons.school,
              title: 'My Exams',
              subtitle: 'View and attempt your available exams',
              onTap: () => Navigator.pushNamed(context, '/exam-list'),
            ),
            const SizedBox(height: 16),
            _buildCard(
              icon: Icons.qr_code_scanner,
              title: 'Scan QR Code',
              subtitle: 'Configure an exam by scanning a QR code',
              onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
            ),
            const SizedBox(height: 16),
            _buildCard(
              icon: Icons.key,
              title: 'Enter Config Key',
              subtitle: 'Configure an exam using a configuration key',
              onTap: () => Navigator.pushNamed(context, '/config-key'),
            ),
            if (userInfo != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _accountRow(Icons.person, 'Username', userInfo.username),
                    const SizedBox(height: 8),
                    _accountRow(
                      Icons.badge,
                      'Role',
                      isAdmin ? 'Administrator' : 'Student',
                    ),
                    const SizedBox(height: 8),
                    _accountRow(Icons.link, 'LMS', provider.moodleBaseUrl),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _accountRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
