TRUNCATE TABLE base_busca
		BULK INSERT base_busca
		FROM 'C:\Users\evaga\OneDrive\Área de Trabalho\teste_fiocruz\base\2026_teste_tecnico_relinke_cidacs(in).csv'
		WITH (	FIRSTROW = 2,
				FIELDTERMINATOR = ';', 
				TABLOCK
		);