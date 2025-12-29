import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool    _loading = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    final email = _email.text.trim();
    debugPrint('🔑 Attempting sign-in for: $email');
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _pass.text,
      );
      // on success, user is redirected by AuthGate
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign-in failed [${e.code}]: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.code}: ${e.message ?? 'Login failed'}')),
      );
    } catch (e) {
      debugPrint('❌ Unexpected sign-in error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    debugPrint('🔑 Attempting Google sign-in');
    setState(() => _loading = true);
    try {
      if (kIsWeb) {
        // WEB: Use direct Firebase Auth popup - most reliable for web
        // This avoids "Null check operator" errors from google_sign_in plugin
        // when index.html meta tags are missing
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
        // Success is handled by AuthGate stream
        debugPrint('✅ Google sign-in popup successful');
      } else {
        // MOBILE: Use google_sign_in plugin
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          // User cancelled
          debugPrint('❌ Google sign-in cancelled by user');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign-in cancelled')));
          setState(() => _loading = false);
          return;
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        await FirebaseAuth.instance.signInWithCredential(credential);
        debugPrint('✅ Google sign-in successful');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Google sign-in failed [${e.code}]: ${e.message}');
      String errorMessage = 'Google Sign-In failed';
      if (e.code == 'account-exists-with-different-credential') {
        errorMessage = 'An account already exists with this email. Please sign in with email/password.';
      } else if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
        errorMessage = 'Sign-in cancelled';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('❌ Unexpected Google sign-in error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e.toString()}')),
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    debugPrint('🔄 Resetting password for: $email');
    setState(() => _loading = true);

    if (email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      setState(() => _loading = false);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://love2learnsign.com',
          handleCodeInApp: true,
        ),
      );
      debugPrint('✅ Password reset email sent to $email');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Reset failed [${e.code}]: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.code}: ${e.message ?? 'Reset failed'}')),
      );
    } catch (e) {
      debugPrint('❌ Unexpected reset error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Love to Learn Sign Dashboard')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _pass,
                obscureText: _obscurePassword,
                onSubmitted: (_) {
                  if (!_loading) _submit();
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _resetPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loading ? null : _signInWithGoogle,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                icon: Image.network(
                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  height: 20,
                  width: 20,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.login, size: 20);
                  },
                ),
                label: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}