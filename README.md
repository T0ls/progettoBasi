# 🛒 Progetto Basi di Dati — Gestione Catena di Negozi

Progetto universitario realizzato per il corso di **Laboratorio di Basi di Dati** (A.A. 2024/2025) presso l'Università degli Studi di Milano. L'obiettivo è la progettazione e implementazione di un'applicazione web con backend in PostgreSQL + PHP per la gestione di una catena di negozi, con funzionalità per **clienti** e **manager**.

## ⚙️ Tecnologie Utilizzate

- **PostgreSQL** (con estensione `pgcrypto`)
- **PL/pgSQL** per funzioni, trigger, viste
- **PHP** per il backend web
- **HTML/CSS** per l'interfaccia utente

## 📦 Contenuto del Repository

- `createTables.sql`: script per la creazione delle tabelle
- `insertData.sql`: script di inserimento dati di test
- `funzioniSql.sql`: tutte le funzioni PL/pgSQL sviluppate
- `funzionalitaSql.sql`: trigger, viste e funzionalità complesse del DB
- `schemaLogico.txt`: schema relazionale completo
- `Er db Uni.png`: schema ER del progetto
- `/php/`: cartella con tutti gli script PHP per il frontend/backend

## 👤 Funzionalità Utente

### Cliente
- Login e modifica password
- Visualizzazione dei negozi aperti e dei relativi prodotti disponibili
- Acquisto prodotti, con opzione per applicare sconti basati sul saldo punti della tessera fedeltà
- Visualizzazione del saldo punti personale

### Manager
- Login e modifica password
- Gestione dei clienti (creazione, modifica, eliminazione)
- Gestione negozi (aggiunta, modifica, chiusura)
- Gestione prodotti e relative vendite nei negozi
- Gestione fornitori e forniture
- Inserimento ordini presso i fornitori
- Visualizzazione:
  - Tessere rilasciate da ogni negozio
  - Storico ordini a fornitori
  - Clienti con oltre 300 punti

## 🧠 Strutture DB Avanzate

Il progetto include l’utilizzo di:
- **Trigger** per aggiornamento automatico dei punti e gestione ordini automatici
- **Viste** per storico ordini, lista tesserati e saldi punti
- **Funzioni** per acquisti, sconti, gestione entità e interazioni complesse
- **Controlli di consistenza e integrità referenziale** tramite vincoli SQL

## 📝 Requisiti Implementati

| Requisito | Implementato |
|----------|--------------|
| Aggiornamento punti | ✅ tramite trigger `trigger_aggiorna_punti` |
| Applicazione sconti fedeltà | ✅ tramite funzione `acquisto_cliente` |
| Storico tessere chiusura negozi | ✅ tramite vista `StoricoTessere` |
| Aggiornamento disponibilità fornitore | ✅ tramite trigger `trigger_aggiorna_disponibilita` |
| Ordini automatici | ✅ tramite funzione `effettua_ordine` e trigger `trigger_quantita_zero` |
| Lista tesserati per negozio | ✅ vista `ListaTesserati` |
| Storico ordini fornitori | ✅ vista `StoricoOrdiniFornitori` |
| Clienti con >300 punti | ✅ vista `ClientiConPiuDi300Punti` |

## 🧪 Credenziali di Test

### Manager
- Username: `user_man1`
- Password: `1234`

### Cliente
- Username: `user_cli2`
- Password: `1234`

## 🚀 Avvio del Progetto

1. Installare PostgreSQL e PHP (con Apache o XAMPP)
2. Creare un database vuoto e importare `createTables.sql` + `insertData.sql`
3. Importare tutte le funzioni e trigger tramite `funzioniSql.sql` e `funzionalitaSql.sql`
4. Configurare il file `db.php` per la connessione al database
5. Avviare il server locale e accedere a `localhost/vostro_path/login.php`

---

Per ulteriori informazioni consultare la [documentazione tecnica](./Documentazione.pdf) e il [manuale utente](./Manuale\ utente.pdf).
