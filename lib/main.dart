import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/donor_dashboard.dart';
import 'screens/ngo_dashboard.dart';
import 'screens/add_food.dart';
import 'screens/donations_list.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/ngo_requests.dart';
import 'screens/available_food.dart';
import 'screens/my_requests.dart';
import 'screens/pickup_status.dart';
import 'screens/analytics.dart';
import 'screens/submit_rating.dart';
import 'screens/ngo_profile.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

class AuthState extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userRole;
  bool _isLoading = true;
  String? _initError;

  bool get isLoggedIn => _isLoggedIn;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get initError => _initError;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _initError = null;
    notifyListeners();

    if (AuthService.currentUser != null) {
      final result = await AuthService.syncSessionFromFirebase();
      if (result.success) {
        _isLoggedIn = true;
        _userRole = await StorageService.getUserRole();
      } else {
        _isLoggedIn = false;
        _userRole = null;
        _initError = result.errorMessage;
      }
    } else {
      final loggedIn = await StorageService.isLoggedIn();
      final role = await StorageService.getUserRole();
      _isLoggedIn = loggedIn;
      _userRole = role;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> onLoginSuccess() async {
    _isLoggedIn = true;
    _userRole = await StorageService.getUserRole();
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.signOut();
    _isLoggedIn = false;
    _userRole = null;
    notifyListeners();
  }
}

final authState = AuthState();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!DefaultFirebaseOptions.isConfigured) {
    runApp(const FirebaseSetupApp());
    return;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

/// Shown when Firebase API keys are still placeholders.
class FirebaseSetupApp extends StatelessWidget {
  const FirebaseSetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Setup Required')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add your Firebase app keys',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Android is configured. For Chrome/Web:\n\n'
                '1. Firebase Console → Project settings → Add app → Web\n'
                '2. Copy Web apiKey and appId into lib/firebase_options.dart\n'
                '   (_webApiKey and _webAppId)\n\n'
                'Or run on Android instead:\n'
                '   flutter run -d android\n\n'
                'Also enable:\n'
                '• Authentication → Email/Password\n'
                '• Firestore Database → Create database',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Waste Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/donor_dashboard': (context) => const DonorDashboard(),
        '/ngo_dashboard': (context) => const NgoDashboard(),
        '/add_food': (context) => AddFood(),
        '/donations_list': (context) => DonationsList(),
        '/ngo_requests': (context) => const NgoRequestsScreen(),
        '/available_food': (context) => const AvailableFoodScreen(),
        '/my_requests': (context) => const MyRequestsScreen(),
        '/pickup_status': (context) => const PickupStatusScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/submit_rating': (context) => const SubmitRatingScreen(),
        '/ngo_profile': (context) => const NgoProfile(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    authState.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authState,
      builder: (context, child) {
        if (authState.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authState.isLoggedIn) {
          return const LoginScreen();
        }

        if (authState.userRole == 'Donor') {
          return const DonorDashboard();
        } else if (authState.userRole == 'NGO') {
          return const NgoDashboard();
        }

        return const LoginScreen();
      },
    );
  }
}
