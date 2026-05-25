# Teste_fiocruz 


# Importante 
Para a execução da solução é implicitamente necessário ter acesso as base de dados disponibilizadas na pasta Base de dados.

# Aquitetura
A realização do teste foi executada utilizando MSSQL Server, uum sistema de gerenciamento de banco de dados.
A arquitetura da solução foi baseada em Meddalion Architecture, por questões de organização, fácil compreensão, 
além de manter todos os dados originais disponiveis para consulta e permitindo a fácil execução.

# Passo a Passo 
# 1ª Etapa - Criação do banco de dados 
Para permitir as consultas é necessário criar um banco de dados no SGBD de sua preferência, entretanto ressalto que para a
realização do projeto é necessário utilizar o MSSQL Server.
Ao entrar no MSSQL, conectar ao servidor local, após isso selecionar a opção "Nova consulta" em seguida digitar o seguinte código: 

# CREATE DATABASE teste_fiocruz

Você terá criado o seu banco de dados.

# 2ª Etapa - Criação das Tabelas
Para criar as tabelas, é necessário conectar-se com o banco de dados anteriormente criado. Para fazer isso é muito simples, basta buscar na aba
"Pesquisador de Objetos" a pasta "Banco de Dados", clicar no "+" e clicar no banco anteriormente criado com o botão direito do mouse e selecionar
a opção "Nova Consulta" na janela que abrir digitar o seguinte código:

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

Observações - Cada coluna é tem que ser baseada no arquivo CSV original e possuir o mesmo tipo primitivo dos dados, além de possuir a mesma quantidade
de caracteres. Nesse projeto foram criadas duas tabelas, a tabela base_busca e a tabela base_cnefe, o código acima ilustra a criação da tabela base_busca, mas é possivel também ter acesso ao script da criação das tabelas disponiveis na pasta scripts.

# 3ª Etapa - Inserindo os dados
A inserção dos dados foi realizada utilizaando novamente a aba de consultas, abaixo segue o código utilizado para a inserção. 

TRUNCATE TABLE base_busca
		BULK INSERT base_busca
		FROM 'C:\Users\evaga\OneDrive\Área de Trabalho\teste_fiocruz\base\2026_teste_tecnico_relinke_cidacs(in).csv'
		WITH (	FIRSTROW = 2,
				FIELDTERMINATOR = ';', 
				TABLOCK
		);

Esse código além de inserir os dados na tabela com o BULK INSERT também "trava" os dados permitindo fazer consultas livre mente sem alterações
na base original dos dados. Ao lado da clausula "FROM" possui o caminho para a base de dados original. A clausula "WITH" é onde se informa as
caracteristicas da tabela original, como o index da tabela que é a primeira linha, ou seja os dados eles só começam na 2ª linha e o delimitador de
colunas que nessa base é o ";" mas pode variar de acordo com a base.
Saliento a extrema importacia da etapa anterior, pois caso haja algum erro no tamanho dos caracteres ou no tipo de dado inserido o comando acima
não irá funcionar.

# 4ª Etapa - Limpando os dados. 
A etapa mais importante de todo o processo, é nessa etapa onde se aplica regras de negocios e realiza as tranformações necessárias para se obter
uma base de dados limpa e confiável. Nos exemplos acima, utilizei somente a base_busca para exemplificar os casos, porém nesse exemplo utilizarei as 
duas bases pois, cada base possui caracteristicas distintas.
Como no processo utilizaremos a abordagem da medallion architecture, nos passos acima nos importamos a camada bronze, com todos os dados brutos sem
nenhum tipo de tratamento, nós não alteraremos esses dados. Para o tratamento desses dados, nós criaremos uma nova camada a camada silver, que terá duas
tabelas a tabela base_busca_silver e a tabela base_cnefe_silver.
Segue o código de criação das tabelas 
  # base_busca_silver 
  Segue o código abaixo:
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

# base_cnefe_silver 
IF OBJECT_ID('base_cnefe_silver','U') IS NOT NULL
	DROP TABLE base_cnefe_silver;
	CREATE TABLE base_cnefe_silver(
codigo_unico VARCHAR(20), 
codigo_setor VARCHAR(50),
cep VARCHAR(10),
cnefe_localidade VARCHAR(100),
cnefe_logradouro VARCHAR(100));

Perceba que, na base cnefe, nessa camada, foi diminuido a quantidade de colunas na tabela, pois as mesmas continham informações redundantes e nao iriam
contribuir para a geração do setor sensitário.Extrair apenas o que considerei necessário para obter as informações.
Agora partimos para a etapa mais interessante como já mencionei acima, a etapa de inserção dos dados. Por ser mais detalhada, começarei pela tabela 
base_cnefe_silver, segue o código abaixo.
# base_cnefe_silver 
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

Para iniciar, identifiquei utilizando "SELECT DISTINCT" que haviam valores duplicados na coluna "COD_UNICO_ENDERECO", criei a função ranking para
identificar e selecionar apenas as linhas que possuiam mais informações disponiveis, deletando todaas as outras. na coluna "COD_SETOR" havia a letra "P"]
presente no final de todos os registros, removi e removi os possiveis espaços entre eles. Na tabela original os endereços estavam separados por tipo de logradouro, o titulo do logradouro e o nome do segmento juntei as três respectivas colunas para gerar o logradouro completo. As decisões foram tomadas e aplicadas visando obter o máximo de informação util e limpa possivel.

# base_busca_silver
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

Pelo fato de ser uma base contendo apenas 107 registros foi possivel identificar algus erros visualmente na primeira coluna, haviem endereços com
caracteres que impossibilitavam a consulta, alem de valores nulos em todas as colunas.Todos os valores nulos foram substituidos por "N/A", para padronização
dos dados e foram removidos possiveis espaços vazios das colunas com a função "TRIM".

# 5ª Etapa - Gerando o setor sensitário 
Finalmente a ultima etapa, após tudo visto acima, a abordagem que eu selecionei para gerar o setor sensitário foi utilizando a funcionalidade "VIEW"
que por sua vez gera uma vizualização das colunas selecionadas. mas também foi possivel gerar o arquivo CSV que estará disponivel na pasta resultado.
Com o editor de consultas aberto, criei esse código: 

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

A view view_busca_setor é uma consulta salva que funciona como uma tabela virtual, trazendo os dados de endereço da base_busca_silver e enriquecendo-os com o código de setor censitário correspondente, buscado na base_cnefe_silver.
A lógica central utiliza o COALESCE, que funciona como uma busca em cascata: primeiro tenta localizar o setor censitário cruzando pelo logradouro do endereço consultado; caso não encontre, faz uma segunda tentativa usando o CEP. Se nenhuma das duas retornar resultado, o campo fica como NULL. O TOP 1 garante que apenas um setor seja retornado por endereço, evitando duplicações.
Essa abordagem foi necessária porque a base de setores original não possuía uma coluna com dados únicos por endereço, tornando o cruzamento pouco confiável. Já a base_cnefe_silver contava com um identificador único por endereço e logradouro completo, o que a tornou a fonte mais adequada para a busca. O CEP foi incluído como critério de apoio — mesmo considerando sua possível duplicidade na base — para ampliar as chances de encontrar o setor censitário de cada registro. A solução foi construída com base em testes, análise visual dos dados e a documentação das bases disponibilizadas.

Observação Final -  Para a geração do arquivo CSV pedido na entrega da solução executei o código e na aba de resultados, cliquei com o botão direito, selecionei a opção "salvar resultados como", O windows ja pré selecionou a opção csv e eu selecionei a pasta que iria salvar.





