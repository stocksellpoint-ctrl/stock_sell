// import 'package:flutter/material.dart';
// // import 'package:stock_sell/core/network/api_endpoints.dart';
// import 'app.dart';


// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // debugPrint('>>> API baseUrl: ${ApiEndpoints.baseUrl}');
//   runApp(const InventoryApp());
// }



import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import 'package:stock_sell/core/network/api_endpoints.dart';
import 'app.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPrint('>>> API baseUrl: ${ApiEndpoints.baseUrl}');

  // Load persisted settings (theme, seed color, locale) before runApp
  // so the first frame is already themed correctly (no flash).
  final settings = SettingsProvider();
  await settings.load();

  runApp(
    // Provide SettingsProvider ABOVE InventoryApp so MaterialApp can
    // watch it and rebuild when the user changes theme/locale.
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      child: const InventoryApp(),
    ),
  );
}