CREATE OR REPLACE TABLE --- Cria uma tabela selecionando um arquivo
acidentes_prf_2025 AS
select
    *
from
    read_csv_auto(
        'dados_brutos/acidentes2025.csv',
        delim = ';',
        header = true,
        encoding = 'latin-1',
        sample_size = -1
    );


------------------- Criação do histórico PRF dos 3 anos ---------------------
CREATE OR REPLACE TABLE acidentes_prf_historico.resumo_geral_por_ano AS
WITH historico AS (
    SELECT 2023 AS ano, *
    FROM prf_2023.main.acidentes_prf_2023

    UNION ALL

    SELECT 2024 AS ano, *
    FROM prf_2024.main.acidentes_prf_2024

    UNION ALL

    SELECT 2025 AS ano, *
    FROM prf_2025.main.acidentes_prf_2025
),
classificado AS (
    SELECT
        *,
        COALESCE(fim_de_semana, 0) = 1 AS eh_fim_semana,
        LOWER(TRIM(COALESCE(data_comemorativa, 'Normal'))) <> 'normal'
            AS eh_feriado
    FROM historico
),
resumo AS (
    SELECT
        ano,
        COUNT(*) AS total_acidentes,
        COALESCE(SUM(TRY_CAST(mortos AS INTEGER)), 0) AS total_mortos,
        COALESCE(SUM(TRY_CAST(pessoas AS INTEGER)), 0)
            AS total_pessoas_envolvidas,
        COALESCE(SUM(TRY_CAST(feridos AS INTEGER)), 0) AS total_feridos,
        COALESCE(SUM(TRY_CAST(acidente_fatal AS INTEGER)), 0)
            AS total_acidentes_fatais,

        REPLACE(
            PRINTF(
                '%.2f%%',
                COUNT(TRY_CAST(mortos AS INTEGER)) FILTER (
                    WHERE TRY_CAST(mortos AS INTEGER) >= 1
                ) * 100.0 / NULLIF(COUNT(id), 0)
            ),
            '.',
            ','
        ) AS "Taxa de Acidentes Fatais",

        COUNT(*) FILTER (WHERE eh_feriado)
            AS acidentes_feriados,

        COUNT(*) FILTER (WHERE eh_fim_semana)
            AS acidentes_fim_semana,

        COUNT(*) FILTER (WHERE eh_feriado OR eh_fim_semana)
            AS acidentes_feriados_e_fim_semana,

        COUNT(*) FILTER (WHERE NOT eh_feriado AND NOT eh_fim_semana)
            AS acidentes_dia_normal
    FROM classificado
    GROUP BY ano
)
SELECT
    *,
    REPLACE(
        PRINTF(
            '%.2f%%',
            acidentes_feriados_e_fim_semana * 100.0
                / NULLIF(acidentes_dia_normal, 0)
        ),
        '.',
        ','
    ) AS "Feriados e Fins de Semana em Relação a Dias Normais"
FROM resumo
ORDER BY ano ASC;


SELECT
    *
FROM
    acidentes_prf_historico.resumo_geral_por_ano;


------------------- Cria uma view por dia com a base dos 3 anos ------------------
CREATE OR REPLACE VIEW vw_historico_por_dia AS
WITH
    historico AS (
        SELECT
            2023 AS ano,
            *
        FROM
            prf_2023.main.acidentes_prf_2023
        UNION ALL
        SELECT
            2024 AS ano,
            *
        FROM
            prf_2024.main.acidentes_prf_2024
        UNION ALL
        SELECT
            2025 AS ano,
            *
        FROM
            prf_2025.main.acidentes_prf_2025
    )
SELECT
    ano,
    dia_semana,
    COUNT(*) AS total_acidentes,
    COUNT(*) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) > 0
    ) AS acidentes_fatais,
    SUM(TRY_CAST (pessoas AS INTEGER)) AS total_pessoas,
    SUM(TRY_CAST (mortos AS INTEGER)) AS total_mortos,
    SUM(TRY_CAST (feridos AS INTEGER)) AS total_feridos,
    SUM(TRY_CAST (veiculos AS INTEGER)) AS total_veiculos,
    SUM(TRY_CAST (acidente_fatal AS INTEGER)) AS total_acidentes_fatais
FROM
    historico
GROUP BY
    ano,
    dia_semana;


SELECT
    *
FROM
    vw_historico_por_dia
ORDER BY
    ano ASC,
    total_acidentes ASC;


---------------- Cria uma view por UF com a base dos 3 anos ------------------
CREATE OR REPLACE VIEW vw_historico_por_uf AS
WITH
    historico AS (
        SELECT
            2023 AS ano,
            *
        FROM
            prf_2023.main.acidentes_prf_2023
        UNION ALL
        SELECT
            2024 AS ano,
            *
        FROM
            prf_2024.main.acidentes_prf_2024
        UNION ALL
        SELECT
            2025 AS ano,
            *
        FROM
            prf_2025.main.acidentes_prf_2025
    )
SELECT
    ano,
    uf,
    COUNT(*) AS total_acidentes,
    COUNT(*) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) > 0
    ) AS acidentes_fatais,
    SUM(TRY_CAST (pessoas AS INTEGER)) AS total_pessoas,
    SUM(TRY_CAST (mortos AS INTEGER)) AS total_mortos,
    SUM(TRY_CAST (feridos AS INTEGER)) AS total_feridos,
    SUM(TRY_CAST (veiculos AS INTEGER)) AS total_veiculos,
    SUM(TRY_CAST (acidente_fatal AS INTEGER)) AS total_acidentes_fatais
FROM
    historico
GROUP BY
    ano,
    uf;


SELECT
    *
FROM
    vw_historico_por_uf
ORDER BY
    ano ASC,
    total_acidentes ASC;


----------------Cria uma view por BR com a base dos 3 anos ------------------
CREATE OR REPLACE VIEW vw_historico_por_br AS
WITH
    historico AS (
        SELECT
            2023 AS ano,
            *
        FROM
            prf_2023.main.acidentes_prf_2023
        UNION ALL
        SELECT
            2024 AS ano,
            *
        FROM
            prf_2024.main.acidentes_prf_2024
        UNION ALL
        SELECT
            2025 AS ano,
            *
        FROM
            prf_2025.main.acidentes_prf_2025
    )
SELECT
    ano,
    br,
    COUNT(*) AS total_acidentes,
    COUNT(*) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) > 0
    ) AS acidentes_fatais,
    SUM(TRY_CAST (pessoas AS INTEGER)) AS total_pessoas,
    SUM(TRY_CAST (mortos AS INTEGER)) AS total_mortos,
    SUM(TRY_CAST (feridos AS INTEGER)) AS total_feridos,
    SUM(TRY_CAST (veiculos AS INTEGER)) AS total_veiculos,
    SUM(TRY_CAST (acidente_fatal AS INTEGER)) AS total_acidentes_fatais
FROM
    historico
GROUP BY
    ano,
    br;


SELECT
    *
FROM
    vw_historico_por_br
ORDER BY
    ano ASC,
    total_acidentes ASC;


----------------------- Cria uma view por causa com a base dos 3 anos ------------------
CREATE OR REPLACE VIEW vw_historico_por_causa AS
WITH
    historico AS (
        SELECT
            2023 AS ano,
            *
        FROM
            prf_2023.main.acidentes_prf_2023
        UNION ALL
        SELECT
            2024 AS ano,
            *
        FROM
            prf_2024.main.acidentes_prf_2024
        UNION ALL
        SELECT
            2025 AS ano,
            *
        FROM
            prf_2025.main.acidentes_prf_2025
    )
SELECT
    ano,
    causa_acidente,
    COUNT(*) AS total_acidentes,
    COUNT(*) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) > 0
    ) AS acidentes_fatais,
    SUM(TRY_CAST (pessoas AS INTEGER)) AS total_pessoas,
    SUM(TRY_CAST (mortos AS INTEGER)) AS total_mortos,
    SUM(TRY_CAST (feridos AS INTEGER)) AS total_feridos,
    SUM(TRY_CAST (veiculos AS INTEGER)) AS total_veiculos,
    SUM(TRY_CAST (acidente_fatal AS INTEGER)) AS total_acidentes_fatais
FROM
    historico
GROUP BY
    ano,
    causa_acidente;


SELECT
    *
FROM
    vw_historico_por_causa
ORDER BY
    ano ASC,
    total_acidentes ASC;


------------------  Cria uma view por tipo com a base dos 3 anos ---------------
CREATE OR REPLACE VIEW vw_historico_por_tipo AS
WITH
    historico AS (
        SELECT
            2023 AS ano,
            *
        FROM
            prf_2023.main.acidentes_prf_2023
        UNION ALL
        SELECT
            2024 AS ano,
            *
        FROM
            prf_2024.main.acidentes_prf_2024
        UNION ALL
        SELECT
            2025 AS ano,
            *
        FROM
            prf_2025.main.acidentes_prf_2025
    )
SELECT
    ano,
    tipo_acidente,
    COUNT(*) AS total_acidentes,
    COUNT(*) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) > 0
    ) AS acidentes_fatais,
    SUM(TRY_CAST (pessoas AS INTEGER)) AS total_pessoas,
    SUM(TRY_CAST (mortos AS INTEGER)) AS total_mortos,
    SUM(TRY_CAST (feridos AS INTEGER)) AS total_feridos,
    SUM(TRY_CAST (veiculos AS INTEGER)) AS total_veiculos,
    SUM(TRY_CAST (acidente_fatal AS INTEGER)) AS total_acidentes_fatais
FROM
    historico
GROUP BY
    ano,
    tipo_acidente;


SELECT
    *
FROM
    vw_historico_por_tipo
ORDER BY
    ano ASC,
    total_acidentes ASC;


-------------------- Cria uma view por classificação com a base dos 3 anos ------------
CREATE OR REPLACE VIEW vw_historico_por_classificacao AS
WITH
    historico AS (
        SELECT
            2023 AS ano,
            *
        FROM
            prf_2023.main.acidentes_prf_2023
        UNION ALL
        SELECT
            2024 AS ano,
            *
        FROM
            prf_2024.main.acidentes_prf_2024
        UNION ALL
        SELECT
            2025 AS ano,
            *
        FROM
            prf_2025.main.acidentes_prf_2025
    )
SELECT
    ano,
    classificacao_acidente,
    COUNT(*) AS total_acidentes,
    COUNT(*) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) > 0
    ) AS acidentes_fatais,
    SUM(TRY_CAST (pessoas AS INTEGER)) AS total_pessoas,
    SUM(TRY_CAST (mortos AS INTEGER)) AS total_mortos,
    SUM(TRY_CAST (feridos AS INTEGER)) AS total_feridos,
    SUM(TRY_CAST (veiculos AS INTEGER)) AS total_veiculos,
    SUM(TRY_CAST (acidente_fatal AS INTEGER)) AS total_acidentes_fatais
FROM
    historico
GROUP BY
    ano,
    classificacao_acidente;


SELECT
    *
FROM
    vw_historico_por_classificacao
ORDER BY
    ano ASC,
    total_acidentes ASC;


------------------------ Cria uma view por fase dia com a base dos 3 anos --------------
CREATE OR REPLACE VIEW vw_historico_por_fase_dia AS
WITH
    historico AS (
        SELECT
            2023 AS ano,
            *
        FROM
            prf_2023.main.acidentes_prf_2023
        UNION ALL
        SELECT
            2024 AS ano,
            *
        FROM
            prf_2024.main.acidentes_prf_2024
        UNION ALL
        SELECT
            2025 AS ano,
            *
        FROM
            prf_2025.main.acidentes_prf_2025
    )
SELECT
    ano,
    fase_dia,
    COUNT(*) AS total_acidentes,
    COUNT(*) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) > 0
    ) AS acidentes_fatais,
    SUM(TRY_CAST (pessoas AS INTEGER)) AS total_pessoas,
    SUM(TRY_CAST (mortos AS INTEGER)) AS total_mortos,
    SUM(TRY_CAST (feridos AS INTEGER)) AS total_feridos,
    SUM(TRY_CAST (veiculos AS INTEGER)) AS total_veiculos,
    SUM(TRY_CAST (acidente_fatal AS INTEGER)) AS total_acidentes_fatais
FROM
    historico
GROUP BY
    ano,
    fase_dia;


SELECT
    *
FROM
    vw_historico_por_fase_dia
ORDER BY
    ano ASC,
    total_acidentes ASC;


-- Cria uma view por tipo de pista com a base dos 3 anos
CREATE OR REPLACE VIEW vw_historico_por_tipo_pista AS
WITH
    historico AS (
        SELECT
            2023 AS ano,
            *
        FROM
            prf_2023.main.acidentes_prf_2023
        UNION ALL
        SELECT
            2024 AS ano,
            *
        FROM
            prf_2024.main.acidentes_prf_2024
        UNION ALL
        SELECT
            2025 AS ano,
            *
        FROM
            prf_2025.main.acidentes_prf_2025
    )
SELECT
    ano,
    tipo_pista,
    COUNT(*) AS total_acidentes,
    COUNT(*) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) > 0
    ) AS acidentes_fatais,
    SUM(TRY_CAST (pessoas AS INTEGER)) AS total_pessoas,
    SUM(TRY_CAST (mortos AS INTEGER)) AS total_mortos,
    SUM(TRY_CAST (feridos AS INTEGER)) AS total_feridos,
    SUM(TRY_CAST (veiculos AS INTEGER)) AS total_veiculos,
    SUM(TRY_CAST (acidente_fatal AS INTEGER)) AS total_acidentes_fatais
FROM
    historico
GROUP BY
    ano,
    tipo_pista;


SELECT
    *
FROM
    vw_historico_por_tipo_pista
ORDER BY
    ano ASC,
    total_acidentes ASC;


-- Cria uma view por sentido via com a base dos 3 anos
CREATE OR REPLACE VIEW vw_historico_por_sentido_via AS
WITH
    historico AS (
        SELECT
            2023 AS ano,
            *
        FROM
            prf_2023.main.acidentes_prf_2023
        UNION ALL
        SELECT
            2024 AS ano,
            *
        FROM
            prf_2024.main.acidentes_prf_2024
        UNION ALL
        SELECT
            2025 AS ano,
            *
        FROM
            prf_2025.main.acidentes_prf_2025
    )
SELECT
    ano,
    sentido_via,
    COUNT(*) AS total_acidentes,
    COUNT(*) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) > 0
    ) AS acidentes_fatais,
    SUM(TRY_CAST (pessoas AS INTEGER)) AS total_pessoas,
    SUM(TRY_CAST (mortos AS INTEGER)) AS total_mortos,
    SUM(TRY_CAST (feridos AS INTEGER)) AS total_feridos,
    SUM(TRY_CAST (veiculos AS INTEGER)) AS total_veiculos,
    SUM(TRY_CAST (acidente_fatal AS INTEGER)) AS total_acidentes_fatais
FROM
    historico
GROUP BY
    ano,
    sentido_via;


SELECT
    *
FROM
    vw_historico_por_sentido_via
ORDER BY
    ano ASC,
    total_acidentes ASC;


-- Cria uma view por condicao meteorologica com a base dos 3 anos
CREATE OR REPLACE VIEW vw_historico_por_condicao_meteorologica AS
WITH
    historico AS (
        SELECT
            2023 AS ano,
            *
        FROM
            prf_2023.main.acidentes_prf_2023
        UNION ALL
        SELECT
            2024 AS ano,
            *
        FROM
            prf_2024.main.acidentes_prf_2024
        UNION ALL
        SELECT
            2025 AS ano,
            *
        FROM
            prf_2025.main.acidentes_prf_2025
    )
SELECT
    ano,
    condicao_metereologica,
    COUNT(*) AS total_acidentes,
    COUNT(*) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) > 0
    ) AS acidentes_fatais,
    SUM(TRY_CAST (pessoas AS INTEGER)) AS total_pessoas,
    SUM(TRY_CAST (mortos AS INTEGER)) AS total_mortos,
    SUM(TRY_CAST (feridos AS INTEGER)) AS total_feridos,
    SUM(TRY_CAST (veiculos AS INTEGER)) AS total_veiculos,
    SUM(TRY_CAST (acidente_fatal AS INTEGER)) AS total_acidentes_fatais
FROM
    historico
GROUP BY
    ano,
    condicao_metereologica;


SELECT
    *
FROM
    vw_historico_por_condicao_meteorologica
ORDER BY
    ano ASC,
    total_acidentes ASC;


-----Cria os acidentes fatais na tabela de acordo com a tabela selecionada.
ALTER TABLE prf_2023.acidentes_prf_2023
ADD COLUMN IF NOT EXISTS acidente_fatal INTEGER;


UPDATE prf_2023.acidentes_prf_2023
SET
    acidente_fatal = CASE
        WHEN COALESCE(TRY_CAST (mortos AS INTEGER), 0) >= 1 THEN 1
        ELSE 0
    END;


-- Adiciona as novas colunas
ALTER TABLE prf_2025.acidentes_prf_2025
ADD COLUMN IF NOT EXISTS ano_acidente INTEGER;


ALTER TABLE prf_2025.acidentes_prf_2025
ADD COLUMN IF NOT EXISTS mes_acidente INTEGER;


select
    *
from
    prf_2025.acidentes_prf_2025;


-- Preenche as colunas usando data_inversa
UPDATE prf_2025.acidentes_prf_2025
SET
    ano_acidente = CAST(
        EXTRACT (
            YEAR
            FROM
                TRY_CAST (data_inversa AS DATE)
        ) AS INTEGER
    ),
    mes_acidente = CAST(
        EXTRACT (
            MONTH
            FROM
                TRY_CAST (data_inversa AS DATE)
        ) AS INTEGER
    );


SELECT
    *
FROM
    prf_2024.acidentes_prf_2024;


ALTER TABLE prf_2025.acidentes_prf_2025
ADD COLUMN IF NOT EXISTS fim_de_semana INTEGER;


UPDATE prf_2025.acidentes_prf_2025
SET
    fim_de_semana = CASE
        WHEN LOWER(TRIM(dia_semana)) IN ('sexta-feira' 'sábado', 'domingo') THEN 1
        ELSE 0
    END;


SELECT
    *
FROM
    prf_2024.acidentes_prf_2024;


-- Tabela compatível com o segundo arquivo anexado
CREATE TABLE IF NOT EXISTS nacional_2024 (data VARCHAR, nome VARCHAR, tipo VARCHAR, descricao VARCHAR);


SELECT
    *
FROM
    feriados.comemorativa;


SELECT
    *
FROM
    feriados.feriado;


-- Janeiro de 2023: continuação do período de fim de ano
INSERT INTO
    nacional_2024 (data, nome, tipo, descricao)
SELECT
    STRFTIME(dia, '%d/%m/%Y'),
    'Fim de Ano',
    'NACIONAL',
    'Período nacional de alto fluxo entre 20 de dezembro e 2 de janeiro.'
FROM
    GENERATE_SERIES(DATE '2024-01-01', DATE '2024-01-02', INTERVAL 1 DAY) AS calendario (dia)
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            nacional_2024
        WHERE
            data = STRFTIME(dia, '%d/%m/%Y')
            AND nome = 'Fim de Ano'
    );


SELECT
    *
FROM
    nacional_2025;


-- Carnaval de 2023
INSERT INTO
    nacional_2024 (data, nome, tipo, descricao)
SELECT
    STRFTIME(dia, '%d/%m/%Y'),
    'Carnaval',
    'NACIONAL',
    'Período de Carnaval de 2024.'
FROM
    GENERATE_SERIES(DATE '2024-02-18', DATE '2024-02-22', INTERVAL 1 DAY) AS calendario (dia)
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            nacional_2024
        WHERE
            data = STRFTIME(dia, '%d/%m/%Y')
            AND nome = 'Carnaval'
    );


-- Dezembro de 2023: início do período de fim de ano
INSERT INTO
    nacional_2025 (data, nome, tipo, descricao)
SELECT
    STRFTIME(dia, '%d/%m/%Y'),
    'Fim de Ano',
    'NACIONAL',
    'Período nacional de alto fluxo entre 20 de dezembro e 2 de janeiro.'
FROM
    GENERATE_SERIES(DATE '2025-12-20', DATE '2025-12-31', INTERVAL 1 DAY) AS calendario (dia)
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            nacional_2025
        WHERE
            data = STRFTIME(dia, '%d/%m/%Y')
            AND nome = 'Fim de Ano'
    );


---Adiciona a coluna de data comemorativa e descrição da data comemorativa na tabela de acidentes da PRF de acordo com o ano selecionado
ALTER TABLE prf_2025.acidentes_prf_2025
ADD COLUMN IF NOT EXISTS data_comemorativa VARCHAR;


---Adiciona a coluna de descrição da data comemorativa na tabela de acidentes da PRF de acordo com o ano selecionado
ALTER TABLE prf_2025.acidentes_prf_2025
ADD COLUMN IF NOT EXISTS descricao_data_comemorativa VARCHAR;


--- Atualiza a tabela selecionada normal como valor padrão para todas as linhas
UPDATE prf_2025.acidentes_prf_2025
SET
    data_comemorativa = 'Normal',
    descricao_data_comemorativa = 'Data sem classificação comemorativa ou período especial.';


---- Atualiza a tabela selecionada com os valores de data comemorativa e descrição da data comemorativa de acordo com a tabela de feriados nacionais e datas comemorativas do ano selecionado
UPDATE prf_2025.acidentes_prf_2025 AS acidentes
SET
    data_comemorativa = calendario.data_comemorativa,
    descricao_data_comemorativa = calendario.descricao_data_comemorativa
FROM
    (
        WITH
            datas_unificadas AS (
                SELECT
                    CAST(COALESCE(TRY_CAST (data AS DATE), TRY_STRPTIME(TRIM(CAST(data AS VARCHAR)), '%d/%m/%Y')) AS DATE) AS data_calendario,
                    TRIM(nome) AS nome,
                    TRIM(descricao) AS descricao
                FROM
                    feriados.nacional_2025
                UNION ALL
                SELECT
                    CAST(COALESCE(TRY_CAST (data AS DATE), TRY_STRPTIME(TRIM(CAST(data AS VARCHAR)), '%d/%m/%Y')) AS DATE) AS data_calendario,
                    TRIM(nome) AS nome,
                    TRIM(descricao) AS descricao
                FROM
                    feriados.nacional_2025
            )
        SELECT
            data_calendario,
            STRING_AGG(DISTINCT nome, ' / ') AS data_comemorativa,
            STRING_AGG(DISTINCT descricao, ' / ') AS descricao_data_comemorativa
        FROM
            datas_unificadas
        WHERE
            data_calendario IS NOT NULL
        GROUP BY
            data_calendario
    ) AS calendario
WHERE
    TRY_CAST (acidentes.data_inversa AS DATE) = calendario.data_calendario;


SELECT
    *
FROM
    feriados.nacional_2025;


SELECT
    *
FROM
    prf_2025.acidentes_prf_2025;


SELECT
    *
FROM
    prf_2025.main.acidentes_prf_2025;


SELECT
    *
FROM
    vw_historico_por_sentido_via;


--------- cria views históricas unindo os 3 anos 
CREATE OR REPLACE VIEW vw_historico_por_br AS
WITH
    historico AS (
        SELECT
            2023 AS ano,
            *
        FROM
            prf_2023.main.acidentes_prf_2023
        UNION ALL
        SELECT
            2024 AS ano,
            *
        FROM
            prf_2024.main.acidentes_prf_2024
        UNION ALL
        SELECT
            2025 AS ano,
            *
        FROM
            prf_2025.main.acidentes_prf_2025
    )
SELECT
    ano,
    br,
    COUNT(*) AS total_acidentes,
    COUNT(*) FILTER(
        WHERE
            COALESCE(acidente_fatal, 0) = 1
    ) AS acidentes_fatais,
    SUM(COALESCE(TRY_CAST (pessoas AS BIGINT), 0)) AS total_pessoas,
    SUM(COALESCE(TRY_CAST (mortos AS BIGINT), 0)) AS total_mortos,
    SUM(COALESCE(TRY_CAST (feridos AS BIGINT), 0)) AS total_feridos,
    SUM(COALESCE(TRY_CAST (veiculos AS BIGINT), 0)) AS total_veiculos,
    -- Fim de semana
    COUNT(*) FILTER(
        WHERE
            COALESCE(fim_de_semana, 0) = 1
    ) AS total_acidentes_fim_semana,
    COUNT(*) FILTER(
        WHERE
            COALESCE(fim_de_semana, 0) = 1
            AND COALESCE(acidente_fatal, 0) = 1
    ) AS acidentes_fatais_fim_semana,
    -- Dia útil
    COUNT(*) FILTER(
        WHERE
            COALESCE(fim_de_semana, 0) = 0
    ) AS total_acidentes_dia_util,
    COUNT(*) FILTER(
        WHERE
            COALESCE(fim_de_semana, 0) = 0
            AND COALESCE(acidente_fatal, 0) = 1
    ) AS acidentes_fatais_dia_util,
    -- Data comemorativa
    COUNT(*) FILTER(
        WHERE
            LOWER(TRIM(COALESCE(data_comemorativa, 'Normal'))) <> 'normal'
    ) AS total_acidentes_data_comemorativa,
    COUNT(*) FILTER(
        WHERE
            LOWER(TRIM(COALESCE(data_comemorativa, 'Normal'))) <> 'normal'
            AND COALESCE(acidente_fatal, 0) = 1
    ) AS acidentes_fatais_data_comemorativa,
    -- Dia normal
    COUNT(*) FILTER(
        WHERE
            LOWER(TRIM(COALESCE(data_comemorativa, 'Normal'))) = 'normal'
    ) AS total_acidentes_dia_normal,
    COUNT(*) FILTER(
        WHERE
            LOWER(TRIM(COALESCE(data_comemorativa, 'Normal'))) = 'normal'
            AND COALESCE(acidente_fatal, 0) = 1
    ) AS acidentes_fatais_dia_normal
FROM
    historico
GROUP BY
    ano,
    br
ORDER BY
    ano ASC,
    total_acidentes ASC;


----- Atualiza a view excluindo colunas administrativas, esqueci e atualizei
CREATE OR REPLACE VIEW limpeza_dados.vw_2025_acidentes_enriquecida AS
SELECT
    * EXCLUDE (latitude, longitude, regional, delegacia, uop)
FROM
    prf_2025.acidentes_prf_2025;
    
SELECT * FROM vw_historico_por_br;


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---CONSULTAS ANALITICAS
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--NIVEL 1
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----- CRIA UMA VIEW PARA ANALISE DE TENDENCIA ANUAL DE ACIDENTES FATAIS E SEVERIDADE
CREATE OR REPLACE VIEW consultas_analiticas.vw_tendencia_anual_severidade AS
WITH
    historico AS (
        SELECT
            2023 AS ano,
            *
        FROM
            limpeza_dados.vw_2023_acidentes_enriquecida
        UNION ALL
        SELECT
            2024 AS ano,
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        UNION ALL
        SELECT
            2025 AS ano,
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
    )
SELECT
    ano,
    count(id) AS "Total de Acidentes",
    count(TRY_CAST (mortos AS INTEGER)) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 1
    ) AS "Total de Acidentes Fatais",
    sum(TRY_CAST (mortos AS INTEGER)) AS "Total de Mortos",
    replace(
        printf(
            '%.2f%%',
            (
                (
                    count(TRY_CAST (mortos AS INTEGER)) FILTER(
                        WHERE
                            TRY_CAST (mortos AS INTEGER) >= 1
                    )
                ) / count(id)
            ) * 100.0
        ),
        '.',
        ','
    ) AS "Taxa de Acidentes Fatais",
FROM
    historico
GROUP BY
    ano
ORDER BY
    ano ASC;


SELECT
    *
FROM
    consultas_analiticas.vw_tendencia_anual_severidade
ORDER BY
    ano;


--- PERGUNTA: A proporção de acidentes fatais está aumentando, diminuindo ou estável ao longo dos anos?
--- Resposta: Se analisarmos o número bruto de acidentes fatais, temos um aumento grande de 2023 para 2024 e uma queda 
--- bem pequena entre 2024 e 2025, se mantendo, porém se olharmos a porcentagem de acidentes fatais, veremos que sempre está aumentando
----- CRIA UMA VIEW A PARTIR DOS MESES SOMANDO OS ACIDENTES DOS 3 ANOS PARA CADA MÊS E SEPARANDO POR PERIODO
CREATE OR REPLACE VIEW consultas_analiticas.vw_sazonalidade_mensal AS
WITH
    historico AS (
        SELECT
            *
        FROM
            limpeza_dados.vw_2023_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
    )
SELECT
    mes_acidente AS "Número do Mês",
    CASE mes_acidente
        WHEN 1 THEN 'Janeiro'
        WHEN 2 THEN 'Fevereiro'
        WHEN 3 THEN 'Março'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Maio'
        WHEN 6 THEN 'Junho'
        WHEN 7 THEN 'Julho'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Setembro'
        WHEN 10 THEN 'Outubro'
        WHEN 11 THEN 'Novembro'
        WHEN 12 THEN 'Dezembro'
        ELSE 'Mês inválido'
    END AS "Mês",
    CASE
        WHEN mes_acidente IN (12, 1) THEN 'Férias de fim de ano'
        WHEN mes_acidente = 7 THEN 'Férias de meio de ano'
        ELSE 'Fora do período tradicional de férias'
    END AS "Período de Férias",
    count(id) AS "Total de Acidentes",
    count(TRY_CAST (mortos AS INTEGER)) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 1
    ) AS "Total de Acidentes Fatais",
    sum(TRY_CAST (mortos AS INTEGER)) AS "Total de Mortos",
    replace(
        printf(
            '%.2f%%',
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) * 100.0
        ),
        '.',
        ','
    ) AS "Taxa de Acidentes Fatais"
FROM
    historico
GROUP BY
    mes_acidente
HAVING
    count(id) > 0
ORDER BY
    (
        count(TRY_CAST (mortos AS INTEGER)) FILTER(
            WHERE
                TRY_CAST (mortos AS INTEGER) >= 1
        ) / count(id)
    ) DESC;


SELECT
    *
FROM
    consultas_analiticas.vw_sazonalidade_mensal;


--- Pergunta: Qual mês apresenta a maior taxa de letalidade ao longo desses três anos? 
--- Resposta: Mês de maio com: 7,71% superando todos os outros
--- Esse pico coincide com os tradicionais períodos de férias de meio ou final de ano?
--- Resposta: Não, está fora do periodo de ferias.
----- CRIA UM VIEW PARA ANALISE DE INFLUENCIA DA LUMINOSIDADE NOS ACIDENTES FATAIS
CREATE OR REPLACE VIEW consultas_analiticas.vw_influencia_luminosidade AS
WITH
    historico AS (
        SELECT
            *
        FROM
            limpeza_dados.vw_2023_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
    )
SELECT
    fase_dia AS "Fase do Dia",
    count(id) AS "Total de Acidentes",
    count(TRY_CAST (mortos AS INTEGER)) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 1
    ) AS "Total de Acidentes Fatais",
    sum(TRY_CAST (mortos AS INTEGER)) AS "Total de Mortos",
    replace(
        printf(
            '%.2f%%',
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) * 100.0
        ),
        '.',
        ','
    ) AS "Taxa de Acidentes Fatais"
FROM
    historico
GROUP BY
    fase_dia
HAVING
    count(id) > 0
ORDER BY
    (
        count(TRY_CAST (mortos AS INTEGER)) FILTER(
            WHERE
                TRY_CAST (mortos AS INTEGER) >= 1
        ) / count(id)
    ) DESC;


SELECT
    *
FROM
    consultas_analiticas.vw_influencia_luminosidade;


--- Pergunta:  Embora o volume absoluto de acidentes possa ser maior durante o dia, a proporção (percentual) de acidentes fatais é maior à noite?
--- Resposta: sim, em pleno dia o percentual é de 5,02%, já em plena noite esse percentual sobe para 10,09%. Praticamente o dobro.
------ CRIA UMA VIEW PARA ANALISE DE INFLUENCIA DO FIM DE SEMANA NOS ACIDENTES FATAIS
CREATE OR REPLACE VIEW consultas_analiticas.vw_impacto_finais_semana AS
WITH
    historico AS (
        SELECT
            *
        FROM
            limpeza_dados.vw_2023_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
    ),
    resumo AS (
        SELECT
            COALESCE(TRY_CAST (fim_de_semana AS INTEGER), 0) AS indicador_fim_de_semana,
            count(id) AS total_acidentes,
            count(TRY_CAST (mortos AS INTEGER)) FILTER(
                WHERE
                    TRY_CAST (mortos AS INTEGER) >= 1
            ) AS total_acidentes_fatais,
            sum(TRY_CAST (mortos AS INTEGER)) AS total_mortos,
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) * 100.0 AS taxa_numerica
        FROM
            historico
        GROUP BY
            COALESCE(TRY_CAST (fim_de_semana AS INTEGER), 0)
        HAVING
            count(id) > 0
    ),
    comparacao AS (
        SELECT
            *,
            max(
                CASE
                    WHEN indicador_fim_de_semana = 0 THEN taxa_numerica
                END
            ) OVER () AS taxa_dia_util
        FROM
            resumo
    )
SELECT
    CASE
        WHEN indicador_fim_de_semana = 1 THEN 'Fim de semana'
        ELSE 'Dia útil'
    END AS "Tipo de Dia",
    total_acidentes AS "Total de Acidentes",
    total_acidentes_fatais AS "Total de Acidentes Fatais",
    total_mortos AS "Total de Mortos",
    replace(printf('%.2f%%', taxa_numerica), '.', ',') AS "Taxa de Acidentes Fatais",
FROM
    comparacao
ORDER BY
    indicador_fim_de_semana ASC;


SELECT
    *
FROM
    consultas_analiticas.vw_impacto_finais_semana;


--- Pergunta:  O risco relativo de um acidente ser fatal muda consideravelmente aos finais de semana?
--- Resposta: Sim o percentual do dia util é de 6,86%, o do final de semana é de 8,72%. Isso apresenta um aumento de 
--- 27,11% no risco de um acidente set fatal em um final de semana.
--- como foi feito o calculo: (8,72% - 6,86%) / 6,86% = 0,2711 ou 27,11%
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--NIVEL 2
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---- CRIA UMA VIEW PARA ANALISE DE LIFT POR TIPO DE ACIDENTE
CREATE OR REPLACE VIEW consultas_analiticas.vw_lift_tipo_acidente AS
WITH
    historico AS (
        SELECT
            *
        FROM
            limpeza_dados.vw_2023_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
    ),
    taxa_fatalidade_global AS (
        SELECT
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) AS taxa_fatalidade
        FROM
            historico
    )
SELECT
    tipo_acidente AS "Tipo de Acidente",
    count(id) AS "Total de Acidentes",
    count(TRY_CAST (mortos AS INTEGER)) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 1
    ) AS "Total de Acidentes Fatais",
    sum(TRY_CAST (mortos AS INTEGER)) AS "Total de Mortos",
    replace(
        printf(
            '%.2f%%',
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) * 100.0
        ),
        '.',
        ','
    ) AS "Taxa de Acidentes Fatais",
    round(
        (
            count(TRY_CAST (mortos AS INTEGER)) FILTER(
                WHERE
                    TRY_CAST (mortos AS INTEGER) >= 1
            ) / count(id)
        ) / taxa_fatalidade,
        2
    ) AS "Lift"
FROM
    historico,
    taxa_fatalidade_global
GROUP BY
    tipo_acidente,
    taxa_fatalidade
HAVING
    count(id) >= 100
ORDER BY
    "Lift" DESC;


SELECT
    *
FROM
    consultas_analiticas.vw_lift_tipo_acidente
ORDER BY
    "Lift" DESC;


--- Pergunta: Qual é a dinâmica de colisão (ex: colisão frontal, capotamento) que mais eleva a probabilidade de uma morte em relação à média global? 
---(Filtre apenas tipos com pelo menos 100 registros usando HAVING).
--- Resposta: Colisão frontal lidera esse ranking em porcentagem de 29,81% e lift de 4.16
----- CRIA UMA VIEW PARA ANALISE DE LIFT POR CAUSA DE ACIDENTE
CREATE OR REPLACE VIEW consultas_analiticas.vw_top5_causas_letalidade AS
WITH
    historico AS (
        SELECT
            *
        FROM
            limpeza_dados.vw_2023_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
    ),
    taxa_fatalidade_global AS (
        SELECT
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) AS taxa_fatalidade
        FROM
            historico
    )
SELECT
    causa_acidente AS "Causa do Acidente",
    count(id) AS "Total de Acidentes",
    count(TRY_CAST (mortos AS INTEGER)) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 1
    ) AS "Total de Acidentes Fatais",
    sum(TRY_CAST (mortos AS INTEGER)) AS "Total de Mortos",
    replace(
        printf(
            '%.2f%%',
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) * 100.0
        ),
        '.',
        ','
    ) AS "Taxa de Acidentes Fatais",
    round(
        (
            count(TRY_CAST (mortos AS INTEGER)) FILTER(
                WHERE
                    TRY_CAST (mortos AS INTEGER) >= 1
            ) / count(id)
        ) / taxa_fatalidade,
        2
    ) AS "Lift"
FROM
    historico,
    taxa_fatalidade_global
GROUP BY
    causa_acidente,
    taxa_fatalidade
HAVING
    count(id) > 0
ORDER BY
    "Lift" DESC;


SELECT
    *
FROM
    consultas_analiticas.vw_top5_causas_letalidade
ORDER BY
    "LIFT" DESC
LIMIT
    5;


--- Pergunta: Retorne as 5 causas presumíveis com o maior Lift. A ingestão de álcool ou a ultrapassagem indevida aparecem nesse top 5?
--- Resposta: Não, nenhum dos 2 estão no top5 
---- CRIA UMA VIEW PARA ANALISE DE LIFT POR TRAÇADO DE VIA
CREATE OR REPLACE VIEW consultas_analiticas.vw_letalidade_tracado_via AS
WITH
    historico AS (
        SELECT
            *
        FROM
            limpeza_dados.vw_2023_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
    ),
    taxa_fatalidade_global AS (
        SELECT
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) AS taxa_fatalidade
        FROM
            historico
    )
SELECT
    tracado_via AS "Traçado da Via",
    count(id) AS "Total de Acidentes",
    count(TRY_CAST (mortos AS INTEGER)) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 1
    ) AS "Total de Acidentes Fatais",
    sum(TRY_CAST (mortos AS INTEGER)) AS "Total de Mortos",
    replace(
        printf(
            '%.2f%%',
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) * 100.0
        ),
        '.',
        ','
    ) AS "Taxa de Acidentes Fatais",
    round(
        (
            count(TRY_CAST (mortos AS INTEGER)) FILTER(
                WHERE
                    TRY_CAST (mortos AS INTEGER) >= 1
            ) / count(id)
        ) / taxa_fatalidade,
        2
    ) AS "Lift"
FROM
    historico,
    taxa_fatalidade_global
GROUP BY
    tracado_via,
    taxa_fatalidade
HAVING
    count(id) > 500
ORDER BY
    "Lift" DESC;


SELECT
    *
FROM
    consultas_analiticas.vw_letalidade_tracado_via
ORDER BY
    "Lift" DESC;


--- Pergunta: A taxa de letalidade é estatisticamente pior em trechos de "Reta" ou em trechos de "Curva"? 
--- é pior em trechos de curva, curva está com 7,67% e reta está com 7,13%. porém retas apresentam um valor muito maior em total de acidentes.
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--NIVEL 3
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
------CRIA UMA VIEW PARA ANALISE DE LIFT POR TIPO DE PISTA E CONDIÇÃO METEOROLÓGICA
CREATE OR REPLACE VIEW consultas_analiticas.vw_pista_clima_letalidade AS
WITH
    historico AS (
        SELECT
            *
        FROM
            limpeza_dados.vw_2023_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
    ),
    taxa_fatalidade_global AS (
        SELECT
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) AS taxa_fatalidade
        FROM
            historico
    )
SELECT
    tipo_pista AS "Tipo de Pista",
    condicao_metereologica AS "Condição Meteorológica",
    count(id) AS "Total de Acidentes",
    count(TRY_CAST (mortos AS INTEGER)) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 1
    ) AS "Total de Acidentes Fatais",
    sum(TRY_CAST (mortos AS INTEGER)) AS "Total de Mortos",
    replace(
        printf(
            '%.2f%%',
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) * 100.0
        ),
        '.',
        ','
    ) AS "Taxa de Acidentes Fatais",
    round(
        (
            count(TRY_CAST (mortos AS INTEGER)) FILTER(
                WHERE
                    TRY_CAST (mortos AS INTEGER) >= 1
            ) / count(id)
        ) / taxa_fatalidade,
        2
    ) AS "Lift"
FROM
    historico,
    taxa_fatalidade_global
GROUP BY
    tipo_pista,
    condicao_metereologica,
    taxa_fatalidade
HAVING
    count(id) >= 50
ORDER BY
    "Lift" DESC,
    "Total de Acidentes" DESC;


SELECT
    *
FROM
    consultas_analiticas.vw_pista_clima_letalidade
ORDER BY
    "Lift" DESC,
    "Total de Acidentes" DESC;


--- Pergunta: Descubra qual combinação específica gera a maior taxa de letalidade.
--- Resposta: simples com nevoeiro / neblina. conta com 13,95% de taxa de letalidade.
---- CRIA UMA VIEW PARA ANALISE DE LIFT POR BR E ACIDENTES NOTURNOS
CREATE OR REPLACE VIEW consultas_analiticas.vw_top10_brs_mortes_noturnas AS
WITH
    historico AS (
        SELECT
            *
        FROM
            limpeza_dados.vw_2023_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
    ),
    taxa_fatalidade_global AS (
        SELECT
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) AS taxa_fatalidade
        FROM
            historico
    )
SELECT
    br AS "BR",
    count(id) AS "Total de Acidentes Noturnos",
    count(TRY_CAST (mortos AS INTEGER)) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 1
    ) AS "Total de Acidentes Fatais Noturnos",
    sum(TRY_CAST (mortos AS INTEGER)) AS "Total de Mortos",
    replace(
        printf(
            '%.2f%%',
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) * 100.0
        ),
        '.',
        ','
    ) AS "Taxa de Acidentes Fatais",
    round(
        (
            count(TRY_CAST (mortos AS INTEGER)) FILTER(
                WHERE
                    TRY_CAST (mortos AS INTEGER) >= 1
            ) / count(id)
        ) / taxa_fatalidade,
        2
    ) AS "Lift"
FROM
    historico,
    taxa_fatalidade_global
WHERE
    lower(trim(fase_dia)) = 'plena noite'
    AND br IS NOT NULL
GROUP BY
    br,
    taxa_fatalidade
HAVING
    count(id) > 0
ORDER BY
    "Total de Mortos" DESC,
    "Total de Acidentes Fatais Noturnos" DESC,
    "Total de Acidentes Noturnos" DESC;


SELECT
    *
FROM
    consultas_analiticas.vw_top10_brs_mortes_noturnas
ORDER BY
    "Total de Mortos" DESC,
    "Total de Acidentes Fatais Noturnos" DESC,
    "Total de Acidentes Noturnos" DESC
LIMIT
    10;


----- CRIA UMA VIEW PARA ANALISE DE LIFT POR PERIODO FESTIVO
CREATE OR REPLACE VIEW consultas_analiticas.vw_efeito_periodos_festivos AS
WITH
    historico AS (
        SELECT
            *
        FROM
            limpeza_dados.vw_2023_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
    ),
    taxa_fatalidade_global AS (
        SELECT
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) AS taxa_fatalidade
        FROM
            historico
    ),
    classificacao_periodo AS (
        SELECT
            *,
            CASE
                WHEN UPPER(TRIM(data_comemorativa)) = 'NORMAL' THEN 'Normal'
                ELSE 'Feriado'
            END AS tipo_periodo
        FROM
            historico
    )
SELECT
    ano_acidente AS "Ano",
    tipo_periodo AS "Tipo de Período",
    count(id) AS "Total de Acidentes",
    count(TRY_CAST (mortos AS INTEGER)) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 1
    ) AS "Total de Acidentes Fatais",
    sum(TRY_CAST (mortos AS INTEGER)) AS "Total de Mortos",
    replace(
        printf(
            '%.2f%%',
            (
                count(TRY_CAST (mortos AS INTEGER)) FILTER(
                    WHERE
                        TRY_CAST (mortos AS INTEGER) >= 1
                ) / count(id)
            ) * 100.0
        ),
        '.',
        ','
    ) AS "Taxa de Acidentes Fatais",
    round(
        (
            count(TRY_CAST (mortos AS INTEGER)) FILTER(
                WHERE
                    TRY_CAST (mortos AS INTEGER) >= 1
            ) / count(id)
        ) / taxa_fatalidade,
        2
    ) AS "Lift"
FROM
    classificacao_periodo
    CROSS JOIN taxa_fatalidade_global
GROUP BY
    ano_acidente,
    tipo_periodo,
    taxa_fatalidade
ORDER BY
    ano_acidente ASC,
    tipo_periodo ASC;


SELECT
    *
FROM
    consultas_analiticas.vw_efeito_periodos_festivos
ORDER BY
    "Ano" ASC,
    "Tipo de Período" ASC;


--- Pergunta: Há um aumento expressivo no volume e na gravidade?
--- Resposta: não há um volume expressivo, porém a taxa de letalidade é maior nos feriados.
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--NIVEL 4
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---- CRIA UMA VIEW POR UF COM ACIDENTES DE ALTISSIMA GRAVIDADE
CREATE OR REPLACE VIEW consultas_analiticas.vw_altissima_gravidade_por_uf AS
WITH
    historico AS (
        SELECT
            *
        FROM
            limpeza_dados.vw_2023_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
    ),
    acidentes_altissima_gravidade AS (
        SELECT
            *
        FROM
            historico
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 3
    )
SELECT
    uf AS "UF",
    count(TRY_CAST (mortos AS INTEGER)) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 1
    ) AS "Total de Acidentes Fatais",
    sum(TRY_CAST (mortos AS INTEGER)) AS "Total de Mortos",
FROM
    acidentes_altissima_gravidade
GROUP BY
    uf
ORDER BY
    "Total de Acidentes Fatais" DESC,
    "Total de Mortos" DESC;


SELECT
    *
FROM
    consultas_analiticas.vw_altissima_gravidade_por_uf;


--- Pergunta: Qual é o estado (uf) que lidera esse triste ranking absoluto? E, nesse grupo restrito, qual é a principal causa relatada?
--- Resposta: o estado que lidera é MG com 75 acidentes de altissima gravidade. 
---- CRIA UMA VIEW PARA ANALIS POR CAUSA DE ACIDENTE COM ALTISSIMA GRAVIDADE
CREATE OR REPLACE VIEW consultas_analiticas.vw_altissima_gravidade_por_causa AS
WITH
    historico AS (
        SELECT
            *
        FROM
            limpeza_dados.vw_2023_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
    ),
    acidentes_altissima_gravidade AS (
        SELECT
            *
        FROM
            historico
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 3
    )
SELECT
    causa_acidente AS "Causa do Acidente",
    count(TRY_CAST (mortos AS INTEGER)) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 1
    ) AS "Total de Acidentes Fatais",
    sum(TRY_CAST (mortos AS INTEGER)) AS "Total de Mortos"
FROM
    acidentes_altissima_gravidade
GROUP BY
    causa_acidente
ORDER BY
    "Total de Acidentes Fatais" DESC,
    "Total de Mortos" DESC;


SELECT
    *
FROM
    consultas_analiticas.vw_altissima_gravidade_por_causa;


--- Resposta: A principal causa é transitar na contramão
---CRIA UMA VIEW PARA ANALISE POR MUNICIPIO COM MAIS ACIDENTES FATAIS NO ESTADO DE PERNAMBUCO
CREATE OR REPLACE VIEW consultas_analiticas.vw_top5_municipios_fatais_pe AS
WITH
    historico_pe AS (
        SELECT
            *
        FROM
            limpeza_dados.vw_2024_acidentes_enriquecida
        WHERE
            UPPER(TRIM(uf)) = 'PE'
        UNION ALL
        SELECT
            *
        FROM
            limpeza_dados.vw_2025_acidentes_enriquecida
        WHERE
            UPPER(TRIM(uf)) = 'PE'
    )
SELECT
    municipio AS "Município",
    count(id) AS "Total de Acidentes",
    count(TRY_CAST (mortos AS INTEGER)) FILTER(
        WHERE
            TRY_CAST (mortos AS INTEGER) >= 1
    ) AS "Total de Acidentes Fatais",
    sum(TRY_CAST (mortos AS INTEGER)) AS "Total de Mortos"
FROM
    historico_pe
WHERE
    municipio IS NOT NULL
    AND TRIM(municipio) <> ''
GROUP BY
    municipio
ORDER BY
    "Total de Acidentes Fatais" DESC,
    "Total de Mortos" DESC,
    "Total de Acidentes" DESC;


SELECT
    *
FROM
    consultas_analiticas.vw_top5_municipios_fatais_pe
LIMIT
    5;

SELECT * FROM limpeza_dados.vw_2023_acidentes_enriquecida;

SELECT * FROM prf_2025.acidentes_prf_2025;

