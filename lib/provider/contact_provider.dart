import 'package:contact_app/models/contact.dart';
import 'package:flutter/material.dart';
import '../services/contact_service.dart';

class ContactProvider with ChangeNotifier {
  final ContactService _service = ContactService();

  List<Contact> _contacts = [];
  List<Contact> get contacts => _contacts;

  String _searchQuery = '';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadContacts() async {
    _isLoading = true;
    notifyListeners();

    _contacts = await _service.getAllContacts();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addContact(Contact contact) async {
    await _service.createContact(contact);
    await loadContacts();
  }

  Future<void> updateContact(Contact contact) async {
    await _service.updateContact(contact);
    await loadContacts();
  }

  Future<void> deleteContact(int id) async {
    await _service.deleteContact(id);
    await loadContacts();
  }

  Map<String, List<Contact>> get getGroupedContacts {
    final Map<String, List<Contact>> grouped = {};

    final filteredContacts = _contacts.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList();

    final favorites = filteredContacts.where((c) => c.isFavorite).toList();
    favorites.sort((a, b) => a.name.compareTo(b.name));

    if (favorites.isNotEmpty) {
      grouped['Favorites'] = favorites;
    }
    filteredContacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    for (var contact in filteredContacts) {
      if (contact.name.isEmpty) continue;

      String firstLetter = contact.name[0].toUpperCase();

      if (!RegExp(r'[A-Z]').hasMatch(firstLetter)) {
        firstLetter = '#';
      }

      if (grouped[firstLetter] == null) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(contact);
    }

    return grouped;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}