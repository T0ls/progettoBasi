<?php
session_start();
require_once "db.php";

if (!isset($_SESSION["ruolo"]) || $_SESSION["ruolo"] !== "cliente") {
	header("Location: login.php");
	exit();
}

$cf_cliente = $_SESSION["codice_fiscale"];

if (
	$_SERVER["REQUEST_METHOD"] === "POST" &&
		isset($_POST["prodotti"], $_POST["totale"], $_POST["applica_sconto"], $_POST["negozio_id"])
) {
	$negozio_id = $_POST["negozio_id"];
	$prodotti_json = $_POST["prodotti"];
	$totale = floatval($_POST["totale"]);
	$applica_sconto = $_POST["applica_sconto"];

	$prodotti = json_decode($prodotti_json, true);
	$id_prodotti = [];
	$quantita = [];

	foreach ($prodotti as $p) {
		$id_prodotti[] = intval($p["id"]);
		$quantita[] = intval($p["quantita"]);
	}

	echo "<!DOCTYPE html>";
	echo "<html lang='it'>";
	echo "<head>";
	echo "    <meta charset='UTF-8'>";
	echo "    <title>Acquisto</title>";
	echo "    <link href='https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css' rel='stylesheet'>";
	echo "</head>";
	echo "<body>";

	if ($negozio_id === null) {
		echo "<div class='container mt-5'>";
		echo "<div class='alert alert-danger'>Errore: negozio non selezionato.</div>";
		echo "</div>";
		echo "</body></html>";
		exit();
	}

	pg_prepare($conn, "acquisto", "SELECT effettua_acquisto($1, $2, $3, $4, $5)");
	$result = pg_execute($conn, "acquisto", [
		$cf_cliente,
		$negozio_id,
		'{' . implode(',', $id_prodotti) . '}',
		'{' . implode(',', $quantita) . '}',
		$applica_sconto
	]);

	if ($result) {
		$output = pg_fetch_result($result, 0, 0);

		if ($output === "OK" || str_starts_with($output, "OK_")) {
			echo "<div class='container mt-5'>";
			echo "<div class='alert alert-success'>Acquisto completato con successo. Verrai reindirizzato alla dashboard...</div>";
			echo "<script>setTimeout(() => window.location.href = 'dashboard_cliente.php', 3000);</script>";
			echo "</div>";
		} else {
			echo "<div class='container mt-5'>";
			$messaggio = match($output) {
				"ARRAY_LENGTH_MISMATCH" => "Errore interno: array prodotti e quantità non corrispondenti.",
				"PRODOTTO_NON_PRESENTE" => "Errore: uno dei prodotti selezionati non è più disponibile in questo negozio.",
				"QUANTITA_NON_DISPONIBILE" => "Errore: la quantità richiesta per uno o più prodotti supera la disponibilità.",
				default => "Errore sconosciuto: $output"
			};
			echo "<div class='alert alert-danger'>$messaggio</div>";
			echo "<a href='checkout.php' class='btn btn-secondary mt-3'>Torna al checkout</a>";
			echo "</div>";
		}
	} else {
		echo "<div class='container mt-5'>";
		$error = pg_result_error($result);
		echo "<div class='alert alert-danger'>Errore durante la comunicazione con il database: $error</div>";
		echo "<a href='checkout.php' class='btn btn-secondary mt-3'>Torna al checkout</a>";
		echo "</div>";
	}

	echo "</body></html>";
} else {
	header("Location: checkout.php");
	exit();
}
?>
