<?php
// Starta la sessione
session_start();
// Rimuove tutte le variabili di sessione
session_unset();
// Elimna la sessione
session_destroy();

header("Location: login.php");
exit();
