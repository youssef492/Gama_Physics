import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageToggle extends StatelessWidget {
  final bool lightBackground;
  const LanguageToggle({super.key, this.lightBackground = false});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return IconButton(
      onPressed: () => lang.toggle(),
      icon: Text(
        lang.isArabic ? 'EN' : 'AR',
        style: TextStyle(
          color: lightBackground ? Colors.white : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      tooltip: lang.isArabic ? 'English' : 'العربية',
    );
  }
}
