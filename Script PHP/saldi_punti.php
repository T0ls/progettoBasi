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

pg_prepare($conn, "clienti_300_vista", "
	SELECT *
	FROM ClientiConPiuDi300Punti
	ORDER BY SaldoPunti DESC
	");
$result = pg_execute($conn, "clienti_300_vista", []);
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Clienti con +300 punti</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
	</head>
	<body class="bg-light">
		<div class="container mt-4">
			<div class="d-flex justify-content-between align-items-center mb-4">
				<h3 class="mb-4">Clienti con saldo punti superiore a 300</h3>
				<form method="POST" action="logout.php">
					<button type="submit" class="btn btn-danger">Logout</button>
				</form>
			</div>

			<!-- Navbar finta -->
			<ul class="nav nav-tabs mb-4">
				<li class="nav-item"><a class="nav-link" href="dashboard_manager.php">Dashboard</a></li>
				<li class="nav-item"><a class="nav-link" href="info_negozio.php">Info Negozio</a></li>
				<li class="nav-item"><a class="nav-link active" href="saldi_punti.php">Clienti +300 Punti</a></li>
				<li class="nav-item"><a class="nav-link" href="negozi_chiusi.php">Negozi Chiusi</a></li>
				<li class="nav-item"><a class="nav-link" href="ordini_fornitore.php">Ordini Fornitore</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_clienti.php">Gestione Clienti</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_negozi.php">Gestione Negozi</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_prodotti.php">Prodotti e Fornitori</a></li>
			</ul>

			<?php if (pg_num_rows($result) > 0): ?>
			<table class="table table-striped table-bordered">
				<thead>
					<tr>
						<th>CF</th>
						<th>Nome</th>
						<th>ID Tessera</th>
						<th>Saldo Punti</th>
						<th>Data Richiesta</th>
						<th>ID Negozio</th>
					</tr>
				</thead>
				<tbody>
					<?php while ($row = pg_fetch_assoc($result)): ?>
					<tr>
						<td><?= htmlspecialchars($row["codicefiscale"]) ?></td>
						<td><?= htmlspecialchars($row["nomecliente"]) ?></td>
						<td><?= $row["idtessera"] ?></td>
						<td><strong><?= $row["saldopunti"] ?></strong></td>
						<td><?= $row["datarichiesta"] ?></td>
						<td><?= $row["negozioid"] ?></td>
					</tr>
					<?php endwhile; ?>
				</tbody>
			</table>
			<?php else: ?>
			<div class="alert alert-info">Nessun cliente con più di 300 punti al momento.</div>
			<?php endif; ?>
		</div>
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
