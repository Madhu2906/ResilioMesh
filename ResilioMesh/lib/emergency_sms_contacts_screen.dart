import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class EmergencySmsContactsScreen extends StatefulWidget {
  const EmergencySmsContactsScreen({super.key});

  @override
  State<EmergencySmsContactsScreen> createState() => _EmergencySmsContactsScreenState();
}

class _EmergencySmsContactsScreenState extends State<EmergencySmsContactsScreen> {
  // Store contacts as maps containing 'name' and 'phone'
  List<Map<String, String>> _contacts = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Load contacts from SharedPreferences (JSON structured)
  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> rawList = prefs.getStringList('emergency_contacts_v2') ?? [];

    // Fallback migration for older plain phone string lists
    if (rawList.isEmpty) {
      List<String> oldList = prefs.getStringList('emergency_contacts') ?? [];
      if (oldList.isNotEmpty) {
        _contacts = oldList.map((num) => {'name': 'Emergency Contact', 'phone': num}).toList();
        await _saveContactsToPrefs();
        return;
      }
    }

    setState(() {
      _contacts = rawList
          .map((item) => Map<String, String>.from(jsonDecode(item)))
          .toList();
    });
  }

  // Save current list state to SharedPreferences
  Future<void> _saveContactsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> rawList = _contacts.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('emergency_contacts_v2', rawList);

    // Keep legacy phone list updated for backwards compatibility with SMS dispatcher
    List<String> phoneOnlyList = _contacts.map((c) => c['phone'] ?? '').toList();
    await prefs.setStringList('emergency_contacts', phoneOnlyList);
  }

  // Add or update contact
  Future<void> _saveContact({int? editIndex}) async {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();

    if (phone.isEmpty) return;
    if (name.isEmpty) name = "Emergency Contact";

    setState(() {
      if (editIndex != null) {
        _contacts[editIndex] = {'name': name, 'phone': phone};
      } else {
        _contacts.add({'name': name, 'phone': phone});
      }
    });

    await _saveContactsToPrefs();
    _nameController.clear();
    _phoneController.clear();

    if (mounted) Navigator.pop(context);
  }

  // Pick directly from phone address book with name and phone number
  Future<void> _pickFromDeviceContacts() async {
    try {
      bool permissionGranted = await FlutterContacts.requestPermission(readonly: true);
      
      if (permissionGranted) {
        final Contact? contact = await FlutterContacts.openExternalPick();
        if (contact != null && contact.phones.isNotEmpty) {
          String name = contact.displayName.isNotEmpty ? contact.displayName : "Emergency Contact";
          String phone = contact.phones.first.number.replaceAll(RegExp(r'[\s\-\(\)]'), '');

          setState(() {
            _contacts.add({'name': name, 'phone': phone});
          });
          await _saveContactsToPrefs();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts permission denied. Enable it in phone settings.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Contact Picker Error: $e");
    }
  }

  Future<void> _deleteContact(int index) async {
    setState(() {
      _contacts.removeAt(index);
    });
    await _saveContactsToPrefs();
  }

  // Dialog for manual creation or renaming existing contacts
  void _showContactDialog({int? editIndex}) {
    if (editIndex != null) {
      _nameController.text = _contacts[editIndex]['name'] ?? '';
      _phoneController.text = _contacts[editIndex]['phone'] ?? '';
    } else {
      _nameController.clear();
      _phoneController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(editIndex == null ? 'Add Emergency Contact' : 'Edit / Rename Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (editIndex == null) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.contacts_rounded),
                label: const Text('Pick from Phone Contacts'),
                onPressed: () {
                  Navigator.pop(context);
                  _pickFromDeviceContacts();
                },
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('OR ENTER MANUALLY', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Contact Name',
                hintText: 'e.g. Mom, Brother, John',
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFFF5252)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+91...',
                prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFFFF5252)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              _phoneController.clear();
              Navigator.pop(context);
            },
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            onPressed: () => _saveContact(editIndex: editIndex),
            child: Text(editIndex == null ? 'SAVE' : 'UPDATE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: const Color(0xFFFF5252),
        foregroundColor: Colors.white,
      ),
      body: _contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.contact_phone_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No Emergency Contacts Saved\nTap + below to pick or enter contact info.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFEBEE),
                      child: Text(
                        (contact['name']?.isNotEmpty == true)
                            ? contact['name']![0].toUpperCase()
                            : 'E',
                        style: const TextStyle(
                            color: Color(0xFFFF5252), fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      contact['name'] ?? 'Emergency Contact',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      contact['phone'] ?? '',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                          onPressed: () => _showContactDialog(editIndex: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          onPressed: () => _deleteContact(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactDialog(),
        backgroundColor: const Color(0xFFFF5252),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Contact', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}