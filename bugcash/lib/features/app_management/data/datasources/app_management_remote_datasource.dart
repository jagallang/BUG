import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/provider_app_model.dart';
import '../../../../core/utils/logger.dart';

abstract class AppManagementRemoteDataSource {
  Stream<List<ProviderAppModel>> getProviderApps(String providerId);
  Future<String> createApp(ProviderAppModel app);
  Future<void> updateApp(ProviderAppModel app);
  Future<void> deleteApp(String appId);
  Future<ProviderAppModel?> getAppById(String appId);
  Future<bool> verifyProviderCredentials(String email, String password);
}

class AppManagementRemoteDataSourceImpl implements AppManagementRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Stream<List<ProviderAppModel>> getProviderApps(String providerId) {
    return _firestore
        .collection('projects')
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => ProviderAppModel.fromFirestore(doc))
              .toList();
          // Client-side sorting for index optimization
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        })
        .handleError((error) {
          // Retry without orderBy if index error occurs
          AppLogger.error('Firestore index error, retrying without orderBy', error.toString());
          return _firestore
              .collection('projects')
              .where('providerId', isEqualTo: providerId)
              .snapshots()
              .map((snapshot) {
                final docs = snapshot.docs
                    .map((doc) => ProviderAppModel.fromFirestore(doc))
                    .toList();
                docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return docs;
              });
        });
  }

  @override
  Future<String> createApp(ProviderAppModel app) async {
    try {
      final docRef = await _firestore.collection('projects').add(app.toFirestore());
      AppLogger.info('App created successfully with ID: ${docRef.id}', 'AppManagementDataSource');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create app', 'AppManagementDataSource', e);
      rethrow;
    }
  }

  @override
  Future<void> updateApp(ProviderAppModel app) async {
    try {
      await _firestore.collection('projects').doc(app.id).update(app.toFirestore());
      AppLogger.info('App updated successfully: ${app.id}', 'AppManagementDataSource');
    } catch (e) {
      AppLogger.error('Failed to update app: ${app.id}', 'AppManagementDataSource', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteApp(String appId) async {
    try {
      await _firestore.collection('projects').doc(appId).delete();
      AppLogger.info('App deleted successfully: $appId', 'AppManagementDataSource');
    } catch (e) {
      AppLogger.error('Failed to delete app: $appId', 'AppManagementDataSource', e);
      rethrow;
    }
  }

  @override
  Future<ProviderAppModel?> getAppById(String appId) async {
    try {
      final doc = await _firestore.collection('projects').doc(appId).get();
      if (doc.exists) {
        return ProviderAppModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get app by ID: $appId', 'AppManagementDataSource', e);
      rethrow;
    }
  }

  @override
  Future<bool> verifyProviderCredentials(String email, String password) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email != email) {
        return false;
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await currentUser.reauthenticateWithCredential(credential);

      AppLogger.info('Provider credentials verified successfully', 'AppManagementDataSource');
      return true;
    } catch (e) {
      AppLogger.error('Failed to verify provider credentials', 'AppManagementDataSource', e);
      return false;
    }
  }
}