import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DetailsPage extends StatefulWidget {
  final int id;
  DetailsPage({required this.id});

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late Future<Map<String, dynamic>> praticienInfo;
  late Future<List<Map<String, dynamic>>> praticienNotes;

  @override
  void initState() {
    super.initState();
    praticienNotes = fetchPraticienNotes(widget.id);
    praticienInfo = fetchPraticienInfo(widget.id);
  }

  Future<List<Map<String, dynamic>>> fetchPraticienNotes(int id) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost/apflutter/api/praticiens/$id/notes'),
      );

      // Afficher la réponse brute pour déboguer
      print('Réponse brute de l\'API : ${response.body}');

      if (response.statusCode == 200) {
        // Décoder la réponse JSON
        dynamic data = jsonDecode(response.body);

        // Vérifier si la réponse contient une clé "notes" et si elle est une liste
        if (data is Map && data.containsKey('notes') && data['notes'] is List) {
          return List<Map<String, dynamic>>.from(data['notes']);
        } else {
          throw Exception('Format inattendu des données des notes.');
        }
      } else {
        throw Exception(
          'Erreur HTTP ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erreur fetchPraticienNotes : $e');
    }
  }

  Future<Map<String, dynamic>> fetchPraticienInfo(int id) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost/apflutter/api/praticiens/$id'),
      );

      // Vérifier la longueur de la réponse avant d'utiliser substring
      if (response.body.length > 500) {
        print(
          'Réponse API praticien (partie 500 premiers caractères) : ${response.body.substring(0, 500)}',
        );
      } else {
        print('Réponse API praticien : ${response.body}');
      }

      // Vérifier le statut HTTP
      if (response.statusCode == 200) {
        // Affichage du corps de la réponse pour analyser plus précisément (20 premiers caractères)
        print(
          "Corps de la réponse (20 premiers caractères): ${response.body.substring(0, 20)}",
        );

        dynamic data;
        try {
          // Essayer de parser le corps JSON
          data = jsonDecode(response.body);
        } catch (e) {
          print("Erreur de parsing JSON : $e");
          throw Exception('Erreur de parsing JSON');
        }

        // Vérification si la réponse est un Map (assurez-vous que la réponse est bien un objet)
        if (data is Map<String, dynamic>) {
          // Retourner les informations du praticien
          print("Praticien trouvé : ${data.toString().substring(0, 20)}");
          return data; // Retourne la donnée sous le type attendu
        } else {
          print(
            "Données incorrectes : attendu un Map<String, dynamic>, mais obtenu : ${data.toString().substring(0, 20)}",
          );
          throw Exception('Format inattendu des données du praticien.');
        }
      } else {
        print(
          'Erreur HTTP ${response.statusCode}: ${response.body.substring(0, 20)}',
        );
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur fetchPraticienInfo : $e');
      throw Exception('Erreur fetchPraticienInfo : $e');
    }
  }

  double calculateAverage(List<Map<String, dynamic>> notes) {
    if (notes.isEmpty) return 0.0;
    double sum = notes
        .where((note) => note['note'] != null)
        .fold(0.0, (prev, note) => prev + (note['note']!.toDouble()));
    return sum / notes.length;
  }

  Widget buildNoteCard(
    String title,
    List<Map<String, dynamic>> notes,
    Color color,
  ) {
    return Card(
      elevation: 8,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 15),
            if (notes.isEmpty)
              Text(
                'Aucune note disponible',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ...notes.map(
              (note) => Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${note['nom']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text('Note: ${note['note']} / 5'),
                    SizedBox(height: 5),
                    Text(
                      'Commentaire: ${note['commentaire'] ?? 'Pas de commentaire'}',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du praticien'),
        backgroundColor: Colors.green[800],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: praticienInfo,
        builder: (context, snapshotInfo) {
          if (snapshotInfo.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshotInfo.hasError) {
            return Center(child: Text('Erreur : ${snapshotInfo.error}'));
          } else if (!snapshotInfo.hasData || snapshotInfo.data!.isEmpty) {
            return Center(
              child: Text('Informations du praticien non disponibles.'),
            );
          } else {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: praticienNotes,
              builder: (context, snapshotNotes) {
                if (snapshotNotes.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshotNotes.hasError) {
                  return Center(child: Text('Erreur : ${snapshotNotes.error}'));
                } else if (!snapshotNotes.hasData ||
                    snapshotNotes.data!.isEmpty) {
                  return Center(child: Text('Aucune note trouvée.'));
                } else {
                  List<Map<String, dynamic>> expertNotes =
                      snapshotNotes.data!
                          .where((n) => n['TypeUtilisateur'] == 3)
                          .toList();
                  List<Map<String, dynamic>> clientNotes =
                      snapshotNotes.data!
                          .where((n) => n['TypeUtilisateur'] == 0)
                          .toList();

                  double avgExpert = calculateAverage(expertNotes);
                  double avgClient = calculateAverage(clientNotes);

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      children: [
                        Card(
                          elevation: 8,
                          margin: EdgeInsets.only(bottom: 20),
                          child: ListTile(
                            title: Text(
                              'Praticien : ${snapshotInfo.data!['nom'] ?? 'Nom non disponible'} ${snapshotInfo.data!['prenom'] ?? 'Prénom non disponible'}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Adresse : ${snapshotInfo.data!['adresse'] ?? 'Adresse non disponible'}\nCode Postal : ${snapshotInfo.data!['code_postal'] ?? 'Code postal non disponible'}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        buildNoteCard(
                          'Moyenne Note Experte : ${avgExpert.toStringAsFixed(1)} / 5',
                          expertNotes,
                          Colors.blueAccent,
                        ),
                        SizedBox(height: 20),
                        buildNoteCard(
                          'Moyenne Note Client : ${avgClient.toStringAsFixed(1)} / 5',
                          clientNotes,
                          Colors.green,
                        ),
                      ],
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}
