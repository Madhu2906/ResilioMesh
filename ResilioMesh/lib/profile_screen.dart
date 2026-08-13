import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditing = false; // 👈 Tracks View Mode vs Edit Mode

  // Cache initial values to restore if user clicks "Cancel"
  String _initialName = '';
  String _initialPhone = '';
  String _initialLocation = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // 📥 READ: Fetch user document directly from Firestore
  Future<void> _loadUserData() async {
    final user = _user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _initialName = data['name'] ?? user.displayName ?? '';
        _initialPhone = data['phone'] ?? '';
        _initialLocation = data['location'] ?? '';
      } else {
        // Document doesn't exist yet (New User) - enable edit mode immediately
        _initialName = user.displayName ?? '';
        _initialPhone = '';
        _initialLocation = '';
        _isEditing = true;
      }

      _resetControllersToCached();
    } catch (e) {
      debugPrint('Error loading profile from Firestore: $e');
      _initialName = user.displayName ?? '';
      _resetControllersToCached();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetControllersToCached() {
    _nameController.text = _initialName;
    _phoneController.text = _initialPhone;
    _locationController.text = _initialLocation;
  }

  // 📤 WRITE: Save or update profile data in Firestore
  Future<void> _saveProfile() async {
    final user = _user;
    if (!_formKey.currentState!.validate() || user == null) return;

    setState(() => _isSaving = true);

    try {
      final userData = {
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      await user.updateDisplayName(_nameController.text.trim());

      // Update cached values and switch back to View Mode
      _initialName = _nameController.text.trim();
      _initialPhone = _phoneController.text.trim();
      _initialLocation = _locationController.text.trim();

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile to Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Cancel editing and revert back to stored values
  void _cancelEditing() {
    setState(() {
      _resetControllersToCached();
      _isEditing = false;
    });
  }

  // Confirm Delete Dialog
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F)),
              SizedBox(width: 8),
              Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteAccountPermanently();
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  // 🗑️ DELETE: Delete from Firestore & Firebase Auth
  Future<void> _deleteAccountPermanently() async {
    final user = _user;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Security Check: Please log out and log in again to delete your account.',
              ),
              backgroundColor: Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: ${e.message}'),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color(0xFFD32F2F);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryRed,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // Quick toggle edit button in AppBar when in view mode
          if (!_isLoading && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryRed),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar
                    Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: primaryRed.withAlpha(25),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 60,
                          color: primaryRed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _user?.email ?? 'User',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Full Name Display / Input
                    _isEditing
                        ? TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: primaryRed, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          )
                        : _buildInfoCard(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            value: _nameController.text.isNotEmpty
                                ? _nameController.text
                                : 'Not set',
                          ),
                    const SizedBox(height: 16),

                    // Phone Number Display / Input
                    _isEditing
                        ? TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: primaryRed, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          )
                        : _buildInfoCard(
                            icon: Icons.phone_outlined,
                            label: 'Phone Number',
                            value: _phoneController.text.isNotEmpty
                                ? _phoneController.text
                                : 'Not set',
                          ),
                    const SizedBox(height: 16),

                    // Location Display / Input
                    _isEditing
                        ? TextFormField(
                            controller: _locationController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Location / Address',
                              prefixIcon:
                                  const Icon(Icons.location_on_outlined),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: primaryRed, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your address or location';
                              }
                              return null;
                            },
                          )
                        : _buildInfoCard(
                            icon: Icons.location_on_outlined,
                            label: 'Location / Address',
                            value: _locationController.text.isNotEmpty
                                ? _locationController.text
                                : 'Not set',
                          ),
                    const SizedBox(height: 28),

                    // Action Buttons (Save/Cancel in Edit Mode OR Edit Profile in View Mode)
                    if (_isEditing) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      if (_initialName.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : _cancelEditing,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Delete Account Button
                    TextButton.icon(
                      onPressed: _confirmDeleteAccount,
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                        color: primaryRed,
                      ),
                      label: const Text(
                        'Delete Account Permanently',
                        style: TextStyle(
                          color: primaryRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // 🎨 View Mode Item Card Component
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD32F2F)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}