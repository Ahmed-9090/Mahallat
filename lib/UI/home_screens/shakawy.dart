import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';

class Shakawy extends StatefulWidget {
  const Shakawy({super.key});

  @override
  State<Shakawy> createState() => _ShakawyState();
}

class _ShakawyState extends State<Shakawy> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _contentController = TextEditingController();
  final _otherRequestController = TextEditingController();
  bool _isLoading = false;
  String? _selectedRequestType;
  bool _showOtherField = false;
  DateTime? _lastBackPressTime;

  @override
  void dispose() {
    _phoneController.dispose();
    _contentController.dispose();
    _otherRequestController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LanguageProvider>(context, listen: false).translate('shakawy.loginRequired'),
              style: GoogleFonts.cairo(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('shakawy').add({
        'userId': user.uid,
        'phoneNumber': _phoneController.text,
        'title': _selectedRequestType,
        'content':
            _selectedRequestType == Provider.of<LanguageProvider>(context, listen: false).translate('shakawy.requestTypes.other')
                ? _otherRequestController.text
                : _selectedRequestType!,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LanguageProvider>(context, listen: false).translate('shakawy.success'),
              style: GoogleFonts.cairo(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        _formKey.currentState!.reset();
        _phoneController.clear();
        _contentController.clear();
        _otherRequestController.clear();
        setState(() {
          _selectedRequestType = null;
          _showOtherField = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LanguageProvider>(context, listen: false).translate('shakawy.error'),
              style: GoogleFonts.cairo(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final requestTypes = [
      languageProvider.translate('shakawy.requestTypes.orders'),
      languageProvider.translate('shakawy.requestTypes.becomeCaptain'),
      languageProvider.translate('shakawy.requestTypes.becomeSeller'),
      languageProvider.translate('shakawy.requestTypes.other'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.translate('shakawy.title'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.05,
            color: const Color(0xff503636),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xffF1E4CF),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffF1E4CF), Color(0xfffaf1e6), Colors.white],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width * 0.04),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('shakawy.phone'),
                    labelStyle: GoogleFonts.cairo(
                      fontSize: width * 0.04,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(width * 0.02),
                    ),
                    prefixIcon: Icon(
                      Icons.phone,
                      size: width * 0.06,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return languageProvider.translate('shakawy.phoneHint');
                    }
                    if (value.length < 10) {
                      return languageProvider.translate('shakawy.phoneInvalid');
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),
                DropdownButtonFormField<String>(
                  value: _selectedRequestType,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('shakawy.requestType'),
                    labelStyle: GoogleFonts.cairo(
                      fontSize: width * 0.04,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(width * 0.02),
                    ),
                    prefixIcon: Icon(
                      Icons.category,
                      size: width * 0.06,
                    ),
                  ),
                  items: requestTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: GoogleFonts.cairo(
                          fontSize: width * 0.04,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRequestType = newValue;
                      _showOtherField = newValue == languageProvider.translate('shakawy.requestTypes.other');
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return languageProvider.translate('shakawy.requestTypeHint');
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),
                if (_selectedRequestType == languageProvider.translate('shakawy.requestTypes.other')) ...[
                  TextFormField(
                    controller: _otherRequestController,
                    decoration: InputDecoration(
                      labelText: languageProvider.translate('shakawy.requestDescription'),
                      labelStyle: GoogleFonts.cairo(
                        fontSize: width * 0.04,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(width * 0.02),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return languageProvider.translate('shakawy.requestDescriptionHint');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: height * 0.02),
                ],
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff44A2E6),
                    padding: EdgeInsets.symmetric(vertical: height * 0.015),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.02),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: width * 0.06,
                          height: width * 0.06,
                          child: const CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          languageProvider.translate('shakawy.send'),
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
