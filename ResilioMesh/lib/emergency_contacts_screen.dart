import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> emergencyContacts = const [
    {
      'title': 'National Emergency Number',
      'number': '112',
      'icon': 'sos',
    },
    {
      'title': 'Police',
      'number': '100',
      'icon': 'local_police',
    },
    {
      'title': 'Fire Brigade',
      'number': '101',
      'icon': 'fire_truck',
    },
    {
      'title': 'Ambulance',
      'number': '102',
      'icon': 'medical_services',
    },
    {
      'title': 'NDRF Helpline',
      'number': '011-24363260',
      'icon': 'shield',
    },
    {
      'title': 'Disaster Management Helpline',
      'number': '1078',
      'icon': 'warning',
    },
    {
      'title': 'Women Helpline',
      'number': '1091',
      'icon': 'person_pin',
    },
  ];

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Could not launch call to $phoneNumber');
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'local_police':
        return Icons.local_police;
      case 'fire_truck':
        return Icons.fire_truck;
      case 'medical_services':
        return Icons.medical_services;
      case 'shield':
        return Icons.shield;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'person_pin':
        return Icons.person_pin;
      default:
        return Icons.phone_in_talk;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.redAccent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: emergencyContacts.length,
        itemBuilder: (context, index) {
          final contact = emergencyContacts[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade50,
                child: Icon(
                  _getIconData(contact['icon']!),
                  color: Colors.redAccent,
                ),
              ),
              title: Text(
                contact['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                contact['number']!,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () => _makePhoneCall(contact['number']!),
              ),
              onTap: () => _makePhoneCall(contact['number']!),
            ),
          );
        },
      ),
    );
  }
}