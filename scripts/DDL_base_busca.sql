IF OBJECT_ID('base_busca','U') IS NOT NULL
	DROP TABLE base_busca;
CREATE TABLE base_busca (
consulta_logradouro	VARCHAR(50),
consulta_numero	VARCHAR(4),
consulta_bairro	VARCHAR(50),
consulta_cep	VARCHAR(8),
consulta_complemento	VARCHAR(50),
consulta_municipio VARCHAR(50)
) 