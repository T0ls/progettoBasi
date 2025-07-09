-- Abilita pgcrypto
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Login:
	CREATE OR REPLACE FUNCTION login_utente(
	    p_username VARCHAR,
	    p_password VARCHAR
	)
	RETURNS TABLE (
	    username VARCHAR(50),
	    codice_fiscale VARCHAR(16),
	    nome VARCHAR(100)
	) AS $$
	BEGIN
	    -- Prova con Cliente
	    RETURN QUERY
	    SELECT u.Username, c.CF, c.Nome
	    FROM Utente u
	    JOIN Cliente c ON u.Username = c.Username
	    WHERE u.Username = p_username
	      AND u.Password = crypt(p_password, u.Password);
	
	    -- Prova con Manager
	    IF NOT FOUND THEN
	        RETURN QUERY
	        SELECT u.Username, m.CF, m.Nome
	        FROM Utente u
	        JOIN Manager m ON u.Username = m.Username
	        WHERE u.Username = p_username
	          AND u.Password = crypt(p_password, u.Password);
	    END IF;
	END;
	$$ LANGUAGE plpgsql;
--



-- Modifica PW:
	CREATE OR REPLACE FUNCTION modifica_password(
	    p_username VARCHAR,
	    p_password_corrente VARCHAR,
	    p_password_nuova VARCHAR
	)
	RETURNS TEXT AS $$
	DECLARE
	    v_password_attuale TEXT;
	    v_trovato BOOLEAN := FALSE;
	BEGIN
	    -- Prova con Cliente
	    SELECT u.Password INTO v_password_attuale
	    FROM Utente u
	    JOIN Cliente c ON u.Username = c.Username
	    WHERE u.Username = p_username;
	
	    IF FOUND THEN
	        v_trovato := TRUE;
	    END IF;
	
	    -- Prova con Manager
	    IF NOT v_trovato THEN
	        SELECT u.Password INTO v_password_attuale
	        FROM Utente u
	        JOIN Manager m ON u.Username = m.Username
	        WHERE u.Username = p_username;
	
	        IF FOUND THEN
	            v_trovato := TRUE;
	        END IF;
	    END IF;
	
	    IF NOT v_trovato THEN
	        RETURN 'USER_NOT_FOUND';
	    END IF;
	
	    -- Verifica password attuale
	    IF NOT (v_password_attuale = crypt(p_password_corrente, v_password_attuale)) THEN
	        RETURN 'WRONG_PASSWORD';
	    END IF;
	
	    -- Verifica se nuova password uguale vecchia
	    IF v_password_attuale = crypt(p_password_nuova, v_password_attuale) THEN
	        RETURN 'SAME_PASSWORD';
	    END IF;
	
	    -- Aggiorna la password
	    UPDATE Utente
	    SET Password = crypt(p_password_nuova, gen_salt('bf'))
	    WHERE Username = p_username;
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;
--


-- MANAGER SECTION:
-- Gestione utenze Clienti:
	-- Eliminazione Cliente
	CREATE OR REPLACE FUNCTION elimina_cliente(
	    p_cf VARCHAR
	)
	RETURNS TEXT AS $$
	DECLARE
	    v_username VARCHAR(50);
	BEGIN
	    -- Ottiene username
	    SELECT Username INTO v_username
	    FROM Cliente
	    WHERE CF = p_cf;
	
	    IF NOT FOUND THEN
	        RETURN 'CLIENTE_NOT_FOUND';
	    END IF;
	
	    -- Rimuove Cliente e l'Utente
	    DELETE FROM Cliente WHERE CF = p_cf;
	    DELETE FROM Utente WHERE Username = v_username;
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;


	-- Creazione Cliente
	CREATE OR REPLACE FUNCTION crea_cliente(
	    p_cf VARCHAR,
	    p_nome VARCHAR,
	    p_username VARCHAR
	)
	RETURNS TEXT AS $$
	BEGIN
	    -- Verifica se esiste lo username
	    IF EXISTS (SELECT 1 FROM Utente WHERE Username = p_username) THEN
	        RETURN 'USERNAME_DUPLICATO';
	    END IF;
	
	    -- Verifica se esiste il cliente
	    IF EXISTS (SELECT 1 FROM Cliente WHERE CF = p_cf) THEN
	        RETURN 'CF_DUPLICATO';
	    END IF;
	
	    -- Crea utente con password '1234'
	    INSERT INTO Utente (Username, Password)
	    VALUES (p_username, crypt('1234', gen_salt('bf')));
	
	    -- Crea cliente
	    INSERT INTO Cliente (CF, Nome, Username)
	    VALUES (p_cf, p_nome, p_username);
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;

	
	-- Modifica Cliente
	CREATE OR REPLACE FUNCTION modifica_dato_cliente(
	    p_cf_attuale VARCHAR,
	    p_campo TEXT,
	    p_valore_nuovo TEXT
	)
	RETURNS TEXT AS $$
	BEGIN
	    -- Controlla esistenza cliente
	    IF NOT EXISTS (SELECT 1 FROM Cliente WHERE CF = p_cf_attuale) THEN
	        RETURN 'CLIENTE_NOT_FOUND';
	    END IF;
	
	    -- Modifica in base al campo specificato
	    IF p_campo = 'nome' THEN
	        UPDATE Cliente SET Nome = p_valore_nuovo WHERE CF = p_cf_attuale;
	    ELSIF p_campo = 'cf' THEN
	        -- Verifica che nuovo CF non sia usato
	        IF EXISTS (SELECT 1 FROM Cliente WHERE CF = p_valore_nuovo) THEN
	            RETURN 'CF_DUPLICATO';
	        END IF;
	        UPDATE Cliente SET CF = p_valore_nuovo WHERE CF = p_cf_attuale;
	    ELSIF p_campo = 'username' THEN
	        -- Verifica che username non sia usato
	        IF EXISTS (SELECT 1 FROM Utente WHERE Username = p_valore_nuovo) THEN
	            RETURN 'USERNAME_DUPLICATO';
	        END IF;
	
	        -- Modifica Cliente e Utente
	        UPDATE Utente SET Username = p_valore_nuovo
	        WHERE Username = (SELECT Username FROM Cliente WHERE CF = p_cf_attuale);
	
	        UPDATE Cliente SET Username = p_valore_nuovo WHERE CF = p_cf_attuale;
	    ELSE
	        RETURN 'CAMPO_NON_VALIDO';
	    END IF;
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;
--



-- Gestione Prodotti:
	-- Creazione Prodotto
	CREATE OR REPLACE FUNCTION crea_prodotto(
	    p_nome VARCHAR,
	    p_descrizione TEXT
	)
	RETURNS TEXT AS $$
	BEGIN
	    -- Controlla duplicato
	    IF EXISTS (SELECT 1 FROM Prodotto WHERE Nome = p_nome) THEN
	        RETURN 'NOME_DUPLICATO';
	    END IF;
	
	    INSERT INTO Prodotto (Nome, Descrizione)
	    VALUES (p_nome, p_descrizione);
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;


	-- Eliminazione Prodotto
	CREATE OR REPLACE FUNCTION elimina_prodotto(
	    p_id INTEGER
	)
	RETURNS TEXT AS $$
	BEGIN
	    -- Controlla esistenza
	    IF NOT EXISTS (SELECT 1 FROM Prodotto WHERE IDProdotto = p_id) THEN
	        RETURN 'PRODOTTO_NOT_FOUND';
	    END IF;
	
	    DELETE FROM Prodotto WHERE IDProdotto = p_id;
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;

	
	-- Modifica Prodotto
	CREATE OR REPLACE FUNCTION modifica_prodotto(
	    p_id INTEGER,
	    p_campo TEXT,
	    p_valore TEXT
	)
	RETURNS TEXT AS $$
	BEGIN
	    IF NOT EXISTS (SELECT 1 FROM Prodotto WHERE IDProdotto = p_id) THEN
	        RETURN 'PRODOTTO_NOT_FOUND';
	    END IF;
	
	    IF p_campo = 'nome' THEN
	        UPDATE Prodotto SET Nome = p_valore WHERE IDProdotto = p_id;
	    ELSIF p_campo = 'descrizione' THEN
	        UPDATE Prodotto SET Descrizione = p_valore WHERE IDProdotto = p_id;
	    ELSE
	        RETURN 'CAMPO_NON_VALIDO';
	    END IF;
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;
--



-- Gestione Negozi:
	-- Creazione Negozi:
	CREATE OR REPLACE FUNCTION crea_negozio(
	    p_orari VARCHAR,
	    p_indirizzo TEXT,
	    p_cf_manager VARCHAR DEFAULT NULL
	)
	RETURNS TEXT AS $$
	BEGIN
	    -- Se CF manager specificato, controlla esistenza
	    IF p_cf_manager IS NOT NULL AND
	       NOT EXISTS (SELECT 1 FROM Manager WHERE CF = p_cf_manager) THEN
	        RETURN 'MANAGER_NOT_FOUND';
	    END IF;
	
	    -- Inserisce negozio
	    INSERT INTO Negozio (OrariApertura, Indirizzo, ManagerCF)
	    VALUES (p_orari, p_indirizzo, p_cf_manager);
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;

		
	-- Eliminazione Negozi:
	CREATE OR REPLACE FUNCTION elimina_negozio(
	    p_id INTEGER
	)
	RETURNS TEXT AS $$
	BEGIN
	    IF NOT EXISTS (SELECT 1 FROM Negozio WHERE IDNegozio = p_id) THEN
	        RETURN 'NEGOZIO_NOT_FOUND';
	    END IF;
	
	    -- Aggiorna stato negozio e orari a NULL 
	    UPDATE Negozio
	    SET Aperto = FALSE,
	        OrariApertura = NULL
	    WHERE IDNegozio = p_id;
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;

	-- Modifica Negozi:
	CREATE OR REPLACE FUNCTION modifica_negozio(
	    p_id INTEGER,
	    p_campo TEXT,
	    p_valore TEXT
	)
	RETURNS TEXT AS $$
	BEGIN
	    IF NOT EXISTS (SELECT 1 FROM Negozio WHERE IDNegozio = p_id) THEN
	        RETURN 'NEGOZIO_NOT_FOUND';
	    END IF;
	
	    IF p_campo = 'orari' THEN
	        UPDATE Negozio SET OrariApertura = p_valore WHERE IDNegozio = p_id;
	    ELSIF p_campo = 'indirizzo' THEN
	        UPDATE Negozio SET Indirizzo = p_valore WHERE IDNegozio = p_id;
	    ELSIF p_campo = 'manager' THEN
	        -- Verifica che nuovo manager esista
	        IF NOT EXISTS (SELECT 1 FROM Manager WHERE CF = p_valore) THEN
	            RETURN 'MANAGER_NOT_FOUND';
	        END IF;
	        UPDATE Negozio SET ManagerCF = p_valore WHERE IDNegozio = p_id;
	    ELSE
	        RETURN 'CAMPO_NON_VALIDO';
	    END IF;
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;
--



-- Gestioni Prodotti nei negozi:
	-- Inserisce prodotto in negozio
	CREATE OR REPLACE FUNCTION aggiungi_vendita_prodotto(
	    p_id_negozio INTEGER,
	    p_id_prodotto INTEGER,
	    p_prezzo NUMERIC,
	    p_quantita INTEGER
	)
	RETURNS TEXT AS $$
	BEGIN
	    -- Verifica esistenza negozio e prodotto
	    IF NOT EXISTS (SELECT 1 FROM Negozio WHERE IDNegozio = p_id_negozio) THEN
	        RETURN 'NEGOZIO_NOT_FOUND';
	    END IF;
	
	    IF NOT EXISTS (SELECT 1 FROM Prodotto WHERE IDProdotto = p_id_prodotto) THEN
	        RETURN 'PRODOTTO_NOT_FOUND';
	    END IF;
	
	    -- Verifica se già presente
	    IF EXISTS (
	        SELECT 1 FROM Vende
	        WHERE NegozioID = p_id_negozio AND ProdottoID = p_id_prodotto
	    ) THEN
	        RETURN 'PRODOTTO_GIA_PRESENTE';
	    END IF;
	
	    -- Inserisce prodotto
	    INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita)
	    VALUES (p_id_negozio, p_id_prodotto, p_prezzo, p_quantita);
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;


	-- Elimina Prodotto da negozio
	CREATE OR REPLACE FUNCTION elimina_vendita_prodotto(
	    p_id_negozio INTEGER,
	    p_id_prodotto INTEGER
	)
	RETURNS TEXT AS $$
	BEGIN
	    IF NOT EXISTS (
	        SELECT 1 FROM Vende
	        WHERE NegozioID = p_id_negozio AND ProdottoID = p_id_prodotto
	    ) THEN
	        RETURN 'VOCE_NON_TROVATA';
	    END IF;
	
	    DELETE FROM Vende
	    WHERE NegozioID = p_id_negozio AND ProdottoID = p_id_prodotto;
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;

	
	-- Modifica Prodotto in negozio
	CREATE OR REPLACE FUNCTION modifica_vendita_prodotto(
	    p_id_negozio INTEGER,
	    p_id_prodotto INTEGER,
	    p_campo TEXT,
	    p_valore NUMERIC
	)
	RETURNS TEXT AS $$
	BEGIN
	    IF NOT EXISTS (
	        SELECT 1 FROM Vende
	        WHERE NegozioID = p_id_negozio AND ProdottoID = p_id_prodotto
	    ) THEN
	        RETURN 'VOCE_NON_TROVATA';
	    END IF;
	
	    IF p_campo = 'prezzo' THEN
	        UPDATE Vende
	        SET Prezzo = p_valore
	        WHERE NegozioID = p_id_negozio AND ProdottoID = p_id_prodotto;
	    ELSIF p_campo = 'quantita' THEN
	        UPDATE Vende
	        SET Quantita = FLOOR(p_valore)
	        WHERE NegozioID = p_id_negozio AND ProdottoID = p_id_prodotto;
	    ELSE
	        RETURN 'CAMPO_NON_VALIDO';
	    END IF;
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;
--



-- Gestioni Fornitori:
	-- Crea Fornitore
	CREATE OR REPLACE FUNCTION crea_fornitore(
	    p_piva VARCHAR,
	    p_indirizzo TEXT
	)
	RETURNS TEXT AS $$
	BEGIN
	    IF EXISTS (SELECT 1 FROM Fornitore WHERE PIVA = p_piva) THEN
	        RETURN 'PIVA_DUPLICATA';
	    END IF;
	
	    INSERT INTO Fornitore (PIVA, Indirizzo)
	    VALUES (p_piva, p_indirizzo);
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;
	
	
	-- Elimina Fornitore
	CREATE OR REPLACE FUNCTION elimina_fornitore(
	    p_piva VARCHAR
	)
	RETURNS TEXT AS $$
	BEGIN
	    IF NOT EXISTS (SELECT 1 FROM Fornitore WHERE PIVA = p_piva) THEN
	        RETURN 'FORNITORE_NOT_FOUND';
	    END IF;
	
	    DELETE FROM Fornitore WHERE PIVA = p_piva;
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;
	
	
	-- Modifica Fornitore
	CREATE OR REPLACE FUNCTION modifica_fornitore(
	    p_piva_attuale VARCHAR,
	    p_campo TEXT,
	    p_valore TEXT
	)
	RETURNS TEXT AS $$
	BEGIN
	    IF NOT EXISTS (SELECT 1 FROM Fornitore WHERE PIVA = p_piva_attuale) THEN
	        RETURN 'FORNITORE_NOT_FOUND';
	    END IF;
	
	    IF p_campo = 'indirizzo' THEN
	        UPDATE Fornitore
	        SET Indirizzo = p_valore
	        WHERE PIVA = p_piva_attuale;
	
	    ELSIF p_campo = 'piva' THEN
	        -- Verifica che nuova PIVA non sia usata
	        IF EXISTS (SELECT 1 FROM Fornitore WHERE PIVA = p_valore) THEN
	            RETURN 'PIVA_DUPLICATA';
	        END IF;
	
	        UPDATE Fornitore
	        SET PIVA = p_valore
	        WHERE PIVA = p_piva_attuale;
	
	    ELSE
	        RETURN 'CAMPO_NON_VALIDO';
	    END IF;
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;
--



-- Gestione prodotti in Fornitori
	-- Inserisce una fornitura
	CREATE OR REPLACE FUNCTION aggiungi_fornitura(
	    p_piva VARCHAR,
	    p_prodotto INTEGER,
	    p_prezzo NUMERIC,
	    p_disp INTEGER
	)
	RETURNS TEXT AS $$
	BEGIN
	    -- Controlla esistenza fornitore e prodotto
	    IF NOT EXISTS (SELECT 1 FROM Fornitore WHERE PIVA = p_piva) THEN
	        RETURN 'FORNITORE_NOT_FOUND';
	    END IF;
	
	    IF NOT EXISTS (SELECT 1 FROM Prodotto WHERE IDProdotto = p_prodotto) THEN
	        RETURN 'PRODOTTO_NOT_FOUND';
	    END IF;
	
	    -- Controlla se fornitura già esistente
	    IF EXISTS (
	        SELECT 1 FROM Fornisce
	        WHERE FornitorePIVA = p_piva AND ProdottoID = p_prodotto
	    ) THEN
	        RETURN 'FORNITURA_DUPLICATA';
	    END IF;
	
	    -- Inserisce nuova fornitura
	    INSERT INTO Fornisce (FornitorePIVA, ProdottoID, PrezzoUnitario, Disponibilita)
	    VALUES (p_piva, p_prodotto, p_prezzo, p_disp);
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;
	
	
	-- Elimina una fornitura
	CREATE OR REPLACE FUNCTION elimina_fornitura(
	    p_piva VARCHAR,
	    p_prodotto INTEGER
	)
	RETURNS TEXT AS $$
	BEGIN
	    IF NOT EXISTS (
	        SELECT 1 FROM Fornisce
	        WHERE FornitorePIVA = p_piva AND ProdottoID = p_prodotto
	    ) THEN
	        RETURN 'FORNITURA_NON_TROVATA';
	    END IF;
	
	    DELETE FROM Fornisce
	    WHERE FornitorePIVA = p_piva AND ProdottoID = p_prodotto;
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;
	
	
	-- Modifica una fornitura
	CREATE OR REPLACE FUNCTION modifica_fornitura(
	    p_piva VARCHAR,
	    p_prodotto INTEGER,
	    p_campo TEXT,
	    p_valore NUMERIC
	)
	RETURNS TEXT AS $$
	BEGIN
	    IF NOT EXISTS (
	        SELECT 1 FROM Fornisce
	        WHERE FornitorePIVA = p_piva AND ProdottoID = p_prodotto
	    ) THEN
	        RETURN 'FORNITURA_NON_TROVATA';
	    END IF;
	
	    IF p_campo = 'prezzo' THEN
	        UPDATE Fornisce
	        SET PrezzoUnitario = p_valore
	        WHERE FornitorePIVA = p_piva AND ProdottoID = p_prodotto;
	    ELSIF p_campo = 'disponibilita' THEN
	        UPDATE Fornisce
	        SET Disponibilita = FLOOR(p_valore)
	        WHERE FornitorePIVA = p_piva AND ProdottoID = p_prodotto;
	    ELSE
	        RETURN 'CAMPO_NON_VALIDO';
	    END IF;
	
	    RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;
--




-- CLIENTE SECTION:
-- Visualizzare tutti i prodotti di un negozio:
	CREATE OR REPLACE FUNCTION prodotti_disponibili_negozio(
	    p_id_negozio INTEGER
	)
	RETURNS TABLE (
	    id_prodotto INTEGER,
	    nome_prodotto VARCHAR,
	    descrizione TEXT,
	    prezzo NUMERIC,
	    quantita INTEGER
	) AS $$
	BEGIN
	    RETURN QUERY
	    SELECT
	        p.IDProdotto,
	        p.Nome,
	        p.Descrizione,
	        v.Prezzo,
	        v.Quantita
	    FROM Vende v
	    JOIN Prodotto p ON p.IDProdotto = v.ProdottoID
	    WHERE v.NegozioID = p_id_negozio
	      AND v.Quantita > 0
	    ORDER BY p.Nome;
	END;
	$$ LANGUAGE plpgsql;
--



-- Effettua acquisto:
	CREATE OR REPLACE FUNCTION effettua_acquisto(
	    p_CF_cliente VARCHAR,
	    p_ID_negozio INTEGER,
	    p_prodotti INTEGER[],
	    p_quantita INTEGER[],
	    p_applica_sconto BOOLEAN
	)
	RETURNS TEXT AS $$
	DECLARE
	    i INTEGER;
	    v_id_prodotto INTEGER;
	    v_qta INTEGER;
	    v_qta_disponibile INTEGER;
	    v_prezzo_unitario NUMERIC;
	    v_totale NUMERIC := 0;
	    v_id_fattura INTEGER;
	    v_output TEXT;
	    v_id_string TEXT;
	BEGIN
	    -- Verifica che gli array abbiano stessa lunghezza
	    IF array_length(p_prodotti, 1) IS DISTINCT FROM array_length(p_quantita, 1) THEN
	        RETURN 'ARRAY_LENGTH_MISMATCH';
	    END IF;
	
	    -- Ciclo su ogni prodotto per validare disponibilità e calcolare il totale
	    FOR i IN 1 .. array_length(p_prodotti, 1) LOOP
	        v_id_prodotto := p_prodotti[i];
	        v_qta := p_quantita[i];
	
	        -- Ottiene prezzo e disponibilità del prodotto
	        SELECT Prezzo, Quantita INTO v_prezzo_unitario, v_qta_disponibile
	        FROM Vende
	        WHERE NegozioID = p_ID_negozio AND ProdottoID = v_id_prodotto;
	
	        -- Se prodotto non esiste nel negozio interrompe
	        IF NOT FOUND THEN
	            RETURN 'PRODOTTO_NON_PRESENTE';
	        -- Se quantità richiesta > disponibilità interrompe
	        ELSIF v_qta_disponibile < v_qta THEN
	            RETURN 'QUANTITA_NON_DISPONIBILE';
	        END IF;
	
	        -- Accumula costo totale
	        v_totale := v_totale + (v_prezzo_unitario * v_qta);
	    END LOOP;
	
	    -- Crea la fattura
	    v_output := acquisto_cliente(p_CF_cliente, p_ID_negozio, v_totale, p_applica_sconto);
	
	    -- Estrae l’ID fattura dalla stringa di output
	    v_id_string := SPLIT_PART(v_output, '_', 4);
	    v_id_fattura := v_id_string::INTEGER;
	
	    -- Inserisce righe in VoceFattura e aggiorna magazzino negozio
	    FOR i IN 1 .. array_length(p_prodotti, 1) LOOP
	        v_id_prodotto := p_prodotti[i];
	        v_qta := p_quantita[i];
	
	        -- Ottiene prezzo del prodotto
	        SELECT Prezzo INTO v_prezzo_unitario
	        FROM Vende
	        WHERE NegozioID = p_ID_negozio AND ProdottoID = v_id_prodotto;
	
	        -- Inserisce riga nella voce della fattura
	        INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita)
	        VALUES (v_id_fattura, v_id_prodotto, v_prezzo_unitario, v_qta);
	
	        -- Aggiorna disponibilità prodotto nel negozio
	        UPDATE Vende
	        SET Quantita = Quantita - v_qta
	        WHERE NegozioID = p_ID_negozio AND ProdottoID = v_id_prodotto;
	    END LOOP;
	
	    -- Ritorna la stringa di output della funzione fattura
	    RETURN v_output;
	END;
	$$ LANGUAGE plpgsql;
--



-- Visualizza saldo Tessera:
	CREATE OR REPLACE FUNCTION visualizza_saldo_punti(
	    p_cf_cliente VARCHAR
	)
	RETURNS TABLE (
	    id_tessera INTEGER,
	    data_richiesta DATE,
	    negozio_id INTEGER,
	    saldo_punti INTEGER
	) AS $$
	BEGIN
	    RETURN QUERY
	    SELECT t.IDTessera, t.DataRichiesta, t.NegozioID, t.SaldoPunti
	    FROM Tessera t
	    WHERE t.ClienteCF = p_cf_cliente;
	END;
	$$ LANGUAGE plpgsql;
--
