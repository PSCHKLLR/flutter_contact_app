import 'dart:io';
import 'package:contact_app/models/contact.dart';
import 'package:contact_app/provider/contact_provider.dart';
import 'package:contact_app/screen/contact_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vcard_vcf/vcard.dart' as vcf;

class ContactDetailScreen extends StatefulWidget {
  final Contact contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.contact.isFavorite;
  }

  Future<void> _makeCall() async {
    final Uri launchUri = Uri(scheme: 'tel', path: widget.contact.phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendMessage() async {
    final Uri launchUri = Uri(scheme: 'sms', path: widget.contact.phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendEmail() async {
    final Uri launchUri = Uri(scheme: 'mailto', path: widget.contact.email,);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    final provider = Provider.of<ContactProvider>(context, listen: false);
    final updatedContact = widget.contact.copyWith(isFavorite: _isFavorite);
    provider.updateContact(updatedContact);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Provider.of<ContactProvider>(context, listen: false)
                  .deleteContact(widget.contact.id!);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _editContact() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactBuilderScreen(contact: widget.contact),
      ),
    );
  }

  void _shareContact() {
    bool shareName = true;
    bool sharePhone = true;
    bool shareEmail = widget.contact.email.isNotEmpty;
    bool shareAddress = widget.contact.address.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {

        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool enabled = shareName || sharePhone || shareEmail || shareAddress;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select details to share',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),

                    CheckboxListTile(
                      title: Text('Name: ${widget.contact.name}'),
                      value: shareName,
                      onChanged: (val) => setSheetState(() => shareName = val!),
                    ),

                    CheckboxListTile(
                      title: Text('Phone Number: ${widget.contact.phone}'),
                      value: sharePhone,
                      onChanged: (val) => setSheetState(() => sharePhone = val!),
                    ),

                    if (widget.contact.email.isNotEmpty)
                      CheckboxListTile(
                        title: Text('Email Address: ${widget.contact.email}'),
                        value: shareEmail,
                        onChanged: (val) => setSheetState(() => shareEmail = val!),
                      ),

                    if (widget.contact.address.isNotEmpty)
                      CheckboxListTile(
                        title: Text('Home Address: ${widget.contact.address}'),
                        value: shareAddress,
                        onChanged: (val) => setSheetState(() => shareAddress = val!),
                      ),

                    const Divider(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.description),
                            label: const Text('Text'),
                            onPressed: enabled ? ()
                            {
                              Navigator.pop(context);
                              _shareAsText(shareName, sharePhone, shareEmail, shareAddress);
                            } : null,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.ios_share),
                            label: const Text('vCard'),
                            onPressed: enabled ? () {
                              Navigator.pop(context);
                              _shareAsVcf(shareName, sharePhone, shareEmail, shareAddress);
                            } : null,
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _shareAsText(bool name, bool phone, bool email, bool address) async {
    final contact = widget.contact;

    List<String> details = [];

    if (name) details.add('Name: ${contact.name}');
    if (phone) details.add('Phone: ${contact.phone}');
    if (email) details.add('Email: ${contact.email}');
    if (address) details.add('Address: ${contact.address}');

    if (details.isEmpty) return;

    final String shareContent = details.join('\n');
    await SharePlus.instance.share(
        ShareParams(
          text: shareContent,
          subject: 'Contact Details: ${contact.name}',
        )
    );
  }

  Future<void> _shareAsVcf(bool name, bool phone, bool email, bool address) async {
    final c = widget.contact;

    vcf.VCard vCard = vcf.VCard();

    if (name) {
      List<String> names = c.name.split(' ');
      vCard.firstName = names.first;
      if (names.length > 1) {
        vCard.lastName = names.sublist(1).join(' ');
      } else {
        vCard.lastName = '';
      }
    }

    if (phone) vCard.cellPhone = c.phone;
    if (email) vCard.email = c.email;
    if (address) vCard.homeAddress.street = c.address;

    try {
      final directory = await getTemporaryDirectory();

      final safeName = c.name.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
      final path = '${directory.path}/$safeName.vcf';

      final file = File(path);

      await file.writeAsString(vCard.getFormattedString());

      await SharePlus.instance.share(
        ShareParams(
         files: [XFile(path)], text: 'Contact: ${c.name}',
        )
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating vCard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContactProvider>(context);
    final currentContact = provider.contacts.firstWhere(
            (c) => c.id == widget.contact.id,
        orElse: () => widget.contact
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFEFEFEF),
        foregroundColor: Colors.black,
      ),

      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFEFEFEF),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBottomAction(
                icon: _isFavorite ? Icons.star : Icons.star_border,
                label: 'Favorite',
                color: Colors.blue,
                onTap: _toggleFavorite,
              ),

              _buildBottomAction(
                icon: Icons.edit,
                label: 'Edit',
                color: Colors.blue,
                onTap: _editContact,
              ),

              _buildBottomAction(
                icon: Icons.share,
                label: 'Share',
                color: Colors.blue,
                onTap: _shareContact,
              ),

              _buildBottomAction(
                icon: Icons.delete,
                label: 'Delete',
                color: Colors.blue,
                onTap: _confirmDelete,
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, // Dark Grey/Black background
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentContact.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Text(
                                  'MOBILE ${currentContact.phone}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Avatar
                      Hero(
                        tag: currentContact.id.toString(),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade200,
                          backgroundImage: currentContact.avatar.isNotEmpty
                              ? FileImage(File(currentContact.avatar))
                              : null,
                          child: currentContact.avatar.isEmpty
                              ? Text(currentContact.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.white))
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderBtn(Icons.call, _makeCall),
                      _buildHeaderBtn(Icons.message, _sendMessage),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            if (currentContact.email.isNotEmpty || currentContact.address.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    if (currentContact.email.isNotEmpty) ...[
                      _buildDetailRow(
                        label: 'Email',
                        value: currentContact.email,
                        icon: Icons.email_outlined,
                        onTap: _sendEmail
                      ),
                      Divider(color: Colors.grey.shade200),
                    ],

                    if (currentContact.address.isNotEmpty) ...[
                      _buildDetailRow(
                        label: 'Address',
                        value: currentContact.address,
                        icon: Icons.location_on_outlined,
                      ),
                    ],
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.blue, size: 24),
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20,),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            ),
            Icon(icon, color: Colors.blueAccent, size: 24),
          ],
        ),
      ),
    );
  }
}