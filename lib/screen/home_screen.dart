import 'dart:async';
import 'dart:io';

import 'package:contact_app/models/contact.dart';
import 'package:contact_app/provider/contact_provider.dart';
import 'package:contact_app/screen/contact_builder_screen.dart';
import 'package:contact_app/screen/contact_detail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as native;
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _debounce;
  final Set<int> _selectedIds = {};
  bool get _isSelectionMode =>_selectedIds.isNotEmpty;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContactProvider>(context, listen: false).loadContacts();
    });
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showErrorSnackBar('Could not launch dialer');
    }
  }

  Future<void> _sendMessage(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showErrorSnackBar('Could not launch messaging app');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showQuickActions(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: contact.avatar.isNotEmpty
                            ? FileImage(File(contact.avatar))
                            : null,
                        child: contact.avatar.isEmpty
                            ? Text(contact.name[0].toUpperCase(), style: const TextStyle(fontSize: 24))
                            : null,
                      ),

                      const SizedBox(width: 15),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(contact.phone, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),

                  const Divider(height: 30),

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        _buildActionButton(
                          icon: Icons.call,
                          label: 'Call',
                          color: Colors.green,
                          onTap: () => _makeCall(contact.phone),
                        ),

                        _buildActionButton(
                          icon: Icons.message,
                          label: 'Message',
                          color: Colors.blue,
                          onTap: () => _sendMessage(contact.phone),
                        ),

                        _buildActionButton(
                          icon: Icons.info,
                          label: 'Detail',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: contact)));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),

          const SizedBox(height: 8),

          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<ContactProvider>(context, listen: false).setSearchQuery(query);
    });
  }

  void _startSearch() {
    ModalRoute.of(context)!.addLocalHistoryEntry(LocalHistoryEntry(onRemove: _stopSearch));
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    _clearSearch();
    setState(() {
      _isSearching = false;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      Provider.of<ContactProvider>(context, listen: false).setSearchQuery('');
    });
  }

  Future<void> _importContact() async {
    if (!await native.FlutterContacts.requestPermission(readonly: true)) {
      _showErrorSnackBar('Permission denied: Cannot access contacts');
      return;
    }

    final native.Contact? contact = await native.FlutterContacts.openExternalPick();

    if (contact != null) {
      final name = '${contact.name.first} ${contact.name.last}'.trim();

      String phone = '';
      if (contact.phones.isNotEmpty) {
        phone = contact.phones.first.number;
      }

      final email = contact.emails.isNotEmpty ? contact.emails.first.address : '';

      final address = contact.addresses.isNotEmpty ? contact.addresses.first.address : '';

      const avatarPath = '';

      final newContact = Contact(
        name: name.isEmpty ? 'Unknown' : name,
        phone: phone,
        email: email,
        address: address,
        avatar: avatarPath,
        isFavorite: false,
      );

      final provider = Provider.of<ContactProvider>(context, listen: false);
      final exists = provider.contacts.any((c) => c.phone.isNotEmpty && c.phone == phone);

      if (exists) {
        _showErrorSnackBar('Contact already exists');
      } else {
        await provider.addContact(newContact);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $name'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _deleteSelected() {
    final provider = Provider.of<ContactProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_selectedIds.length} contacts?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              for (var id in _selectedIds) {
                provider.deleteContact(id);
              }
              setState(() => _selectedIds.clear());
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
        ? IconButton(onPressed: () => setState(() {
          _selectedIds.clear();
        }),
            icon: Icon(Icons.close)
        )
        : null,
        backgroundColor: Colors.white,
        title: _isSearching ?
        TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration(
            hintText: 'Search name or phone...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: _onSearchChanged,
        ) :  Text(_isSelectionMode? '${_selectedIds.length} Selected' :  'My Contacts'),
        actions: _isSelectionMode ? [
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteSelected),
        ] :
        [
          IconButton(onPressed: () {
            if (_isSearching) {
              if (_searchController.text.isNotEmpty) {
                _clearSearch();
              } else {
                Navigator.pop(context);
              }
            } else {
              _startSearch();
            }
            } ,
          icon: Icon(_isSearching ? Icons.close : Icons.search)),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.import_contacts),
              tooltip: 'Import from Device',
              onPressed: _importContact,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade100,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ContactBuilderScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<ContactProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(),);
          }

          if (provider.contacts.isEmpty) {
            return const Center(
              child: Text('No Contacts. \n Tap + to add.',
              textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final groupedMap = provider.getGroupedContacts;
          final List<dynamic> contactList = [];

          groupedMap.forEach((key, value) {
            contactList.add(key);
            contactList.addAll(value);
          });

          return ListView.builder(
            itemCount: contactList.length,
            itemBuilder: (context, index) {
              final item = contactList[index];

              if (item is String) {
                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  width: double.infinity,
                  child: Text(
                    item,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: item == 'Favorites' ? Colors.amber[800] : Colors.blue
                    ),
                  ),
                );
              } else if (item is Contact) {
                return _buildContactTile(item);
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  // Widget _buildContactTile(Contact contact) {
  //   return Card(
  //     margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //     child: ListTile(
  //       leading: CircleAvatar(
  //         radius: 25,
  //         backgroundColor: Colors.blue.shade100,
  //         backgroundImage: contact.avatar.isNotEmpty
  //             ? FileImage(File(contact.avatar))
  //             : null,
  //         child: contact.avatar.isEmpty
  //             ? Text(
  //           contact.name[0].toUpperCase(),
  //           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
  //         )
  //             : null,
  //       ),
  //       title: Text(
  //         contact.name,
  //         style: const TextStyle(fontWeight: FontWeight.bold),
  //       ),
  //       subtitle: Text(contact.phone),
  //       // trailing: contact.isFavorite
  //       //     ? const Icon(Icons.star, color: Colors.amber)
  //       //     : const Icon(Icons.star_border, color: Colors.grey),
  //       onTap: () => _showQuickActions(context, contact),
  //     ),
  //   );
  // }

  Widget _buildContactTile(Contact contact) {
    final isSelected = _selectedIds.contains(contact.id);

    Widget cardContent = Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      elevation: 0,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      shape: isSelected
          ? RoundedRectangleBorder(
          side: const BorderSide(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(4))
          : RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(4)
      ),
      child: ListTile(
        leading: isSelected
            ? const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.check, color: Colors.white),
        )
            : CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          backgroundImage: contact.avatar.isNotEmpty ? FileImage(File(contact.avatar)) : null,
          child: contact.avatar.isEmpty ? Text(contact.name[0].toUpperCase()) : null,
        ),
        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(contact.phone),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(contact.id!);
          } else {
            _showQuickActions(context, contact);
          }
        },
        onLongPress: () => _toggleSelection(contact.id!),
      ),
    );

    if (_isSelectionMode) {
      return cardContent;
    }
    return Dismissible(
      key: Key(contact.id.toString()),

      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _makeCall(contact.phone);
        } else {
          _sendMessage(contact.phone);
        }
        return false;
      },

      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.call, color: Colors.white, size: 30),
      ),

      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.message, color: Colors.white, size: 30),
      ),

      child: cardContent,
    );
  }
}