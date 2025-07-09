<?php
session_start();
require_once "db.php";

if (!isset($_SESSION["ruolo"]) || $_SESSION["ruolo"] !== "cliente") {
	header("Location: login.php");
	exit();
}

$cf_cliente = $_SESSION["codice_fiscale"];
$nome = $_SESSION["nome"];
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Acquisti</title>
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
			document.body.addEventListener('click', function (e) {
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

			<!-- Finta navbar -->
			<ul class="nav nav-tabs mb-4">
				<li class="nav-item"><a class="nav-link" href="dashboard_cliente.php">Dashboard</a></li>
				<li class="nav-item"><a class="nav-link" href="fatture.php">Le mie fatture</a></li>
				<li class="nav-item"><a class="nav-link active" href="acquisti.php">Acquisti</a></li>
			</ul>

			<form method="GET">
				<div class="mb-3">
					<label for="negozio_id" class="form-label me-2">Seleziona negozio</label>
					<select name="negozio_id" id="negozio_id" class="form-select w-auto d-inline-block">
						<option value="">-- Seleziona --</option>
						<?php
						pg_prepare(
						$conn,
						"negozi_attivi",
						"SELECT IDNegozio, Indirizzo FROM Negozio WHERE Aperto = TRUE"
						);
						$negozi = pg_execute($conn, "negozi_attivi", []);
						while ($n = pg_fetch_assoc($negozi)) {
						$sel =
						isset($_GET["negozio_id"]) &&
						$_GET["negozio_id"] == $n["idnegozio"]
						? "selected"
						: "";
						echo "<option value='{$n["idnegozio"]}' $sel>{$n["idnegozio"]} – " .
						htmlspecialchars($n["indirizzo"]) .
						"</option>";
						}
						?>
					</select>
					<button type="submit" class="btn btn-primary">Carica prodotti</button>
				</div>
			</form>

			<script>
			const negozioSelect = document.getElementById("negozio_id");
			negozioSelect.addEventListener("change", () => {
			sessionStorage.setItem("negozio_id", negozioSelect.value);
			});
			</script>

			<?php if (isset($_GET["negozio_id"]) && is_numeric($_GET["negozio_id"])): ?>
			<div class="row">
				<!-- Colonna prodotti -->
				<div class="col-md-9">
					<div class="row">
						<?php
						pg_prepare(
						$conn,
						"prodotti_disponibili",
						"SELECT * FROM prodotti_disponibili_negozio($1)"
						);
						$prodotti = pg_execute($conn, "prodotti_disponibili", [
						$_GET["negozio_id"],
						]);

						if (pg_num_rows($prodotti) === 0) {
						echo "<div class='col-12'><div class='alert alert-secondary'>Nessun prodotto disponibile in questo negozio.</div></div>";
						} else {
						while ($p = pg_fetch_assoc($prodotti)) {
						$nome_js = htmlspecialchars(
						$p["nome_prodotto"],
						ENT_QUOTES
						);
						echo "<div class='col-md-4'>
						<div class='card mb-4 shadow-sm'>
						<div class='card-body'>
						<h5 class='card-title'>" .
						htmlspecialchars($p["nome_prodotto"]) .
						"</h5>
						<p class='card-text'>" .
						htmlspecialchars($p["descrizione"]) .
						"</p>
						<p class='mb-1'><strong>Prezzo:</strong> €" .
						number_format($p["prezzo"], 2) .
						"</p>
						<p><strong>Disponibilità:</strong> {$p["quantita"]}</p>
						<input type='number' id='quantita_{$p["id_prodotto"]}' class='form-control mb-2' placeholder='Quantità' min='1'>
						<button class='btn btn-success' onclick='aggiungiAlCarrello(\"{$p["id_prodotto"]}\", \"{$nome_js}\", {$p["prezzo"]})'>Aggiungi al carrello</button>
						</div>
						</div>
						</div>";
						}
						}
						?>
					</div>
				</div>

				<!-- Colonna carrello -->
				<div class="col-md-3">
					<h5>Carrello:</h5>
					<ul class="list-group" id="contenutoCarrello"></ul>
					<button class="btn btn-primary mt-3 w-100" onclick="vaiAlCheckout()">Vai al checkout</button>
				</div>
			</div>
			<?php endif; ?>


		</div>
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
