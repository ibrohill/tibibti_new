import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'settings_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/clent/home_client_screen.dart';
import 'screens/pharmacien/home_pharmacien_screen.dart';
import 'screens/admin/admin_dashboard.dart';

import 'package:tibibti/screens/clent/settings_screen.dart' as client_settings;
import 'package:tibibti/screens/admin/liste_produits_admin_screen.dart';
import 'package:tibibti/screens/clent/pharmacies_list_screen.dart';
import 'package:tibibti/screens/clent/pharmacie_detail_screen.dart';
import 'package:tibibti/screens/clent/profile_client_screen.dart';
import 'package:tibibti/screens/clent/chat_screen.dart';
import 'package:tibibti/screens/pharmacien/liste_produits_pharmacie.dart';
import 'package:tibibti/screens/pharmacien/add_product_screen.dart';
import 'package:tibibti/screens/pharmacien/pharmacien_profile_screen.dart';
import 'package:tibibti/screens/pharmacien/parametres_pharmacien_screen.dart';
import 'package:tibibti/screens/pharmacien/modifier_produit_pharmacie.dart';
import 'package:tibibti/screens/pharmacien/pharmacien_prescriptions_screen.dart';
import 'package:tibibti/screens/pharmacien/ordonnances_pharmacien_screen.dart';
import 'package:tibibti/screens/clent/upload_ordonnance_screen.dart';
import 'package:tibibti/pages/placeholder_screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tibibti/screens/clent/prescription_uploader.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Notification reçue en arrière-plan : ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initSettings =
  InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      debugPrint('Notification tap: ${response.payload}');
    },
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const TibibtiApp(),
    ),
  );
}

Locale _localeFromLanguageCode(String language) {
  switch (language) {
    case 'Français':
      return const Locale('fr');
    case 'English':
      return const Locale('en');
    case 'العربية':
      return const Locale('ar');
    default:
      return const Locale('fr');
  }
}

class TibibtiApp extends StatelessWidget {
  const TibibtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Tibibti',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: settings.isDark ? ThemeMode.dark : ThemeMode.light,
      locale: _localeFromLanguageCode(settings.language),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Utilisation de la gate d'auth pour garder connexion
      home: const AuthGate(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home_client': (context) => const HomeClientScreen(),
        '/home_pharmacien': (context) => const HomePharmacienScreen(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/liste_produits_pharmacie': (context) =>
        const ListeProduitsPharmacieScreen(),
        '/ajout_produit_pharmacie': (context) => const AddProductScreen(),
        '/profil_pharmacien': (context) => const PharmacienProfileScreen(),
        '/parametres_pharmacien': (context) =>
        const ParametresPharmacienScreen(),
        '/pharmacies_list': (context) => const PharmaciesListScreen(),
        '/pharmacie_detail': (context) => const PharmacieDetailsScreen(),
        '/admin_users': (context) => const AdminDashboard(),
        '/admin_pharmacies': (context) => const PharmaciesListScreen(),
        '/admin_products': (context) => const ListeProduitsAdminScreen(),
        '/chat': (context) => const ChatScreen(recipientId: '', recipientName: ''),
        '/modifier_produit_pharmacie': (context) {
          final product =
          ModalRoute.of(context)!.settings.arguments as DocumentSnapshot;
          return ModifierProduitPharmacieScreen(product: product);
        },
        '/profil': (context) => const ProfileClientScreen(),
        '/orders': (_) => const OrdersScreen(),
        '/support': (_) => const SupportScreen(),
        '/about': (_) => const AboutScreen(),
        '/invite': (_) => const InviteFriendScreen(),
        '/notifications': (_) => const NotificationScreen(),
        '/settings': (context) => const client_settings.SettingsScreen(),
        '/pharmacien/ordonnances': (context) {
          final pharmacieId =
          ModalRoute.of(context)!.settings.arguments as String;
          return PharmacienPrescriptionsScreen(pharmacieId: pharmacieId);
        },
        '/envoyer_ordonnance': (context) {
          final pharmacyId =
          ModalRoute.of(context)!.settings.arguments as String;
          return PrescriptionUploader(pharmacyId: pharmacyId);
        },
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // en attente d'initialisation
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // TODO: Si tu as des rôles (pharmacien vs client), tu peux les récupérer ici
        // et rediriger conditionnellement.
        return const HomeClientScreen();
      },
    );
  }
}
