import 'package:flutter/material.dart';
import 'main.dart'; // Imports AppDrawer & HomeScreen for navigation

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: _currentIndex == 0
          ? const PrivacyPolicyContent()
          : Center(
              child: Text(
                _currentIndex == 1
                    ? "About Us Page"
                    : _currentIndex == 2
                        ? "SOS Page"
                        : "Helpline Page",
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF5252),
        unselectedItemColor: const Color(0xFF9E9E9E),
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline_rounded),
            label: 'About Us',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radio_button_checked, color: Colors.redAccent),
            label: 'SOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call_rounded),
            label: 'Helpline',
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyContent extends StatelessWidget {
  const PrivacyPolicyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Header curved blue container with info badge
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 45.0),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5252),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(100),
                      bottomRight: Radius.circular(100),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu_rounded,
                                color: Colors.white, size: 26),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Text(
                            'ResilioMesh',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F000000), // Fixed deprecation warning
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF212121),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),

          // Paragraphs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildParagraph(
                  'Disaster Management Unit of ResilioMesh is an Organisation working for benefit of people. This department has built the Disaster Management ResilioMesh app as a free app. This SERVICE is provided by Disaster Management Unit at no cost and is intended for use as is for the Citizens of the City.',
                ),
                _buildParagraph(
                  'This page is used to inform visitors regarding our policies with the collection, use, and disclosure of Personal Information if anyone decided to use our Service.',
                ),
                _buildParagraph(
                  'If you choose to use our Service, then you agree to the collection and use of information in relation to this policy. The Personal Information that we collect is used for providing and improving the Service. We will not use or share your information with anyone except as described in this Privacy Policy.',
                ),
                _buildParagraph(
                  'The terms used in this Privacy Policy have the same meanings as in our Terms and Conditions, which is accessible at Disaster Management ResilioMesh unless otherwise defined in this Privacy Policy.',
                ),
                const SizedBox(height: 8),
                _buildSectionHeader('Information Collection and Use'),
                _buildParagraph(
                  'For a better experience, while using our Service, we may require you to provide us with certain personally identifiable information including but not limited to location services and device details.',
                ),
                _buildParagraph(
                  'The app does use third party services that may collect information used to identify you.',
                ),
                const SizedBox(height: 8),
                _buildSectionHeader('Children\'s Privacy'),
                _buildParagraph(
                  'These Services do not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13. In the case we discover that a child under 13 has provided us with personal information, we immediately delete this from our servers. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact us so that we will be able to do necessary actions.',
                ),
                const SizedBox(height: 8),
                _buildSectionHeader('Changes to This Privacy Policy'),
                _buildParagraph(
                  'We may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. We will notify you of any changes by posting the new Privacy Policy on this page. These changes are effective immediately after they are posted on this page.',
                ),
                const SizedBox(height: 8),
                _buildSectionHeader('Contact Us'),
                _buildParagraph(
                  'If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us.',
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.5,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}