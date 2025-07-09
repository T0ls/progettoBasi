-- Aggiornamento saldo punti su tessera fedelt`a:
	CREATE OR REPLACE FUNCTION aggiorna_punti_tessera()
	RETURNS TRIGGER AS $$
	BEGIN
	  IF EXISTS (
	    SELECT 1 FROM Tessera WHERE ClienteCF = NEW.ClienteCF
	  ) THEN
	    UPDATE Tessera
	    SET SaldoPunti = SaldoPunti + FLOOR(NEW.TotalePagato)
	    WHERE ClienteCF = NEW.ClienteCF;
	  END IF;
	
	  RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;
	
	
	CREATE TRIGGER trigger_aggiorna_punti
	AFTER INSERT ON Fattura
	FOR EACH ROW
	EXECUTE FUNCTION aggiorna_punti_tessera();
--


-- Acquisto del cliente di prodotti:
	CREATE OR REPLACE FUNCTION acquisto_cliente(
	    p_CF_cliente VARCHAR,
	    p_ID_negozio INTEGER,
	    p_importo NUMERIC,
	    p_sconto BOOLEAN
	)
	RETURNS TEXT
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
	
	    -- Se sconto richiesto
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
	
	        -- Se può applicare sconto
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
	
	    -- Inserisce fattura
	    INSERT INTO Fattura (ClienteCF, NegozioID, DataAcquisto, ScontoApplicato, TotalePagato)
	    VALUES (p_CF_cliente, p_ID_negozio, CURRENT_DATE, v_percentuale, v_totale_finale)
	    RETURNING IDFattura INTO v_id_fattura;
	
	    -- Se applicato sconto scala punti
	    IF v_soglia_usata > 0 THEN
	        UPDATE Tessera
	        SET SaldoPunti = SaldoPunti - v_soglia_usata
	        WHERE ClienteCF = p_CF_cliente;
	    END IF;
	
	    RETURN v_flag_testo || '_' || v_id_fattura;
	END;
	$$ LANGUAGE plpgsql;
--



-- Aggiornamento disponibilita prodotti dai fornitori:
	CREATE OR REPLACE FUNCTION aggiorna_disponibilita_fornitore()
	RETURNS TRIGGER AS $$
	BEGIN
	  UPDATE Fornisce
	  SET Disponibilita = Disponibilita - NEW.Quantita
	  WHERE FornitorePIVA = NEW.FornitorePIVA
	    AND ProdottoID = NEW.ProdottoID;
	
	  RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;
	
	CREATE TRIGGER trigger_aggiorna_disponibilita
	AFTER INSERT ON Ordina
	FOR EACH ROW
	EXECUTE FUNCTION aggiorna_disponibilita_fornitore();
--



-- Ordine prodotti da fornitore:
	CREATE OR REPLACE FUNCTION effettua_ordine(
	  p_ID_negozio INTEGER,
	  p_ID_prodotto INTEGER,
	  p_quantita INTEGER
	)
	RETURNS TEXT AS $$
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
	
	  -- Seleziona fornitore con disponibilità e prezzo minimo
	  SELECT FornitorePIVA
	  INTO v_fornitore_scelto
	  FROM Fornisce
	  WHERE ProdottoID = p_ID_prodotto
	    AND Disponibilita >= p_quantita
	  ORDER BY PrezzoUnitario ASC
	  LIMIT 1;
	
	  -- Se fornitore non disponibile segnala errore
	  IF NOT FOUND THEN
	    RETURN 'NESSUN_FORNITORE_DISPONIBILE';
	  END IF;
	
	  -- Inserisce ordine
	  INSERT INTO Ordina (NegozioID, ProdottoID, FornitorePIVA, DataConsegna, Quantita)
	  VALUES (p_ID_negozio, p_ID_prodotto, v_fornitore_scelto, CURRENT_DATE, p_quantita);
	
	  RETURN 'OK';
	END;
	$$ LANGUAGE plpgsql;
--



-- Lista tesserati:
	CREATE OR REPLACE VIEW ListaTesserati AS
	SELECT
	  n.IDNegozio,
	  n.Indirizzo AS IndirizzoNegozio,
	  c.CF AS CodiceFiscale,
	  c.Nome AS NomeCliente,
	  t.IDTessera,
	  t.DataRichiesta,
	  t.SaldoPunti
	FROM Tessera t
	JOIN Cliente c ON t.ClienteCF = c.CF
	JOIN Negozio n ON t.NegozioID = n.IDNegozio;
--



-- Storico ordini a fornitori:
	CREATE OR REPLACE VIEW StoricoOrdiniFornitori AS
	SELECT
	  f.PIVA AS FornitorePIVA,
	  f.Indirizzo AS IndirizzoFornitore,
	  o.IDOrdine,
	  o.NegozioID,
	  o.ProdottoID,
	  p.Nome AS NomeProdotto,
	  o.DataConsegna,
	  o.Quantita
	FROM Ordina o
	JOIN Fornitore f ON o.FornitorePIVA = f.PIVA
	JOIN Prodotto p ON o.ProdottoID = p.IDProdotto;
--



-- Saldi punti:
	CREATE OR REPLACE VIEW ClientiConPiuDi300Punti AS
	SELECT
	  c.CF AS CodiceFiscale,
	  c.Nome AS NomeCliente,
	  t.IDTessera,
	  t.SaldoPunti,
	  t.DataRichiesta,
	  t.NegozioID
	FROM Tessera t
	JOIN Cliente c ON t.ClienteCF = c.CF
	WHERE t.SaldoPunti > 300;
--



-- Rimozione prodotto x quantità <= 0 + ordine automatico:
	CREATE OR REPLACE FUNCTION gestisci_quantita_zero()
	RETURNS TRIGGER AS $$
	BEGIN
	  -- Se quantità = zero
	  IF NEW.Quantita = 0 THEN
	
	    -- Elimina prodotto dalla vendita
	    DELETE FROM Vende
	    WHERE NegozioID = NEW.NegozioID
	      AND ProdottoID = NEW.ProdottoID;
	
	    -- Effettua ordine automatico di 1 unità
	    PERFORM effettua_ordine(NEW.NegozioID, NEW.ProdottoID, 1);
	
	  END IF;
	
	  RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;
	
	
	CREATE TRIGGER trigger_quantita_zero
	AFTER UPDATE ON Vende
	FOR EACH ROW
	WHEN (NEW.Quantita = 0 AND OLD.Quantita > 0)
	EXECUTE FUNCTION gestisci_quantita_zero();
--
	
	

-- Mantenimento storico tessere:
	CREATE OR REPLACE VIEW StoricoTessere AS
	SELECT
	  t.IDTessera,
	  n.Indirizzo AS IndirizzoNegozio,
	  t.DataRichiesta
	FROM Tessera t
	JOIN Negozio n ON t.NegozioID = n.IDNegozio
	WHERE n.Aperto = FALSE;
--
