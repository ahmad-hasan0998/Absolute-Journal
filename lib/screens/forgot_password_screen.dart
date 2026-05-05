import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  Widget _buildShadowedInput({required String hint, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: const Color(0xFF0A2463)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Reset Password', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF0A2463), height: 1.1)),
              const SizedBox(height: 16),
              const Text('Enter your email to receive a recovery link.', style: TextStyle(color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 40),
              _buildShadowedInput(hint: 'Email Address', icon: Icons.email_outlined),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0A2463), Color(0xFF1E3A8A)]), // Navy to Blue
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: const Color(0xFF0A2463).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: const Center(child: Text('Send Reset Link', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}