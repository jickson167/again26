import 'package:flutter/material.dart';

/// 웹사카 스타일 사용자 설정 (로그아웃 · 탈퇴).
class GameUserSettingsPage extends StatelessWidget {
  const GameUserSettingsPage({
    super.key,
    required this.userLabel,
    required this.onBack,
    required this.onLogout,
    required this.onWithdraw,
    this.processing = false,
  });

  final String userLabel;
  final VoidCallback onBack;
  final Future<void> Function() onLogout;
  final Future<void> Function() onWithdraw;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4D7C0F), Color(0xFF166534)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: processing ? null : onBack,
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            '사용자 설정',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEF4),
                          border: Border.all(color: Colors.black45, width: 2),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (userLabel.isNotEmpty) ...[
                                Text(
                                  userLabel,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              _SettingsSection(
                                title: '로그인',
                                child: _SettingsActionButton(
                                  label: '로그아웃',
                                  subtitle: '다른 Google·네이버 계정으로 다시 로그인할 수 있습니다.',
                                  icon: Icons.logout,
                                  enabled: !processing,
                                  onTap: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('로그아웃'),
                                        content: const Text(
                                          '로그아웃하면 로그인 화면으로 돌아갑니다.\n'
                                          '네이버 등 다른 계정으로 로그인할 수 있습니다.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('취소'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('로그아웃'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true && context.mounted) {
                                      await onLogout();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              _SettingsSection(
                                title: '탈퇴 절차',
                                child: _SettingsActionButton(
                                  label: '탈퇴하기',
                                  subtitle: '구단 데이터를 삭제하고 로그아웃합니다.',
                                  icon: Icons.person_off_outlined,
                                  enabled: !processing,
                                  destructive: true,
                                  onTap: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('탈퇴'),
                                        content: const Text(
                                          '구단·편성 데이터가 삭제되고 로그아웃됩니다.\n'
                                          '이 작업은 되돌릴 수 없습니다. 계속할까요?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('취소'),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.red.shade800,
                                            ),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('탈퇴'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true && context.mounted) {
                                      await onWithdraw();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF334155),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          color: const Color(0xFFD1D5DB),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    );
  }
}

class _SettingsActionButton extends StatelessWidget {
  const _SettingsActionButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black26),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 36,
                color: destructive ? Colors.red.shade800 : const Color(0xFF2563EB),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: destructive ? Colors.red.shade900 : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
