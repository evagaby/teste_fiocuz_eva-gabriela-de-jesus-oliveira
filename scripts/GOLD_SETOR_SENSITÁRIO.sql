CREATE VIEW view_busca_setor AS
SELECT
    b.consulta_logradouro,
    b.consulta_numero,
    b.consulta_bairro,
    b.consulta_cep,
    b.consulta_complemento,
    b.consulta_municipio,
    COALESCE(
        (SELECT TOP 1 c.codigo_setor 
         FROM base_cnefe_silver c 
         WHERE c.cnefe_logradouro = b.consulta_logradouro),
        (SELECT TOP 1 c.codigo_setor 
         FROM base_cnefe_silver c 
         WHERE c.cep = b.consulta_cep),
        NULL
    ) AS setor_sensitario_encontrado
FROM base_busca_silver b