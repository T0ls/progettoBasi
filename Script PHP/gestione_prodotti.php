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
		if ($azione === 'crea_prodotto') {
			$nome = $_POST['nome'];
			$desc = $_POST['descrizione'];
			$res = pg_query_params($conn, "SELECT crea_prodotto($1, $2)", [$nome, $desc]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Prodotto creato." : "Errore: $esito";

		} elseif ($azione === 'modifica_prodotto') {
			$id = $_POST['id_prodotto'];
			$campo = $_POST['campo'];
			$valore = $_POST['valore'];
			$res = pg_query_params($conn, "SELECT modifica_prodotto($1, $2, $3)", [$id, $campo, $valore]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Modificato." : "Errore: $esito";

		} elseif ($azione === 'elimina_prodotto') {
			$id = $_POST['id_elimina'];
			$res = pg_query_params($conn, "SELECT elimina_prodotto($1)", [$id]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Prodotto eliminato." : "Errore: $esito";

		} elseif ($azione === 'crea_fornitore') {
			$piva = $_POST['piva'];
			$indirizzo = $_POST['indirizzo_f'];
			$res = pg_query_params($conn, "SELECT crea_fornitore($1, $2)", [$piva, $indirizzo]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Fornitore creato." : "Errore: $esito";

		} elseif ($azione === 'elimina_fornitore') {
			$piva = $_POST['piva_elimina'];
			$res = pg_query_params($conn, "SELECT elimina_fornitore($1)", [$piva]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Fornitore eliminato." : "Errore: $esito";
		} elseif ($azione === 'modifica_fornitore') {
			$piva = $_POST['piva_modifica'];
			$campo = $_POST['campo_f'];
			$valore = $_POST['valore_f'];
			$res = pg_query_params($conn, "SELECT modifica_fornitore($1, $2, $3)", [$piva, $campo, $valore]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Fornitore modificato." : "Errore: $esito";
		} elseif ($azione === 'crea_fornitura') {
			$piva = $_POST['piva_f'];
			$prodotto = $_POST['id_prodotto_f'];
			$prezzo = $_POST['prezzo_f'];
			$disp = $_POST['disponibilita_f'];
			$res = pg_query_params($conn, "SELECT aggiungi_fornitura($1, $2, $3, $4)", [$piva, $prodotto, $prezzo, $disp]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Fornitura creata." : "Errore: $esito";
		} elseif ($azione === 'elimina_fornitura') {
			$piva = $_POST['piva_elimina_f'];
			$prodotto = $_POST['id_prodotto_elimina_f'];
			$res = pg_query_params($conn, "SELECT elimina_fornitura($1, $2)", [$piva, $prodotto]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Fornitura eliminata." : "Errore: $esito";

		} elseif ($azione === 'modifica_fornitura') {
			$piva = $_POST['piva_modifica_f'];
			$prodotto = $_POST['id_prodotto_modifica_f'];
			$campo = $_POST['campo_forn'];
			$valore = $_POST['valore_modifica_f'];
			$res = pg_query_params($conn, "SELECT modifica_fornitura($1, $2, $3, $4)", [$piva, $prodotto, $campo, $valore]);
			$esito = pg_fetch_result($res, 0, 0);
			$msg = ($esito === 'OK') ? "Fornitura modificata." : "Errore: $esito";
		}
	} catch (Exception $e) {
		$err = "Errore: " . $e->getMessage();
	}
}

$prodotti = pg_query($conn, "SELECT IDProdotto FROM Prodotto ORDER BY IDProdotto");
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Gestione Prodotti e Fornitori</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
	</head>
	<body class="bg-light">
		<div class="container mt-4">
			<div class="d-flex justify-content-between align-items-center mb-4">
				<h3 class="mb-4">Gestione Prodotti e Fornitori</h3>
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
				<li class="nav-item"><a class="nav-link" href="gestione_negozi.php">Gestione Negozi</a></li>
				<li class="nav-item"><a class="nav-link active" href="gestione_prodotti.php">Prodotti e Fornitori</a></li>
			</ul>

			<?php if ($msg): ?><div class="alert alert-success"><?= $msg ?></div><?php endif; ?>
			<?php if ($err): ?><div class="alert alert-danger"><?= $err ?></div><?php endif; ?>

			<div class="accordion" id="accordionProdotti">
				<!-- Prodotti -->
				<div class="accordion-item">
					<h2 class="accordion-header">
						<button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#prodotti">Prodotti</button>
					</h2>
					<div id="prodotti" class="accordion-collapse collapse show">
						<div class="accordion-body">
							<h5>Crea negozio</h5>
							<!-- Crea -->
							<form method="POST" class="mb-3">
								<input type="hidden" name="azione" value="crea_prodotto">
								<input type="text" name="nome" class="form-control mb-2" placeholder="Nome prodotto" required>
								<input type="text" name="descrizione" class="form-control mb-2" placeholder="Descrizione">
								<button type="submit" class="btn btn-success">Crea prodotto</button>
							</form>

							<!-- Elimina -->
							<form method="POST">
								<h5>Elimina negozio</h5>
								<input type="hidden" name="azione" value="elimina_prodotto">
								<input type="number" name="id_elimina" class="form-control mb-2" placeholder="ID prodotto da eliminare" required>
								<button type="submit" class="btn btn-danger">Elimina prodotto</button>
							</form>

							<!-- Modifica -->
							<form method="POST" class="mb-3">
								<h5>Modifica negozio</h5>
								<input type="hidden" name="azione" value="modifica_prodotto">
								<select name="id_prodotto" class="form-select mb-2" required>
									<?php while ($p = pg_fetch_assoc($prodotti)): ?>
									<option value="<?= $p['idprodotto'] ?>">ID #<?= $p['idprodotto'] ?></option>
									<?php endwhile; ?>
								</select>
								<select name="campo" class="form-select mb-2" required>
									<option value="nome">Nome</option>
									<option value="descrizione">Descrizione</option>
								</select>
								<input type="text" name="valore" class="form-control mb-2" placeholder="Nuovo valore" required>
								<button type="submit" class="btn btn-primary">Modifica prodotto</button>
							</form>
						</div>
					</div>
				</div>

				<!-- Fornitori -->
				<div class="accordion-item">
					<h2 class="accordion-header">
						<button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#fornitori">Fornitori</button>
					</h2>
					<div id="fornitori" class="accordion-collapse collapse">
						<div class="accordion-body">
							<!-- Crea -->
							<form method="POST" class="mb-3">
								<h5>Crea fornitore</h5>
								<input type="hidden" name="azione" value="crea_fornitore">
								<input type="text" name="piva" class="form-control mb-2" placeholder="P.IVA" required>
								<input type="text" name="indirizzo_f" class="form-control mb-2" placeholder="Indirizzo" required>
								<button type="submit" class="btn btn-success">Crea fornitore</button>
							</form>

							<!-- Elimina -->
							<form method="POST">
								<h5>Elimina fornitore</h5>
								<input type="hidden" name="azione" value="elimina_fornitore">
								<input type="text" name="piva_elimina" class="form-control mb-2" placeholder="P.IVA da eliminare" required>
								<button type="submit" class="btn btn-danger mb-3">Elimina fornitore</button>
							</form>

							<!-- Modifica -->
							<form method="POST">
								<h5>Modifica fornitore</h5>
								<input type="hidden" name="azione" value="modifica_fornitore">
								<input type="text" name="piva_modifica" class="form-control mb-2" placeholder="P.IVA del fornitore da modificare" required>
								<select name="campo_f" class="form-select mb-2" required>
									<option value="indirizzo">Indirizzo</option>
									<option value="piva">P.IVA (nuova)</option>
								</select>
								<input type="text" name="valore_f" class="form-control mb-2" placeholder="Nuovo valore" required>
								<button type="submit" class="btn btn-primary">Modifica fornitore</button>
							</form>

						</div>
					</div>
				</div>

				<!-- Fornisce -->
				<div class="accordion-item">
					<h2 class="accordion-header">
						<button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#fornisce">Forniture</button>
					</h2>
					<div id="fornisce" class="accordion-collapse collapse">
						<div class="accordion-body">
							<!-- Crea -->
							<form method="POST" class="mb-3">
								<h5>Crea fornitura</h5>
								<input type="hidden" name="azione" value="crea_fornitura">
								<input type="text" name="piva_f" class="form-control mb-2" placeholder="P.IVA Fornitore" required>
								<input type="number" name="id_prodotto_f" class="form-control mb-2" placeholder="ID Prodotto" required>
								<input type="number" step="0.01" name="prezzo_f" class="form-control mb-2" placeholder="Prezzo unitario" required>
								<input type="number" name="disponibilita_f" class="form-control mb-2" placeholder="Disponibilità iniziale" required>
								<button type="submit" class="btn btn-success">Crea fornitura</button>
							</form>

							<!-- Elimina -->
							<form method="POST" class="mb-3">
								<h5>Elimina fornitura</h5>
								<input type="hidden" name="azione" value="elimina_fornitura">
								<input type="text" name="piva_elimina_f" class="form-control mb-2" placeholder="P.IVA Fornitore" required>
								<input type="number" name="id_prodotto_elimina_f" class="form-control mb-2" placeholder="ID Prodotto" required>
								<button type="submit" class="btn btn-danger">Elimina fornitura</button>
							</form>

							<!-- Modifica -->
							<form method="POST">
								<h5>Modifica fornitura</h5>
								<input type="hidden" name="azione" value="modifica_fornitura">
								<input type="text" name="piva_modifica_f" class="form-control mb-2" placeholder="P.IVA Fornitore" required>
								<input type="number" name="id_prodotto_modifica_f" class="form-control mb-2" placeholder="ID Prodotto" required>
								<select name="campo_forn" class="form-select mb-2" required>
									<option value="prezzo">Prezzo</option>
									<option value="disponibilita">Disponibilità</option>
								</select>
								<input type="number" step="0.01" name="valore_modifica_f" class="form-control mb-2" placeholder="Nuovo valore" required>
								<button type="submit" class="btn btn-primary">Modifica fornitura</button>
							</form>
						</div>
					</div>
				</div>

			</div>
		</div>
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
