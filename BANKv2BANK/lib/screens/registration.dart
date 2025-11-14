import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // kept to retain original imports
import 'package:shared_preferences/shared_preferences.dart';
import 'training.dart'; // ✅ Import TrainingPage

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _securityAnswerController = TextEditingController();
  final TextEditingController _mpinController = TextEditingController();
  final TextEditingController _confirmMpinController = TextEditingController();

  String? _selectedQuestion;

  bool otpSent = false;
  bool otpVerified = false;
  bool askDetails = false;
  bool setMpin = false;
  bool _obscureMpin = true;
  bool _obscureConfirmMpin = true;

  // kept to retain original code; not used in hardcoded OTP mode
  final String backendUrl = "http://172.20.10.2:5001/";

  final PageController _pageController = PageController();

  // 🔐 Hardcoded demo OTP
  static const String _demoOtp = "123456";

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page == 0 && otpSent) {
        setState(() => otpSent = true);
      } else if (page == 1 && otpVerified) {
        setState(() => otpVerified = true);
      } else if (page == 2 && askDetails) {
        setState(() => askDetails = true);
      } else if (page == 3 && setMpin) {
        setState(() => setMpin = true);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// UPDATED: No network call. Immediately "send" demo OTP and navigate to OTP page.
  Future<void> sendOtp(String phone) async {
    if (phone.isEmpty || phone.length != 10) {
      _showSnack("Please enter a valid 10-digit phone number");
      return;
    }

    // Optionally ensure digits only
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      _showSnack("Phone number should contain digits only");
      return;
    }

    // Simulate success
    setState(() {
      otpSent = true;
    });

    // Move to OTP page
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Inform user about demo OTP (kept snack style consistent with your UI)
    _showSnack("OTP sent to +91$phone (demo: $_demoOtp)");
  }

  /// UPDATED: Verifies against hardcoded OTP locally; no backend call.
  Future<void> verifyOtp(String phone, String otp) async {
    if (otp.isEmpty || otp.length != 6) {
      _showSnack("Please enter a valid 6-digit OTP");
      return;
    }

    final formattedPhone = "+91$phone";

    if (otp == _demoOtp) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("phone", formattedPhone);

      setState(() {
        otpVerified = true;
        askDetails = true;
      });

      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      _showSnack("✅ OTP Verified! Continue with details.");
    } else {
      _showSnack("❌ Invalid OTP");
    }
  }

  Future<void> saveUserDetails() async {
    if (_nameController.text.isEmpty) {
      _showSnack("Please enter your name");
      return;
    }

    if (_selectedQuestion == null) {
      _showSnack("Please select a security question");
      return;
    }

    if (_securityAnswerController.text.isEmpty) {
      _showSnack("Please provide an answer to the security question");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("name", _nameController.text.trim());
    await prefs.setString("security_question", _selectedQuestion!);
    await prefs.setString("security_answer", _securityAnswerController.text.trim().toLowerCase());

    setState(() {
      askDetails = false;
      setMpin = true;
    });

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> saveMpin() async {
    if (_mpinController.text.length != 6) {
      _showSnack("MPIN must be exactly 6 digits");
      return;
    }

    if (_mpinController.text != _confirmMpinController.text) {
      _showSnack("MPINs do not match");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("mpin", _mpinController.text);
    await prefs.setBool("registered", true);

    _showSnack("✅ Registration complete! Proceed to training.");

    // 🔹 After MPIN setup → go to TrainingPage instead of login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TrainingPage()),
    );
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

  Widget _buildIndicator(int currentPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPage == index ? Colors.blue.shade700 : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = otpSent
        ? (otpVerified
        ? (askDetails
        ? 2
        : (setMpin ? 3 : 2))
        : 1)
        : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () {
            if (currentPage > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );

              if (currentPage == 1) {
                setState(() => otpSent = false);
              } else if (currentPage == 2) {
                setState(() => otpVerified = false);
              } else if (currentPage == 3) {
                setState(() {
                  askDetails = true;
                  setMpin = false;
                });
              }
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        title: Text(
          "Registration",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildIndicator(currentPage),
            const SizedBox(height: 20),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPhonePage(),
                  _buildOtpPage(),
                  _buildDetailsPage(),
                  _buildMpinPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhonePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.phone_iphone,
            size: 64,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            "Phone Verification",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll send you a verification code to your phone number",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: _inputDecoration("Phone Number", Icons.phone),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => sendOtp(_phoneController.text.trim()),
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
                "Send OTP",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOtpPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.sms,
            size: 64,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            "Enter OTP",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter the 6-digit code sent to +91${_phoneController.text}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: _inputDecoration("OTP Code", Icons.lock_outline),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive code? ",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              TextButton(
                onPressed: () => sendOtp(_phoneController.text.trim()),
                child: Text(
                  "Resend OTP",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => verifyOtp(_phoneController.text.trim(), _otpController.text.trim()),
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
                "Verify OTP",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.security, size: 64, color: Colors.blue.shade700),
          const SizedBox(height: 16),
          Text("Security Details",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text("Set up your security information for account recovery",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration("Full Name", Icons.person_outline),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedQuestion,
            items: [
              "What is your favourite color?",
              "What is your pet's name?",
              "What city were you born in?",
              "What is your mother's maiden name?"
            ].map((q) => DropdownMenuItem(
              value: q,
              child: Text(
                q,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
            onChanged: (val) => setState(() => _selectedQuestion = val),
            decoration: _inputDecoration("Security Question", Icons.question_answer),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _securityAnswerController,
            decoration: _inputDecoration("Your Answer", Icons.edit),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saveUserDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Continue",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMpinPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            "Set MPIN",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create a 6-digit MPIN for secure login",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _mpinController,
            obscureText: _obscureMpin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: _inputDecoration("Enter MPIN", Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureMpin ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () => setState(() => _obscureMpin = !_obscureMpin),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmMpinController,
            obscureText: _obscureConfirmMpin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: _inputDecoration("Confirm MPIN", Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmMpin ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () => setState(() => _obscureConfirmMpin = !_obscureConfirmMpin),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saveMpin,
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
                "Complete Registration",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey),
      labelText: label,
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
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
