import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _usersCollection = 'users';

  Future<void> saveUser(AppUser user) async {
    await _db.collection(_usersCollection).doc(user.id).set(user.toJson());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection(_usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return AppUser.fromJson(data);
  }

  Future<void> updateUser(AppUser user) async {
    await _db.collection(_usersCollection).doc(user.id).set(user.toJson());
  }
}
