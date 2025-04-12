// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'screens/main_app_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyCampusPTEApp());
}

class MyCampusPTEApp extends StatelessWidget {
  const MyCampusPTEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyCampusPTE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade800),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyCampusPTE')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome! Choose an option:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Login'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _neptunOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _status;
  bool _isLoading = false;

  Future<void> _login() async {
    final input = _neptunOrEmailController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.length < 6) {
      setState(() => _status = '❌ Enter valid email/Neptun and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = null;
    });

    try {
      String email = input;
      if (!input.contains('@')) {
        final query = await FirebaseFirestore.instance.collection('users').where('neptun', isEqualTo: input.toUpperCase()).get();
        if (query.docs.isEmpty) throw Exception('❌ Neptun code not found');
        email = query.docs.first['email'];
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainAppScreen()));
    } catch (e) {
      setState(() => _status = '❌ ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);

      // Save or update user in Firestore
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid);
      await userDoc.set({
        'email': userCred.user!.email,
        'uid': userCred.user!.uid,
        'signedInWith': 'google',
      }, SetOptions(merge: true));

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainAppScreen()));
    } catch (e) {
      setState(() => _status = '❌ Google Sign-In failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _neptunOrEmailController,
              decoration: const InputDecoration(labelText: 'Email or Neptun Code', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(onPressed: _login, child: const Text('Login')),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                      ),
                    ],
                  ),
            const SizedBox(height: 16),
            if (_status != null)
              Text(_status!, style: TextStyle(color: _status!.startsWith('✅') ? Colors.green : Colors.red)),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _neptunController = TextEditingController();
  bool _isLoading = false;
  String? _status;

  Future<void> _registerUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final neptun = _neptunController.text.trim().toUpperCase();

    if (email.isEmpty || password.length < 6 || neptun.length != 6) {
      setState(() {
        _status = '❌ Enter valid email, 6+ char password, and 6-char Neptun code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      final userCred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await firestore.collection('users').doc(userCred.user!.uid).set({
        'email': email,
        'neptun': neptun,
        'createdAt': Timestamp.now(),
        'uid': userCred.user!.uid,
      });

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainAppScreen()));
    } catch (e) {
      setState(() => _status = '❌ ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _neptunController,
              decoration: const InputDecoration(labelText: 'Neptun Code (6 characters)', border: OutlineInputBorder()),
              maxLength: 6,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _registerUser, child: const Text('Register')),
            if (_status != null) ...[
              const SizedBox(height: 20),
              Text(_status!, style: TextStyle(color: _status!.startsWith('✅') ? Colors.green : Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}
