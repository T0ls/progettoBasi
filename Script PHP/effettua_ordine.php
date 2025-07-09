<?php
session_start();
require_once "db.php";

if (!isset($_SESSION["ruolo"]) || $_SESSION["ruolo"] !== "manager") {
	header("Location: login.php");
	exit();
}

$esito = null;
$errore = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
	$id_negozio = $_POST['negozio'] ?? null;
	$id_prodotto = $_POST['prodotto'] ?? null;
	$quantita = $_POST['quantita'] ?? null;

	if (is_numeric($id_negozio) && is_numeric($id_prodotto) && is_numeric($quantita) && $quantita > 0) {
		try {
			pg_prepare($conn, "esegui_ordine", "SELECT effettua_ordine($1, $2, $3)");
			$result = pg_execute($conn, "esegui_ordine", [$id_negozio, $id_prodotto, $quantita]);
			$esito_funzione = pg_fetch_result($result, 0, 0);

			switch ($esito_funzione) {
				case 'OK':
					$esito = "Ordine effettuato con successo.";
					break;
				case 'NEGOZIO_CHIUSO':
					$errore = "Impossibile effettuare l'ordine: il negozio selezionato è chiuso.";
					break;
				case 'NESSUN_FORNITORE_DISPONIBILE':
					$errore = "Nessun fornitore ha disponibilità sufficiente per il prodotto selezionato.";
					break;
				case 'NEGOZIO_NOT_FOUND':
					$errore = "Errore: negozio non trovato.";
					break;
				default:
					$errore = "Errore imprevisto: " . htmlspecialchars($esito_funzione);
			}
		} catch (Exception $e) {
			$errore = "Errore: " . $e->getMessage();
		}
	}
}

$negozi = pg_query($conn, "SELECT IDNegozio, Indirizzo FROM Negozio ORDER BY IDNegozio");
$prodotti = pg_query($conn, "SELECT IDProdotto, Nome FROM Prodotto ORDER BY Nome");
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Effettua Ordine</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
	</head>
	<body class="bg-light">
		<div class="container mt-4">
			<div class="d-flex justify-content-between align-items-center mb-4">
				<h3 class="mb-4">Effettua un nuovo ordine</h3>
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

			<?php if ($esito): ?><div class="alert alert-success"><?= $esito ?></div><?php endif; ?>
			<?php if ($errore): ?><div class="alert alert-danger"><?= $errore ?></div><?php endif; ?>

			<form method="POST" class="card p-4 shadow-sm mb-4">
				<div class="mb-3">
					<label for="negozio" class="form-label">Negozio</label>
					<select name="negozio" id="negozio" class="form-select" required>
						<option disabled selected value="">-- seleziona un negozio --</option>
						<?php while ($n = pg_fetch_assoc($negozi)): ?>
						<option value="<?= $n['idnegozio'] ?>">
							#<?= $n['idnegozio'] ?> - <?= htmlspecialchars($n['indirizzo']) ?>
						</option>
						<?php endwhile; ?>
					</select>
				</div>

				<div class="mb-3">
					<label for="prodotto" class="form-label">Prodotto</label>
					<select name="prodotto" id="prodotto" class="form-select" required>
						<option disabled selected value="">-- seleziona un prodotto --</option>
						<?php while ($p = pg_fetch_assoc($prodotti)): ?>
						<option value="<?= $p['idprodotto'] ?>">
							<?= htmlspecialchars($p['nome']) ?> (#<?= $p['idprodotto'] ?>)
						</option>
						<?php endwhile; ?>
					</select>
				</div>

				<div class="mb-3">
					<label for="quantita" class="form-label">Quantità</label>
					<input type="number" name="quantita" id="quantita" class="form-control" min="1" required>
				</div>

				<button type="submit" class="btn btn-success">Conferma Ordine</button>
			</form>

			<a href="ordini_fornitore.php" class="btn btn-secondary">Torna agli ordini</a>
		</div>
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
