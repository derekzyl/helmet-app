import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/telemetry_model.dart';
import '../services/api_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<EmergencyContactModel> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final list = await ApiService.getContacts();
    if (mounted) {
      setState(() {
        _contacts = list.isNotEmpty
            ? list
            : [
                EmergencyContactModel(
                  id: 'c-1',
                  name: 'Dr. Aisha Bello',
                  phoneNumber: '+2348000000001',
                  relationship: 'Primary Physician / Kin',
                  priority: 1,
                ),
                EmergencyContactModel(
                  id: 'c-2',
                  name: 'Fleet Dispatch HQ',
                  phoneNumber: '+2348000000002',
                  relationship: 'Command Center',
                  priority: 2,
                ),
              ];
        _isLoading = false;
      });
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLow,
        title: const Text('Add SOS Contact', style: TextStyle(color: AppColors.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number (E.164)'),
            ),
            TextField(
              controller: relCtrl,
              decoration: const InputDecoration(labelText: 'Relationship'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.outline)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                await ApiService.addEmergencyContact(nameCtrl.text, phoneCtrl.text, relCtrl.text);
                if (mounted) {
                  setState(() {
                    _contacts.add(
                      EmergencyContactModel(
                        id: 'c-${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text,
                        phoneNumber: phoneCtrl.text,
                        relationship: relCtrl.text,
                        priority: _contacts.length + 1,
                      ),
                    );
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save & Sync to Helmet', style: TextStyle(color: AppColors.onPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS Contacts'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = _contacts[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'PRIORITY #${c.priority}',
                                  style: const TextStyle(
                                    color: AppColors.tertiary,
                                    fontSize: 9,
                                    fontFamily: 'JetBrains Mono',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.phoneNumber,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            c.relationship,
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.sms, color: AppColors.primary, size: 22),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
