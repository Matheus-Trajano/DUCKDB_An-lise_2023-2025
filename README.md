# Análise de Acidentes Rodoviários da PRF com DuckDB

Projeto de análise de dados dos acidentes registrados pela Polícia Rodoviária Federal (PRF) nos anos de 2023, 2024 e 2025, utilizando DuckDB como motor de banco de dados analítico e SQL puro para ingestão, limpeza, modelagem e geração de indicadores.

## Sumário

- [Visão geral](#visão-geral)
- [Fonte dos dados](#fonte-dos-dados)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Requisitos](#requisitos)
- [Como reproduzir a análise](#como-reproduzir-a-análise)
- [Pipeline de dados](#pipeline-de-dados)
- [Principais consultas analíticas](#principais-consultas-analíticas)
- [Resultados](#resultados)
- [Observações](#observações)

## Visão geral

O projeto consolida três anos de dados abertos de acidentes de trânsito em rodovias federais e constrói, em cima deles, um conjunto de tabelas e views que permitem responder perguntas como:

- Qual a evolução anual do número de acidentes e da taxa de letalidade.
- Como sazonalidade, luminosidade, condição climática e traçado da via se relacionam com a gravidade dos acidentes.
- Se feriados, datas comemorativas e finais de semana têm impacto estatístico sobre a frequência e a letalidade dos acidentes.
- Quais BRs, UFs e municípios concentram os acidentes mais graves.

Toda a lógica de transformação e análise está em SQL, organizada em bancos DuckDB separados por responsabilidade (dados brutos por ano, calendário de feriados, dados limpos e consultas analíticas).

## Fonte dos dados

Os dados brutos (`data/raw`) são os microdados públicos de acidentes da PRF, disponibilizados anualmente pelo órgão, um CSV por ano (2023, 2024 e 2025), no formato `;`-delimitado e encoding `latin-1`:

| Arquivo | Ano | Registros | Colunas |
|---|---|---|---|
| `acidentes2023.csv` | 2023 | 67.766 | 30 |
| `acidentes2024.csv` | 2024 | 73.156 | 30 |
| `acidentes2025.csv` | 2025 | 72.529 | 30 |

Cada linha representa um acidente e traz, entre outras, as colunas `id`, `data_inversa`, `dia_semana`, `horario`, `uf`, `br`, `km`, `municipio`, `causa_acidente`, `tipo_acidente`, `classificacao_acidente`, `fase_dia`, `sentido_via`, `condicao_metereologica`, `tipo_pista`, `tracado_via`, `uso_solo`, `pessoas`, `mortos`, `feridos_leves`, `feridos_graves`, `ilesos`, `ignorados`, `feridos`, `veiculos`, `latitude`, `longitude`, `regional`, `delegacia` e `uop`.

As tabelas de feriados e datas comemorativas (`sql/feriados`) foram compiladas manualmente para os anos de 2023 a 2025 e inseridas via `INSERT INTO` em scripts SQL próprios, um arquivo por ano e por tipo:

| Arquivo | Registros |
|---|---|
| `2023_nacional.sql` | 9 feriados nacionais |
| `2023_comemorativa.sql` | 21 datas comemorativas |
| `2024_nacional.sql` | 10 feriados nacionais |
| `2024_comemorativa.sql` | 21 datas comemorativas |
| `2025_nacional.sql` | 10 feriados nacionais |
| `2025_comemorativa.sql` | 21 datas comemorativas |

## Estrutura do repositório

```
prf-acidentes-duckdb/
├── README.md
├── .gitignore
├── data/
│   └── raw/
│       ├── acidentes2023.csv                 # 67.766 acidentes de 2023 (30 colunas)
│       ├── acidentes2024.csv                 # 73.156 acidentes de 2024 (30 colunas)
│       └── acidentes2025.csv                 # 72.529 acidentes de 2025 (30 colunas)
├── db/
│   ├── prf_2023.duckdb                  # 3,3 MB — CSV de 2023 carregado como tabela acidentes_prf_2023
│   ├── prf_2024.duckdb                  # 8,6 MB — CSV de 2024 carregado como tabela acidentes_prf_2024
│   ├── prf_2025.duckdb                  # 18 MB  — CSV de 2025 carregado como tabela acidentes_prf_2025
│   ├── feriados.duckdb                  # 2,1 MB — tabelas feriado e comemorativa, 2023-2025 (60 e 63 registros)
│   ├── limpeza_dados.duckdb             # 268 KB — views vw_2023/2024/2025_acidentes_enriquecida (sem colunas administrativas)
│   ├── acidentes_prf_historico.duckdb   # 780 KB — base histórica unificada 2023-2025 e view vw_historico_por_dia/uf/br/etc.
│   ├── consultas_analiticas.duckdb      # 268 KB — as 13 views analíticas (níveis 1 a 4, ver seção abaixo)
│   ├── nacional_2024.duckdb             # 12 KB  — base auxiliar de apoio à análise de 2024
│   └── _revisar/                        # 2 arquivos de 12 KB cada, nomes duplicados/ambíguos, pendentes de revisão
│       ├── feriado.duckdb                    # possível versão antiga/duplicada de feriados.duckdb
│       └── feriados.comemorativa_2024duckdb  # nome sem extensão correta (".duckdb" colado a "2024")
├── sql/
│   ├── 01_ingestao_historico_e_views.sql  # 1.920 linhas: carga dos 3 CSVs, base histórica e views por dia/UF/BR/causa/tipo/etc.
│   └── feriados/
│       ├── 2023_nacional.sql        # 9 feriados nacionais de 2023
│       ├── 2023_comemorativa.sql    # 21 datas comemorativas de 2023
│       ├── 2024_nacional.sql        # 10 feriados nacionais de 2024
│       ├── 2024_comemorativa.sql    # 21 datas comemorativas de 2024
│       ├── 2025_nacional.sql        # 10 feriados nacionais de 2025
│       └── 2025_comemorativa.sql    # 21 datas comemorativas de 2025
└── resultados/
    └── bivariada_tipo_acidente.csv  # export da view vw_lift_tipo_acidente: 17 tipos de acidente x letalidade x lift
```

## Requisitos

- [DuckDB](https://duckdb.org/docs/installation/) (CLI ou extensão para o editor de preferência).
- Extensão DuckDB para VS Code, caso deseje navegar pelos bancos por interface gráfica (opcional).

O executável do DuckDB não está incluído neste repositório. Baixe a versão adequada ao seu sistema operacional diretamente no site oficial.

## Como reproduzir a análise

1. Clone o repositório e instale o DuckDB.
2. Abra o DuckDB CLI a partir da raiz do projeto.
3. Anexe (`ATTACH`) os bancos necessários, por exemplo:

   ```sql
   ATTACH 'db/prf_2023.duckdb' AS prf_2023;
   ATTACH 'db/prf_2024.duckdb' AS prf_2024;
   ATTACH 'db/prf_2025.duckdb' AS prf_2025;
   ATTACH 'db/feriados.duckdb' AS feriados;
   ATTACH 'db/limpeza_dados.duckdb' AS limpeza_dados;
   ATTACH 'db/acidentes_prf_historico.duckdb' AS acidentes_prf_historico;
   ATTACH 'db/consultas_analiticas.duckdb' AS consultas_analiticas;
   ```

4. Execute os scripts em `sql/feriados` para popular o calendário de feriados e datas comemorativas (necessário apenas na primeira configuração do ambiente).
5. Execute `sql/01_ingestao_historico_e_views.sql` para carregar os CSVs de `data/raw`, montar a base histórica e criar as views por dia, UF, BR, causa, tipo, classificação e fase do dia.
6. Consulte as views criadas nos bancos `acidentes_prf_historico` e `consultas_analiticas` conforme a pergunta de análise desejada.

## Pipeline de dados

O script principal (`sql/01_ingestao_historico_e_views.sql`) segue, em linhas gerais, as seguintes etapas:

1. **Ingestão**: leitura dos CSVs anuais com `read_csv_auto`, tratando encoding `latin-1` e delimitador `;`.
2. **Consolidação histórica**: união dos três anos em uma base única, com colunas derivadas (`eh_fim_semana`, `eh_feriado`) e métricas agregadas por ano (total de acidentes, mortos, feridos, taxa de acidentes fatais, comparação entre feriados/finais de semana e dias normais).
3. **Views dimensionais**: criação de views agregadas por dia da semana, UF, BR, causa do acidente, tipo de acidente, classificação, fase do dia, sentido da via, entre outras.
4. **Limpeza e enriquecimento**: views que removem colunas administrativas (latitude, longitude, regional, delegacia, uop) e padronizam os dados por ano.
5. **Consultas analíticas**: um conjunto de views organizadas em quatro níveis de complexidade crescente (`NIVEL 1` a `NIVEL 4`), cobrindo desde tendência anual de severidade até indicadores como lift por tipo de acidente, letalidade por traçado da via, condição de pista e clima, top 10 BRs com mais mortes noturnas e efeito de períodos festivos.

## Principais consultas analíticas

Todas definidas em `sql/01_ingestao_historico_e_views.sql`, dentro do banco `consultas_analiticas`:

- `vw_tendencia_anual_severidade` – evolução anual de acidentes fatais e taxa de letalidade.
- `vw_sazonalidade_mensal` – distribuição mensal dos acidentes.
- `vw_influencia_luminosidade` – relação entre fase do dia e gravidade.
- `vw_impacto_finais_semana` – comparação entre dias úteis e finais de semana.
- `vw_lift_tipo_acidente` – lift de letalidade por tipo de acidente.
- `vw_top5_causas_letalidade` – principais causas por taxa de letalidade.
- `vw_letalidade_tracado_via` – letalidade por traçado da via.
- `vw_pista_clima_letalidade` – letalidade cruzando tipo de pista e condição climática.
- `vw_top10_brs_mortes_noturnas` – BRs com mais mortes em período noturno.
- `vw_efeito_periodos_festivos` – comparação entre períodos festivos e dias normais.
- `vw_altissima_gravidade_por_uf` e `vw_altissima_gravidade_por_causa` – concentração de acidentes de altíssima gravidade.
- `vw_top5_municipios_fatais_pe` – municípios de Pernambuco com mais acidentes fatais.

## Resultados

A pasta `resultados/` contém exports de análises específicas em CSV, prontos para uso em relatórios ou visualizações externas.

`bivariada_tipo_acidente.csv` traz a análise bivariada de tipo de acidente x letalidade (17 tipos, base 2023-2025), com total de acidentes, total de acidentes fatais, total de mortos, taxa de acidentes fatais e lift em relação à taxa média. Os três tipos mais letais são:

| Tipo de acidente | Total de acidentes | Taxa de acidentes fatais | Lift |
|---|---|---|---|
| Atropelamento de Pedestre | 3.057 | 29,51% | 4,11 |
| Colisão frontal | 4.739 | 29,46% | 4,10 |
| Colisão lateral sentido oposto | 2.152 | 9,85% | 1,37 |

## Observações

- A pasta `db/_revisar/` contém dois arquivos (`feriado.duckdb` e `feriados.comemorativa_2024duckdb`) cujos nomes sugerem duplicidade ou erro de digitação em relação a `feriados.duckdb`. Eles foram mantidos separados para revisão antes de decidir se devem ser removidos do projeto.
- Os bancos `.duckdb` e os CSVs de `data/raw` são artefatos relativamente grandes para versionamento em Git. Caso prefira não versioná-los, use o `.gitignore` incluído (as linhas relevantes já estão preparadas, apenas descomente) e disponibilize os dados brutos por outro meio (ex.: link para a fonte oficial, Git LFS ou release do repositório).
- O arquivo de configuração original do VS Code (`.vscode/settings.json`) referenciava caminhos absolutos da máquina local e não foi incluído; ao abrir o projeto, configure novamente os aliases dos bancos DuckDB na extensão do seu editor, se desejar.
