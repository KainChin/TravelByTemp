import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // -- Lấy userId hiện tại --
  static String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? 'backend-session-user';

  // --------------------------------
  // TRIPS
  // --------------------------------

  /// T?o trip mới, trả về tripId
  static Future<String> createTrip(String name) async {
    final ref = await _db
        .collection('users')
        .doc(_uid)
        .collection('trips')
        .add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'photoCount': 0,
    });
    return ref.id;
  }

  /// L?y danh sách trips
  static Stream<QuerySnapshot> getTrips() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('trips')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --------------------------------
  // PHOTOS
  // --------------------------------

  /// Luu ?nh (base64) vào trip
  static Future<String> savePhoto({
    required String tripId,
    required String base64Data,
    required String fileName,
  }) async {
    final ref = await _db
        .collection('users')
        .doc(_uid)
        .collection('trips')
        .doc(tripId)
        .collection('photos')
        .add({
      'base64': base64Data,
      'fileName': fileName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Tang photoCount
    await _db
        .collection('users')
        .doc(_uid)
        .collection('trips')
        .doc(tripId)
        .update({'photoCount': FieldValue.increment(1)});

    return ref.id;
  }

  /// L?y danh sách ảnh của trip
  static Stream<QuerySnapshot> getPhotos(String tripId) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('trips')
        .doc(tripId)
        .collection('photos')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // --------------------------------
  // VIDEOS
  // --------------------------------

  /// Luu metadata video sau khi t?o xong
  static Future<void> saveVideoMetadata({
    required String tripId,
    required String tripName,
    required String videoName,
    required String thumbnailBase64,
  }) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('videos')
        .add({
      'tripId': tripId,
      'tripName': tripName,
      'videoName': videoName,
      'thumbnail': thumbnailBase64,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// L?y danh sách videos
  static Stream<QuerySnapshot> getVideos() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

