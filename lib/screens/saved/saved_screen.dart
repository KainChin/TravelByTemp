import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, size: 64, color: AppColors.primary),
          SizedBox(height: 16),
          Text('Saved Places', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Your favorite destinations appear here.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
