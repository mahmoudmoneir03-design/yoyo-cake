import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/customers.dart';
import 'screens/home.dart';
import 'screens/ingredients.dart';
import 'screens/orders.dart';
import 'screens/reports.dart';
import 'notifications.dart';
import 'photos.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  await initPhotos();
  await initNotifications();
  await resyncAllNotifications(store.orders);
  runApp(const DafterApp());
}

class DafterApp extends StatelessWidget {
  const DafterApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFB4235A), brightness: b),
          inputDecorationTheme:
              const InputDecorationTheme(border: OutlineInputBorder()),
        );
    return MaterialApp(
      title: 'Yoyo Cake',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: i,
        children: const [
          HomePage(),
          OrdersPage(),
          CustomersPage(),
          IngredientsPage(),
          ReportsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'الطلبات'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'العملاء'),
          NavigationDestination(
              icon: Icon(Icons.egg_outlined),
              selectedIcon: Icon(Icons.egg),
              label: 'المكونات'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'التقارير'),
        ],
      ),
    );
  }
}
