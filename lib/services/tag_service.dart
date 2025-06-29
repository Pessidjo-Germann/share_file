import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tag.dart';

class TagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Créer un nouveau tag
  Future<String> createTag(String name, String color) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final docRef = await _firestore.collection('tags').add({
        'name': name,
        'color': color,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du tag: $e');
    }
  }

  // Récupérer tous les tags de l'utilisateur
  Stream<List<Tag>> getUserTags() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('tags')
        .where('createdBy', isEqualTo: user.uid)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tag.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Récupérer tous les tags (pour les tags prédéfinis)
  Stream<List<Tag>> getAllTags() {
    return _firestore.collection('tags').orderBy('name').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => Tag.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Supprimer un tag
  Future<void> deleteTag(String tagId) async {
    try {
      await _firestore.collection('tags').doc(tagId).delete();

      // Supprimer ce tag de tous les documents qui l'utilisent
      final documentsWithTag = await _firestore
          .collection('folder')
          .where('tags', arrayContains: tagId)
          .get();

      final batch = _firestore.batch();
      for (var doc in documentsWithTag.docs) {
        batch.update(doc.reference, {
          'tags': FieldValue.arrayRemove([tagId])
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du tag: $e');
    }
  }

  // Mettre à jour un tag
  Future<void> updateTag(String tagId, String name, String color) async {
    try {
      await _firestore.collection('tags').doc(tagId).update({
        'name': name,
        'color': color,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du tag: $e');
    }
  }

  // Ajouter des tags à un document/dossier
  Future<void> addTagsToDocument(String documentId, List<String> tagIds) async {
    try {
      await _firestore.collection('folder').doc(documentId).update({
        'tags': FieldValue.arrayUnion(tagIds),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout des tags: $e');
    }
  }

  // Supprimer des tags d'un document/dossier
  Future<void> removeTagsFromDocument(
      String documentId, List<String> tagIds) async {
    try {
      await _firestore.collection('folder').doc(documentId).update({
        'tags': FieldValue.arrayRemove(tagIds),
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression des tags: $e');
    }
  }

  // Rechercher des documents par tags
  Stream<List<QueryDocumentSnapshot>> getDocumentsByTags(List<String> tagIds) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('folder')
        .where('createdBy', isEqualTo: user.uid)
        .where('tags', arrayContainsAny: tagIds)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Getter pour l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Créer des tags prédéfinis lors de la première utilisation
  Future<void> createDefaultTags() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final defaultTags = [
      {'name': 'Important', 'color': '#F44336'},
      {'name': 'Urgent', 'color': '#FF9800'},
      {'name': 'À traiter', 'color': '#FFC107'},
      {'name': 'Terminé', 'color': '#4CAF50'},
      {'name': 'En cours', 'color': '#2196F3'},
      {'name': 'Archivé', 'color': '#9E9E9E'},
    ];

    for (var tagData in defaultTags) {
      // Vérifier si le tag existe déjà
      final existingTag = await _firestore
          .collection('tags')
          .where('name', isEqualTo: tagData['name'])
          .where('createdBy', isEqualTo: user.uid)
          .get();

      if (existingTag.docs.isEmpty) {
        await createTag(tagData['name']!, tagData['color']!);
      }
    }
  }
}
