import 'package:cloud_firestore/cloud_firestore.dart';

class NodeItem {
  String? id;
  String services;
  String? cpu;
  String? location;
  String? ram;
  String? deviceSDR;
  double? progress;

  NodeItem({
    this.id,
    this.services = '',
    this.cpu,
    this.location,
    this.ram,
    this.deviceSDR,
    this.progress,
  });
  factory NodeItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return NodeItem(
      id: doc.id,
      deviceSDR: data['SDRDevice'] ?? '',
      services: data['SDRService'] ?? '',
      progress: 0.0,
      cpu: data['RaspStorage'] ?? '',
      ram: data['RaspRam'] ?? '',
      location: data['NodeLocation'] ?? '',
    );
  }
}
