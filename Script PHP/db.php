<?php
	$conn = pg_connect("host=localhost dbname=progettoDb user=giulio password=1547");
	if (!$conn) {
		die("Connessione al database fallita.");
	}
?>
