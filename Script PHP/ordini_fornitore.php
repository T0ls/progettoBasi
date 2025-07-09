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

pg_prepare($conn, "elenco_fornitori", "SELECT PIVA, Indirizzo FROM Fornitore ORDER BY PIVA");
$fornitori = pg_execute($conn, "elenco_fornitori", []);

$fatture = [];
$info_fornitore = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['piva'])) {
	$piva = $_POST['piva'];

	pg_prepare($conn, "storico_fornitore_vista", "
		SELECT IDOrdine, NegozioID, ProdottoID, NomeProdotto, DataConsegna, Quantita
		FROM StoricoOrdiniFornitori
		WHERE FornitorePIVA = $1
		ORDER BY DataConsegna DESC
		");
	$fatture = pg_execute($conn, "storico_fornitore_vista", [$piva]);

	pg_prepare($conn, "fornitore_info", "SELECT Indirizzo FROM Fornitore WHERE PIVA = $1");
	$info = pg_execute($conn, "fornitore_info", [$piva]);
	$info_fornitore = pg_fetch_assoc($info);
}
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Ordini Fornitore</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
	</head>
	<body class="bg-light">
		<div class="container mt-4">
			<div class="d-flex justify-content-between align-items-center mb-4">
				<h3 class="mb-4">Ordini a Fornitore</h3>
				<form method="POST" action="logout.php">
					<button type="submit" class="btn btn-danger">Logout</button>
				</form>
			</div>

			<!-- Navbar finta -->
			<ul class="nav nav-tabs mb-4">
				<li class="nav-item"><a class="nav-link" href="dashboard_manager.php">Dashboard</a></li>
				<li class="nav-item"><a class="nav-link" href="info_negozio.php">Info Negozio</a></li>
				<li class="nav-item"><a class="nav-link" href="saldi_punti.php">Clienti +300 Punti</a></li>
				<li class="nav-item"><a class="nav-link" href="negozi_chiusi.php">Negozi Chiusi</a></li>
				<li class="nav-item"><a class="nav-link active" href="ordini_fornitore.php">Ordini Fornitore</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_clienti.php">Gestione Clienti</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_negozi.php">Gestione Negozi</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_prodotti.php">Prodotti e Fornitori</a></li>
			</ul>

			<form method="POST" class="mb-4">
				<div class="row g-3 align-items-center">
					<div class="col-auto">
						<label for="piva" class="col-form-label">Seleziona Fornitore:</label>
					</div>
					<div class="col-auto">
						<select class="form-select" id="piva" name="piva" required>
							<option value="" disabled selected>-- scegli un fornitore --</option>
							<?php while ($f = pg_fetch_assoc($fornitori)): ?>
							<option value="<?= $f['piva'] ?>" <?= isset($piva) && $piva === $f['piva'] ? 'selected' : '' ?>>
								<?= $f['piva'] ?> - <?= htmlspecialchars($f['indirizzo']) ?>
							</option>
							<?php endwhile; ?>
						</select>
					</div>
					<div class="col-auto">
						<button type="submit" class="btn btn-primary">Visualizza ordini</button>
					</div>
				</div>
			</form>

			<?php if ($info_fornitore): ?>
			<div class="card mb-4">
				<div class="card-body">
					<h5 class="card-title">Indirizzo fornitore</h5>
					<p class="card-text"><?= htmlspecialchars($info_fornitore['indirizzo']) ?></p>
				</div>
			</div>
			<?php endif; ?>

			<?php if (!empty($fatture)): ?>
			<table class="table table-bordered table-sm">
				<thead><tr><th>ID Ordine</th><th>ID Negozio</th><th>Prodotto</th><th>Data</th><th>Quantità</th></tr></thead>
				<tbody>
					<?php while ($o = pg_fetch_assoc($fatture)): ?>
					<tr>
						<td><?= $o['idordine'] ?></td>
						<td><?= $o['negozioid'] ?></td>
						<td><?= htmlspecialchars($o['nomeprodotto']) ?> (#<?= $o['prodottoid'] ?>)</td>
						<td><?= $o['dataconsegna'] ?></td>
						<td><?= $o['quantita'] ?></td>
					</tr>
					<?php endwhile; ?>
				</tbody>
			</table>
			<?php elseif ($_SERVER['REQUEST_METHOD'] === 'POST'): ?>
			<div class="alert alert-info">Nessun ordine trovato per questo fornitore.</div>
			<?php endif; ?>

			<div class="mt-5">
				<a href="effettua_ordine.php" class="btn btn-success">Effettua un nuovo ordine</a>
			</div>
		</div>
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
