import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_profile.dart';
import 'dashboard.dart';

class SubmitOTP extends StatefulWidget {
  final String email;

  const SubmitOTP({super.key, required this.email});

  @override
  State<SubmitOTP> createState() => _SubmitOTPState();
}

class _SubmitOTPState extends State<SubmitOTP> {
  final otpController = TextEditingController();
  bool isVerifying = false;

  void verifyOTP() async {
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter OTP")));
      return;
    }

    setState(() => isVerifying = true);

    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.email,
      );

      final user = res.user;
      if (user == null) {
        throw 'Verification failed';
      }

      final existing = await Supabase.instance.client
          .from('Users')
          .select('email')
          .eq('email', widget.email)
          .maybeSingle();

      if (existing != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Dashboard()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => CreateProfile(email: widget.email)),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("OTP failed: $e")));
    } finally {
      setState(() => isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(
                0xFF1a2a3a,
              ), // 🔹 Brighter shade for visible sunlight (same as LoginPage)
              Color(0xFF101820),
              Color(0xFF000000),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔹 OTP Icon inside glowing circle
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(45),
                      border: Border.all(
                        color: const Color(0xFF39FF14),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF39FF14),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 🔹 Title + Subtitle
                  const Text(
                    "Verify Your Email",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "OTP has been sent to\n${widget.email}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 30),

                  // 🔹 OTP Input
                  TextField(
                    controller: otpController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "Enter 6-digit OTP",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔹 Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isVerifying ? null : verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39FF14),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor: const Color(0xFF39FF14),
                        elevation: 10,
                      ),
                      child: isVerifying
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              "Verify & Continue",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Resend OTP link
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Resend OTP feature not implemented"),
                        ),
                      );
                    },
                    child: const Text(
                      "Didn't receive OTP? Resend",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
