<?php
session_start();
require_once "db.php";

if (!isset($_SESSION["ruolo"]) || $_SESSION["ruolo"] !== "manager") {
	header("Location: login.php");
	exit();
}

$username = $_SESSION["username"];
$cf_manager = $_SESSION["codice_fiscale"];
$nome = $_SESSION["nome"];

pg_prepare($conn, "negozio_info", "SELECT IDNegozio, Indirizzo FROM Negozio WHERE ManagerCF = $1");
$negozio = pg_execute($conn, "negozio_info", [$cf_manager]);
$info_negozio = pg_fetch_assoc($negozio);
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Dashboard Manager</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
	</head>
	<body class="bg-light">
		<div class="container mt-4">
			<div class="d-flex justify-content-between align-items-center mb-4">
				<h3>Benvenuto, <?= htmlspecialchars($nome) ?></h3>
				<form method="POST" action="logout.php">
					<button type="submit" class="btn btn-danger">Logout</button>
				</form>
			</div>

			<!-- Navbar finta -->
			<ul class="nav nav-tabs mb-4">
				<li class="nav-item">
					<a class="nav-link active" href="dashboard_manager.php">Dashboard</a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="info_negozio.php">Info Negozio</a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="saldi_punti.php">Clienti +300 Punti</a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="negozi_chiusi.php">Negozi Chiusi</a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="ordini_fornitore.php">Ordini Fornitore</a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="gestione_clienti.php">Gestione Clienti</a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="gestione_negozi.php">Gestione Negozi</a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="gestione_prodotti.php">Prodotti e Fornitori</a>
				</li>
			</ul>

			<!-- Dati Manager -->
			<div class="card shadow-sm mb-4">
				<div class="card-header">I tuoi dati</div>
				<div class="card-body">
					<ul class="list-group">
						<li class="list-group-item"><strong>Nome:</strong> <?= htmlspecialchars($nome) ?></li>
						<li class="list-group-item"><strong>Codice Fiscale:</strong> <?= htmlspecialchars($cf_manager) ?></li>
						<li class="list-group-item"><strong>Username:</strong> <?= htmlspecialchars($username) ?></li>
						<li class="list-group-item">
							<strong>Password:</strong> ********
							<a href="modifica_password.php" class="btn btn-sm btn-outline-primary ms-2">Modifica</a>
						</li>
					</ul>
				</div>
			</div>

			<!-- Dati Negozio Assegnato -->
			<?php if ($info_negozio): ?>
			<div class="card shadow-sm">
				<div class="card-header">Negozio Assegnato</div>
				<div class="card-body">
					<ul class="list-group">
						<li class="list-group-item"><strong>ID Negozio:</strong> <?= $info_negozio["idnegozio"] ?></li>
						<li class="list-group-item"><strong>Indirizzo:</strong> <?= htmlspecialchars($info_negozio["indirizzo"]) ?></li>
					</ul>
				</div>
			</div>
			<?php else: ?>
			<div class="alert alert-warning">Non sei ancora assegnato a nessun negozio.</div>
			<?php endif; ?>
		</div>

		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
