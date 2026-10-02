import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Method to handle user logout with a confirmation dialog
  static void confirmAndLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F), // Theme Red
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                Navigator.of(context).pop(); // Close drawer menu
                await FirebaseAuth.instance.signOut(); // End Firebase Session
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}