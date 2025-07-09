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

pg_prepare($conn, "negozi_chiusi", "SELECT IDNegozio, Indirizzo FROM Negozio WHERE Aperto = FALSE");

pg_prepare($conn, "fatture_su_negozio", "
	SELECT IDFattura, ClienteCF, DataAcquisto, ScontoApplicato, TotalePagato
	FROM Fattura
	WHERE NegozioID = $1
	ORDER BY DataAcquisto DESC
	");

pg_prepare($conn, "voci_su_fattura", "
	SELECT vf.ProdottoID, p.Nome, vf.PrezzoUnitario, vf.Quantita
	FROM VoceFattura vf
	JOIN Prodotto p ON vf.ProdottoID = p.IDProdotto
	WHERE vf.FatturaID = $1
	");

pg_prepare($conn, "storico_tessere_negozio", "
	SELECT IDTessera, DataRichiesta
	FROM StoricoTessere
	WHERE IndirizzoNegozio = $1
	");

$negozi_data = pg_execute($conn, "negozi_chiusi", []);
$fatture_per_negozio = [];

while ($n = pg_fetch_assoc($negozi_data)) {
	$id = $n["idnegozio"];
	$indirizzo = $n["indirizzo"];

	// Fatture emesse + voci
	$fatture = pg_execute($conn, "fatture_su_negozio", [$id]);
	$fatture_con_voci = [];
	while ($f = pg_fetch_assoc($fatture)) {
		$voci = pg_execute($conn, "voci_su_fattura", [$f["idfattura"]]);
		$f["voci"] = [];
		while ($voce = pg_fetch_assoc($voci)) {
			$f["voci"][] = $voce;
		}
		$fatture_con_voci[] = $f;
	}

	// Tessere
	$tessere = pg_execute($conn, "storico_tessere_negozio", [$indirizzo]);
	$storico_tessere = [];
	while ($t = pg_fetch_assoc($tessere)) {
		$storico_tessere[] = $t;
	}

	$fatture_per_negozio[$id] = [
		"info" => $n,
		"fatture" => $fatture_con_voci,
		"tessere" => $storico_tessere
	];
}
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Negozi Chiusi</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
	</head>
	<body class="bg-light">
		<div class="container mt-4">
			<div class="d-flex justify-content-between align-items-center mb-4">
				<h3 class="mb-4">Negozi Chiusi</h3>
				<form method="POST" action="logout.php">
					<button type="submit" class="btn btn-danger">Logout</button>
				</form>
			</div>

			<ul class="nav nav-tabs mb-4">
				<li class="nav-item"><a class="nav-link" href="dashboard_manager.php">Dashboard</a></li>
				<li class="nav-item"><a class="nav-link" href="info_negozio.php">Info Negozio</a></li>
				<li class="nav-item"><a class="nav-link" href="saldi_punti.php">Clienti +300 Punti</a></li>
				<li class="nav-item"><a class="nav-link active" href="negozi_chiusi.php">Negozi Chiusi</a></li>
				<li class="nav-item"><a class="nav-link" href="ordini_fornitore.php">Ordini Fornitore</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_clienti.php">Gestione Clienti</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_negozi.php">Gestione Negozi</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_prodotti.php">Prodotti e Fornitori</a></li>
			</ul>

			<div class="accordion" id="accordionNegozi">
				<?php if (empty($fatture_per_negozio)): ?>
				<div class="alert alert-info">Nessun negozio è stato chiuso.</div>
				<?php else: ?>
				<?php foreach ($fatture_per_negozio as $id => $dati): ?>

				<div class="accordion-item">
					<h2 class="accordion-header" id="heading<?= $id ?>">
						<button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapse<?= $id ?>">
							Negozio ID <?= $id ?> - <?= htmlspecialchars($dati["info"]["indirizzo"]) ?>
						</button>
					</h2>
					<div id="collapse<?= $id ?>" class="accordion-collapse collapse" data-bs-parent="#accordionNegozi">
						<div class="accordion-body">
							<!-- Storico tessere -->
							<?php if (!empty($dati["tessere"])): ?>
							<h5 class="mb-2">Tessere emesse dal negozio:</h5>
							<ul class="list-group mb-4">
								<?php foreach ($dati["tessere"] as $t): ?>
								<li class="list-group-item">
									Tessera #<?= $t["idtessera"] ?> - Data richiesta: <?= $t["datarichiesta"] ?>
								</li>
								<?php endforeach; ?>
							</ul>
							<?php else: ?>
							<div class="alert alert-secondary">Nessuna tessera storicizzata per questo negozio.</div>
							<?php endif; ?>

							<!-- Fatture -->
							<?php if (!empty($dati["fatture"])): ?>
							<h5 class="mb-2">Fatture emesse dal negozio:</h5>
							<?php foreach ($dati["fatture"] as $f): ?>
							<div class="border rounded p-3 mb-3 bg-light">
								<div><strong>Fattura #<?= $f["idfattura"] ?></strong></div>
								<div>Cliente: <?= $f["clientecf"] ?></div>
								<div>Data: <?= $f["dataacquisto"] ?> - Sconto: <?= (int)$f["scontoapplicato"] ?>% - Totale: €<?= $f["totalepagato"] ?></div>
								<hr>
								<div><strong>Voci fattura:</strong></div>
								<ul class="mb-0">
									<?php foreach ($f["voci"] as $voce): ?>
									<li><?= htmlspecialchars($voce["nome"]) ?> (x<?= $voce["quantita"] ?> @ €<?= $voce["prezzounitario"] ?>)</li>
									<?php endforeach; ?>
								</ul>
							</div>
							<?php endforeach; ?>
							<?php else: ?>
							<div class="alert alert-secondary">Nessuna fattura registrata per questo negozio.</div>
							<?php endif; ?>
						</div>
					</div>
				</div>
				<?php endforeach; ?>
				<?php endif; ?>
			</div>
		</div>
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
