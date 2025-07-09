<?php
session_start();
require_once "db.php";

if (!isset($_SESSION["username"]) || !isset($_SESSION["ruolo"])) {
	header("Location: login.php");
	exit();
}

$username = $_SESSION["username"];
$ruolo = $_SESSION["ruolo"];
$messaggio = "";
$redirect = false;

if ($_SERVER["REQUEST_METHOD"] === "POST") {
	$attuale = $_POST["attuale"] ?? "";
	$nuova = $_POST["nuova"] ?? "";
	$conferma = $_POST["conferma"] ?? "";

	if ($nuova !== $conferma) {
		$messaggio = "La nuova password e la conferma non coincidono.";
	} else {
		$sql = "SELECT modifica_password($1, $2, $3)";
		pg_prepare($conn, "modifica_pw", $sql);
		$result = pg_execute($conn, "modifica_pw", [
			$username,
			$attuale,
			$nuova,
		]);

		if ($result) {
			$esito = pg_fetch_result($result, 0, 0);
			switch ($esito) {
				case "OK":
					$messaggio =
					"Password modificata con successo. Verrai reindirizzato...";
					$redirect = true;
					break;
				case "WRONG_PASSWORD":
					$messaggio = "Password attuale errata.";
					break;
				case "SAME_PASSWORD":
					$messaggio = "La nuova password è uguale a quella attuale.";
					break;
				case "USER_NOT_FOUND":
					$messaggio = "Utente non trovato.";
					break;
				default:
					$messaggio = "Errore sconosciuto.";
			}
		} else {
			$messaggio = "Errore nell'esecuzione della query.";
		}
	}
}
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Modifica Password</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
		<?php if ($redirect): ?>
		<meta http-equiv="refresh" content="3;url=dashboard_<?= $ruolo ?>.php">
		<?php endif; ?>
	</head>
	<body class="bg-light">
		<div class="container py-5">
			<div class="row justify-content-center">
				<div class="col-md-4">
					<div class="card shadow rounded-4">
						<div class="card-header">
							<h2 class="mb-4">Modifica password</h2>
						</div>
						<div class="card-body">
							<?php if ($messaggio): ?>
							<div class="alert alert-info"><?= $messaggio ?></div>
							<?php endif; ?>

							<form method="POST">
								<div class="mb-3">
									<label class="form-label">Password attuale</label>
									<input type="password" name="attuale" class="form-control" required>
								</div>
								<div class="mb-3">
									<label class="form-label">Nuova password</label>
									<input type="password" name="nuova" class="form-control" required>
								</div>
								<div class="mb-3">
									<label class="form-label">Conferma nuova password</label>
									<input type="password" name="conferma" class="form-control" required>
								</div>
								<button type="submit" class="btn btn-primary">Modifica</button>
								<a href="dashboard_<?= $ruolo ?>.php" class="btn btn-secondary ms-2">Annulla</a>
							</form>
						</div>
					</div>
				</div>
			</div>
		</div>
	</body>
</html>
