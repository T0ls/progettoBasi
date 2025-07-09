<?php
session_start();
require_once "db.php";

if (!isset($_SESSION["ruolo"]) || $_SESSION["ruolo"] !== "cliente") {
	header("Location: login.php");
	exit();
}

$cf_cliente = $_SESSION["codice_fiscale"];
$username = $_SESSION["username"];
$nome = $_SESSION["nome"];

pg_prepare($conn, "saldo", "SELECT * FROM visualizza_saldo_punti($1)");
$saldo = pg_execute($conn, "saldo", [$cf_cliente]);
$info_tessera = pg_fetch_assoc($saldo);
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Dashboard Cliente</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
		<script>
		let carrello = [];
		function aggiungiAlCarrello(id, nome, prezzo) {
			const input = document.getElementById('quantita_' + id);
			const quantita = parseInt(input.value);
			if (!quantita || quantita <= 0) return alert("Inserisci una quantità valida");

			const esiste = carrello.find(p => p.id === id);
			if (esiste) {
				esiste.quantita += quantita;
			} else {
				carrello.push({ id, nome, prezzo, quantita });
			}
		}

		function vaiAlCheckout() {
			sessionStorage.setItem("carrello", JSON.stringify(carrello));
			window.location.href = "checkout.php";
		}

		function renderCarrello() {
			const container = document.getElementById('contenutoCarrello');
			container.innerHTML = "";
			let totale = 0;
			carrello.forEach(p => {
				totale += p.prezzo * p.quantita;
				container.innerHTML += `<li class='list-group-item d-flex justify-content-between'>${p.quantita}x ${p.nome}<span>€ ${(p.prezzo * p.quantita).toFixed(2)}</span></li>`;
			});
			container.innerHTML += `<li class='list-group-item fw-bold d-flex justify-content-between'>Totale:<span>€ ${totale.toFixed(2)}</span></li>`;
		}

		document.addEventListener('DOMContentLoaded', () => {
			document.body.addEventListener('click', function(e) {
				if (e.target && e.target.classList.contains('btn-success')) {
					setTimeout(renderCarrello, 100);
				}
			});
		});
		</script>
	</head>
	<body class="bg-light">
		<div class="container mt-4">
			<div class="d-flex justify-content-between align-items-center mb-3">
				<h3>Benvenuto, <?= htmlspecialchars($nome) ?></h3>
				<form method="POST" action="logout.php">
					<button type="submit" class="btn btn-danger">Logout</button>
				</form>
			</div>

			<ul class="nav nav-tabs" id="tabs" role="tablist">
				<li class="nav-item"><button class="nav-link active" data-bs-toggle="tab" data-bs-target="#dashboard">Dashboard</button></li>
				<li class="nav-item"><a class="nav-link" href="fatture.php">Le mie fatture</a></li>
				<li class="nav-item"><a class="nav-link" href="acquisti.php">Acquisti</a></li>
			</ul>

			<div class="tab-content p-3 bg-white rounded-bottom shadow-sm">
				<!-- Tab Dashboard -->
				<div class="tab-pane fade show active" id="dashboard" role="tabpanel">
					<ul class="list-group">
						<li class="list-group-item"><strong>Nome:</strong> <?= htmlspecialchars(
							$nome
							) ?></li>
						<li class="list-group-item"><strong>Codice Fiscale:</strong> <?= htmlspecialchars(
							$cf_cliente
							) ?></li>
						<li class="list-group-item"><strong>Username:</strong> <?= htmlspecialchars(
							$username
							) ?></li>
						<li class="list-group-item">
							<strong>Password:</strong> ******** 
							<a href="modifica_password.php" class="btn btn-sm btn-outline-primary ms-2">Modifica</a>
						</li>
						<li class="list-group-item">
							<strong>Saldo punti:</strong> 
							<span class="fw-bold text-success">
								<?= isset($info_tessera["saldo_punti"])
								? $info_tessera["saldo_punti"]
								: "Tessera non trovata" ?>
							</span>
						</li>
					</ul>
				</div>

				<!-- Tab Fatture -->
				<div class="tab-pane fade" id="fatture" role="tabpanel">
					<h5>Le tue fatture</h5>
					<?php
					pg_prepare(
					$conn,
					"fatture_cliente",
					"SELECT * FROM Fattura WHERE ClienteCF = $1 ORDER BY DataAcquisto DESC"
					);
					$fatture = pg_execute($conn, "fatture_cliente", [$cf_cliente]);

					if (pg_num_rows($fatture) === 0) {
					echo "<p class='text-muted'>Non hai ancora effettuato acquisti.</p>";
					}

					while ($f = pg_fetch_assoc($fatture)) {
					echo "<div class='border rounded p-3 mb-3 bg-light shadow-sm'>";
					echo "<h6>Fattura #{$f["idfattura"]} - {$f["dataacquisto"]}</h6>";
					echo "<p class='mb-1'><strong>Sconto:</strong> " .
					intval($f["scontoapplicato"]) .
					"%</p>";
					echo "<p class='mb-1'><strong>Totale pagato:</strong> €" .
					number_format($f["totalepagato"], 2) .
					"</p>";

					pg_prepare(
					$conn,
					"voci_fattura_{$f["idfattura"]}",
					"SELECT p.Nome, v.Quantita, v.PrezzoUnitario FROM VoceFattura v JOIN Prodotto p ON v.ProdottoID = p.IDProdotto WHERE v.FatturaID = $1"
					);
					$voci = pg_execute($conn, "voci_fattura_{$f["idfattura"]}", [
					$f["idfattura"],
					]);
					echo "<ul class='list-group list-group-flush'>";
					while ($voce = pg_fetch_assoc($voci)) {
					echo "<li class='list-group-item'>{$voce["quantita"]}x " .
					htmlspecialchars($voce["nome"]) .
					" – €" .
					number_format($voce["prezzounitario"], 2) .
					"</li>";
					}
					echo "</ul></div>";
					}
					?>
				</div>
			</div>
		</div>

		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
