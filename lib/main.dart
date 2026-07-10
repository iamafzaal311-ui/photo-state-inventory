import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_model.dart';
import 'models/product_model.dart';
import 'models/sale_model.dart';
import 'services/auth_service.dart';
import 'services/inventory_service.dart';
import 'services/report_service.dart';
import 'theme/app_theme.dart';
import 'utils/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter('InventoryManData');

  // Register adapters
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(SaleItemModelAdapter());
  Hive.registerAdapter(SaleModelAdapter());

  // Open boxes
  await Hive.openBox<UserModel>('users');
  await Hive.openBox<ProductModel>('products');
  await Hive.openBox<SaleModel>('sales');

  // Seed data
  // Default admin is created here for development/testing: admin / admin123
  await AuthService.seedAdminIfNeeded();
  await InventoryService.seedDefaultProducts();

  // Auto-generate monthly report if a new month has started
  await ReportService.autoGeneratePreviousMonthReportIfNeeded();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'PrintPOS Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
