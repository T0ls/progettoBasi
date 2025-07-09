<?php
session_start();
require_once "db.php";

if (!isset($_SESSION["ruolo"]) || $_SESSION["ruolo"] !== "manager") {
	header("Location: login.php");
	exit();
}

$msg = $err = "";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
	$azione = $_POST['azione'] ?? '';

	try {
		if ($azione === 'crea') {
			$indirizzo = $_POST['indirizzo'];
			$orari = $_POST['orari'];
			$cf_manager_input = $_POST['cf_manager'] ?: null;

			pg_prepare($conn, "crea_neg", "SELECT crea_negozio($1, $2, $3)");
			$res = pg_execute($conn, "crea_neg", [$orari, $indirizzo, $cf_manager_input]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Negozio creato." : "Errore: $esito";

		} elseif ($azione === 'modifica') {
			$id = $_POST['id'];
			$campo = $_POST['campo'];
			$valore = $_POST['valore'];

			pg_prepare($conn, "modifica_neg", "SELECT modifica_negozio($1, $2, $3)");
			$res = pg_execute($conn, "modifica_neg", [$id, $campo, $valore]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Dato aggiornato." : "Errore: $esito";

		} elseif ($azione === 'elimina') {
			$id = $_POST['id_elimina'];

			pg_prepare($conn, "elimina_neg", "SELECT elimina_negozio($1)");
			$res = pg_execute($conn, "elimina_neg", [$id]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Negozio eliminato." : "Errore: $esito";

		} elseif ($azione === 'aggiungi_prodotto') {
			$id_negozio = $_POST['negozio_prod'];
			$id_prodotto = $_POST['id_prodotto'];
			$prezzo = $_POST['prezzo'];
			$quantita = $_POST['quantita'];

			pg_prepare($conn, "aggiungi_vendita", "SELECT aggiungi_vendita_prodotto($1, $2, $3, $4)");
			$res = pg_execute($conn, "aggiungi_vendita", [$id_negozio, $id_prodotto, $prezzo, $quantita]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Prodotto aggiunto." : "Errore: $esito";

		} elseif ($azione === 'modifica_prodotto_negozio') {
			$id_negozio = $_POST['negozio_mod'];
			$id_prodotto = $_POST['id_prodotto_mod'];
			$campo = $_POST['campo_mod'];
			$valore = $_POST['valore_mod'];

			pg_prepare($conn, "modifica_vendita", "SELECT modifica_vendita_prodotto($1, $2, $3, $4)");
			$res = pg_execute($conn, "modifica_vendita", [$id_negozio, $id_prodotto, $campo, $valore]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Prodotto aggiornato nel negozio." : "Errore: $esito";

		} elseif ($azione === 'rimuovi_prodotto_negozio') {
			$id_negozio = $_POST['negozio_rimuovi'];
			$id_prodotto = $_POST['id_prodotto_rimuovi'];

			pg_prepare($conn, "rimuovi_vendita", "SELECT elimina_vendita_prodotto($1, $2)");
			$res = pg_execute($conn, "rimuovi_vendita", [$id_negozio, $id_prodotto]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Prodotto rimosso dal negozio." : "Errore: $esito";
		}
	} catch (Exception $e) {
		$err = "Errore: " . $e->getMessage();
	}
}

$negozi = pg_query($conn, "SELECT IDNegozio FROM Negozio ORDER BY IDNegozio");
$prodotti = pg_query($conn, "SELECT IDProdotto, Nome FROM Prodotto ORDER BY Nome");
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Gestione Negozi</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
	</head>
	<body class="bg-light">
		<div class="container mt-4">
			<div class="d-flex justify-content-between align-items-center mb-4">
				<h3 class="mb-4">Gestione Negozi</h3>
				<form method="POST" action="logout.php">
					<button type="submit" class="btn btn-danger">Logout</button>
				</form>
			</div>

			<ul class="nav nav-tabs mb-4">
				<li class="nav-item"><a class="nav-link" href="dashboard_manager.php">Dashboard</a></li>
				<li class="nav-item"><a class="nav-link" href="info_negozio.php">Info Negozio</a></li>
				<li class="nav-item"><a class="nav-link" href="saldi_punti.php">Clienti +300 Punti</a></li>
				<li class="nav-item"><a class="nav-link" href="negozi_chiusi.php">Negozi Chiusi</a></li>
				<li class="nav-item"><a class="nav-link" href="ordini_fornitore.php">Ordini Fornitore</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_clienti.php">Gestione Clienti</a></li>
				<li class="nav-item"><a class="nav-link active" href="gestione_negozi.php">Gestione Negozi</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_prodotti.php">Prodotti e Fornitori</a></li>
			</ul>

			<?php if ($msg): ?><div class="alert alert-success"><?= $msg ?></div><?php endif; ?>
			<?php if ($err): ?><div class="alert alert-danger"><?= $err ?></div><?php endif; ?>

			<div class="accordion" id="accordionNegozi">
				<div class="accordion-item">
					<h2 class="accordion-header">
						<button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#modifica">Gestione negozi</button>
					</h2>
					<div id="modifica" class="accordion-collapse show">
						<div class="accordion-body">
							<form method="POST" class="mb-3">
								<!-- Modifica -->
								<h5>Modifica negozio</h5>
								<input type="hidden" name="azione" value="modifica">
								<select name="id" class="form-select mb-2" required>
									<?php while ($n = pg_fetch_assoc($negozi)): ?>
									<option value="<?= $n['idnegozio'] ?>">Negozio #<?= $n['idnegozio'] ?></option>
									<?php endwhile; ?>
								</select>
								<select name="campo" class="form-select mb-2" required>
									<option value="indirizzo">Indirizzo</option>
									<option value="orari">Orari Apertura</option>
									<option value="manager">Manager</option>
								</select>
								<input type="text" name="valore" class="form-control mb-2" placeholder="Nuovo valore" required>
								<button type="submit" class="btn btn-primary">Modifica</button>
							</form>

							<!-- Elimina -->
							<form method="POST">
								<h5>Elimina negozio</h5>
								<input type="hidden" name="azione" value="elimina">
								<input type="number" name="id_elimina" class="form-control mb-2" placeholder="ID negozio da eliminare" required>
								<button type="submit" class="btn btn-danger mb-2">Elimina</button>
							</form>

							<!-- Crea -->
							<form method="POST">
								<h5>Crea negozio</h5>
								<input type="hidden" name="azione" value="crea">
								<input type="text" name="indirizzo" class="form-control mb-2" placeholder="Indirizzo" required>
								<input type="text" name="orari" class="form-control mb-2" placeholder="Orari apertura" required>
								<input type="text" name="cf_manager" class="form-control mb-2" placeholder="Codice Fiscale Manager (opzionale)">
								<button type="submit" class="btn btn-success">Crea negozio</button>
							</form>
						</div>
					</div>
				</div>

				<div class="accordion-item">
					<h2 class="accordion-header">
						<button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#aggiungiProd">Gestisci prodotti in negozio</button>
					</h2>
					<div id="aggiungiProd" class="accordion-collapse collapse">
						<div class="accordion-body">
							<!-- Aggiungi prodotto -->
							<form method="POST" class="mb-4">
								<input type="hidden" name="azione" value="aggiungi_prodotto">
								<h5>Aggiungi prodotto a negozio</h5>
								<div class="mb-2">
									<select name="negozio_prod" class="form-select" required>
										<?php pg_result_seek($negozi, 0); while ($n = pg_fetch_assoc($negozi)): ?>
										<option value="<?= $n['idnegozio'] ?>">Negozio #<?= $n['idnegozio'] ?></option>
										<?php endwhile; ?>
									</select>
								</div>
								<div class="mb-2">
									<select name="id_prodotto" class="form-select" required>
										<?php pg_result_seek($prodotti, 0); while ($p = pg_fetch_assoc($prodotti)): ?>
										<option value="<?= $p['idprodotto'] ?>"><?= $p['nome'] ?></option>
										<?php endwhile; ?>
									</select>
								</div>
								<input type="number" name="prezzo" class="form-control mb-2" step="0.01" placeholder="Prezzo" required>
								<input type="number" name="quantita" class="form-control mb-2" placeholder="Quantità" required>
								<button type="submit" class="btn btn-success">Aggiungi</button>
							</form>

							<!-- Modifica prodotto -->
							<form method="POST" class="mb-4">
								<input type="hidden" name="azione" value="modifica_prodotto_negozio">
								<h5>Modifica prodotto in negozio</h5>
								<div class="mb-2">
									<select name="negozio_mod" class="form-select" required>
										<?php pg_result_seek($negozi, 0); while ($n = pg_fetch_assoc($negozi)): ?>
										<option value="<?= $n['idnegozio'] ?>">Negozio #<?= $n['idnegozio'] ?></option>
										<?php endwhile; ?>
									</select>
								</div>
								<div class="mb-2">
									<select name="id_prodotto_mod" class="form-select" required>
										<?php pg_result_seek($prodotti, 0); while ($p = pg_fetch_assoc($prodotti)): ?>
										<option value="<?= $p['idprodotto'] ?>"><?= $p['nome'] ?></option>
										<?php endwhile; ?>
									</select>
								</div>
								<select name="campo_mod" class="form-select mb-2" required>
									<option value="prezzo">Prezzo</option>
									<option value="quantita">Quantità</option>
								</select>
								<input type="number" step="0.01" name="valore_mod" class="form-control mb-2" placeholder="Nuovo valore" required>
								<button type="submit" class="btn btn-primary">Modifica</button>
							</form>

							<!-- Rimuovi prodotto -->
							<form method="POST">
								<input type="hidden" name="azione" value="rimuovi_prodotto_negozio">
								<h5>Rimuovi prodotto da negozio</h5>
								<div class="mb-2">
									<select name="negozio_rimuovi" class="form-select" required>
										<?php pg_result_seek($negozi, 0); while ($n = pg_fetch_assoc($negozi)): ?>
										<option value="<?= $n['idnegozio'] ?>">Negozio #<?= $n['idnegozio'] ?></option>
										<?php endwhile; ?>
									</select>
								</div>
								<div class="mb-2">
									<select name="id_prodotto_rimuovi" class="form-select" required>
										<?php pg_result_seek($prodotti, 0); while ($p = pg_fetch_assoc($prodotti)): ?>
										<option value="<?= $p['idprodotto'] ?>"><?= $p['nome'] ?></option>
										<?php endwhile; ?>
									</select>
								</div>
								<button type="submit" class="btn btn-danger">Rimuovi</button>
							</form>
						</div>
					</div>
				</div>
			</div>
		</div>
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
