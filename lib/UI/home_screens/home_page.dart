import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../profile_screens/about_app_user.dart';
import '../profile_screens/user_profile.dart';
import 'home_content.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool isDarkMode = false;

  final List<Widget> _pages = [
    const HomeContent(),

    const AboutAppUser(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xffF7F7F7),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            selectedItemColor: const Color(0xff503636),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.cairo(),
            items: [
              BottomNavigationBarItem(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                    key: ValueKey(_selectedIndex),
                  ),
                ),
                label: languageProvider.translate('home.navigation.home'),
              ),

              BottomNavigationBarItem(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _selectedIndex == 1 ? Icons.info : Icons.info_outline,
                    key: ValueKey(_selectedIndex),
                  ),
                ),
                label: languageProvider.translate('home.navigation.about'),
              ),
              BottomNavigationBarItem(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _selectedIndex == 2 ? Icons.person : Icons.person_outline,
                    key: ValueKey(_selectedIndex),
                  ),
                ),
                label: languageProvider.translate('home.navigation.profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


