import 'package:contact_app/models/contact.dart';
import 'package:contact_app/services/database_manager.dart';
import 'package:sqflite/sqflite.dart';

class ContactService {
  Future<Database> get _db async => await DatabaseManager.instance.database;

  Future<int> createContact(Contact contact) async {
    final db = await _db;
    return await db.insert('contacts', contact.toMap());
  }

  Future<List<Contact>> getAllContacts() async {
    final db = await _db;
    final result = await db.query('contacts', orderBy: 'name ASC');
    return result.map((json) => Contact.fromMap(json)).toList();
  }

  Future<Contact?> getContactById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Contact.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateContact(Contact contact) async {
    final db = await _db;
    return db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await _db;
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}