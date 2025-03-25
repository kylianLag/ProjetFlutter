<?php
$host = "localhost";
$user = "admin";
$password = "admin";
$database = "ara";

$conn = new mysqli($host, $user, $password, $database);

if ($conn->connect_error) {
    die("Erreur de connexion : " . $conn->connect_error);
}

$sql = "SELECT * FROM praticien";
$result = $conn->query($sql);

$praticien = [];
while ($row = $result->fetch_assoc()) {
    $praticien[] = $row;
}

echo json_encode($praticien);
?>
