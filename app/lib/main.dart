import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/core.dart';
import 'providers/providers.dart';
import 'screens/security/security_home_screen.dart';
import 'screens/customer/customer_login_screen.dart';
import 'screens/customer/product_scan_screen.dart';
import 'screens/customer/cart_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: SmartExitApp()));
}

class SmartExitApp extends ConsumerWidget {
  const SmartExitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SmartExit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper that checks auth state and shows appropriate screen
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.pure,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.voidBlack),
        ),
      );
    }

    if (authState.isAuthenticated) {
      // Navigate based on role
      switch (authState.userRole) {
        case 'security':
          return const SecurityHomeScreen();
        case 'admin':
          return const AdminDashboardScreen();
        default:
          // Customer goes to scan screen
          return const CustomerHomeScreen();
      }
    }

    return const RoleSelectionScreen();
  }
}

/// Customer home screen after login
class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch cart on init
    Future.microtask(() => ref.read(cartProvider.notifier).fetchCart());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.pure,
      appBar: AppBar(
        backgroundColor: AppColors.pure,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              await ref.read(authProvider.notifier).logout();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cloud,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.voidBlack,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Welcome, ${authState.userName ?? "Customer"}',
          style: AppTypography.headlineSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.voidBlack),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.screenAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start Shopping',
              style: AppTypography.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Scan products to add them to your cart',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.steel),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Quick action cards
            _buildActionCard(
              icon: Icons.qr_code_scanner,
              title: 'Scan Products',
              description: 'Add items to your cart',
              color: AppColors.customer,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductScanScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildActionCard(
              icon: Icons.shopping_cart_outlined,
              title: 'View Cart',
              description: 'Review and checkout',
              color: AppColors.voidBlack,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.pure,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mist),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.steel),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.steel, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Premium Role Selection Screen
/// Full-screen, no app bar, with animated role cards
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _taglineController;
  late AnimationController _cardsController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Tagline animation
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    // Cards animation
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start animations in sequence
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _taglineController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _cardsController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _taglineController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  void _navigateToRole(String role) {
    HapticFeedback.mediumImpact();

    Widget screen;
    switch (role) {
      case 'Customer':
        screen = const CustomerLoginScreen();
        break;
      case 'Security':
        screen = const SecurityLoginScreen();
        break;
      case 'Admin':
        screen = const AdminLoginScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pure,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenAll,
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo and Branding
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Column(
                        children: [
                          // Logo
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.voidBlack,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppShadows.lg,
                            ),
                            padding: const EdgeInsets.all(20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/logo/smartexit_logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Brand Name
                          Text(
                            'SmartExit',
                            style: GoogleFonts.dmSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppColors.voidBlack,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Tagline
              AnimatedBuilder(
                animation: _taglineController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _taglineOpacity.value,
                    child: Transform.translate(
                      offset: _taglineSlide.value,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Scan. Pay. Exit.',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.steel,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 2),

              // Role Selection Cards
              AnimatedBuilder(
                animation: _cardsController,
                builder: (context, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section title
                      Opacity(
                        opacity: _cardsController.value,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            bottom: AppSpacing.md,
                          ),
                          child: Text(
                            'Continue as',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.steel,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      // Customer Card
                      _buildAnimatedCard(
                        index: 0,
                        child: RoleCard(
                          title: 'Customer',
                          description: 'Scan products and checkout',
                          icon: Icons.shopping_bag_outlined,
                          accentColor: AppColors.customer,
                          onTap: () => _navigateToRole('Customer'),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Security Card
                      _buildAnimatedCard(
                        index: 1,
                        child: RoleCard(
                          title: 'Security',
                          description: 'Verify exit QR codes',
                          icon: Icons.shield_outlined,
                          accentColor: AppColors.security,
                          onTap: () => _navigateToRole('Security'),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Admin Card
                      _buildAnimatedCard(
                        index: 2,
                        child: RoleCard(
                          title: 'Admin',
                          description: 'Dashboard and analytics',
                          icon: Icons.insights_outlined,
                          accentColor: AppColors.admin,
                          onTap: () => _navigateToRole('Admin'),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const Spacer(flex: 1),

              // Version text
              AnimatedBuilder(
                animation: _cardsController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _cardsController.value * 0.5,
                    child: Text(
                      'v2.0.0',
                      style: AppTypography.caption,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({
    required int index,
    required Widget child,
  }) {
    final delay = index * 0.15;
    final animation = CurvedAnimation(
      parent: _cardsController,
      curve: Interval(
        delay,
        delay + 0.6,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Security Login Screen (placeholder - uses same OTP flow)
class SecurityLoginScreen extends StatelessWidget {
  const SecurityLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerLoginScreen(roleHint: 'security');
  }
}

/// Admin Login Screen (placeholder - uses same OTP flow)
class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerLoginScreen(roleHint: 'admin');
  }
}
