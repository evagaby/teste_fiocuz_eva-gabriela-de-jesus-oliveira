TRUNCATE TABLE base_busca_silver
INSERT INTO base_busca_silver (
    consulta_logradouro,
    consulta_numero,
    consulta_bairro,
    consulta_cep,
    consulta_complemento,
    consulta_municipio
)
SELECT
    TRIM(REPLACE(REPLACE(consulta_logradouro, 'None', ''), '10R', '')) AS consulta_logradouro,
    ISNULL(NULLIF(TRIM(REPLACE(consulta_numero, 'SN', '')), ''), 'N/A') AS consulta_numero,
    ISNULL(NULLIF(TRIM(consulta_bairro), ''), 'N/A') AS consulta_bairro,
    ISNULL(NULLIF(TRIM(consulta_cep), ''), 'N/A') AS consulta_cep,
    ISNULL(NULLIF(TRIM(consulta_complemento), ''), 'N/A') AS consulta_complemento,
    ISNULL(NULLIF(TRIM(consulta_municipio), ''), 'N/A') AS consulta_municipio
FROM base_busca