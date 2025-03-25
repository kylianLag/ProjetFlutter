import 'dart:convert';

import 'package:apflutter/DetailsPage.dart'; // Importation de la page de détails
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note Praticien',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> praticiens = [];
  bool isAscending = true;
  bool isLoading = true;

  // Fonction pour récupérer la liste des praticiens depuis l'API
  Future<void> fetchPraticiens({bool ascending = true}) async {
    setState(() {
      isLoading = true; // Début du chargement
    });

    try {
      // Mise à jour de l'URL pour l'API RESTful avec le paramètre de tri
      final response = await http.get(
        Uri.parse(
          'http://localhost/apflutter/api/praticiens?order=${ascending ? 'ASC' : 'DESC'}', // Remplacez par 10.0.2.2 pour émulateur
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          praticiens =
              data
                  .map(
                    (row) => {
                      'id': row['id'],
                      'nom': row['nom'],
                      'prenom': row['prenom'],
                      'moyenne':
                          double.tryParse(
                            row['moyenne'].toString(),
                          )?.toStringAsFixed(1) ??
                          '0.0',
                    },
                  )
                  .toList();
        });
      } else {
        throw Exception('Erreur de chargement');
      }
    } catch (e) {
      print("Erreur : $e");
    } finally {
      setState(() {
        isLoading = false; // Fin du chargement
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPraticiens(); // Appel initial pour récupérer la liste des praticiens
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Liste des Praticiens')),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isAscending = true;
                      fetchPraticiens(ascending: true);
                    });
                  },
                  child: Text('Trier Croissant'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isAscending = false;
                      fetchPraticiens(ascending: false);
                    });
                  },
                  child: Text('Trier Décroissant'),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : praticiens.isEmpty
                    ? Center(child: Text('Aucun praticien trouvé'))
                    : ListView.builder(
                      itemCount: praticiens.length,
                      itemBuilder: (context, index) {
                        var praticien = praticiens[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: EdgeInsets.all(10),
                          child: ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  praticien['moyenne'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  Icons.star,
                                  color: Colors.yellow,
                                  size: 24,
                                ),
                              ],
                            ),
                            title: Text(
                              '${praticien['nom']} ${praticien['prenom']}',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                // Vérifier si l'ID est déjà un entier ou une chaîne
                                var id = praticien['id'];
                                if (id is String) {
                                  // Si l'ID est une chaîne, le convertir en entier
                                  id = int.parse(id);
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailsPage(id: id),
                                  ),
                                );
                              },
                              child: Text('Détails'),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
