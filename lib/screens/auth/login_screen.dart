import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _adminFormKey = GlobalKey<FormState>();
  final _adminPasswordCtrl = TextEditingController();

  final _staffFormKey = GlobalKey<FormState>();
  final _staffUsernameCtrl = TextEditingController();
  final _staffPasswordCtrl = TextEditingController();

  bool _adminObscure = true;
  bool _staffObscure = true;

  @override
  void dispose() {
    _adminPasswordCtrl.dispose();
    _staffUsernameCtrl.dispose();
    _staffPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async {
    if (!_adminFormKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(
      'admin',
      _adminPasswordCtrl.text,
    );
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _loginStaff() async {
    if (!_staffFormKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(
      _staffUsernameCtrl.text.trim(),
      _staffPasswordCtrl.text,
    );
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left panel - branding
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.accent.withValues(alpha: 0.12)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Background circles
                  Positioned(
                    top: -100, left: -100,
                    child: Container(
                      width: 400, height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80, right: -80,
                    child: Container(
                      width: 300, height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppColors.accent.withValues(alpha: 0.15),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.print_rounded, size: 40, color: Colors.white),
                          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                          const SizedBox(height: 32),
                          Text(
                            'PrintPOS Pro',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 40, fontWeight: FontWeight.w800,
                              foreground: Paint()..shader = const LinearGradient(
                                colors: [AppColors.primaryLight, AppColors.accent],
                              ).createShader(const Rect.fromLTWH(0, 0, 300, 60)),
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                          const SizedBox(height: 12),
                          Text(
                            'Professional Point of Sale\nfor Printing & Photostat Shops',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                          const SizedBox(height: 48),
                          _FeatureTile(icon: Icons.point_of_sale, label: 'Fast POS Billing'),
                          _FeatureTile(icon: Icons.inventory_2, label: 'Inventory Management'),
                          _FeatureTile(icon: Icons.bar_chart, label: 'Monthly Reports & PDF'),
                          _FeatureTile(icon: Icons.manage_accounts, label: 'User Role Management'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right panel - login form with tabs
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.surface,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome Back',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.2),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue to PrintPOS Pro',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 32),
                          
                          // Tab Bar
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              indicator: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: Colors.white,
                              unselectedLabelColor: AppColors.textSecondary,
                              dividerColor: Colors.transparent,
                              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              tabs: const [
                                Tab(text: 'Admin'),
                                Tab(text: 'Staff'),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                          
                          if (auth.error != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accentRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.accentRed, size: 18),
                                  const SizedBox(width: 8),
                                  Text(auth.error!, style: const TextStyle(color: AppColors.accentRed)),
                                ],
                              ),
                            ).animate().shake(),
                          ],

                          const SizedBox(height: 24),
                          
                          // Tab Views
                          SizedBox(
                            height: 280, // Fixed height to prevent jumping
                            child: TabBarView(
                              children: [
                                // Admin Tab
                                Form(
                                  key: _adminFormKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.admin_panel_settings, color: AppColors.primaryLight, size: 20),
                                            const SizedBox(width: 12),
                                            const Text('Username:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                            const SizedBox(width: 8),
                                            const Text('admin', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                                          ],
                                        ),
                                      ).animate().fadeIn(delay: 400.ms),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        controller: _adminPasswordCtrl,
                                        obscureText: _adminObscure,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            icon: Icon(_adminObscure ? Icons.visibility_off : Icons.visibility),
                                            onPressed: () => setState(() => _adminObscure = !_adminObscure),
                                          ),
                                        ),
                                        validator: (v) => v!.isEmpty ? 'Enter password' : null,
                                        onFieldSubmitted: (_) => _loginAdmin(),
                                      ).animate().fadeIn(delay: 500.ms),
                                      const SizedBox(height: 32),
                                      SizedBox(
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: auth.isLoading ? null : _loginAdmin,
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              gradient: AppColors.primaryGradient,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: auth.isLoading
                                                  ? const SizedBox(
                                                      width: 22, height: 22,
                                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                                    )
                                                  : const Text('Admin Login', style: TextStyle(
                                                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                                                    )),
                                            ),
                                          ),
                                        ),
                                      ).animate().fadeIn(delay: 600.ms),
                                    ],
                                  ),
                                ),
                                // Staff Tab
                                Form(
                                  key: _staffFormKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        controller: _staffUsernameCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Username',
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                        validator: (v) => v!.isEmpty ? 'Enter username' : null,
                                        onFieldSubmitted: (_) => _loginStaff(),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _staffPasswordCtrl,
                                        obscureText: _staffObscure,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            icon: Icon(_staffObscure ? Icons.visibility_off : Icons.visibility),
                                            onPressed: () => setState(() => _staffObscure = !_staffObscure),
                                          ),
                                        ),
                                        validator: (v) => v!.isEmpty ? 'Enter password' : null,
                                        onFieldSubmitted: (_) => _loginStaff(),
                                      ),
                                      const SizedBox(height: 32),
                                      SizedBox(
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: auth.isLoading ? null : _loginStaff,
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              color: AppColors.accent,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: auth.isLoading
                                                  ? const SizedBox(
                                                      width: 22, height: 22,
                                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                                    )
                                                  : const Text('Staff Login', style: TextStyle(
                                                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                                                    )),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1);
  }
}
