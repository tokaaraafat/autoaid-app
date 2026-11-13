import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

LatLng? _toLatLng(dynamic v) =>
    v is GeoPoint ? LatLng(v.latitude, v.longitude) : null;
GeoPoint? _toGeoPoint(LatLng? p) =>
    p == null ? null : GeoPoint(p.latitude, p.longitude);

enum UserRole { customer, provider, admin }

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.verified = false,
    this.available = false,
    this.rating = 0,
    this.ratingCount = 0,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final bool verified;
  final bool available;
  final double rating;
  final int ratingCount;

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        role: UserRole.values.firstWhere((r) => r.name == m['role'],
            orElse: () => UserRole.customer),
        verified: m['verified'] ?? false,
        available: m['available'] ?? false,
        rating: ((m['rating'] ?? 0) as num).toDouble(),
        ratingCount: ((m['ratingCount'] ?? 0) as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'verified': verified,
        'available': available,
        'rating': rating,
        'ratingCount': ratingCount,
      };
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.model,
    required this.licensePlate,
    this.insuranceInfo = '',
    this.registrationInfo = '',
  });

  final String id;
  final String model;
  final String licensePlate;
  final String insuranceInfo;
  final String registrationInfo;

  String get summary => '$model ($licensePlate)';

  factory Vehicle.fromMap(String id, Map<String, dynamic> m) => Vehicle(
        id: id,
        model: m['model'] ?? '',
        licensePlate: m['licensePlate'] ?? '',
        insuranceInfo: m['insuranceInfo'] ?? '',
        registrationInfo: m['registrationInfo'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'model': model,
        'licensePlate': licensePlate,
        'insuranceInfo': insuranceInfo,
        'registrationInfo': registrationInfo,
      };
}

enum RequestStatus { pending, accepted, onTheWay, arrived, completed, cancelled }

extension RequestStatusX on RequestStatus {
  String get label => switch (this) {
        RequestStatus.pending => 'Waiting for a provider',
        RequestStatus.accepted => 'Provider accepted',
        RequestStatus.onTheWay => 'Provider is on the way',
        RequestStatus.arrived => 'Provider arrived',
        RequestStatus.completed => 'Completed',
        RequestStatus.cancelled => 'Cancelled',
      };

  /// Request is still in progress.
  bool get isActive =>
      this == RequestStatus.pending ||
      this == RequestStatus.accepted ||
      this == RequestStatus.onTheWay ||
      this == RequestStatus.arrived;

  /// Customer may still cancel.
  bool get canCancel =>
      this == RequestStatus.pending ||
      this == RequestStatus.accepted ||
      this == RequestStatus.onTheWay;

  Color get color => switch (this) {
        RequestStatus.pending => Colors.orange,
        RequestStatus.accepted => Colors.blue,
        RequestStatus.onTheWay => Colors.indigo,
        RequestStatus.arrived => Colors.teal,
        RequestStatus.completed => Colors.green,
        RequestStatus.cancelled => Colors.grey,
      };
}

class AssistanceRequest {
  const AssistanceRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.type,
    required this.description,
    required this.severity,
    required this.location,
    required this.vehicle,
    required this.isAccident,
    required this.status,
    required this.price,
    required this.createdAt,
    this.providerId,
    this.providerName,
    this.providerPhone,
    this.providerLocation,
    this.paymentMethod,
    this.paid = false,
    this.rated = false,
    this.rating,
    this.feedback,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String type;
  final String description;
  final String severity;
  final LatLng location;
  final String vehicle;
  final bool isAccident;
  final RequestStatus status;
  final int price;
  final DateTime createdAt;
  final String? providerId;
  final String? providerName;
  final String? providerPhone;
  final LatLng? providerLocation;
  final String? paymentMethod;
  final bool paid;
  final bool rated;
  final int? rating;
  final String? feedback;

  factory AssistanceRequest.fromMap(String id, Map<String, dynamic> m) {
    final created = m['createdAt'];
    return AssistanceRequest(
      id: id,
      customerId: m['customerId'] ?? '',
      customerName: m['customerName'] ?? '',
      customerPhone: m['customerPhone'] ?? '',
      type: m['type'] ?? 'towing',
      description: m['description'] ?? '',
      severity: m['severity'] ?? 'medium',
      location: _toLatLng(m['location']) ?? const LatLng(0, 0),
      vehicle: m['vehicle'] ?? '',
      isAccident: m['isAccident'] ?? false,
      status: RequestStatus.values.firstWhere((s) => s.name == m['status'],
          orElse: () => RequestStatus.pending),
      price: ((m['price'] ?? 0) as num).toInt(),
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      providerId: m['providerId'],
      providerName: m['providerName'],
      providerPhone: m['providerPhone'],
      providerLocation: _toLatLng(m['providerLocation']),
      paymentMethod: m['paymentMethod'],
      paid: m['paid'] ?? false,
      rated: m['rated'] ?? false,
      rating: (m['rating'] as num?)?.toInt(),
      feedback: m['feedback'],
    );
  }

  /// Fields written when the customer creates the request.
  Map<String, dynamic> toCreateMap() => {
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'type': type,
        'description': description,
        'severity': severity,
        'location': _toGeoPoint(location),
        'vehicle': vehicle,
        'isAccident': isAccident,
        'status': RequestStatus.pending.name,
        'providerId': null, // always present so security rules can read it
        'price': price,
        'paid': false,
        'rated': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> m) {
    final t = m['timestamp'];
    return ChatMessage(
      id: id,
      senderId: m['senderId'] ?? '',
      senderName: m['senderName'] ?? '',
      text: m['text'] ?? '',
      timestamp: t is Timestamp ? t.toDate() : DateTime.now(),
    );
  }
}
