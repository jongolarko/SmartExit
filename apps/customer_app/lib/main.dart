import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

// Shared packages
import 'package:smartexit_services/smartexit_services.dart';
import 'package:smartexit_shared/smartexit_shared.dart';

// Customer app screens
import 'screens/customer/customer_login_screen.dart';
import 'screens/customer/product_scan_screen.dart';
import 'screens/customer/cart_screen.dart';
import 'screens/customer/order_history_screen.dart';

// Customer providers
import 'providers/cart_provider.dart';

// Customer theme
import 'config/customer_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize customer app configuration
  ConfigService.initialize(CustomerAppConfig(
    baseUrl: 'http://localhost:5000/api',
    socketUrl: 'http://localhost:5000',
  ));

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const ProviderScope(child: SmartExitCustomerApp()));
}

class SmartExitCustomerApp extends ConsumerWidget {
  const SmartExitCustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SmartExit',
      debugShowCheckedModeBanner: false,
      theme: CustomerTheme.light,
      themeMode: ThemeMode.light,
      home: const AuthWrapper(),
    );
  }
}

/// Auth wrapper - shows login or home based on auth state
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: CustomerTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: CustomerTheme.primaryBlue),
        ),
      );
    }

    // If authenticated and role is customer, show home screen
    if (authState.isAuthenticated && authState.userRole == 'customer') {
      return const CustomerHomeScreen();
    }

    // Otherwise show login
    return const CustomerLoginScreen();
  }
}

/// Customer home screen with quick actions
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
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      appBar: AppBar(
        backgroundColor: CustomerTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CustomerTheme.textSecondary,
              ),
            ),
            Text(
              authState.userName ?? 'Customer',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CustomerTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Cart badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                  color: CustomerTheme.primaryBlue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cartState.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: CustomerTheme.accentGreen,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${cartState.itemCount}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: CustomerTheme.primaryBlue),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start Shopping',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: CustomerTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan products, checkout, and exit with ease',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CustomerTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Quick action cards
            _buildActionCard(
              context,
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan Products',
              description: 'Add items to your cart',
              color: CustomerTheme.primaryBlue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductScanScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              icon: Icons.shopping_cart_outlined,
              title: 'View Cart',
              description: 'Review and checkout (${cartState.itemCount} items)',
              color: CustomerTheme.accentGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'Order History',
              description: 'View past orders and receipts',
              color: CustomerTheme.coolPurple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CustomerTheme.surface,
          borderRadius: BorderRadius.circular(CustomerTheme.radiusCard),
          boxShadow: CustomerTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CustomerTheme.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: CustomerTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
