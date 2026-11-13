import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../core/models.dart';

/// All Firestore access lives here.
///
/// Collections:
///   users/{uid}
///   users/{uid}/vehicles/{id}
///   requests/{id}
///   requests/{id}/messages/{id}
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('requests');

  // ---------------------------------------------------------------- users

  Future<void> createUser(AppUser user) => _users.doc(user.uid).set(user.toMap());

  Stream<AppUser?> userStream(String uid) => _users.doc(uid).snapshots().map(
      (d) => d.exists ? AppUser.fromMap(d.id, d.data()!) : null);

  Future<void> setAvailability(String uid, bool available) =>
      _users.doc(uid).update({'available': available});

  // ------------------------------------------------------------- vehicles

  Stream<List<Vehicle>> vehicles(String uid) =>
      _users.doc(uid).collection('vehicles').snapshots().map((s) =>
          s.docs.map((d) => Vehicle.fromMap(d.id, d.data())).toList());

  Future<void> addVehicle(String uid, Vehicle v) =>
      _users.doc(uid).collection('vehicles').add(v.toMap());

  Future<void> deleteVehicle(String uid, String vehicleId) =>
      _users.doc(uid).collection('vehicles').doc(vehicleId).delete();

  // ------------------------------------------------------------- requests

  Future<String> createRequest(AssistanceRequest r) async {
    final ref = await _requests.add(r.toCreateMap());
    return ref.id;
  }

  Stream<AssistanceRequest?> requestStream(String id) =>
      _requests.doc(id).snapshots().map((d) =>
          d.exists ? AssistanceRequest.fromMap(d.id, d.data()!) : null);

  /// Requests created by a customer, newest first (sorted on the device so no
  /// composite index is needed).
  Stream<List<AssistanceRequest>> customerRequests(String uid) => _requests
      .where('customerId', isEqualTo: uid)
      .snapshots()
      .map((s) => _sorted(s.docs));

  /// All requests that still wait for a provider.
  Stream<List<AssistanceRequest>> pendingRequests() => _requests
      .where('status', isEqualTo: RequestStatus.pending.name)
      .snapshots()
      .map((s) => _sorted(s.docs));

  /// Jobs a provider has accepted.
  Stream<List<AssistanceRequest>> providerJobs(String uid) => _requests
      .where('providerId', isEqualTo: uid)
      .snapshots()
      .map((s) => _sorted(s.docs));

  List<AssistanceRequest> _sorted(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final list =
        docs.map((d) => AssistanceRequest.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// First provider to accept wins: the transaction fails if the request is
  /// no longer pending. Returns false when someone else was faster.
  Future<bool> acceptRequest(
      String requestId, AppUser provider, LatLng? providerLocation) {
    final ref = _requests.doc(requestId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists ||
          snap.data()!['status'] != RequestStatus.pending.name) {
        return false;
      }
      tx.update(ref, {
        'status': RequestStatus.accepted.name,
        'providerId': provider.uid,
        'providerName': provider.name,
        'providerPhone': provider.phone,
        if (providerLocation != null)
          'providerLocation':
              GeoPoint(providerLocation.latitude, providerLocation.longitude),
      });
      return true;
    });
  }

  Future<void> updateStatus(String requestId, RequestStatus status) =>
      _requests.doc(requestId).update({'status': status.name});

  Future<void> updateProviderLocation(String requestId, LatLng p) =>
      _requests.doc(requestId).update(
          {'providerLocation': GeoPoint(p.latitude, p.longitude)});

  // -------------------------------------------------------------- payment

  /// Records how the customer paid. There is no real payment gateway: card /
  /// wallet payments are simulated (see README).
  Future<void> markPaid(String requestId, String method) => _requests
      .doc(requestId)
      .update({'paid': true, 'paymentMethod': method});

  // --------------------------------------------------------------- rating

  Future<void> rateProvider({
    required String requestId,
    required String providerId,
    required int stars,
    required String feedback,
  }) {
    final reqRef = _requests.doc(requestId);
    final providerRef = _users.doc(providerId);
    return _db.runTransaction((tx) async {
      final p = await tx.get(providerRef);
      final oldRating = ((p.data()?['rating'] ?? 0) as num).toDouble();
      final oldCount = ((p.data()?['ratingCount'] ?? 0) as num).toInt();
      final newCount = oldCount + 1;
      final newRating = (oldRating * oldCount + stars) / newCount;
      tx.update(providerRef, {'rating': newRating, 'ratingCount': newCount});
      tx.update(reqRef,
          {'rated': true, 'rating': stars, 'feedback': feedback.trim()});
    });
  }

  // ----------------------------------------------------------------- chat

  Stream<List<ChatMessage>> messages(String requestId) => _requests
      .doc(requestId)
      .collection('messages')
      .orderBy('timestamp')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());

  Future<void> sendMessage(
      String requestId, AppUser sender, String text) {
    return _requests.doc(requestId).collection('messages').add({
      'senderId': sender.uid,
      'senderName': sender.name,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------- admin

  Stream<List<AppUser>> unverifiedProviders() => _users
      .where('role', isEqualTo: UserRole.provider.name)
      .where('verified', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());

  Future<void> setVerified(String uid, bool verified) =>
      _users.doc(uid).update({'verified': verified});
}
