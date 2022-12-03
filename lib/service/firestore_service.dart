import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:where/model/member.dart';

class FireStoreService {
  final _db = FirebaseFirestore.instance;
  static final FireStoreService _service = FireStoreService._();

  factory FireStoreService() {
    return _service;
  }

  FireStoreService._();

  Future<void> updateMember(Member member) {
    return _db
        .collection('Members')
        .doc(member.id)
        .set(member.toJson(), SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenToMembers() {
    return _db.collection('Members').snapshots();
  }
}
