import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  final PageController _pageController = PageController();

  String? savedMpin;
  String? savedName; // ✅ Store name here
  String enteredPin = '';
  int _currentPage = 0;
  bool _obscurePassword = true;

  final passwordController = TextEditingController();
  final pinController = TextEditingController();

  // Biometric type state
  BiometricType? _preferredBiometric;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkBiometrics();
  }

  /// ✅ Load MPIN and Name from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedMpin = prefs.getString("mpin");
      savedName = prefs.getString("name") ?? "User"; // default fallback
    });
  }

  /// ✅ Detect available biometric type (Face ID / Fingerprint)
  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      if (!canCheck) return;

      final availableBiometrics = await auth.getAvailableBiometrics();

      if (availableBiometrics.contains(BiometricType.face)) {
        setState(() => _preferredBiometric = BiometricType.face);
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        setState(() => _preferredBiometric = BiometricType.fingerprint);
      }
    } catch (e) {
      debugPrint("Biometric check error: $e");
    }
  }

  /// ✅ Real biometric authentication
  Future<void> _authenticateBiometric() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason:
        'Authenticate with ${_preferredBiometric == BiometricType.face ? "Face ID" : "Fingerprint"}',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        _showSnack("✅ Authentication Successful");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => HomePage()));
      } else {
        _showSnack("❌ Authentication Failed");
      }
    } catch (e) {
      _showSnack("⚠️ Error: $e");
    }
  }

  void _login() {
    if (_currentPage == 0) {
      _authenticateBiometric();
    } else if (_currentPage == 1) {
      if (enteredPin == savedMpin) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => HomePage()));
      } else {
        _showSnack("❌ Incorrect PIN");
        setState(() => enteredPin = '');
        pinController.clear();
      }
    } else if (_currentPage == 2) {
      if (passwordController.text.length == 6) {
        _showSnack("✅ Logged in successfully");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => HomePage()));
      } else {
        _showSnack("❌ Password must be 6 digits");
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _pinField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: pinController,
        onChanged: (val) {
          setState(() => enteredPin = val);
        },
        maxLength: 6,
        keyboardType: TextInputType.number,
        obscureText: true,
        style: const TextStyle(
            letterSpacing: 32, fontSize: 24, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          hintText: "••••••",
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            letterSpacing: 32,
            fontSize: 24,
          ),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _passwordField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: passwordController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        obscureText: _obscurePassword,
        style: const TextStyle(
            fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          counterText: "",
          labelText: "6-digit Password",
          labelStyle: TextStyle(color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          suffixIcon: IconButton(
            icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Colors.blue.shade700
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Choose icon & label dynamically
    final biometricIcon =
    _preferredBiometric == BiometricType.face ? Icons.face : Icons.fingerprint;
    final biometricLabel =
    _preferredBiometric == BiometricType.face ? "Face ID" : "Fingerprint";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.help_outline, color: Colors.grey.shade600),
                    onPressed: () => _showSnack("Help & Support"),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // User Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade100, width: 2),
                      ),
                      child: Icon(Icons.person,
                          size: 40, color: Colors.blue.shade700),
                    ),

                    const SizedBox(height: 16),

                    // ✅ Show saved user name instead of hardcoded
                    Text(
                      savedName ?? "Loading...",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Welcome Text
                    Text(
                      "Welcome back to SecureBank",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Login Methods Pager
                    SizedBox(
                      height: 300,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        children: [
                          // Biometric Login
                          Column(
                            children: [
                              Icon(
                                biometricIcon,
                                size: 64,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "$biometricLabel Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  "Use your $biometricLabel for quick and secure access",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.7,
                                child: ElevatedButton(
                                  onPressed: _authenticateBiometric,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(biometricIcon, size: 20),
                                      const SizedBox(width: 8),
                                      Text("Authenticate"),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // PIN Login
                          Column(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 64,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "PIN Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  "Enter your 6-digit PIN to access your account",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _pinField(),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => _showSnack("Forgot PIN tapped"),
                                child: Text(
                                  "Forgot PIN?",
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Password Login
                          Column(
                            children: [
                              Icon(
                                Icons.password,
                                size: 64,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Password Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  "Enter your 6-digit password to access your account",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _passwordField(),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Page Indicator
                    _buildIndicator(),

                    const SizedBox(height: 24),

                    // Login Button
                    if (_currentPage != 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage == 1 && enteredPin.length == 6) {
                                _login();
                              }
                              if (_currentPage == 2 &&
                                  passwordController.text.length == 6) {
                                _login();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Alternative Options
                    TextButton(
                      onPressed: () => _showSnack("Add Another User"),
                      child: Text(
                        "Not ${savedName ?? "User"}? Add Another User",
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Footer
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        "Secure Banking • Privacy Policy",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
