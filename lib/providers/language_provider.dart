import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _currentLocale = const Locale('ar');
  Map<String, dynamic> _translations = {};
  bool _isLoading = true;

  Locale get currentLocale => _currentLocale;
  Map<String, dynamic> get translations => _translations;
  bool get isLoading => _isLoading;
  bool get isRTL => _currentLocale.languageCode == 'ar';

  LanguageProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSavedLanguage();
    await _loadTranslations();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null) {
        _currentLocale = Locale(savedLanguage);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved language: $e');
    }
  }

  Future<void> _loadTranslations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String arJson = await rootBundle.loadString('lib/l10n/ar.json');
      final String enJson = await rootBundle.loadString('lib/l10n/en.json');
      
      _translations = {
        'ar': json.decode(arJson),
        'en': json.decode(enJson),
      };
    } catch (e) {
      print('Error loading translations: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  String translate(String key) {
    if (_isLoading) {
      return key;
    }
    
    try {
      final keys = key.split('.');
      dynamic value = _translations[_currentLocale.languageCode];
      
      for (final k in keys) {
        if (value is Map && value.containsKey(k)) {
          value = value[k];
        } else {
          print('Translation key not found: $key');
          return key;
        }
      }
      
      return value.toString();
    } catch (e) {
      print('Error translating key $key: $e');
      return key;
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_currentLocale.languageCode == languageCode) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      _currentLocale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }
} 