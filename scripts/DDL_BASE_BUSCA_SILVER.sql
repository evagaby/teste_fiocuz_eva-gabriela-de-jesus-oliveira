IF OBJECT_ID('base_busca_silver','U') IS NOT NULL
	DROP TABLE base_busca_silver;
CREATE TABLE base_busca_silver (
consulta_logradouro	VARCHAR(50),
consulta_numero	VARCHAR(4),
consulta_bairro	VARCHAR(50),
consulta_cep	VARCHAR(8),
consulta_complemento	VARCHAR(50),
consulta_municipio VARCHAR(50)
) 