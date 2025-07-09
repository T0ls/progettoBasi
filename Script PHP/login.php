<?php
session_start();
require_once "db.php";

$errore = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$username = $_POST["username"] ?? "";
	$password = $_POST["password"] ?? "";

	$sql_login = "SELECT * FROM login_utente($1, $2)";
	pg_prepare($conn, "login_query", $sql_login);
	$result = pg_execute($conn, "login_query", [$username, $password]);

	if ($result && pg_num_rows($result) > 0) {
		$utente = pg_fetch_assoc($result);

		$_SESSION["username"] = $utente["username"];
		$_SESSION["codice_fiscale"] = $utente["codice_fiscale"];
		$_SESSION["nome"] = $utente["nome"];

		pg_prepare(
			$conn,
			"check_manager",
			"SELECT 1 FROM Manager WHERE CF = $1"
		);
		$check_manager = pg_execute($conn, "check_manager", [
			$utente["codice_fiscale"],
		]);
		$_SESSION["ruolo"] =
		pg_num_rows($check_manager) > 0 ? "manager" : "cliente";

		header("Location: dashboard_" . $_SESSION["ruolo"] . ".php");
		exit();
	} else {
		$errore = "Credenziali errate.";
	}
}
?>

<!DOCTYPE html>
<html lang="it">
	<head>
		<meta charset="UTF-8">
		<title>Login - Gestione Negozi</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
	</head>
	<body class="bg-light">
		<div class="container py-5">
			<div class="row justify-content-center">
				<div class="col-md-4">
					<div class="card shadow rounded-4">
						<div class="card-header">
							<h2 class="text-center">Accedi ai servizi</h2>
						</div>
						<div class="card-body">
							<?php if ($errore): ?>
							<div class="alert alert-danger"><?= $errore ?></div>
							<?php endif; ?>
							<form method="POST">
								<div class="mb-3">
									<label class="form-label">Username</label>
									<input type="text" name="username" class="form-control" required>
								</div>
								<div class="mb-3">
									<label class="form-label">Password</label>
									<input type="password" name="password" class="form-control" required>
								</div>
								<button class="btn btn-primary w-100" type="submit">Login</button>
							</form>
						</div>
						<div class="card-footer text-muted text-center">
							Autenticati come cliente o manager
						</div>
					</div>
				</div>
			</div>
		</div>
	</body>
</html>
