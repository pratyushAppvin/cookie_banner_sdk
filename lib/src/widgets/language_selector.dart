import 'package:flutter/material.dart';
import '../models/language.dart';

/// Language selector dropdown for cookie banner
class LanguageSelector extends StatelessWidget {
  final List<Language> languages;
  final String selectedLanguageCode;
  final ValueChanged<String> onLanguageChanged;
  final Color? textColor;
  final Color? dropdownColor;

  const LanguageSelector({
    super.key,
    required this.languages,
    required this.selectedLanguageCode,
    required this.onLanguageChanged,
    this.textColor,
    this.dropdownColor,
  });

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: dropdownColor ?? Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (textColor ?? Colors.black).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLanguageCode,
          icon: Icon(
            Icons.language,
            color: textColor ?? Colors.black,
            size: 18,
          ),
          dropdownColor: dropdownColor ?? Colors.white,
          style: TextStyle(
            color: textColor ?? Colors.black,
            fontSize: 14,
          ),
          items: languages.map((Language language) {
            return DropdownMenuItem<String>(
              value: language.languageCode,
              child: Text(
                language.language,
                style: TextStyle(
                  color: textColor ?? Colors.black,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onLanguageChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}
