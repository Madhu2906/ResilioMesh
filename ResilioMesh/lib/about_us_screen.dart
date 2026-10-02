import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('About ResilioMesh'),
        backgroundColor: const Color(0xFFFF5252),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. App Header / Branding Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFFF7676)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1AFF5252),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings_input_antenna_rounded,
                        size: 44,
                        color: Color(0xFFFF5252),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ResilioMesh',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Offline-First P2P Emergency Mesh Platform',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Architecture Stats Row
              Row(
                children: [
                  Expanded(child: _buildStatCard('P2P', 'Bluetooth Mesh', Icons.bluetooth_connected_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('ECVA', 'Anti-Fake Math', Icons.verified_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('PostGIS', 'Cloud Sync', Icons.cloud_sync_rounded)),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Project Mission Statement
              _buildSectionCard(
                title: 'Our Mission & Vision',
                icon: Icons.flag_rounded,
                iconColor: Colors.blue,
                child: const Text(
                  'Traditional municipal platforms (such as city disaster management portals) rely entirely on active cellular infrastructure and internet connectivity. During catastrophic cyclones, floods, or major earthquakes, telecom networks inevitably fail. ResilioMesh bridges this critical communication gap by creating an independent, self-healing peer-to-peer mobile mesh network when cell service drops.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Core Technical Capabilities
              _buildSectionCard(
                title: 'Core Architecture',
                icon: Icons.architecture_rounded,
                iconColor: Colors.amber,
                child: Column(
                  children: const [
                    _FeatureItem(
                      icon: Icons.router_rounded,
                      title: 'P2P Bluetooth & Wi-Fi Direct Hop',
                      subtitle: 'Transmits small JSON payload packets (<5 KB) device-to-device within a 20-30m neighborhood radius without cell service.',
                    ),
                    SizedBox(height: 14),
                    _FeatureItem(
                      icon: Icons.security_rounded,
                      title: 'Edge-Consensus Verification (ECVA)',
                      subtitle: 'Local spatial math and Haversine distance calculations verify genuine crowdsourced reports locally to eliminate fake alerts.',
                    ),
                    SizedBox(height: 14),
                    _FeatureItem(
                      icon: Icons.battery_charging_full_rounded,
                      title: 'Smart Battery Survival Mode',
                      subtitle: 'Dynamically scales BLE scanning intervals (continuous, intermittent, or passive) based on device battery percentage.',
                    ),
                    SizedBox(height: 14),
                    _FeatureItem(
                      icon: Icons.map_rounded,
                      title: 'Offline Routing & Gateway Sync',
                      subtitle: 'Provides pre-cached OSM vector tile detours and automatically acts as a gateway to upload queued logs to Spring Boot / PostGIS once signal returns.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Municipal Complement Note
              _buildSectionCard(
                title: 'Resilience & Municipal Integration',
                icon: Icons.account_balance_rounded,
                iconColor: Colors.green,
                child: const Text(
                  'While command centers (like React.js dashboard views for rescue authorities) handle macro coordination, ResilioMesh acts at the grassroots level—maintaining device connectivity, micro-local hazard mapping, and secure data routing right at the disaster zone perimeter.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Development Team Card
              _buildSectionCard(
                title: 'Engineering & Academic Project',
                icon: Icons.code_rounded,
                iconColor: Colors.purple,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Developed as an advanced technical project focusing on distributed systems, edge computing, and disaster resilience infrastructure.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF334155),
                      ),
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFFE2E8F0),
                          child: Icon(Icons.group_rounded, color: Color(0xFF64748B)),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ResilioMesh Development Team',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'Distributed Systems & Mesh Computing',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer Copyright
              const Center(
                child: Text(
                  '© 2026 ResilioMesh Project. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFF5252)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ),
          child,
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF5252), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}