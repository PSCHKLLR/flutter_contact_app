import 'dart:io';

import 'package:contact_app/models/contact.dart';
import 'package:contact_app/provider/contact_provider.dart';
import 'package:contact_app/screen/contact_detail.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

class ContactBuilderScreen extends StatefulWidget {
  final Contact? contact;

  const ContactBuilderScreen({super.key, this.contact});

  @override
  State<ContactBuilderScreen> createState() => _ContactBuilderScreenState();
}

class _ContactBuilderScreenState extends State<ContactBuilderScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  File? _imageFile;
  bool _isFavorite = false;
  String _fullPhoneNumber = '';
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _emailController = TextEditingController(text: widget.contact?.email ?? '');
    _addressController = TextEditingController(text: widget.contact?.address ?? '');
    _isFavorite = widget.contact?.isFavorite ?? false;
    _fullPhoneNumber = widget.contact?.phone ?? '';

    if (widget.contact?.avatar != null && widget.contact!.avatar.isNotEmpty) {
      _imageFile = File(widget.contact!.avatar);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final directory = await getApplicationDocumentsDirectory();

      final fileName = path.basename(picked.path);
      final savedImage = await File(picked.path).copy('${directory.path}/$fileName');

      setState(() {
        _imageFile = savedImage;
      });
    }
  }

  void _saveContact() {
    if (!_formKey.currentState!.validate()) return;

    if (_fullPhoneNumber.isEmpty || _fullPhoneNumber.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number'), backgroundColor: Colors.red),
      );
      return;
    }

    final name = _nameController.text;
    final phone = _fullPhoneNumber;
    final email = _emailController.text;
    final address = _addressController.text;
    final avatarPath = _imageFile?.path ?? '';

    final provider = Provider.of<ContactProvider>(context, listen: false);

    if (widget.contact == null) {
      final newContact = Contact(
        name: name,
        phone: phone,
        email: email,
        address: address,
        avatar: avatarPath,
        isFavorite: _isFavorite,
      );
      provider.addContact(newContact);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: newContact)));
    } else {
      final updatedContact = widget.contact!.copyWith(
        name: name,
        phone: phone,
        email: email,
        address: address,
        avatar: avatarPath,
        isFavorite: _isFavorite,
      );
      provider.updateContact(updatedContact);
      Navigator.pop(context);
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null
                      ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
              ),

              const SizedBox(height: 10),

              IntlPhoneField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(),
                  ),
                ),
                initialCountryCode: 'MY',
                initialValue: widget.contact?.phone,
                onChanged: (phone) {
                  _fullPhoneNumber = phone.completeNumber;
                },
                disableLengthCheck: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (PhoneNumber? value) {
                  if (value == null || value.number.trim().isEmpty) {
                    return 'Phone cannot be empty';
                  }

                  final provider = Provider.of<ContactProvider>(context, listen: false);
                  final enteredNumber = value.completeNumber;

                  try {
                    final duplicate = provider.contacts.firstWhere((c) {
                      if (widget.contact != null && c.id == widget.contact!.id) {
                        return false;
                      }
                      return c.phone == enteredNumber;
                    });

                    return 'Phone number already exists (${duplicate.name})';

                  } catch (e) {
                    return null;
                  }

                },
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }

                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

                  if (!emailRegex.hasMatch(value)) {
                    return 'Enter a valid email address';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
              ),

              const SizedBox(height: 10),

              SwitchListTile(
                title: const Text('Mark as Favorite'),
                value: _isFavorite,
                onChanged: (val) => setState(() => _isFavorite = val),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveContact,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}