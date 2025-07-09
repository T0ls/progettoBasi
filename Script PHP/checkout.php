<?php
session_start();
if (!isset($_SESSION["ruolo"]) || $_SESSION["ruolo"] !== "cliente") {
	header("Location: login.php");
	exit();
}

?>
<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Checkout</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
		<script>
		let carrello = [];

		document.addEventListener('DOMContentLoaded', () => {
			const dati = sessionStorage.getItem("carrello");
			if (!dati) {
				document.getElementById("checkoutContainer").innerHTML = "<p class='text-muted'>Carrello vuoto.</p>";
				return;
			}

			carrello = JSON.parse(dati);
			renderRiepilogo();

			const negozioID = sessionStorage.getItem("negozio_id");
			if (negozioID) {
				document.getElementById("negozio_id_hidden").value = negozioID;
			}
		});

		function renderRiepilogo() {
			const contenitore = document.getElementById("riepilogoCarrello");
			contenitore.innerHTML = "";
			let totale = 0;

			carrello.forEach(p => {
				totale += p.prezzo * p.quantita;

				const riga = document.createElement("li");
				riga.className = "list-group-item d-flex justify-content-between align-items-center";

				riga.innerHTML = `
<div>
	<button class='btn btn-sm btn-outline-danger me-1' onclick='aggiornaQuantita("${p.id}", -1)'>-</button>
	<button class='btn btn-sm btn-outline-success me-2' onclick='aggiornaQuantita("${p.id}", 1)'>+</button>
	${p.quantita}x ${p.nome}<br><small>€ ${(p.prezzo * p.quantita).toFixed(2)}</small>
</div>
`;
				contenitore.appendChild(riga);
			});

			const totaleRiga = document.createElement("li");
			totaleRiga.className = "list-group-item fw-bold d-flex justify-content-between";
			totaleRiga.innerHTML = `Totale:<span>€ ${totale.toFixed(2)}</span>`;
			contenitore.appendChild(totaleRiga);

			document.getElementById("totaleHidden").value = totale.toFixed(2);
		}

		function aggiornaQuantita(id, delta) {
			const item = carrello.find(p => p.id === id);
			if (!item) return;
			item.quantita += delta;
			if (item.quantita <= 0) {
				carrello = carrello.filter(p => p.id !== id);
			}
			renderRiepilogo();
		}

		function inviaOrdine() {
			const form = document.getElementById("formCheckout");
			const prodotti = carrello.map(p => ({ id: p.id, quantita: p.quantita }));

			const hidden = document.createElement("input");
			hidden.type = "hidden";
			hidden.name = "prodotti";
			hidden.value = JSON.stringify(prodotti);
			form.appendChild(hidden);

			form.submit();
		}
		</script>
	</head>
	<body class="bg-light">
		<div class="container mt-5" id="checkoutContainer">
			<h3 class="mb-4">Riepilogo Carrello</h3>

			<ul class="list-group mb-4" id="riepilogoCarrello"></ul>

			<form method="POST" action="conferma_acquisto.php" id="formCheckout">
				<input type="hidden" name="negozio_id" id="negozio_id_hidden">
				<input type="hidden" name="totale" id="totaleHidden">
				<div class="mb-3">
					<label for="applica_sconto" class="form-label">Applicare sconto?</label>
					<select name="applica_sconto" id="applica_sconto" class="form-select w-auto">
						<option value="false" selected>No</option>
						<option value="true">Sì</option>
					</select>
				</div>
				<button type="button" class="btn btn-success" onclick="inviaOrdine()">Conferma Acquisto</button>
			</form>
		</div>
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
