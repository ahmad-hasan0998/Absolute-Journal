import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  Widget _buildShadowedInput({required String hint, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: TextField(
        obscureText: isPassword,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create Account', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF0A2463), height: 1.1)),
              const SizedBox(height: 40),
              _buildShadowedInput(hint: 'Username', icon: Icons.person_outline),
              const SizedBox(height: 20),
              _buildShadowedInput(hint: 'Email Address', icon: Icons.email_outlined),
              const SizedBox(height: 20),
              _buildShadowedInput(hint: 'Password', icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]), // Orange to Yellow
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: const Color(0xFFFF6B00).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: const Center(child: Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}