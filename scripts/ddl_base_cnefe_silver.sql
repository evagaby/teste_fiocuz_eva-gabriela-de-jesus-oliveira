IF OBJECT_ID('base_cnefe_silver','U') IS NOT NULL
	DROP TABLE base_cnefe_silver;
	CREATE TABLE base_cnefe_silver(
codigo_unico VARCHAR(20),
codigo_setor VARCHAR(50),
cep VARCHAR(10),
cnefe_localidade VARCHAR(100),
cnefe_logradouro VARCHAR(100));