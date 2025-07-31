import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../models/document_file.dart';

class DocumentPreviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Récupérer les détails d'un document
  Future<DocumentFile?> getDocumentDetails(
      String folderId, String fileId) async {
    try {
      final doc = await _firestore
          .collection('folder')
          .doc(folderId)
          .collection('files')
          .doc(fileId)
          .get();

      if (doc.exists) {
        return DocumentFile.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du document: $e');
    }
  }

  // Récupérer tous les documents d'un dossier
  Stream<List<DocumentFile>> getFolderDocuments(String folderId) {
    return _firestore
        .collection('folder')
        .doc(folderId)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentFile.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Mettre à jour les métadonnées d'un document
  Future<void> updateDocumentMetadata(
    String folderId,
    String fileId, {
    String? name,
    List<String>? tags,
    String? mimeType,
    int? fileSize,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (tags != null) updates['tags'] = tags;
      if (mimeType != null) updates['mimeType'] = mimeType;
      if (fileSize != null) updates['fileSize'] = fileSize;

      if (updates.isNotEmpty) {
        await _firestore
            .collection('folder')
            .doc(folderId)
            .collection('files')
            .doc(fileId)
            .update(updates);
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // Supprimer un document
  Future<void> deleteDocument(
      String folderId, String fileId, String fileUrl) async {
    try {
      // Supprimer de Firestore
      await _firestore
          .collection('folder')
          .doc(folderId)
          .collection('files')
          .doc(fileId)
          .delete();

      // Supprimer de Supabase Storage
      if (fileUrl.isNotEmpty) {
        try {
          final bucketName = 'files';
          final pathStartIndex =
              fileUrl.indexOf('$bucketName/') + bucketName.length + 1;
          final supabasePath = fileUrl.substring(pathStartIndex);

          await _supabase.storage.from(bucketName).remove([supabasePath]);
        } catch (e) {
          print(
              'Erreur lors de la suppression du fichier de Supabase Storage: $e');
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // Copier le lien du document
  Future<void> copyDocumentLink(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
    } catch (e) {
      throw Exception('Erreur lors de la copie: $e');
    }
  }

  // Vérifier si l'utilisateur peut modifier le document
  bool canEditDocument(DocumentFile document) {
    final currentUser = _auth.currentUser;
    return currentUser != null && document.createdBy == currentUser.uid;
  }

  // Rechercher des documents par nom
  Future<List<DocumentFile>> searchDocuments(String query,
      {String? folderId}) async {
    try {
      if (folderId == null) return [];

      final snapshot = await _firestore
          .collection('folder')
          .doc(folderId)
          .collection('files')
          .get();

      final allDocuments = snapshot.docs
          .map((doc) => DocumentFile.fromFirestore(doc.data(), doc.id))
          .toList();

      // Filtrage côté client par nom
      return allDocuments.where((doc) {
        return doc.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Obtenir les statistiques des documents
  Future<Map<String, dynamic>> getDocumentStatistics(String folderId) async {
    try {
      final snapshot = await _firestore
          .collection('folder')
          .doc(folderId)
          .collection('files')
          .get();

      final documents = snapshot.docs
          .map((doc) => DocumentFile.fromFirestore(doc.data(), doc.id))
          .toList();

      final stats = <String, dynamic>{
        'totalDocuments': documents.length,
        'totalSize': 0,
        'typeBreakdown': <String, int>{},
        'lastUpload': null,
      };

      for (final doc in documents) {
        // Taille totale
        if (doc.fileSize != null) {
          stats['totalSize'] += doc.fileSize!;
        }

        // Répartition par type
        final typeName = doc.documentType.displayName;
        stats['typeBreakdown'][typeName] =
            (stats['typeBreakdown'][typeName] ?? 0) + 1;

        // Dernier upload
        if (stats['lastUpload'] == null ||
            doc.uploadedAt.isAfter(stats['lastUpload'])) {
          stats['lastUpload'] = doc.uploadedAt;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }
}
