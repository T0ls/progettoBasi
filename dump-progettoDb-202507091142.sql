--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

-- Started on 2025-07-09 11:42:06

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 23296)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 5011 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 315 (class 1255 OID 25798)
-- Name: acquisto_cliente(character varying, integer, numeric, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.acquisto_cliente(p_cf_cliente character varying, p_id_negozio integer, p_importo numeric, p_sconto boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
	DECLARE
	    v_punti INTEGER;
	    v_soglia_usata INTEGER := 0;
	    v_percentuale NUMERIC := 0;
	    v_sconto_euro NUMERIC := 0;
	    v_totale_finale NUMERIC := p_importo;
	    v_id_fattura INTEGER;
	    v_flag_testo TEXT;
	BEGIN
	    -- Controlla esistenza tessera
	    SELECT SaldoPunti INTO v_punti
	    FROM Tessera
	    WHERE ClienteCF = p_CF_cliente;
	
	    IF NOT FOUND THEN
	        RAISE EXCEPTION 'Il cliente non possiede una tessera fedeltà';
	    END IF;
	
	    -- Se è stato richiesto lo sconto
	    IF p_sconto THEN
	        IF v_punti >= 300 THEN
	            v_soglia_usata := 300;
	            v_percentuale := 30;
	        ELSIF v_punti >= 200 THEN
	            v_soglia_usata := 200;
	            v_percentuale := 15;
	        ELSIF v_punti >= 100 THEN
	            v_soglia_usata := 100;
	            v_percentuale := 5;
	        END IF;
	
	        -- Se si può applicare sconto
	        IF v_soglia_usata > 0 THEN
	            v_sconto_euro := ROUND(LEAST(p_importo * v_percentuale / 100, 100), 2);
	            v_totale_finale := p_importo - v_sconto_euro;
	            v_flag_testo := CONCAT('OK_SCONTO_', v_percentuale::TEXT);
	        ELSE
	            v_flag_testo := 'OK_NO_SCONTO';
	        END IF;
	    ELSE
	        v_flag_testo := 'OK_SENZA_RICHIESTA';
	    END IF;
	
	    -- Inserisce la fattura
	    INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato)
	    VALUES (p_CF_cliente, p_ID_negozio, CURRENT_DATE, v_percentuale, v_totale_finale)
	    RETURNING IDFattura INTO v_id_fattura;
	
	    -- Se applicato sconto, scala punti
	    IF v_soglia_usata > 0 THEN
	        UPDATE Tessera
	        SET SaldoPunti = SaldoPunti - v_soglia_usata
	        WHERE ClienteCF = p_CF_cliente;
	    END IF;
	
	    RETURN v_flag_testo || '_' || v_id_fattura;
	END;
	$$;


--
-- TOC entry 301 (class 1255 OID 25799)
-- Name: aggiorna_disponibilita_fornitore(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.aggiorna_disponibilita_fornitore() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
	  UPDATE Fornisce
	  SET Disponibilita = Disponibilita - NEW.Quantita
	  WHERE FornitorePIVA = NEW.FornitorePIVA
	    AND ProdottoID = NEW.ProdottoID;
	
	  RETURN NEW;
	END;
	$$;


--
-- TOC entry 292 (class 1255 OID 25796)
-- Name: aggiorna_punti_tessera(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.aggiorna_punti_tessera() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
	  -- Se il cliente ha una tessera
	  IF EXISTS (
	    SELECT 1 FROM Tessera WHERE ClienteCF = NEW.ClienteCF
	  ) THEN
	    -- Aggiorna il saldo punti sommando i punti derivati dall'acquisto
	    UPDATE Tessera
	    SET SaldoPunti = SaldoPunti + FLOOR(NEW.TotalePagato)
	    WHERE ClienteCF = NEW.ClienteCF;
	  END IF;
	
	  RETURN NEW;
	END;
	$$;


--
-- TOC entry 295 (class 1255 OID 25836)
-- Name: aggiungi_fornitura(character varying, integer, numeric, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.aggiungi_fornitura(p_piva character varying, p_prodotto integer, p_prezzo numeric, p_disp integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    -- Controlli esistenza fornitore e prodotto
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
	$$;


--
-- TOC entry 312 (class 1255 OID 25830)
-- Name: aggiungi_vendita_prodotto(integer, integer, numeric, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.aggiungi_vendita_prodotto(p_id_negozio integer, p_id_prodotto integer, p_prezzo numeric, p_quantita integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
	
	    -- Inserisce
	    INSERT INTO Vende (NegozioID, ProdottoID, Prezzo, Quantita)
	    VALUES (p_id_negozio, p_id_prodotto, p_prezzo, p_quantita);
	
	    RETURN 'OK';
	END;
	$$;


--
-- TOC entry 305 (class 1255 OID 25822)
-- Name: crea_cliente(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.crea_cliente(p_cf character varying, p_nome character varying, p_username character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    -- Verifica se esiste già lo username
	    IF EXISTS (SELECT 1 FROM Utente WHERE Username = p_username) THEN
	        RETURN 'USERNAME_DUPLICATO';
	    END IF;
	
	    -- Verifica se esiste già il cliente
	    IF EXISTS (SELECT 1 FROM Cliente WHERE CF = p_cf) THEN
	        RETURN 'CF_DUPLICATO';
	    END IF;
	
	    -- Crea utente con password di default '1234'
	    INSERT INTO Utente (Username, Password)
	    VALUES (p_username, crypt('1234', gen_salt('bf')));
	
	    -- Crea cliente
	    INSERT INTO Cliente (CF, Nome, Username)
	    VALUES (p_cf, p_nome, p_username);
	
	    RETURN 'OK';
	END;
	$$;


--
-- TOC entry 293 (class 1255 OID 25833)
-- Name: crea_fornitore(character varying, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.crea_fornitore(p_piva character varying, p_indirizzo text) RETURNS text
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    IF EXISTS (SELECT 1 FROM Fornitore WHERE PIVA = p_piva) THEN
	        RETURN 'PIVA_DUPLICATA';
	    END IF;
	
	    INSERT INTO Fornitore (PIVA, Indirizzo)
	    VALUES (p_piva, p_indirizzo);
	
	    RETURN 'OK';
	END;
	$$;


--
-- TOC entry 309 (class 1255 OID 25827)
-- Name: crea_negozio(character varying, text, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.crea_negozio(p_orari character varying, p_indirizzo text, p_cf_manager character varying DEFAULT NULL::character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    -- Se CF manager è specificato, controlla che esista
	    IF p_cf_manager IS NOT NULL AND
	       NOT EXISTS (SELECT 1 FROM Manager WHERE CF = p_cf_manager) THEN
	        RETURN 'MANAGER_NOT_FOUND';
	    END IF;
	
	    -- Inserisci negozio
	    INSERT INTO Negozio (OrariApertura, Indirizzo, ManagerCF)
	    VALUES (p_orari, p_indirizzo, p_cf_manager);
	
	    RETURN 'OK';
	END;
	$$;


--
-- TOC entry 306 (class 1255 OID 25824)
-- Name: crea_prodotto(character varying, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.crea_prodotto(p_nome character varying, p_descrizione text) RETURNS text
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    -- Controlla duplicato opzionale (se necessario)
	    IF EXISTS (SELECT 1 FROM Prodotto WHERE Nome = p_nome) THEN
	        RETURN 'NOME_DUPLICATO';
	    END IF;
	
	    INSERT INTO Prodotto (Nome, Descrizione)
	    VALUES (p_nome, p_descrizione);
	
	    RETURN 'OK';
	END;
	$$;


--
-- TOC entry 319 (class 1255 OID 25840)
-- Name: effettua_acquisto(character varying, integer, integer[], integer[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.effettua_acquisto(p_cf_cliente character varying, p_id_negozio integer, p_prodotti integer[], p_quantita integer[], p_applica_sconto boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
	DECLARE
	    i INTEGER;                          -- indice del ciclo
	    v_id_prodotto INTEGER;             -- ID del prodotto corrente
	    v_qta INTEGER;                     -- quantità richiesta del prodotto corrente
	    v_qta_disponibile INTEGER;         -- quantità disponibile nel negozio
	    v_prezzo_unitario NUMERIC;        -- prezzo del prodotto nel negozio
	    v_totale NUMERIC := 0;            -- totale iniziale della spesa (senza sconto)
	    v_id_fattura INTEGER;             -- ID della fattura generata
	    v_output TEXT;                    -- output della funzione sconto (es: OK_SCONTO_15_42)
	    v_id_string TEXT;                 -- parte finale dell'output con solo l'ID fattura
	BEGIN
	    -- Verifica che gli array abbiano stessa lunghezza
	    IF array_length(p_prodotti, 1) IS DISTINCT FROM array_length(p_quantita, 1) THEN
	        RETURN 'ARRAY_LENGTH_MISMATCH';
	    END IF;
	
	    -- Ciclo su ogni prodotto per validare disponibilità e calcolare il totale
	    FOR i IN 1 .. array_length(p_prodotti, 1) LOOP
	        v_id_prodotto := p_prodotti[i];
	        v_qta := p_quantita[i];
	
	        -- Ottiene prezzo e disponibilità per il prodotto richiesto
	        SELECT Prezzo, Quantita INTO v_prezzo_unitario, v_qta_disponibile
	        FROM Vende
	        WHERE NegozioID = p_ID_negozio AND ProdottoID = v_id_prodotto;
	
	        -- Se il prodotto non esiste nel negozio, interrompe
	        IF NOT FOUND THEN
	            RETURN 'PRODOTTO_NON_PRESENTE';
	        -- Se la quantità richiesta eccede la disponibilità, interrompe
	        ELSIF v_qta_disponibile < v_qta THEN
	            RETURN 'QUANTITA_NON_DISPONIBILE';
	        END IF;
	
	        -- Accumula il costo totale
	        v_totale := v_totale + (v_prezzo_unitario * v_qta);
	    END LOOP;
	
	    -- Crea la fattura, con o senza sconto
	    v_output := acquisto_cliente(p_CF_cliente, p_ID_negozio, v_totale, p_applica_sconto);
	
	    -- Estrae l’ID fattura dalla stringa (es: da OK_SCONTO_15_42 prende 42)
	    v_id_string := SPLIT_PART(v_output, '_', 4);
	    v_id_fattura := v_id_string::INTEGER;
	
	    -- Inserisce righe in VoceFattura e aggiorna magazzino Vende
	    FOR i IN 1 .. array_length(p_prodotti, 1) LOOP
	        v_id_prodotto := p_prodotti[i];
	        v_qta := p_quantita[i];
	
	        -- Ottiene di nuovo il prezzo del prodotto (sicurezza contro variazioni)
	        SELECT Prezzo INTO v_prezzo_unitario
	        FROM Vende
	        WHERE NegozioID = p_ID_negozio AND ProdottoID = v_id_prodotto;
	
	        -- Inserisce riga nella voce della fattura
	        INSERT INTO VoceFattura (FatturaID, ProdottoID, PrezzoUnitario, Quantita)
	        VALUES (v_id_fattura, v_id_prodotto, v_prezzo_unitario, v_qta);
	
	        -- Aggiorna disponibilità magazzino nel negozio
	        UPDATE Vende
	        SET Quantita = Quantita - v_qta
	        WHERE NegozioID = p_ID_negozio AND ProdottoID = v_id_prodotto;
	    END LOOP;
	
	    -- Ritorna la stringa di output della funzione fattura (include info sullo sconto)
	    RETURN v_output;
	END;
	$$;


--
-- TOC entry 302 (class 1255 OID 25621)
-- Name: effettua_ordine(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.effettua_ordine(p_id_negozio integer, p_id_prodotto integer, p_quantita integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
	DECLARE
	  v_fornitore_scelto VARCHAR(11);
	  v_aperto BOOLEAN;
	BEGIN
	  -- Verifica che il negozio sia aperto
	  SELECT Aperto INTO v_aperto
	  FROM Negozio
	  WHERE IDNegozio = p_ID_negozio;
	
	  IF NOT FOUND THEN
	    RETURN 'NEGOZIO_NOT_FOUND';
	  END IF;
	
	  IF NOT v_aperto THEN
	    RETURN 'NEGOZIO_CHIUSO';
	  END IF;
	
	  -- Seleziona il fornitore con disponibilità sufficiente e prezzo minimo
	  SELECT FornitorePIVA
	  INTO v_fornitore_scelto
	  FROM Fornisce
	  WHERE ProdottoID = p_ID_prodotto
	    AND Disponibilita >= p_quantita
	  ORDER BY PrezzoUnitario ASC
	  LIMIT 1;
	
	  -- Se non c'è fornitore disponibile, segnala errore
	  IF NOT FOUND THEN
	    RETURN 'NESSUN_FORNITORE_DISPONIBILE';
	  END IF;
	
	  -- Inserisce l’ordine nella tabella Ordina
	  INSERT INTO Ordina (NegozioID, ProdottoID, FornitorePIVA, DataConsegna, Quantita)
	  VALUES (p_ID_negozio, p_ID_prodotto, v_fornitore_scelto, CURRENT_DATE, p_quantita);
	
	  RETURN 'OK';
	END;
	$$;


--
-- TOC entry 304 (class 1255 OID 25821)
-- Name: elimina_cliente(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.elimina_cliente(p_cf character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
	DECLARE
	    v_username VARCHAR(50);
	BEGIN
	    -- Ottieni username associato
	    SELECT Username INTO v_username
	    FROM Cliente
	    WHERE CF = p_cf;
	
	    IF NOT FOUND THEN
	        RETURN 'CLIENTE_NOT_FOUND';
	    END IF;
	
	    -- Rimuove il Cliente (CASCADE elimina anche la Tessera) e l'Utente
	    DELETE FROM Cliente WHERE CF = p_cf;
	    DELETE FROM Utente WHERE Username = v_username;
	
	    RETURN 'OK';
	END;
	$$;


--
-- TOC entry 294 (class 1255 OID 25834)
-- Name: elimina_fornitore(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.elimina_fornitore(p_piva character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    IF NOT EXISTS (SELECT 1 FROM Fornitore WHERE PIVA = p_piva) THEN
	        RETURN 'FORNITORE_NOT_FOUND';
	    END IF;
	
	    DELETE FROM Fornitore WHERE PIVA = p_piva;
	
	    RETURN 'OK';
	END;
	$$;


--
-- TOC entry 296 (class 1255 OID 25837)
-- Name: elimina_fornitura(character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.elimina_fornitura(p_piva character varying, p_prodotto integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
	$$;


--
-- TOC entry 310 (class 1255 OID 25828)
-- Name: elimina_negozio(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.elimina_negozio(p_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    IF NOT EXISTS (SELECT 1 FROM Negozio WHERE IDNegozio = p_id) THEN
	        RETURN 'NEGOZIO_NOT_FOUND';
	    END IF;
	
	    -- Aggiorna lo stato del negozio invece di eliminarlo
	    UPDATE Negozio
	    SET Aperto = FALSE,
	        OrariApertura = NULL
	    WHERE IDNegozio = p_id;
	
	    RETURN 'OK';
	END;
	$$;


--
-- TOC entry 307 (class 1255 OID 25825)
-- Name: elimina_prodotto(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.elimina_prodotto(p_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    -- Controlla esistenza
	    IF NOT EXISTS (SELECT 1 FROM Prodotto WHERE IDProdotto = p_id) THEN
	        RETURN 'PRODOTTO_NOT_FOUND';
	    END IF;
	
	    DELETE FROM Prodotto WHERE IDProdotto = p_id;
	    RETURN 'OK';
	END;
	$$;


--
-- TOC entry 313 (class 1255 OID 25831)
-- Name: elimina_vendita_prodotto(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.elimina_vendita_prodotto(p_id_negozio integer, p_id_prodotto integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
	$$;


--
-- TOC entry 300 (class 1255 OID 25813)
-- Name: gestisci_quantita_zero(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gestisci_quantita_zero() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
	  -- Se la quantità diventa zero
	  IF NEW.Quantita = 0 THEN
	
	    -- Elimina il prodotto dalla vendita
	    DELETE FROM Vende
	    WHERE NegozioID = NEW.NegozioID
	      AND ProdottoID = NEW.ProdottoID;
	
	    -- Effettua ordine automatico di 1 unità usando la funzione modulare già definita
	    PERFORM effettua_ordine(NEW.NegozioID, NEW.ProdottoID, 1);
	
	  END IF;
	
	  RETURN NEW;
	END;
	$$;


--
-- TOC entry 303 (class 1255 OID 25819)
-- Name: login_utente(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.login_utente(p_username character varying, p_password character varying) RETURNS TABLE(username character varying, codice_fiscale character varying, nome character varying)
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    -- Cliente
	    RETURN QUERY
	    SELECT u.Username, c.CF, c.Nome
	    FROM Utente u
	    JOIN Cliente c ON u.Username = c.Username
	    WHERE u.Username = p_username
	      AND u.Password = crypt(p_password, u.Password);
	
	    -- Se non è cliente, prova come manager
	    IF NOT FOUND THEN
	        RETURN QUERY
	        SELECT u.Username, m.CF, m.Nome
	        FROM Utente u
	        JOIN Manager m ON u.Username = m.Username
	        WHERE u.Username = p_username
	          AND u.Password = crypt(p_password, u.Password);
	    END IF;
	END;
	$$;


--
-- TOC entry 317 (class 1255 OID 25823)
-- Name: modifica_dato_cliente(character varying, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.modifica_dato_cliente(p_cf_attuale character varying, p_campo text, p_valore_nuovo text) RETURNS text
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    -- Controlla esistenza cliente
	    IF NOT EXISTS (SELECT 1 FROM Cliente WHERE CF = p_cf_attuale) THEN
	        RETURN 'CLIENTE_NOT_FOUND';
	    END IF;
	
	    -- Modifica in base al campo specificato
	    IF p_campo = 'nome' THEN
	        UPDATE Cliente SET Nome = p_valore_nuovo WHERE CF = p_cf_attuale;
	    ELSIF p_campo = 'cf' THEN
	        -- Verifica che il nuovo CF non sia già usato
	        IF EXISTS (SELECT 1 FROM Cliente WHERE CF = p_valore_nuovo) THEN
	            RETURN 'CF_DUPLICATO';
	        END IF;
	        UPDATE Cliente SET CF = p_valore_nuovo WHERE CF = p_cf_attuale;
	    ELSIF p_campo = 'username' THEN
	        -- Verifica che username non sia già usato
	        IF EXISTS (SELECT 1 FROM Utente WHERE Username = p_valore_nuovo) THEN
	            RETURN 'USERNAME_DUPLICATO';
	        END IF;
	
	        -- Modifica sia Cliente che Utente
	        UPDATE Utente SET Username = p_valore_nuovo
	        WHERE Username = (SELECT Username FROM Cliente WHERE CF = p_cf_attuale);
	
	        UPDATE Cliente SET Username = p_valore_nuovo WHERE CF = p_cf_attuale;
	    ELSE
	        RETURN 'CAMPO_NON_VALIDO';
	    END IF;
	
	    RETURN 'OK';
	END;
	$$;


--
-- TOC entry 318 (class 1255 OID 25835)
-- Name: modifica_fornitore(character varying, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.modifica_fornitore(p_piva_attuale character varying, p_campo text, p_valore text) RETURNS text
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    IF NOT EXISTS (SELECT 1 FROM Fornitore WHERE PIVA = p_piva_attuale) THEN
	        RETURN 'FORNITORE_NOT_FOUND';
	    END IF;
	
	    IF p_campo = 'indirizzo' THEN
	        UPDATE Fornitore
	        SET Indirizzo = p_valore
	        WHERE PIVA = p_piva_attuale;
	
	    ELSIF p_campo = 'piva' THEN
	        -- Verifica che la nuova PIVA non sia già usata
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
	$$;


--
-- TOC entry 297 (class 1255 OID 25838)
-- Name: modifica_fornitura(character varying, integer, text, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.modifica_fornitura(p_piva character varying, p_prodotto integer, p_campo text, p_valore numeric) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
	$$;


--
-- TOC entry 311 (class 1255 OID 25829)
-- Name: modifica_negozio(integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.modifica_negozio(p_id integer, p_campo text, p_valore text) RETURNS text
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    IF NOT EXISTS (SELECT 1 FROM Negozio WHERE IDNegozio = p_id) THEN
	        RETURN 'NEGOZIO_NOT_FOUND';
	    END IF;
	
	    IF p_campo = 'orari' THEN
	        UPDATE Negozio SET OrariApertura = p_valore WHERE IDNegozio = p_id;
	    ELSIF p_campo = 'indirizzo' THEN
	        UPDATE Negozio SET Indirizzo = p_valore WHERE IDNegozio = p_id;
	    ELSIF p_campo = 'manager' THEN
	        -- Verifica che il nuovo manager esista
	        IF NOT EXISTS (SELECT 1 FROM Manager WHERE CF = p_valore) THEN
	            RETURN 'MANAGER_NOT_FOUND';
	        END IF;
	        UPDATE Negozio SET ManagerCF = p_valore WHERE IDNegozio = p_id;
	    ELSE
	        RETURN 'CAMPO_NON_VALIDO';
	    END IF;
	
	    RETURN 'OK';
	END;
	$$;


--
-- TOC entry 316 (class 1255 OID 25820)
-- Name: modifica_password(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.modifica_password(p_username character varying, p_password_corrente character varying, p_password_nuova character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
	
	    -- Se non trovato come cliente, prova con Manager
	    IF NOT v_trovato THEN
	        SELECT u.Password INTO v_password_attuale
	        FROM Utente u
	        JOIN Manager m ON u.Username = m.Username
	        WHERE u.Username = p_username;
	
	        IF FOUND THEN
	            v_trovato := TRUE;
	        END IF;
	    END IF;
	
	    -- Ancora non trovato: errore
	    IF NOT v_trovato THEN
	        RETURN 'USER_NOT_FOUND';
	    END IF;
	
	    -- Verifica password attuale
	    IF NOT (v_password_attuale = crypt(p_password_corrente, v_password_attuale)) THEN
	        RETURN 'WRONG_PASSWORD';
	    END IF;
	
	    -- Verifica se nuova password è uguale alla vecchia
	    IF v_password_attuale = crypt(p_password_nuova, v_password_attuale) THEN
	        RETURN 'SAME_PASSWORD';
	    END IF;
	
	    -- Aggiorna la password
	    UPDATE Utente
	    SET Password = crypt(p_password_nuova, gen_salt('bf'))
	    WHERE Username = p_username;
	
	    RETURN 'OK';
	END;
	$$;


--
-- TOC entry 308 (class 1255 OID 25826)
-- Name: modifica_prodotto(integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.modifica_prodotto(p_id integer, p_campo text, p_valore text) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
	$$;


--
-- TOC entry 314 (class 1255 OID 25832)
-- Name: modifica_vendita_prodotto(integer, integer, text, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.modifica_vendita_prodotto(p_id_negozio integer, p_id_prodotto integer, p_campo text, p_valore numeric) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
	$$;


--
-- TOC entry 298 (class 1255 OID 25839)
-- Name: prodotti_disponibili_negozio(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prodotti_disponibili_negozio(p_id_negozio integer) RETURNS TABLE(id_prodotto integer, nome_prodotto character varying, descrizione text, prezzo numeric, quantita integer)
    LANGUAGE plpgsql
    AS $$
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
	$$;


--
-- TOC entry 299 (class 1255 OID 25841)
-- Name: visualizza_saldo_punti(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.visualizza_saldo_punti(p_cf_cliente character varying) RETURNS TABLE(id_tessera integer, data_richiesta date, negozio_id integer, saldo_punti integer)
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    RETURN QUERY
	    SELECT t.IDTessera, t.DataRichiesta, t.NegozioID, t.SaldoPunti
	    FROM Tessera t
	    WHERE t.ClienteCF = p_cf_cliente;
	END;
	$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 225 (class 1259 OID 25629)
-- Name: cliente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente (
    cf character varying(16) NOT NULL,
    nome character varying(100) NOT NULL,
    username character varying(50) NOT NULL
);


--
-- TOC entry 240 (class 1259 OID 25776)
-- Name: tessera; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tessera (
    idtessera integer NOT NULL,
    datarichiesta date NOT NULL,
    negozioid integer,
    clientecf character varying(16),
    saldopunti integer DEFAULT 0,
    CONSTRAINT tessera_saldopunti_check CHECK ((saldopunti >= 0))
);


--
-- TOC entry 243 (class 1259 OID 25954)
-- Name: clienticonpiudi300punti; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.clienticonpiudi300punti AS
 SELECT c.cf AS codicefiscale,
    c.nome AS nomecliente,
    t.idtessera,
    t.saldopunti,
    t.datarichiesta,
    t.negozioid
   FROM (public.tessera t
     JOIN public.cliente c ON (((t.clientecf)::text = (c.cf)::text)))
  WHERE (t.saldopunti > 300);


--
-- TOC entry 237 (class 1259 OID 25741)
-- Name: fattura; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fattura (
    idfattura integer NOT NULL,
    clientecf character varying(16) NOT NULL,
    negozioid integer NOT NULL,
    dataacquisto date NOT NULL,
    scontoapplicato numeric(5,2) DEFAULT 0.00,
    totalepagato numeric(10,2) NOT NULL
);


--
-- TOC entry 236 (class 1259 OID 25740)
-- Name: fattura_idfattura_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fattura_idfattura_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5012 (class 0 OID 0)
-- Dependencies: 236
-- Name: fattura_idfattura_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fattura_idfattura_seq OWNED BY public.fattura.idfattura;


--
-- TOC entry 233 (class 1259 OID 25702)
-- Name: fornisce; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fornisce (
    fornitorepiva character varying(11) NOT NULL,
    prodottoid integer NOT NULL,
    prezzounitario numeric(8,2) NOT NULL,
    disponibilita integer DEFAULT 0
);


--
-- TOC entry 232 (class 1259 OID 25695)
-- Name: fornitore; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fornitore (
    piva character varying(11) NOT NULL,
    indirizzo text NOT NULL
);


--
-- TOC entry 228 (class 1259 OID 25654)
-- Name: negozio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.negozio (
    idnegozio integer NOT NULL,
    managercf character varying(16),
    orariapertura character varying(100),
    indirizzo text NOT NULL,
    aperto boolean DEFAULT true
);


--
-- TOC entry 241 (class 1259 OID 25946)
-- Name: listatesserati; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.listatesserati AS
 SELECT n.idnegozio,
    n.indirizzo AS indirizzonegozio,
    c.cf AS codicefiscale,
    c.nome AS nomecliente,
    t.idtessera,
    t.datarichiesta,
    t.saldopunti
   FROM ((public.tessera t
     JOIN public.cliente c ON (((t.clientecf)::text = (c.cf)::text)))
     JOIN public.negozio n ON ((t.negozioid = n.idnegozio)));


--
-- TOC entry 226 (class 1259 OID 25641)
-- Name: manager; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.manager (
    cf character varying(16) NOT NULL,
    nome character varying(100) NOT NULL,
    username character varying(50) NOT NULL
);


--
-- TOC entry 227 (class 1259 OID 25653)
-- Name: negozio_idnegozio_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.negozio_idnegozio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5013 (class 0 OID 0)
-- Dependencies: 227
-- Name: negozio_idnegozio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.negozio_idnegozio_seq OWNED BY public.negozio.idnegozio;


--
-- TOC entry 235 (class 1259 OID 25719)
-- Name: ordina; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordina (
    idordine integer NOT NULL,
    negozioid integer,
    prodottoid integer,
    fornitorepiva character varying(11),
    dataconsegna date NOT NULL,
    quantita integer NOT NULL
);


--
-- TOC entry 234 (class 1259 OID 25718)
-- Name: ordina_idordine_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordina_idordine_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5014 (class 0 OID 0)
-- Dependencies: 234
-- Name: ordina_idordine_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ordina_idordine_seq OWNED BY public.ordina.idordine;


--
-- TOC entry 230 (class 1259 OID 25671)
-- Name: prodotto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prodotto (
    idprodotto integer NOT NULL,
    nome character varying(100) NOT NULL,
    descrizione text
);


--
-- TOC entry 229 (class 1259 OID 25670)
-- Name: prodotto_idprodotto_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prodotto_idprodotto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5015 (class 0 OID 0)
-- Dependencies: 229
-- Name: prodotto_idprodotto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prodotto_idprodotto_seq OWNED BY public.prodotto.idprodotto;


--
-- TOC entry 242 (class 1259 OID 25950)
-- Name: storicoordinifornitori; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.storicoordinifornitori AS
 SELECT f.piva AS fornitorepiva,
    f.indirizzo AS indirizzofornitore,
    o.idordine,
    o.negozioid,
    o.prodottoid,
    p.nome AS nomeprodotto,
    o.dataconsegna,
    o.quantita
   FROM ((public.ordina o
     JOIN public.fornitore f ON (((o.fornitorepiva)::text = (f.piva)::text)))
     JOIN public.prodotto p ON ((o.prodottoid = p.idprodotto)));


--
-- TOC entry 244 (class 1259 OID 25958)
-- Name: storicotessere; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.storicotessere AS
 SELECT t.idtessera,
    n.indirizzo AS indirizzonegozio,
    t.datarichiesta
   FROM (public.tessera t
     JOIN public.negozio n ON ((t.negozioid = n.idnegozio)))
  WHERE (n.aperto = false);


--
-- TOC entry 239 (class 1259 OID 25775)
-- Name: tessera_idtessera_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tessera_idtessera_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5016 (class 0 OID 0)
-- Dependencies: 239
-- Name: tessera_idtessera_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tessera_idtessera_seq OWNED BY public.tessera.idtessera;


--
-- TOC entry 224 (class 1259 OID 25622)
-- Name: utente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.utente (
    username character varying(50) NOT NULL,
    password text NOT NULL
);


--
-- TOC entry 231 (class 1259 OID 25679)
-- Name: vende; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vende (
    negozioid integer NOT NULL,
    prodottoid integer NOT NULL,
    prezzo numeric(8,2) NOT NULL,
    quantita integer DEFAULT 0
);


--
-- TOC entry 238 (class 1259 OID 25758)
-- Name: vocefattura; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vocefattura (
    fatturaid integer NOT NULL,
    prodottoid integer NOT NULL,
    prezzounitario numeric(8,2) NOT NULL,
    quantita integer DEFAULT 1,
    CONSTRAINT vocefattura_quantita_check CHECK ((quantita > 0))
);


--
-- TOC entry 4782 (class 2604 OID 25744)
-- Name: fattura idfattura; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fattura ALTER COLUMN idfattura SET DEFAULT nextval('public.fattura_idfattura_seq'::regclass);


--
-- TOC entry 4776 (class 2604 OID 25657)
-- Name: negozio idnegozio; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.negozio ALTER COLUMN idnegozio SET DEFAULT nextval('public.negozio_idnegozio_seq'::regclass);


--
-- TOC entry 4781 (class 2604 OID 25722)
-- Name: ordina idordine; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordina ALTER COLUMN idordine SET DEFAULT nextval('public.ordina_idordine_seq'::regclass);


--
-- TOC entry 4778 (class 2604 OID 25674)
-- Name: prodotto idprodotto; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prodotto ALTER COLUMN idprodotto SET DEFAULT nextval('public.prodotto_idprodotto_seq'::regclass);


--
-- TOC entry 4785 (class 2604 OID 25779)
-- Name: tessera idtessera; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tessera ALTER COLUMN idtessera SET DEFAULT nextval('public.tessera_idtessera_seq'::regclass);


--
-- TOC entry 4990 (class 0 OID 25629)
-- Dependencies: 225
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.cliente VALUES ('MTECQO61X84S959J', 'Gianpaolo Callegaro', 'user_cli1');
INSERT INTO public.cliente VALUES ('NQRSRP64E75M255M', 'Donatella Udinese-Gotti', 'user_cli2');
INSERT INTO public.cliente VALUES ('XXDOCZ27U64Z835U', 'Baccio Franceschi-Zola', 'user_cli3');
INSERT INTO public.cliente VALUES ('IPVJIQ53V76L724T', 'Ramona Piane', 'user_cli4');
INSERT INTO public.cliente VALUES ('HJOKYR53B28M710A', 'Orlando Paruta', 'user_cli5');
INSERT INTO public.cliente VALUES ('RIWRXP97V84H801U', 'Raffaellino Cuda-Sansoni', 'user_cli6');
INSERT INTO public.cliente VALUES ('OGMMJX04W82K814O', 'Nicoletta Abate', 'user_cli7');
INSERT INTO public.cliente VALUES ('PDPKFF95U70F154C', 'Vito Cavanna', 'user_cli8');
INSERT INTO public.cliente VALUES ('BNIWUS27M82T489G', 'Pasqual Palombi-Roncalli', 'user_cli9');
INSERT INTO public.cliente VALUES ('BLJOLO87A13E315U', 'Dott. Federica Boito', 'user_cli10');


--
-- TOC entry 5002 (class 0 OID 25741)
-- Dependencies: 237
-- Data for Name: fattura; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.fattura VALUES (1, 'OGMMJX04W82K814O', 2, '2025-05-21', 15.00, 160.37);
INSERT INTO public.fattura VALUES (2, 'RIWRXP97V84H801U', 1, '2025-06-21', 5.00, 39.38);
INSERT INTO public.fattura VALUES (3, 'OGMMJX04W82K814O', 1, '2025-06-20', 5.00, 166.45);
INSERT INTO public.fattura VALUES (4, 'BNIWUS27M82T489G', 1, '2025-05-06', 0.00, 72.52);
INSERT INTO public.fattura VALUES (5, 'IPVJIQ53V76L724T', 2, '2025-05-27', 0.00, 40.18);
INSERT INTO public.fattura VALUES (6, 'HJOKYR53B28M710A', 2, '2025-06-08', 15.00, 72.98);
INSERT INTO public.fattura VALUES (7, 'BLJOLO87A13E315U', 3, '2025-04-12', 30.00, 53.50);
INSERT INTO public.fattura VALUES (8, 'PDPKFF95U70F154C', 3, '2025-06-25', 15.00, 46.74);
INSERT INTO public.fattura VALUES (9, 'XXDOCZ27U64Z835U', 1, '2025-04-19', 15.00, 86.76);
INSERT INTO public.fattura VALUES (10, 'IPVJIQ53V76L724T', 3, '2025-06-19', 0.00, 55.87);
INSERT INTO public.fattura VALUES (11, 'BLJOLO87A13E315U', 3, '2025-04-12', 15.00, 122.14);
INSERT INTO public.fattura VALUES (12, 'XXDOCZ27U64Z835U', 3, '2025-06-13', 30.00, 82.79);
INSERT INTO public.fattura VALUES (13, 'BLJOLO87A13E315U', 1, '2025-06-14', 0.00, 61.22);
INSERT INTO public.fattura VALUES (14, 'NQRSRP64E75M255M', 1, '2025-04-14', 15.00, 230.72);
INSERT INTO public.fattura VALUES (15, 'BNIWUS27M82T489G', 1, '2025-06-21', 30.00, 56.20);
INSERT INTO public.fattura VALUES (16, 'HJOKYR53B28M710A', 2, '2025-05-07', 30.00, 67.54);
INSERT INTO public.fattura VALUES (17, 'HJOKYR53B28M710A', 3, '2025-03-30', 15.00, 114.12);
INSERT INTO public.fattura VALUES (18, 'XXDOCZ27U64Z835U', 3, '2025-04-14', 15.00, 75.73);
INSERT INTO public.fattura VALUES (19, 'BNIWUS27M82T489G', 1, '2025-06-07', 0.00, 83.64);
INSERT INTO public.fattura VALUES (20, 'XXDOCZ27U64Z835U', 3, '2025-06-11', 15.00, 98.89);
INSERT INTO public.fattura VALUES (21, 'MTECQO61X84S959J', 3, '2025-07-04', 0.00, 91.35);
INSERT INTO public.fattura VALUES (22, 'MTECQO61X84S959J', 1, '2025-07-04', 0.00, 704.08);
INSERT INTO public.fattura VALUES (23, 'MTECQO61X84S959J', 2, '2025-07-04', 30.00, 80.42);
INSERT INTO public.fattura VALUES (24, 'MTECQO61X84S959J', 2, '2025-07-04', 30.00, 399.00);
INSERT INTO public.fattura VALUES (25, 'NQRSRP64E75M255M', 2, '2025-07-07', 0.00, 85.54);
INSERT INTO public.fattura VALUES (26, 'NQRSRP64E75M255M', 2, '2025-07-07', 0.00, 1077.91);
INSERT INTO public.fattura VALUES (27, 'NQRSRP64E75M255M', 2, '2025-07-07', 30.00, 451.34);
INSERT INTO public.fattura VALUES (28, 'NQRSRP64E75M255M', 2, '2025-07-07', 30.00, 76.86);
INSERT INTO public.fattura VALUES (29, 'NQRSRP64E75M255M', 2, '2025-07-09', 30.00, 67.06);


--
-- TOC entry 4998 (class 0 OID 25702)
-- Dependencies: 233
-- Data for Name: fornisce; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.fornisce VALUES ('92581319988', 4, 17.95, 89);
INSERT INTO public.fornisce VALUES ('92581319988', 9, 26.78, 77);
INSERT INTO public.fornisce VALUES ('92581319988', 1, 33.57, 20);
INSERT INTO public.fornisce VALUES ('92581319988', 5, 40.35, 40);
INSERT INTO public.fornisce VALUES ('9388046742', 7, 18.61, 63);
INSERT INTO public.fornisce VALUES ('9388046742', 6, 14.09, 68);
INSERT INTO public.fornisce VALUES ('9388046742', 5, 13.87, 64);
INSERT INTO public.fornisce VALUES ('9388046742', 2, 34.15, 25);
INSERT INTO public.fornisce VALUES ('88784233468', 8, 13.15, 57);
INSERT INTO public.fornisce VALUES ('88784233468', 9, 43.18, 99);
INSERT INTO public.fornisce VALUES ('88784233468', 2, 45.42, 66);
INSERT INTO public.fornisce VALUES ('88784233468', 4, 33.09, 28);
INSERT INTO public.fornisce VALUES ('76595351346', 1, 44.21, 32);
INSERT INTO public.fornisce VALUES ('76595351346', 4, 25.21, 78);
INSERT INTO public.fornisce VALUES ('76595351346', 5, 35.43, 66);
INSERT INTO public.fornisce VALUES ('8808114191', 4, 35.40, 88);
INSERT INTO public.fornisce VALUES ('8808114191', 5, 39.17, 40);
INSERT INTO public.fornisce VALUES ('8808114191', 2, 28.49, 54);
INSERT INTO public.fornisce VALUES ('8808114191', 9, 49.58, 91);
INSERT INTO public.fornisce VALUES ('76595351346', 10, 16.51, 64);
INSERT INTO public.fornisce VALUES ('92581319988', 11, 12.34, 499);
INSERT INTO public.fornisce VALUES ('92581319988', 12, 9.99, 0);
INSERT INTO public.fornisce VALUES ('9388046742', 12, 1899.54, 14);


--
-- TOC entry 4997 (class 0 OID 25695)
-- Dependencies: 232
-- Data for Name: fornitore; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.fornitore VALUES ('92581319988', 'Contrada Gian 980, Arturo a mare, 88208 Belluno (VI)');
INSERT INTO public.fornitore VALUES ('9388046742', 'Strada Gozzi 9, Settimo Biagio veneto, 43534 Lucca (BS)');
INSERT INTO public.fornitore VALUES ('88784233468', 'Strada Aloisio 99 Appartamento 18, Settimo Giustino, 51354 Campobasso (MI)');
INSERT INTO public.fornitore VALUES ('76595351346', 'Canale Cammarata 411, Sesto Ignazio, 53487 Fermo (VI)');
INSERT INTO public.fornitore VALUES ('8808114191', 'Piazza Mariano 427 Piano 8, San Benvenuto sardo, 80598 Cagliari (ME)');


--
-- TOC entry 4991 (class 0 OID 25641)
-- Dependencies: 226
-- Data for Name: manager; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.manager VALUES ('RVIFLB10C43B321G', 'Gian Giannini', 'user_man1');
INSERT INTO public.manager VALUES ('OCLRZA89W08Z386Z', 'Piersanti Morpurgo', 'user_man2');
INSERT INTO public.manager VALUES ('GWWMQZ42C35U116O', 'Ninetta Cattaneo', 'user_man3');
INSERT INTO public.manager VALUES ('RHLPAU01P22R551N', 'Ginluca Rioghetta', 'user_man4');
INSERT INTO public.manager VALUES ('PHTDAU01P22R661U', 'Lucia Casetti', 'user_man5');


--
-- TOC entry 4993 (class 0 OID 25654)
-- Dependencies: 228
-- Data for Name: negozio; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.negozio VALUES (2, 'OCLRZA89W08Z386Z', 'Lun-Sab 9:00-19:00', 'Piazza Patrizio 5, Borgo Fredo del friuli, 26247 Enna (BT)', true);
INSERT INTO public.negozio VALUES (3, 'GWWMQZ42C35U116O', 'Lun-Sab 9:00-19:00', 'Canale Adriana 132, Spanevello nell''emilia, 60260 Lodi (FE)', true);
INSERT INTO public.negozio VALUES (4, 'RHLPAU01P22R551N', 'Lun-Sab 9:00-19:00', 'Via Spadolini 35, Burrago nel''Milanese, 20837 Milano (MI)', true);
INSERT INTO public.negozio VALUES (5, NULL, NULL, 'Via dante 3, Cala Galera, 41173 Grosseto (GR)', false);
INSERT INTO public.negozio VALUES (1, 'RVIFLB10C43B321G', NULL, 'Stretto Gilberto 73 Appartamento 99, Golino nell''''emilia, 31165 Matera (MN)', false);


--
-- TOC entry 5000 (class 0 OID 25719)
-- Dependencies: 235
-- Data for Name: ordina; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.ordina VALUES (1, 3, 4, '88784233468', '2025-04-11', 6);
INSERT INTO public.ordina VALUES (2, 1, 4, '88784233468', '2025-03-26', 17);
INSERT INTO public.ordina VALUES (3, 1, 5, '9388046742', '2025-05-16', 23);
INSERT INTO public.ordina VALUES (4, 1, 6, '76595351346', '2025-05-27', 17);
INSERT INTO public.ordina VALUES (5, 1, 8, '88784233468', '2025-03-25', 9);
INSERT INTO public.ordina VALUES (6, 3, 4, '8808114191', '2025-05-26', 22);
INSERT INTO public.ordina VALUES (7, 3, 5, '8808114191', '2025-04-27', 18);
INSERT INTO public.ordina VALUES (8, 2, 10, '88784233468', '2025-05-05', 12);
INSERT INTO public.ordina VALUES (9, 3, 3, '76595351346', '2025-04-06', 7);
INSERT INTO public.ordina VALUES (10, 1, 1, '9388046742', '2025-05-25', 25);
INSERT INTO public.ordina VALUES (11, 4, 10, '76595351346', '2025-07-04', 1);
INSERT INTO public.ordina VALUES (12, 2, 11, '92581319988', '2025-07-07', 1);
INSERT INTO public.ordina VALUES (13, 2, 12, '92581319988', '2025-07-07', 1);
INSERT INTO public.ordina VALUES (14, 2, 12, '9388046742', '2025-07-09', 2);


--
-- TOC entry 4995 (class 0 OID 25671)
-- Dependencies: 230
-- Data for Name: prodotto; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.prodotto VALUES (1, 'Trapano Avvitatore 18V', 'Ideale per forare e avvitare su legno e metallo.');
INSERT INTO public.prodotto VALUES (2, 'Pittura Murale Bianca', 'Smalto lavabile, alta copertura.');
INSERT INTO public.prodotto VALUES (3, 'Lampada LED E27', 'Luce fredda 6500K, risparmio energetico.');
INSERT INTO public.prodotto VALUES (4, 'Martello da Carpentiere', 'Testa in acciaio, manico antiscivolo.');
INSERT INTO public.prodotto VALUES (5, 'Sega Circolare 1200W', 'Lama 185mm, taglio preciso.');
INSERT INTO public.prodotto VALUES (6, 'Tassellatore Pneumatico', 'Mandrino SDS-plus, potenza elevata.');
INSERT INTO public.prodotto VALUES (7, 'Mensola in Legno 80cm', 'Legno massello di rovere.');
INSERT INTO public.prodotto VALUES (8, 'Cacciavite a Cricchetto', 'Punte intercambiabili, uso versatile.');
INSERT INTO public.prodotto VALUES (9, 'Livella Laser', 'Linee laser orizzontali/verticali.');
INSERT INTO public.prodotto VALUES (10, 'Vernice per Ferro', 'Protezione antiruggine per metallo.');
INSERT INTO public.prodotto VALUES (11, 'Sacco di pietre', 'Un sacco vuoto fatto di pietre');
INSERT INTO public.prodotto VALUES (12, 'Valvola per la Valve (steam)', 'Montala sulla testa di una persona e poi girala di 90° veso nord');
INSERT INTO public.prodotto VALUES (13, 'Colla vinilica', 'Se la compri fai contento Giovanni Muciaccia');
INSERT INTO public.prodotto VALUES (14, 'Fernovus SARATOGA (vernice ANTIRUGGINE)', 'Se lo compri fai contenta Giovanna');


--
-- TOC entry 5005 (class 0 OID 25776)
-- Dependencies: 240
-- Data for Name: tessera; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tessera VALUES (3, '2025-02-24', 1, 'XXDOCZ27U64Z835U', 525);
INSERT INTO public.tessera VALUES (4, '2024-06-13', 1, 'IPVJIQ53V76L724T', 96);
INSERT INTO public.tessera VALUES (5, '2024-02-02', 3, 'HJOKYR53B28M710A', 441);
INSERT INTO public.tessera VALUES (6, '2024-05-19', 1, 'RIWRXP97V84H801U', 39);
INSERT INTO public.tessera VALUES (7, '2024-12-18', 1, 'OGMMJX04W82K814O', 653);
INSERT INTO public.tessera VALUES (8, '2025-01-13', 1, 'PDPKFF95U70F154C', 46);
INSERT INTO public.tessera VALUES (9, '2025-01-15', 4, 'BNIWUS27M82T489G', 50);
INSERT INTO public.tessera VALUES (1, '2025-06-14', 3, 'MTECQO61X84S959J', 674);
INSERT INTO public.tessera VALUES (2, '2025-02-24', 1, 'NQRSRP64E75M255M', 1317);


--
-- TOC entry 4989 (class 0 OID 25622)
-- Dependencies: 224
-- Data for Name: utente; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.utente VALUES ('user_cli2', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_cli3', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_cli4', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_cli5', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_cli6', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_cli7', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_cli8', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_cli9', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_cli10', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_man2', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_man3', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_man4', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_man5', '$2a$06$wV9c2sQIlfhE7P4N2kOlu.sJqxTEFegJfU0pzavFXRs.1yeM4ju.2');
INSERT INTO public.utente VALUES ('user_cli1', '$2a$06$NH0ROX/d.OeIAo8kX2GEIOCbyQQoAuloA20t9/5vRIDOifF/WcB7m');
INSERT INTO public.utente VALUES ('user_man1', '$2a$06$RJgbqDAhHhueC07S.vGaPevGGyFF12jWPgJg5iMycpc7KT3jOzkq2');


--
-- TOC entry 4996 (class 0 OID 25679)
-- Dependencies: 231
-- Data for Name: vende; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.vende VALUES (1, 1, 28.20, 7);
INSERT INTO public.vende VALUES (2, 1, 25.25, 19);
INSERT INTO public.vende VALUES (3, 1, 26.69, 5);
INSERT INTO public.vende VALUES (1, 2, 43.36, 13);
INSERT INTO public.vende VALUES (3, 2, 43.33, 18);
INSERT INTO public.vende VALUES (3, 3, 26.41, 8);
INSERT INTO public.vende VALUES (1, 4, 52.80, 11);
INSERT INTO public.vende VALUES (3, 4, 55.21, 5);
INSERT INTO public.vende VALUES (1, 5, 43.85, 8);
INSERT INTO public.vende VALUES (2, 5, 48.25, 14);
INSERT INTO public.vende VALUES (3, 5, 41.35, 12);
INSERT INTO public.vende VALUES (1, 6, 59.59, 7);
INSERT INTO public.vende VALUES (3, 6, 59.90, 9);
INSERT INTO public.vende VALUES (1, 7, 24.89, 10);
INSERT INTO public.vende VALUES (2, 7, 22.79, 18);
INSERT INTO public.vende VALUES (3, 7, 29.78, 11);
INSERT INTO public.vende VALUES (3, 8, 44.73, 12);
INSERT INTO public.vende VALUES (1, 10, 33.21, 15);
INSERT INTO public.vende VALUES (2, 10, 24.87, 12);
INSERT INTO public.vende VALUES (3, 10, 26.94, 20);
INSERT INTO public.vende VALUES (3, 9, 18.27, 1);
INSERT INTO public.vende VALUES (1, 8, 47.51, 5);
INSERT INTO public.vende VALUES (1, 3, 21.36, 7);
INSERT INTO public.vende VALUES (1, 9, 17.77, 9);
INSERT INTO public.vende VALUES (2, 6, 57.44, 5);
INSERT INTO public.vende VALUES (5, 11, 0.02, 13);
INSERT INTO public.vende VALUES (1, 11, 49.99, 15);
INSERT INTO public.vende VALUES (2, 9, 23.44, 2);
INSERT INTO public.vende VALUES (2, 3, 31.05, 7);
INSERT INTO public.vende VALUES (2, 11, 499.99, 7);
INSERT INTO public.vende VALUES (2, 4, 51.35, 9);
INSERT INTO public.vende VALUES (2, 2, 49.90, 3);
INSERT INTO public.vende VALUES (2, 12, 10.01, 1);
INSERT INTO public.vende VALUES (2, 8, 47.90, 17);


--
-- TOC entry 5003 (class 0 OID 25758)
-- Dependencies: 238
-- Data for Name: vocefattura; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.vocefattura VALUES (1, 8, 46.93, 3);
INSERT INTO public.vocefattura VALUES (1, 1, 23.94, 2);
INSERT INTO public.vocefattura VALUES (2, 4, 41.45, 1);
INSERT INTO public.vocefattura VALUES (3, 4, 37.73, 3);
INSERT INTO public.vocefattura VALUES (3, 2, 23.92, 3);
INSERT INTO public.vocefattura VALUES (4, 3, 36.26, 2);
INSERT INTO public.vocefattura VALUES (5, 7, 20.09, 2);
INSERT INTO public.vocefattura VALUES (6, 9, 26.19, 2);
INSERT INTO public.vocefattura VALUES (6, 8, 28.71, 1);
INSERT INTO public.vocefattura VALUES (7, 6, 22.29, 3);
INSERT INTO public.vocefattura VALUES (8, 1, 58.43, 1);
INSERT INTO public.vocefattura VALUES (9, 4, 36.15, 3);
INSERT INTO public.vocefattura VALUES (10, 10, 23.28, 3);
INSERT INTO public.vocefattura VALUES (11, 5, 46.79, 2);
INSERT INTO public.vocefattura VALUES (11, 4, 29.55, 2);
INSERT INTO public.vocefattura VALUES (12, 8, 57.16, 1);
INSERT INTO public.vocefattura VALUES (12, 6, 20.37, 3);
INSERT INTO public.vocefattura VALUES (13, 9, 30.61, 2);
INSERT INTO public.vocefattura VALUES (14, 3, 53.35, 3);
INSERT INTO public.vocefattura VALUES (14, 8, 32.10, 3);
INSERT INTO public.vocefattura VALUES (15, 2, 30.58, 1);
INSERT INTO public.vocefattura VALUES (15, 3, 49.70, 1);
INSERT INTO public.vocefattura VALUES (16, 6, 28.14, 3);
INSERT INTO public.vocefattura VALUES (17, 1, 45.37, 2);
INSERT INTO public.vocefattura VALUES (17, 2, 21.76, 2);
INSERT INTO public.vocefattura VALUES (18, 8, 42.07, 2);
INSERT INTO public.vocefattura VALUES (19, 3, 41.82, 2);
INSERT INTO public.vocefattura VALUES (20, 4, 52.30, 1);
INSERT INTO public.vocefattura VALUES (20, 8, 23.77, 3);
INSERT INTO public.vocefattura VALUES (21, 9, 18.27, 5);
INSERT INTO public.vocefattura VALUES (22, 8, 47.51, 11);
INSERT INTO public.vocefattura VALUES (22, 3, 21.36, 6);
INSERT INTO public.vocefattura VALUES (22, 9, 17.77, 3);
INSERT INTO public.vocefattura VALUES (23, 6, 57.44, 2);
INSERT INTO public.vocefattura VALUES (24, 2, 49.90, 10);
INSERT INTO public.vocefattura VALUES (25, 3, 31.05, 2);
INSERT INTO public.vocefattura VALUES (25, 9, 23.44, 1);
INSERT INTO public.vocefattura VALUES (26, 9, 23.44, 2);
INSERT INTO public.vocefattura VALUES (26, 3, 31.05, 1);
INSERT INTO public.vocefattura VALUES (26, 11, 499.99, 2);
INSERT INTO public.vocefattura VALUES (27, 11, 499.99, 1);
INSERT INTO public.vocefattura VALUES (27, 4, 51.35, 1);
INSERT INTO public.vocefattura VALUES (28, 12, 10.00, 1);
INSERT INTO public.vocefattura VALUES (28, 2, 49.90, 2);
INSERT INTO public.vocefattura VALUES (29, 8, 47.90, 2);


--
-- TOC entry 5017 (class 0 OID 0)
-- Dependencies: 236
-- Name: fattura_idfattura_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.fattura_idfattura_seq', 29, true);


--
-- TOC entry 5018 (class 0 OID 0)
-- Dependencies: 227
-- Name: negozio_idnegozio_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.negozio_idnegozio_seq', 5, true);


--
-- TOC entry 5019 (class 0 OID 0)
-- Dependencies: 234
-- Name: ordina_idordine_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ordina_idordine_seq', 14, true);


--
-- TOC entry 5020 (class 0 OID 0)
-- Dependencies: 229
-- Name: prodotto_idprodotto_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.prodotto_idprodotto_seq', 14, true);


--
-- TOC entry 5021 (class 0 OID 0)
-- Dependencies: 239
-- Name: tessera_idtessera_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tessera_idtessera_seq', 9, true);


--
-- TOC entry 4792 (class 2606 OID 25930)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (cf);


--
-- TOC entry 4794 (class 2606 OID 25635)
-- Name: cliente cliente_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_username_key UNIQUE (username);


--
-- TOC entry 4814 (class 2606 OID 25747)
-- Name: fattura fattura_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fattura
    ADD CONSTRAINT fattura_pkey PRIMARY KEY (idfattura);


--
-- TOC entry 4810 (class 2606 OID 25707)
-- Name: fornisce fornisce_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fornisce
    ADD CONSTRAINT fornisce_pkey PRIMARY KEY (fornitorepiva, prodottoid);


--
-- TOC entry 4808 (class 2606 OID 25701)
-- Name: fornitore fornitore_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fornitore
    ADD CONSTRAINT fornitore_pkey PRIMARY KEY (piva);


--
-- TOC entry 4796 (class 2606 OID 25918)
-- Name: manager manager_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manager
    ADD CONSTRAINT manager_pkey PRIMARY KEY (cf);


--
-- TOC entry 4798 (class 2606 OID 25647)
-- Name: manager manager_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manager
    ADD CONSTRAINT manager_username_key UNIQUE (username);


--
-- TOC entry 4800 (class 2606 OID 25901)
-- Name: negozio negozio_managercf_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.negozio
    ADD CONSTRAINT negozio_managercf_key UNIQUE (managercf);


--
-- TOC entry 4802 (class 2606 OID 25662)
-- Name: negozio negozio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.negozio
    ADD CONSTRAINT negozio_pkey PRIMARY KEY (idnegozio);


--
-- TOC entry 4812 (class 2606 OID 25724)
-- Name: ordina ordina_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordina
    ADD CONSTRAINT ordina_pkey PRIMARY KEY (idordine);


--
-- TOC entry 4804 (class 2606 OID 25678)
-- Name: prodotto prodotto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prodotto
    ADD CONSTRAINT prodotto_pkey PRIMARY KEY (idprodotto);


--
-- TOC entry 4818 (class 2606 OID 25785)
-- Name: tessera tessera_clientecf_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tessera
    ADD CONSTRAINT tessera_clientecf_key UNIQUE (clientecf);


--
-- TOC entry 4820 (class 2606 OID 25783)
-- Name: tessera tessera_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tessera
    ADD CONSTRAINT tessera_pkey PRIMARY KEY (idtessera);


--
-- TOC entry 4790 (class 2606 OID 25628)
-- Name: utente utente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.utente
    ADD CONSTRAINT utente_pkey PRIMARY KEY (username);


--
-- TOC entry 4806 (class 2606 OID 25684)
-- Name: vende vende_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vende
    ADD CONSTRAINT vende_pkey PRIMARY KEY (negozioid, prodottoid);


--
-- TOC entry 4816 (class 2606 OID 25764)
-- Name: vocefattura vocefattura_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocefattura
    ADD CONSTRAINT vocefattura_pkey PRIMARY KEY (fatturaid, prodottoid);


--
-- TOC entry 4838 (class 2620 OID 25800)
-- Name: ordina trigger_aggiorna_disponibilita; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_aggiorna_disponibilita AFTER INSERT ON public.ordina FOR EACH ROW EXECUTE FUNCTION public.aggiorna_disponibilita_fornitore();


--
-- TOC entry 4839 (class 2620 OID 25797)
-- Name: fattura trigger_aggiorna_punti; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_aggiorna_punti AFTER INSERT ON public.fattura FOR EACH ROW EXECUTE FUNCTION public.aggiorna_punti_tessera();


--
-- TOC entry 4837 (class 2620 OID 25814)
-- Name: vende trigger_quantita_zero; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_quantita_zero AFTER UPDATE ON public.vende FOR EACH ROW WHEN (((new.quantita = 0) AND (old.quantita > 0))) EXECUTE FUNCTION public.gestisci_quantita_zero();


--
-- TOC entry 4821 (class 2606 OID 25636)
-- Name: cliente cliente_username_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_username_fkey FOREIGN KEY (username) REFERENCES public.utente(username) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4831 (class 2606 OID 25936)
-- Name: fattura fattura_clientecf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fattura
    ADD CONSTRAINT fattura_clientecf_fkey FOREIGN KEY (clientecf) REFERENCES public.cliente(cf) ON DELETE RESTRICT;


--
-- TOC entry 4832 (class 2606 OID 25753)
-- Name: fattura fattura_negozioid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fattura
    ADD CONSTRAINT fattura_negozioid_fkey FOREIGN KEY (negozioid) REFERENCES public.negozio(idnegozio) ON DELETE RESTRICT;


--
-- TOC entry 4826 (class 2606 OID 25708)
-- Name: fornisce fornisce_fornitorepiva_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fornisce
    ADD CONSTRAINT fornisce_fornitorepiva_fkey FOREIGN KEY (fornitorepiva) REFERENCES public.fornitore(piva) ON DELETE CASCADE;


--
-- TOC entry 4827 (class 2606 OID 25713)
-- Name: fornisce fornisce_prodottoid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fornisce
    ADD CONSTRAINT fornisce_prodottoid_fkey FOREIGN KEY (prodottoid) REFERENCES public.prodotto(idprodotto) ON DELETE CASCADE;


--
-- TOC entry 4822 (class 2606 OID 25648)
-- Name: manager manager_username_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manager
    ADD CONSTRAINT manager_username_fkey FOREIGN KEY (username) REFERENCES public.utente(username) ON DELETE CASCADE;


--
-- TOC entry 4823 (class 2606 OID 25919)
-- Name: negozio negozio_managercf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.negozio
    ADD CONSTRAINT negozio_managercf_fkey FOREIGN KEY (managercf) REFERENCES public.manager(cf) ON DELETE CASCADE;


--
-- TOC entry 4828 (class 2606 OID 25735)
-- Name: ordina ordina_fornitorepiva_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordina
    ADD CONSTRAINT ordina_fornitorepiva_fkey FOREIGN KEY (fornitorepiva) REFERENCES public.fornitore(piva) ON DELETE RESTRICT;


--
-- TOC entry 4829 (class 2606 OID 25725)
-- Name: ordina ordina_negozioid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordina
    ADD CONSTRAINT ordina_negozioid_fkey FOREIGN KEY (negozioid) REFERENCES public.negozio(idnegozio) ON DELETE RESTRICT;


--
-- TOC entry 4830 (class 2606 OID 25730)
-- Name: ordina ordina_prodottoid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordina
    ADD CONSTRAINT ordina_prodottoid_fkey FOREIGN KEY (prodottoid) REFERENCES public.prodotto(idprodotto) ON DELETE RESTRICT;


--
-- TOC entry 4835 (class 2606 OID 25931)
-- Name: tessera tessera_clientecf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tessera
    ADD CONSTRAINT tessera_clientecf_fkey FOREIGN KEY (clientecf) REFERENCES public.cliente(cf) ON DELETE CASCADE;


--
-- TOC entry 4836 (class 2606 OID 25786)
-- Name: tessera tessera_negozioid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tessera
    ADD CONSTRAINT tessera_negozioid_fkey FOREIGN KEY (negozioid) REFERENCES public.negozio(idnegozio) ON DELETE CASCADE;


--
-- TOC entry 4824 (class 2606 OID 25685)
-- Name: vende vende_negozioid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vende
    ADD CONSTRAINT vende_negozioid_fkey FOREIGN KEY (negozioid) REFERENCES public.negozio(idnegozio) ON DELETE CASCADE;


--
-- TOC entry 4825 (class 2606 OID 25690)
-- Name: vende vende_prodottoid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vende
    ADD CONSTRAINT vende_prodottoid_fkey FOREIGN KEY (prodottoid) REFERENCES public.prodotto(idprodotto) ON DELETE CASCADE;


--
-- TOC entry 4833 (class 2606 OID 25765)
-- Name: vocefattura vocefattura_fatturaid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocefattura
    ADD CONSTRAINT vocefattura_fatturaid_fkey FOREIGN KEY (fatturaid) REFERENCES public.fattura(idfattura) ON DELETE CASCADE;


--
-- TOC entry 4834 (class 2606 OID 25770)
-- Name: vocefattura vocefattura_prodottoid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocefattura
    ADD CONSTRAINT vocefattura_prodottoid_fkey FOREIGN KEY (prodottoid) REFERENCES public.prodotto(idprodotto) ON DELETE RESTRICT;


-- Completed on 2025-07-09 11:42:06

--
-- PostgreSQL database dump complete
--

