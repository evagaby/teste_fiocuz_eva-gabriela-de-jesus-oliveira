WITH ranking AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY COD_UNICO_ENDERECO
               ORDER BY (
                   CASE WHEN COD_SETOR IS NOT NULL THEN 1 ELSE 0 END +
                   CASE WHEN CEP IS NOT NULL THEN 1 ELSE 0 END +
                   CASE WHEN DSC_LOCALIDADE IS NOT NULL THEN 1 ELSE 0 END +
                   CASE WHEN NOM_TIPO_SEGLOGR IS NOT NULL THEN 1 ELSE 0 END +
                   CASE WHEN NOM_TITULO_SEGLOGR IS NOT NULL THEN 1 ELSE 0 END +
                   CASE WHEN NOM_SEGLOGR IS NOT NULL THEN 1 ELSE 0 END
               ) DESC
           ) AS rn
    FROM base_cnefe
)
DELETE FROM ranking
WHERE rn > 1;

TRUNCATE TABLE base_cnefe_silver;

INSERT INTO base_cnefe_silver (
    codigo_unico,
    codigo_setor,
    cep,
    cnefe_localidade,
    cnefe_logradouro
)
SELECT
    COD_UNICO_ENDERECO AS codigo_unico,
    TRIM(REPLACE(COD_SETOR  , 'P', ''))  AS codigo_setor,
    CEP                                        AS cep,
    DSC_LOCALIDADE                             AS cnefe_localidade,
    CONCAT(NOM_TIPO_SEGLOGR, ' ', NOM_TITULO_SEGLOGR, ' ', NOM_SEGLOGR) AS cnefe_logradouro
FROM base_cnefe