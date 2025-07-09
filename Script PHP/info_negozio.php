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

pg_prepare($conn, "info_negozio_completa", "
	SELECT IDNegozio, Indirizzo, OrariApertura, Aperto,
	(SELECT COUNT(*) FROM Vende v WHERE v.NegozioID = n.IDNegozio AND v.Quantita > 0) AS NumProdotti,
	(SELECT COUNT(*) FROM Tessera t WHERE t.NegozioID = n.IDNegozio) AS NumTesserati,
	(SELECT COUNT(*) FROM Fattura f WHERE f.NegozioID = n.IDNegozio) AS NumFatture
	FROM Negozio n
	WHERE ManagerCF = $1
	");

$result = pg_execute($conn, "info_negozio_completa", [$cf_manager]);
$negozio = pg_fetch_assoc($result);

$tesserati = $fatture = [];
if ($negozio) {
	$id_negozio = $negozio["idnegozio"];

	pg_prepare($conn, "lista_tesserati_vista", "
		SELECT CodiceFiscale, NomeCliente, IDTessera, SaldoPunti, DataRichiesta
		FROM ListaTesserati
		WHERE IDNegozio = $1
		");
	$tesserati = pg_execute($conn, "lista_tesserati_vista", [$id_negozio]);

	pg_prepare($conn, "fatture_negozio", "
		SELECT IDFattura, ClienteCF, DataAcquisto, ScontoApplicato, TotalePagato
		FROM Fattura
		WHERE NegozioID = $1
		ORDER BY DataAcquisto DESC
		");
	$fatture = pg_execute($conn, "fatture_negozio", [$id_negozio]);
}
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Info Negozio</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
	</head>
	<body class="bg-light">
		<div class="container mt-4">
			<div class="d-flex justify-content-between align-items-center mb-4">
				<h3 class="mb-4">Negozio assegnato a <?= htmlspecialchars($nome) ?></h3>
				<form method="POST" action="logout.php">
					<button type="submit" class="btn btn-danger">Logout</button>
				</form>
			</div>

			<!-- Navbar finta -->
			<ul class="nav nav-tabs mb-4">
				<li class="nav-item"><a class="nav-link" href="dashboard_manager.php">Dashboard</a></li>
				<li class="nav-item"><a class="nav-link active" href="info_negozio.php">Info Negozio</a></li>
				<li class="nav-item"><a class="nav-link" href="saldi_punti.php">Clienti +300 Punti</a></li>
				<li class="nav-item"><a class="nav-link" href="negozi_chiusi.php">Negozi Chiusi</a></li>
				<li class="nav-item"><a class="nav-link" href="ordini_fornitore.php">Ordini Fornitore</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_clienti.php">Gestione Clienti</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_negozi.php">Gestione Negozi</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_prodotti.php">Prodotti e Fornitori</a></li>
			</ul>

			<?php if ($negozio): ?>
			<div class="card mb-4 shadow-sm">
				<div class="card-header">Informazioni Negozio</div>
				<ul class="list-group list-group-flush">
					<li class="list-group-item"><strong>ID:</strong> <?= $negozio["idnegozio"] ?></li>
					<li class="list-group-item"><strong>Indirizzo:</strong> <?= htmlspecialchars($negozio["indirizzo"]) ?></li>
					<li class="list-group-item"><strong>Orari:</strong> <?= htmlspecialchars($negozio["orariapertura"]) ?></li>
					<li class="list-group-item"><strong>Prodotti disponibili:</strong> <?= $negozio["numprodotti"] ?></li>
					<li class="list-group-item"><strong>Numero tesserati:</strong> <?= $negozio["numtesserati"] ?></li>
					<li class="list-group-item"><strong>Fatture emesse:</strong> <?= $negozio["numfatture"] ?></li>
					<li class="list-group-item"><strong>Stato:</strong> <?= $negozio["aperto"] === 't' ? "Aperto" : "Chiuso definitivamente" ?></li>
				</ul>
			</div>

			<!-- Lista tesserati -->
			<div class="accordion mb-4" id="accordionTesserati">
				<div class="accordion-item">
					<h2 class="accordion-header" id="headingTess">
						<button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseTess">
							Lista Tesserati
						</button>
					</h2>
					<div id="collapseTess" class="accordion-collapse collapse">
						<div class="accordion-body">
							<table class="table table-bordered table-sm">
								<thead>
									<tr>
										<th>CF</th>
										<th>Nome</th>
										<th>ID Tessera</th>
										<th>Punti</th>
										<th>Data richiesta</th>
									</tr>
								</thead>
								<tbody>
									<?php while ($row = pg_fetch_assoc($tesserati)): ?>
									<tr>
										<td><?= htmlspecialchars($row["codicefiscale"]) ?></td>
										<td><?= htmlspecialchars($row["nomecliente"]) ?></td>
										<td><?= $row["idtessera"] ?></td>
										<td><?= $row["saldopunti"] ?></td>
										<td><?= $row["datarichiesta"] ?></td>
									</tr>
									<?php endwhile; ?>
								</tbody>
							</table>
						</div>
					</div>
				</div>
			</div>

			<!-- Lista fatture -->
			<div class="accordion" id="accordionFatture">
				<div class="accordion-item">
					<h2 class="accordion-header" id="headingFatt">
						<button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseFatt">
							Fatture emesse dal negozio
						</button>
					</h2>
					<div id="collapseFatt" class="accordion-collapse collapse">
						<div class="accordion-body">
							<table class="table table-bordered table-sm">
								<thead><tr><th>ID</th><th>CF Cliente</th><th>Data</th><th>Sconto %</th><th>Totale</th></tr></thead>
								<tbody>
									<?php while ($row = pg_fetch_assoc($fatture)): ?>
									<tr>
										<td><?= $row["idfattura"] ?></td>
										<td><?= $row["clientecf"] ?></td>
										<td><?= $row["dataacquisto"] ?></td>
										<td><?= (int)$row["scontoapplicato"] ?></td>
										<td>&euro; <?= $row["totalepagato"] ?></td>
									</tr>
									<?php endwhile; ?>
								</tbody>
							</table>
						</div>
					</div>
				</div>
			</div>

			<?php else: ?>
			<div class="alert alert-warning">Nessun negozio assegnato.</div>
			<?php endif; ?>
		</div>
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
