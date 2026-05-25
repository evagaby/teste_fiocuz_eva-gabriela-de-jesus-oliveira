TRUNCATE TABLE base_cnefe
BULK INSERT base_cnefe
FROM 'C:\Users\evaga\OneDrive\Área de Trabalho\teste_fiocruz\base\29_BA.csv'
WITH (FIRSTROW = 2,
FIELDTERMINATOR = ';',
TABLOCK)