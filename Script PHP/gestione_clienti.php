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

	if ($azione === 'crea') {
		$cf = $_POST['cf'];
		$nome = $_POST['nome'];
		$username = $_POST['username'];
		try {
			$res = pg_query_params($conn, "SELECT crea_cliente($1, $2, $3)", [$cf, $nome, $username]);
			$esito = pg_fetch_result($res, 0, 0);
			if ($esito === 'OK') {
				$msg = "Cliente creato con successo.";
			} else {
				$err = "Errore durante la creazione: $esito";
			}
		} catch (Exception $e) {
			$err = "Errore: " . $e->getMessage();
		}

	} elseif ($azione === 'elimina') {
		$cf = $_POST['cf_elimina'];
		try {
			$res = pg_query_params($conn, "SELECT elimina_cliente($1)", [$cf]);
			$esito = pg_fetch_result($res, 0, 0);
			if ($esito === 'OK') {
				$msg = "Cliente eliminato con successo.";
			} else {
				$err = "Errore durante l'eliminazione: $esito";
			}
		} catch (Exception $e) {
			$err = "Errore: " . $e->getMessage();
		}

	} elseif ($azione === 'modifica') {
		$cf = $_POST['cf_modifica'];
		$campo = $_POST['campo'];
		$valore = $_POST['valore'];

		try {
			$res = pg_query_params($conn, "SELECT modifica_dato_cliente($1, $2, $3)", [$cf, $campo, $valore]);
			$esito = pg_fetch_result($res, 0, 0);
			if ($esito === 'OK') {
				$msg = "Cliente modificato con successo.";
			} else {
				$err = "Errore durante la modifica: $esito";
			}
		} catch (Exception $e) {
			$err = "Errore: " . $e->getMessage();
		}
	}
}
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Gestione Clienti</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
	</head>
	<body class="bg-light">
		<div class="container mt-4">
			<div class="d-flex justify-content-between align-items-center mb-4">
				<h3 class="mb-4">Gestione Clienti</h3>
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
				<li class="nav-item"><a class="nav-link active" href="gestione_clienti.php">Gestione Clienti</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_negozi.php">Gestione Negozi</a></li>
				<li class="nav-item"><a class="nav-link" href="gestione_prodotti.php">Prodotti e Fornitori</a></li>
			</ul>

			<?php if ($msg): ?><div class="alert alert-success"><?= $msg ?></div><?php endif; ?>
			<?php if ($err): ?><div class="alert alert-danger"><?= $err ?></div><?php endif; ?>

			<div class="accordion" id="accordionGestioneClienti">
				<!-- Crea -->
				<div class="accordion-item">
					<h2 class="accordion-header" id="headingCrea">
						<button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#collapseCrea">
							Crea nuovo cliente
						</button>
					</h2>
					<div id="collapseCrea" class="accordion-collapse collapse show" data-bs-parent="#accordionGestioneClienti">
						<div class="accordion-body">
							<form method="POST">
								<input type="hidden" name="azione" value="crea">
								<div class="mb-2"><label>Codice Fiscale: <input type="text" name="cf" class="form-control" required></label></div>
								<div class="mb-2"><label>Nome: <input type="text" name="nome" class="form-control" required></label></div>
								<div class="mb-2"><label>Username: <input type="text" name="username" class="form-control" required></label></div>
								<button type="submit" class="btn btn-success">Crea cliente</button>
							</form>
						</div>
					</div>
				</div>

				<!-- Elimina -->
				<div class="accordion-item">
					<h2 class="accordion-header" id="headingElimina">
						<button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseElimina">
							Elimina cliente
						</button>
					</h2>
					<div id="collapseElimina" class="accordion-collapse collapse" data-bs-parent="#accordionGestioneClienti">
						<div class="accordion-body">
							<form method="POST">
								<input type="hidden" name="azione" value="elimina">
								<div class="mb-2"><label>Codice Fiscale: <input type="text" name="cf_elimina" class="form-control" required></label></div>
								<button type="submit" class="btn btn-danger">Elimina cliente</button>
							</form>
						</div>
					</div>
				</div>

				<!-- Modifica -->
				<div class="accordion-item">
					<h2 class="accordion-header" id="headingModifica">
						<button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseModifica">
							Modifica cliente
						</button>
					</h2>
					<div id="collapseModifica" class="accordion-collapse collapse" data-bs-parent="#accordionGestioneClienti">
						<div class="accordion-body">
							<form method="POST">
								<input type="hidden" name="azione" value="modifica">
								<div class="mb-2"><label>Codice Fiscale: <input type="text" name="cf_modifica" class="form-control" required></label></div>
								<div class="mb-2">
									<label>Campo da modificare:
										<select name="campo" class="form-select" required>
											<option value="nome">Nome</option>
											<option value="username">Username</option>
										</select>
									</label>
								</div>
								<div class="mb-2"><label>Nuovo valore: <input type="text" name="valore" class="form-control" required></label></div>
								<button type="submit" class="btn btn-primary">Modifica cliente</button>
							</form>
						</div>
					</div>
				</div>
			</div>
		</div>
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
