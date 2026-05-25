# Teste Fiocruz

## Índice
- [Requisitos](#requisitos)
- [Arquitetura](#arquitetura)
- [Passo a Passo](#passo-a-passo)
  - [1ª Etapa — Criação do Banco de Dados](#1ª-etapa--criação-do-banco-de-dados)
  - [2ª Etapa — Criação das Tabelas](#2ª-etapa--criação-das-tabelas)
  - [3ª Etapa — Inserção dos Dados](#3ª-etapa--inserção-dos-dados)
  - [4ª Etapa — Limpeza dos Dados](#4ª-etapa--limpeza-dos-dados)
  - [5ª Etapa — Geração do Setor Censitário](#5ª-etapa--geração-do-setor-censitário)

---

## Requisitos

> Para a execução da solução é necessário ter acesso às bases de dados disponibilizadas na pasta `Base de dados`.

---

## Arquitetura

A solução foi desenvolvida utilizando **MSSQL Server** como sistema de gerenciamento de banco de dados.

A arquitetura é baseada na **Medallion Architecture**, escolhida por proporcionar organização, fácil compreensão e por manter todos os dados originais disponíveis para consulta, permitindo execução simplificada.

---

## Passo a Passo

### 1ª Etapa — Criação do Banco de Dados

Ao entrar no MSSQL, conecte-se ao servidor local, selecione a opção **"Nova Consulta"** e execute:

```sql
CREATE DATABASE teste_fiocruz
```

---

### 2ª Etapa — Criação das Tabelas

Conecte-se ao banco criado anteriormente via **"Pesquisador de Objetos" → "Banco de Dados"**, clique com o botão direito no banco e selecione **"Nova Consulta"**.

> Os scripts completos de criação das tabelas estão disponíveis na pasta `scripts`.

Cada coluna deve respeitar o tipo primitivo e a quantidade de caracteres do CSV original.

**Exemplo — `base_busca`:**
```sql
IF OBJECT_ID('base_busca','U') IS NOT NULL
    DROP TABLE base_busca;

CREATE TABLE base_busca (
    consulta_logradouro  VARCHAR(50),
    consulta_numero      VARCHAR(4),
    consulta_bairro      VARCHAR(50),
    consulta_cep         VARCHAR(8),
    consulta_complemento VARCHAR(50),
    consulta_municipio   VARCHAR(50)
);
```

---

### 3ª Etapa — Inserção dos Dados

A inserção foi realizada com `BULK INSERT`. O comando também utiliza `TABLOCK` para travar os dados durante a carga, garantindo que a base original não seja alterada.

> ⚠️ Caso haja algum erro no tamanho dos caracteres ou no tipo de dado definido na etapa anterior, o comando abaixo não funcionará.

```sql
TRUNCATE TABLE base_busca;

BULK INSERT base_busca
FROM 'C:\Users\evaga\OneDrive\Área de Trabalho\teste_fiocruz\base\2026_teste_tecnico_relinke_cidacs(in).csv'
WITH (
    FIRSTROW       = 2,
    FIELDTERMINATOR = ';',
    TABLOCK
);
```

- `FIRSTROW = 2` — indica que os dados começam na segunda linha (a primeira é o cabeçalho)
- `FIELDTERMINATOR = ';'` — define o delimitador de colunas (pode variar conforme a base)

---

### 4ª Etapa — Limpeza dos Dados

Etapa mais importante do processo, onde são aplicadas as regras de negócio e realizadas as transformações para obter uma base limpa e confiável.

Seguindo a Medallion Architecture, os dados brutos importados formam a **camada Bronze** e não são alterados. O tratamento é feito na **camada Silver**, composta por duas novas tabelas:

---

#### `base_cnefe_silver`

Na tabela original foram identificadas colunas redundantes, que foram descartadas. Apenas as informações relevantes para a geração do setor censitário foram mantidas.

**Criação da tabela:**
```sql
IF OBJECT_ID('base_cnefe_silver','U') IS NOT NULL
    DROP TABLE base_cnefe_silver;

CREATE TABLE base_cnefe_silver (
    codigo_unico     VARCHAR(20),
    codigo_setor     VARCHAR(50),
    cep              VARCHAR(10),
    cnefe_localidade VARCHAR(100),
    cnefe_logradouro VARCHAR(100)
);
```

**Inserção e tratamento:**
```sql
-- Remove duplicatas, mantendo o registro mais completo por COD_UNICO_ENDERECO
WITH ranking AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY COD_UNICO_ENDERECO
               ORDER BY (
                   CASE WHEN COD_SETOR         IS NOT NULL THEN 1 ELSE 0 END +
                   CASE WHEN CEP               IS NOT NULL THEN 1 ELSE 0 END +
                   CASE WHEN DSC_LOCALIDADE    IS NOT NULL THEN 1 ELSE 0 END +
                   CASE WHEN NOM_TIPO_SEGLOGR  IS NOT NULL THEN 1 ELSE 0 END +
                   CASE WHEN NOM_TITULO_SEGLOGR IS NOT NULL THEN 1 ELSE 0 END +
                   CASE WHEN NOM_SEGLOGR       IS NOT NULL THEN 1 ELSE 0 END
               ) DESC
           ) AS rn
    FROM base_cnefe
)
DELETE FROM ranking WHERE rn > 1;

TRUNCATE TABLE base_cnefe_silver;

INSERT INTO base_cnefe_silver (codigo_unico, codigo_setor, cep, cnefe_localidade, cnefe_logradouro)
SELECT
    COD_UNICO_ENDERECO                                                        AS codigo_unico,
    TRIM(REPLACE(COD_SETOR, 'P', ''))                                         AS codigo_setor,
    CEP                                                                        AS cep,
    DSC_LOCALIDADE                                                             AS cnefe_localidade,
    CONCAT(NOM_TIPO_SEGLOGR, ' ', NOM_TITULO_SEGLOGR, ' ', NOM_SEGLOGR)       AS cnefe_logradouro
FROM base_cnefe;
```

**Tratamentos aplicados:**
- Identificados valores duplicados em `COD_UNICO_ENDERECO` via `SELECT DISTINCT`; a função `ranking` seleciona apenas o registro mais completo por endereço
- Removida a letra `P` presente ao final de todos os registros de `COD_SETOR`, além de espaços extras
- As colunas de tipo, título e nome do logradouro foram concatenadas para gerar o endereço completo

---

#### `base_busca_silver`

Por ser uma base pequena (107 registros), foi possível identificar erros visualmente.

**Criação da tabela:**
```sql
IF OBJECT_ID('base_busca_silver','U') IS NOT NULL
    DROP TABLE base_busca_silver;

CREATE TABLE base_busca_silver (
    consulta_logradouro  VARCHAR(50),
    consulta_numero      VARCHAR(4),
    consulta_bairro      VARCHAR(50),
    consulta_cep         VARCHAR(8),
    consulta_complemento VARCHAR(50),
    consulta_municipio   VARCHAR(50)
);
```

**Inserção e tratamento:**
```sql
TRUNCATE TABLE base_busca_silver;

INSERT INTO base_busca_silver (
    consulta_logradouro, consulta_numero, consulta_bairro,
    consulta_cep, consulta_complemento, consulta_municipio
)
SELECT
    TRIM(REPLACE(REPLACE(consulta_logradouro, 'None', ''), '10R', ''))      AS consulta_logradouro,
    ISNULL(NULLIF(TRIM(REPLACE(consulta_numero, 'SN', '')), ''), 'N/A')     AS consulta_numero,
    ISNULL(NULLIF(TRIM(consulta_bairro), ''), 'N/A')                        AS consulta_bairro,
    ISNULL(NULLIF(TRIM(consulta_cep), ''), 'N/A')                           AS consulta_cep,
    ISNULL(NULLIF(TRIM(consulta_complemento), ''), 'N/A')                   AS consulta_complemento,
    ISNULL(NULLIF(TRIM(consulta_municipio), ''), 'N/A')                     AS consulta_municipio
FROM base_busca;
```

**Tratamentos aplicados:**
- Removidos caracteres inválidos na coluna de logradouro (`None`, `10R`) que impediam a consulta
- Todos os valores nulos substituídos por `N/A` para padronização
- Espaços extras removidos com `TRIM` em todas as colunas

---

### 5ª Etapa — Geração do Setor Censitário

A abordagem escolhida foi a criação de uma **VIEW**, que gera uma visualização virtual com os dados de endereço enriquecidos pelo setor censitário. O resultado também foi exportado como CSV, disponível na pasta `resultado`.

```sql
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
    ) AS setor_censitario_encontrado
FROM base_busca_silver b;
```

A `view_busca_setor` traz os dados de endereço da `base_busca_silver` e enriquece cada registro com o código de setor censitário correspondente, buscado na `base_cnefe_silver`. A lógica central utiliza o `COALESCE`, que funciona como uma busca em cascata: primeiro tenta localizar o setor pelo logradouro; se não encontrar, tenta pelo CEP; se nenhuma das duas retornar resultado, o campo fica como `NULL`. O `TOP 1` garante que apenas um setor seja retornado por endereço, evitando duplicações.

Essa abordagem foi necessária porque a base de setores original não possuía uma coluna com dados únicos por endereço. Já a `base_cnefe_silver` contava com identificador único e logradouro completo, tornando-a a fonte mais adequada. O CEP foi incluído como critério de apoio — mesmo considerando sua possível duplicidade — para ampliar as chances de encontrar o setor censitário de cada registro.

---

> **Exportação do CSV:** Com a view executada, na aba de resultados clique com o botão direito → **"Salvar resultados como"** → selecione a pasta de destino (o formato CSV já vem pré-selecionado pelo Windows).
