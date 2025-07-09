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
		<title>Le mie Fatture</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
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
				<li class="nav-item"><a class="nav-link active" href="fatture.php">Le mie fatture</a></li>
				<li class="nav-item"><a class="nav-link" href="acquisti.php">Acquisti</a></li>
			</ul>

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
			"SELECT p.Nome, v.Quantita, v.PrezzoUnitario 
			FROM VoceFattura v 
			JOIN Prodotto p ON v.ProdottoID = p.IDProdotto 
			WHERE v.FatturaID = $1"
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
		<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
	</body>
</html>
