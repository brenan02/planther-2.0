import 'package:flutter/material.dart';

void showAddedToGardenToast(BuildContext context) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Row(
        children: [
          Icon(Icons.eco, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text(
            'Added to garden!',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF2D6A4F),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
    ),
  );
}