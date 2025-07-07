-- User
INSERT INTO Utente (Username, Password) VALUES ('user_cli1', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_cli2', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_cli3', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_cli4', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_cli5', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_cli6', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_cli7', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_cli8', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_cli9', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_cli10', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_man1', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_man2', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_man3', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_man4', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO Utente (Username, Password) VALUES ('user_man5', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');


-- Manager
INSERT INTO Manager (CF, Nome, Username) VALUES ('RVIFLB10C43B321G', 'Gian Giannini', 'user_man1');
INSERT INTO Manager (CF, Nome, Username) VALUES ('OCLRZA89W08Z386Z', 'Piersanti Morpurgo', 'user_man2');
INSERT INTO Manager (CF, Nome, Username) VALUES ('GWWMQZ42C35U116O', 'Ninetta Cattaneo', 'user_man3');
INSERT INTO Manager (CF, Nome, Username) VALUES ('RHLPAU01P22R551N', 'Ginluca Rioghetta', 'user_man4');
INSERT INTO Manager (CF, Nome, Username) VALUES ('PHTDAU01P22R661U', 'Lucia Casetti', 'user_man5');

-- Cliente
INSERT INTO Cliente (CF, Nome, Username) VALUES ('MTECQO61X84S959J', 'Gianpaolo Callegaro', 'user_cli1');
INSERT INTO Cliente (CF, Nome, Username) VALUES ('NQRSRP64E75M255M', 'Donatella Udinese-Gotti', 'user_cli2');
INSERT INTO Cliente (CF, Nome, Username) VALUES ('XXDOCZ27U64Z835U', 'Baccio Franceschi-Zola', 'user_cli3');
INSERT INTO Cliente (CF, Nome, Username) VALUES ('IPVJIQ53V76L724T', 'Ramona Piane', 'user_cli4');
INSERT INTO Cliente (CF, Nome, Username) VALUES ('HJOKYR53B28M710A', 'Orlando Paruta', 'user_cli5');
INSERT INTO Cliente (CF, Nome, Username) VALUES ('RIWRXP97V84H801U', 'Raffaellino Cuda-Sansoni', 'user_cli6');
INSERT INTO Cliente (CF, Nome, Username) VALUES ('OGMMJX04W82K814O', 'Nicoletta Abate', 'user_cli7');
INSERT INTO Cliente (CF, Nome, Username) VALUES ('PDPKFF95U70F154C', 'Vito Cavanna', 'user_cli8');
INSERT INTO Cliente (CF, Nome, Username) VALUES ('BNIWUS27M82T489G', 'Pasqual Palombi-Roncalli', 'user_cli9');
INSERT INTO Cliente (CF, Nome, Username) VALUES ('BLJOLO87A13E315U', 'Dott. Federica Boito', 'user_cli10');

-- Negozio
INSERT INTO Negozio (ManagerCF, OrariApertura, Indirizzo) VALUES ('RVIFLB10C43B321G', 'Lun-Sab 9:00-19:00', 'Stretto Gilberto 73 Appartamento 99, Golino nell''emilia, 31165 Matera (MN)');
INSERT INTO Negozio (ManagerCF, OrariApertura, Indirizzo) VALUES ('OCLRZA89W08Z386Z', 'Lun-Sab 9:00-19:00', 'Piazza Patrizio 5, Borgo Fredo del friuli, 26247 Enna (BT)');
INSERT INTO Negozio (ManagerCF, OrariApertura, Indirizzo) VALUES ('GWWMQZ42C35U116O', 'Lun-Sab 9:00-19:00', 'Canale Adriana 132, Spanevello nell''emilia, 60260 Lodi (FE)');
INSERT INTO Negozio (ManagerCF, OrariApertura, Indirizzo) VALUES ('RHLPAU01P22R551N', 'Lun-Sab 9:00-19:00', 'Via Spadolini 35, Burrago nel''Milanese, 20837 Milano (MI)');

-- Tessera
INSERT INTO Tessera (DataRichiesta, NegozioID, ClienteCF, SaldoPunti) VALUES ('2025-06-14', 3, 'MTECQO61X84S959J', 0);
INSERT INTO Tessera (DataRichiesta, NegozioID, ClienteCF, SaldoPunti) VALUES ('2025-02-24', 1, 'NQRSRP64E75M255M', 461);
INSERT INTO Tessera (DataRichiesta, NegozioID, ClienteCF, SaldoPunti) VALUES ('2025-02-24', 1, 'XXDOCZ27U64Z835U', 525);
INSERT INTO Tessera (DataRichiesta, NegozioID, ClienteCF, SaldoPunti) VALUES ('2024-06-13', 1, 'IPVJIQ53V76L724T', 96);
INSERT INTO Tessera (DataRichiesta, NegozioID, ClienteCF, SaldoPunti) VALUES ('2024-02-02', 3, 'HJOKYR53B28M710A', 441);
INSERT INTO Tessera (DataRichiesta, NegozioID, ClienteCF, SaldoPunti) VALUES ('2024-05-19', 1, 'RIWRXP97V84H801U', 39);
INSERT INTO Tessera (DataRichiesta, NegozioID, ClienteCF, SaldoPunti) VALUES ('2024-12-18', 1, 'OGMMJX04W82K814O', 653);
INSERT INTO Tessera (DataRichiesta, NegozioID, ClienteCF, SaldoPunti) VALUES ('2025-01-13', 1, 'PDPKFF95U70F154C', 46);
INSERT INTO Tessera (DataRichiesta, NegozioID, ClienteCF, SaldoPunti) VALUES ('2025-01-15', 4, 'BNIWUS27M82T489G', 50);

-- Prodotto
INSERT INTO Prodotto (Nome, Descrizione) VALUES ('Trapano Avvitatore 18V', 'Ideale per forare e avvitare su legno e metallo.');
INSERT INTO Prodotto (Nome, Descrizione) VALUES ('Pittura Murale Bianca', 'Smalto lavabile, alta copertura.');
INSERT INTO Prodotto (Nome, Descrizione) VALUES ('Lampada LED E27', 'Luce fredda 6500K, risparmio energetico.');
INSERT INTO Prodotto (Nome, Descrizione) VALUES ('Martello da Carpentiere', 'Testa in acciaio, manico antiscivolo.');
INSERT INTO Prodotto (Nome, Descrizione) VALUES ('Sega Circolare 1200W', 'Lama 185mm, taglio preciso.');
INSERT INTO Prodotto (Nome, Descrizione) VALUES ('Tassellatore Pneumatico', 'Mandrino SDS-plus, potenza elevata.');
INSERT INTO Prodotto (Nome, Descrizione) VALUES ('Mensola in Legno 80cm', 'Legno massello di rovere.');
INSERT INTO Prodotto (Nome, Descrizione) VALUES ('Cacciavite a Cricchetto', 'Punte intercambiabili, uso versatile.');
INSERT INTO Prodotto (Nome, Descrizione) VALUES ('Livella Laser', 'Linee laser orizzontali/verticali.');
INSERT INTO Prodotto (Nome, Descrizione) VALUES ('Vernice per Ferro', 'Protezione antiruggine per metallo.');

-- Fornitore
INSERT INTO Fornitore (PIVA, Indirizzo) VALUES ('92581319988', 'Contrada Gian 980, Arturo a mare, 88208 Belluno (VI)');
INSERT INTO Fornitore (PIVA, Indirizzo) VALUES ('9388046742', 'Strada Gozzi 9, Settimo Biagio veneto, 43534 Lucca (BS)');
INSERT INTO Fornitore (PIVA, Indirizzo) VALUES ('88784233468', 'Strada Aloisio 99 Appartamento 18, Settimo Giustino, 51354 Campobasso (MI)');
INSERT INTO Fornitore (PIVA, Indirizzo) VALUES ('76595351346', 'Canale Cammarata 411, Sesto Ignazio, 53487 Fermo (VI)');
INSERT INTO Fornitore (PIVA, Indirizzo) VALUES ('8808114191', 'Piazza Mariano 427 Piano 8, San Benvenuto sardo, 80598 Cagliari (ME)');

-- Fornisce
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('92581319988', 4, 17.95, 89);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('92581319988', 9, 26.78, 77);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('92581319988', 1, 33.57, 20);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('92581319988', 5, 40.35, 40);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('9388046742', 7, 18.61, 63);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('9388046742', 6, 14.09, 68);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('9388046742', 5, 13.87, 64);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('9388046742', 2, 34.15, 25);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('88784233468', 8, 13.15, 57);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('88784233468', 9, 43.18, 99);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('88784233468', 2, 45.42, 66);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('88784233468', 4, 33.09, 28);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('76595351346', 1, 44.21, 32);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('76595351346', 4, 25.21, 78);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('76595351346', 5, 35.43, 66);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('76595351346', 10, 16.51, 65);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('8808114191', 4, 35.4, 88);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('8808114191', 5, 39.17, 40);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('8808114191', 2, 28.49, 54);
INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita) VALUES ('8808114191', 9, 49.58, 91);

-- Ordina
INSERT INTO Ordina (NegozioID, ProdottoID, FornitorePIVA, DataConsegna, Quantita) VALUES (3, 4, '88784233468', '2025-04-11', 6);
INSERT INTO Ordina (NegozioID, ProdottoID, FornitorePIVA, DataConsegna, Quantita) VALUES (1, 4, '88784233468', '2025-03-26', 17);
INSERT INTO Ordina (NegozioID, ProdottoID, FornitorePIVA, DataConsegna, Quantita) VALUES (1, 5, '9388046742', '2025-05-16', 23);
INSERT INTO Ordina (NegozioID, ProdottoID, FornitorePIVA, DataConsegna, Quantita) VALUES (1, 6, '76595351346', '2025-05-27', 17);
INSERT INTO Ordina (NegozioID, ProdottoID, FornitorePIVA, DataConsegna, Quantita) VALUES (1, 8, '88784233468', '2025-03-25', 9);
INSERT INTO Ordina (NegozioID, ProdottoID, FornitorePIVA, DataConsegna, Quantita) VALUES (3, 4, '8808114191', '2025-05-26', 22);
INSERT INTO Ordina (NegozioID, ProdottoID, FornitorePIVA, DataConsegna, Quantita) VALUES (3, 5, '8808114191', '2025-04-27', 18);
INSERT INTO Ordina (NegozioID, ProdottoID, FornitorePIVA, DataConsegna, Quantita) VALUES (2, 10, '88784233468', '2025-05-05', 12);
INSERT INTO Ordina (NegozioID, ProdottoID, FornitorePIVA, DataConsegna, Quantita) VALUES (3, 3, '76595351346', '2025-04-06', 7);
INSERT INTO Ordina (NegozioID, ProdottoID, FornitorePIVA, DataConsegna, Quantita) VALUES (1, 1, '9388046742', '2025-05-25', 25);

-- Vende
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (1, 1, 28.2, 7);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (2, 1, 25.25, 19);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (3, 1, 26.69, 5);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (1, 2, 43.36, 13);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (2, 2, 49.9, 15);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (3, 2, 43.33, 18);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (1, 3, 21.36, 13);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (2, 3, 31.05, 10);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (3, 3, 26.41, 8);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (1, 4, 52.8, 11);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (2, 4, 51.35, 10);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (3, 4, 55.21, 5);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (1, 5, 43.85, 8);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (2, 5, 48.25, 14);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (3, 5, 41.35, 12);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (1, 6, 59.59, 7);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (2, 6, 57.44, 7);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (3, 6, 59.9, 9);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (1, 7, 24.89, 10);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (2, 7, 22.79, 18);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (3, 7, 29.78, 11);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (1, 8, 47.51, 16);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (2, 8, 47.9, 19);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (3, 8, 44.73, 12);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (1, 9, 17.77, 12);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (2, 9, 23.44, 5);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (3, 9, 18.27, 6);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (1, 10, 33.21, 15);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (2, 10, 24.87, 12);
INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita) VALUES (3, 10, 26.94, 20);

-- Fattura
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('OGMMJX04W82K814O', 2, '2025-05-21', 15, 160.37);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('RIWRXP97V84H801U', 1, '2025-06-21', 5, 39.38);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('OGMMJX04W82K814O', 1, '2025-06-20', 5, 166.45);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('BNIWUS27M82T489G', 1, '2025-05-06', 0, 72.52);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('IPVJIQ53V76L724T', 2, '2025-05-27', 0, 40.18);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('HJOKYR53B28M710A', 2, '2025-06-08', 15, 72.98);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('BLJOLO87A13E315U', 3, '2025-04-12', 30, 53.5);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('PDPKFF95U70F154C', 3, '2025-06-25', 15, 46.74);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('XXDOCZ27U64Z835U', 1, '2025-04-19', 15, 86.76);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('IPVJIQ53V76L724T', 3, '2025-06-19', 0, 55.87);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('BLJOLO87A13E315U', 3, '2025-04-12', 15, 122.14);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('XXDOCZ27U64Z835U', 3, '2025-06-13', 30, 82.79);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('BLJOLO87A13E315U', 1, '2025-06-14', 0, 61.22);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('NQRSRP64E75M255M', 1, '2025-04-14', 15, 230.72);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('BNIWUS27M82T489G', 1, '2025-06-21', 30, 56.2);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('HJOKYR53B28M710A', 2, '2025-05-07', 30, 67.54);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('HJOKYR53B28M710A', 3, '2025-03-30', 15, 114.12);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('XXDOCZ27U64Z835U', 3, '2025-04-14', 15, 75.73);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('BNIWUS27M82T489G', 1, '2025-06-07', 0, 83.64);
INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato) VALUES ('XXDOCZ27U64Z835U', 3, '2025-06-11', 15, 98.89);

-- VoceFattura

INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (1, 8, 46.93, 3);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (1, 1, 23.94, 2);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (2, 4, 41.45, 1);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (3, 4, 37.73, 3);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (3, 2, 23.92, 3);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (4, 3, 36.26, 2);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (5, 7, 20.09, 2);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (6, 9, 26.19, 2);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (6, 8, 28.71, 1);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (7, 6, 22.29, 3);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (8, 1, 58.43, 1);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (9, 4, 36.15, 3);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (10, 10, 23.28, 3);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (11, 5, 46.79, 2);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (11, 4, 29.55, 2);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (12, 8, 57.16, 1);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (12, 6, 20.37, 3);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (13, 9, 30.61, 2);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (14, 3, 53.35, 3);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (14, 8, 32.1, 3);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (15, 2, 30.58, 1);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (15, 3, 49.7, 1);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (16, 6, 28.14, 3);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (17, 1, 45.37, 2);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (17, 2, 21.76, 2);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (18, 8, 42.07, 2);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (19, 3, 41.82, 2);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (20, 4, 52.3, 1);
INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita) VALUES (20, 8, 23.77, 3);
