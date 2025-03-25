<?php
// Connexion à la base de données avec les paramètres d'hôte, utilisateur, mot de passe et base de données
$mysqli = new mysqli("localhost", "root", "", "ara");

// Vérification de la connexion à la base de données
if ($mysqli->connect_error) {
    // Si la connexion échoue, afficher une erreur et arrêter le script
    die("Échec de la connexion : " . $mysqli->connect_error);
}

// Récupération de la méthode HTTP utilisée (GET, POST, etc.)
$request_method = $_SERVER['REQUEST_METHOD'];

// Récupération de l'URL complète de la requête
$request_uri = $_SERVER['REQUEST_URI'];

// Séparation de l'URL en segments pour extraire les paramètres comme les IDs
$uri_segments = explode('/', $request_uri);

// Récupérer l'ID du praticien à partir des segments d'URL si disponible
$praticien_id = isset($uri_segments[2]) ? $uri_segments[2] : null;
// Récupérer l'ID de la note à partir des segments d'URL si disponible
$note_id = isset($uri_segments[4]) ? $uri_segments[4] : null;

// Début du traitement des routes et des méthodes HTTP

// Route pour récupérer les détails d'un praticien spécifique
if (preg_match('/^\/apflutter\/api\/praticiens\/(\d+)$/', $request_uri, $matches)) {
    // Si la méthode HTTP est GET
    if ($request_method == 'GET') {
        // L'ID du praticien est extrait de l'URL
        $praticien_id = $matches[1];

        // Vérification que l'ID du praticien est un entier valide
        if (!filter_var($praticien_id, FILTER_VALIDATE_INT)) {
            // Si l'ID n'est pas valide, renvoyer une erreur
            echo json_encode(['error' => 'ID du praticien invalide']);
            exit;
        }

        // Requête SQL pour récupérer les informations détaillées d'un praticien par son ID
        $sqlInfo = "
            SELECT praticien.id, praticien.nom, praticien.prenom, praticien.adresse, ville.code_postal
            FROM praticien 
            JOIN ville ON praticien.id_ville = ville.id
            WHERE praticien.id = ?
        ";

        // Préparer la requête SQL
        $stmtInfo = $mysqli->prepare($sqlInfo);
        // Lier l'ID du praticien à la requête
        $stmtInfo->bind_param("i", $praticien_id);
        // Exécuter la requête
        $stmtInfo->execute();
        // Récupérer le résultat de la requête
        $resultInfo = $stmtInfo->get_result();
        // Extraire les données du praticien
        $praticienInfo = $resultInfo->fetch_assoc();

        // Vérification si un praticien a été trouvé
        if ($praticienInfo) {
            // Si trouvé, renvoyer les informations en format JSON
            echo json_encode($praticienInfo);
        } else {
            // Si le praticien n'est pas trouvé, renvoyer une erreur
            echo json_encode(['error' => 'Praticien non trouvé']);
        }

        // Fermer la préparation de la requête
        $stmtInfo->close();
    }
}

// Route pour récupérer les notes d'un praticien spécifique
else if (preg_match('/^\/apflutter\/api\/praticiens\/(\d+)\/notes$/', $request_uri, $matches)) {
    // Si la méthode HTTP est GET
    if ($request_method == 'GET') {
        // L'ID du praticien est extrait de l'URL
        $praticien_id = $matches[1];

        // Vérification que l'ID du praticien est un entier valide
        if (!filter_var($praticien_id, FILTER_VALIDATE_INT)) {
            // Si l'ID n'est pas valide, renvoyer une erreur
            echo json_encode(['error' => 'ID du praticien invalide']);
            exit;
        }

        // Requête SQL pour récupérer les notes associées à un praticien
        $sqlNotes = "
            SELECT note.idNote, note.note, note.commentaire, utilisateur.nom , utilisateur.TypeUtilisateur
            FROM note 
            JOIN utilisateur ON note.idUtilisateur = utilisateur.id
            WHERE note.idPraticien = ?
        ";

        // Préparer la requête SQL
        $stmtNotes = $mysqli->prepare($sqlNotes);
        // Lier l'ID du praticien à la requête
        $stmtNotes->bind_param("i", $praticien_id);
        // Exécuter la requête
        $stmtNotes->execute();
        // Récupérer le résultat de la requête
        $resultNotes = $stmtNotes->get_result();
        // Initialiser un tableau pour stocker les notes
        $notes = [];
        // Boucler pour extraire chaque note et l'ajouter au tableau
        while ($row = $resultNotes->fetch_assoc()) {
            $notes[] = $row;
        }

        // Renvoyer les notes sous forme JSON
        echo json_encode(['notes' => $notes]);
        // Fermer la préparation de la requête
        $stmtNotes->close();
    }
} 

// Route pour récupérer la liste de tous les praticiens avec tri par moyenne de notes
else if (preg_match('/^\/apflutter\/api\/praticiens/', $request_uri)) {
    // Si la méthode HTTP est GET
    if ($request_method == 'GET') {
        // Récupérer l'ordre de tri des résultats (par défaut "ASC" si non défini)
        $order = isset($_GET['order']) ? $_GET['order'] : 'ASC';
        // Liste des valeurs d'ordre autorisées (ASC ou DESC)
        $allowed_order = ['ASC', 'DESC'];
        // Si la valeur d'ordre n'est pas valide, utiliser la valeur par défaut "ASC"
        if (!in_array($order, $allowed_order)) {
            $order = 'ASC';
        }

        // Requête SQL pour récupérer tous les praticiens triés par la moyenne de leurs notes
        $sql = "
            SELECT praticien.id, praticien.nom, praticien.prenom, 
                COALESCE(SUM(note.note) / NULLIF(COUNT(note.note), 0), 0) AS moyenne 
            FROM praticien 
            LEFT JOIN note ON praticien.id = note.idPraticien 
            GROUP BY praticien.id, praticien.nom, praticien.prenom 
            ORDER BY moyenne $order
        ";

        // Préparer la requête SQL
        $stmt = $mysqli->prepare($sql);
        // Si la préparation échoue, renvoyer une erreur
        if (!$stmt) {
            echo json_encode(['error' => 'Erreur dans la préparation de la requête']);
            exit;
        }

        // Exécuter la requête
        $stmt->execute();
        // Récupérer le résultat de la requête
        $result = $stmt->get_result();
        // Initialiser un tableau pour stocker les praticiens
        $praticiens = [];
        // Boucler pour extraire chaque praticien et l'ajouter au tableau
        while ($row = $result->fetch_assoc()) {
            $praticiens[] = $row;
        }

        // Renvoyer la liste des praticiens sous forme JSON
        echo json_encode($praticiens);
        // Fermer la préparation de la requête
        $stmt->close();
    }
}

// Si aucune des routes ci-dessus ne correspond, afficher une erreur 404
else {
    echo json_encode(['error' => 'Route non trouvée']);
}

// Fermer la connexion à la base de données
$mysqli->close();
?>
