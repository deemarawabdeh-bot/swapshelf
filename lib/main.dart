import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/app_shell.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/item_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SwapShelfApp());
}

class SwapShelfApp extends StatelessWidget {
  const SwapShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final storage = FirebaseStorage.instance;

    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(auth, firestore),
        ),
        Provider<ItemService>(
          create: (_) => ItemService(firestore),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(storage),
        ),
        Provider<ChatService>(
          create: (_) => ChatService(firestore),
        ),
      ],
      child: MaterialApp(
        title: 'SwapShelf',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    return StreamBuilder(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const AppShell();
        }
        return const AuthScreen();
      },
    );
  }
}
