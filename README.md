# Análise de Acidentes Rodoviários da PRF com DuckDB

Projeto de análise dos acidentes registrados pela Polícia Rodoviária Federal (PRF) em 2023, 2024 e 2025, usando DuckDB como banco analítico e SQL puro para ingestão, enriquecimento, modelagem e geração de indicadores.

## Sumário

- [Visão geral](#visão-geral)
- [Fonte dos dados](#fonte-dos-dados)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Requisitos](#requisitos)
- [Como reproduzir a análise](#como-reproduzir-a-análise)
- [Pipeline de dados](#pipeline-de-dados)
- [Bancos e objetos criados](#bancos-e-objetos-criados)
- [Consultas analíticas](#consultas-analíticas)
- [Resultados](#resultados)
- [Observações e limitações](#observações-e-limitações)

## Visão geral

O projeto consolida três anos de dados abertos de acidentes em rodovias federais e constrói sobre eles tabelas e views que respondem perguntas como:

- A proporção de acidentes fatais está aumentando, diminuindo ou estável ao longo dos anos?
- Como sazonalidade, luminosidade, condição climática, tipo de pista e traçado da via se relacionam com a gravidade?
- Finais de semana, feriados e datas comemorativas alteram a frequência e a letalidade dos acidentes?
- Quais tipos de acidente, causas, BRs, UFs e municípios concentram os casos mais graves?

Toda a lógica está em SQL, organizada em bancos DuckDB separados por responsabilidade: dados brutos por ano, calendário de feriados, dados limpos, base histórica e consultas analíticas.

## Fonte dos dados

Os dados brutos são os microdados públicos de acidentes da PRF, um CSV por ano, delimitado por `;` e com encoding `latin-1`:

| Arquivo | Ano | Registros | Colunas |
|---|---|---|---|
| `acidentes2023.csv` | 2023 | 67.766 | 30 |
| `acidentes2024.csv` | 2024 | 73.156 | 30 |
| `acidentes2025.csv` | 2025 | 72.529 | 30 |

Colunas originais: `id`, `data_inversa`, `dia_semana`, `horario`, `uf`, `br`, `km`, `municipio`, `causa_acidente`, `tipo_acidente`, `classificacao_acidente`, `fase_dia`, `sentido_via`, `condicao_metereologica`, `tipo_pista`, `tracado_via`, `uso_solo`, `pessoas`, `mortos`, `feridos_leves`, `feridos_graves`, `ilesos`, `ignorados`, `feridos`, `veiculos`, `latitude`, `longitude`, `regional`, `delegacia`, `uop`.

Durante o tratamento, cada tabela anual recebe colunas derivadas: `acidente_fatal`, `ano_acidente`, `mes_acidente`, `fim_de_semana`, `data_comemorativa` e `descricao_data_comemorativa` (ver [Pipeline de dados](#pipeline-de-dados)).

O calendário de feriados e datas comemorativas foi compilado manualmente e inserido via `INSERT INTO`, um script por ano e por tipo:

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
.
├── README.md
├── .gitignore
├── data/
│   └── raw/
│       ├── acidentes2023.csv
│       ├── acidentes2024.csv
│       └── acidentes2025.csv
├── db/
│   ├── prf_2023.duckdb                  # tabela acidentes_prf_2023 (com colunas derivadas)
│   ├── prf_2024.duckdb                  # tabela acidentes_prf_2024
│   ├── prf_2025.duckdb                  # tabela acidentes_prf_2025
│   ├── feriados.duckdb                  # tabelas nacional_/comemorativa_ 2023-2025 e consolidadas (feriado, comemorativa)
│   ├── limpeza_dados.duckdb             # views vw_2023/2024/2025_acidentes_enriquecida
│   ├── acidentes_prf_historico.duckdb   # resumo_geral_por_ano + views vw_historico_por_*
│   ├── consultas_analiticas.duckdb      # 13 views analíticas (níveis 1 a 4)
│   ├── nacional_2024.duckdb             # base auxiliar de apoio (2024)
│   └── _revisar/                        # arquivos duplicados/ambíguos, pendentes de revisão
├── sql/
│   ├── 01_ingestao_historico_e_views.sql
│   └── feriados/
│       ├── 2023_nacional.sql
│       ├── 2023_comemorativa.sql
│       ├── 2024_nacional.sql
│       ├── 2024_comemorativa.sql
│       ├── 2025_nacional.sql
│       └── 2025_comemorativa.sql
└── resultados/
    └── bivariada_tipo_acidente.csv      # export da view vw_lift_tipo_acidente
```

## Requisitos

- [DuckDB](https://duckdb.org/docs/installation/) (CLI ou extensão para o editor de preferência).
- Extensão DuckDB para VS Code (opcional), para navegar pelos bancos em interface gráfica.

O executável do DuckDB não faz parte do repositório; baixe a versão do seu sistema operacional no site oficial.

## Como reproduzir a análise

1. Clone o repositório e instale o DuckDB.
2. Abra o DuckDB CLI a partir da raiz do projeto.
3. Anexe os bancos:

   ```sql
   ATTACH 'db/prf_2023.duckdb'                AS prf_2023;
   ATTACH 'db/prf_2024.duckdb'                AS prf_2024;
   ATTACH 'db/prf_2025.duckdb'                AS prf_2025;
   ATTACH 'db/feriados.duckdb'                AS feriados;
   ATTACH 'db/limpeza_dados.duckdb'           AS limpeza_dados;
   ATTACH 'db/acidentes_prf_historico.duckdb' AS acidentes_prf_historico;
   ATTACH 'db/consultas_analiticas.duckdb'    AS consultas_analiticas;
   ```

4. **Consultar apenas (caminho rápido):** os bancos em `db/` já contêm tudo processado. Basta consultar as views, por exemplo:

   ```sql
   SELECT * FROM consultas_analiticas.vw_tendencia_anual_severidade;
   ```

5. **Reconstruir do zero (opcional):**
   - Os scripts de `sql/feriados/` apenas fazem `INSERT` e pressupõem que as tabelas `nacional_AAAA` e `comemorativa_AAAA` (colunas `data`, `nome`, `tipo`, `descricao`) já existam em `feriados.duckdb`.
   - `sql/01_ingestao_historico_e_views.sql` é um roteiro de trabalho com muitas etapas e consultas exploratórias. Execute-o **por blocos**, na ordem em que aparece, e não de uma só vez. Ele lê o CSV com caminho relativo, então o DuckDB deve ser aberto na raiz do projeto.

## Pipeline de dados

O roteiro `sql/01_ingestao_historico_e_views.sql` (cerca de 1.900 linhas) segue estas etapas:

1. **Ingestão**: leitura do CSV anual com `read_csv_auto` (`delim = ';'`, `header = true`, `encoding = 'latin-1'`, `sample_size = -1`) e criação da tabela `acidentes_prf_AAAA`.
2. **Colunas derivadas** em cada tabela anual:
   - `acidente_fatal` (1 quando `mortos >= 1`);
   - `ano_acidente` e `mes_acidente`, extraídos de `data_inversa`;
   - `fim_de_semana` (1 para sexta-feira, sábado e domingo, com base em `dia_semana`);
   - `data_comemorativa` e `descricao_data_comemorativa`, preenchidas por cruzamento de `data_inversa` com as tabelas de feriados (padrão `'Normal'` nos dias sem data especial; quando há mais de uma ocorrência na mesma data, os nomes são concatenados com ` / `).
3. **Resumo histórico**: tabela `acidentes_prf_historico.resumo_geral_por_ano`, com total de acidentes, mortos, pessoas, feridos, acidentes fatais, taxa de acidentes fatais e comparação entre feriados/fins de semana e dias normais.
4. **Views históricas** (`vw_historico_por_*`) unindo os três anos por dia da semana, UF, BR, causa, tipo, classificação, fase do dia, tipo de pista, sentido da via e condição meteorológica. A view por BR é a mais detalhada: além dos totais, separa acidentes e acidentes fatais em fim de semana × dia útil e em data comemorativa × dia normal.
5. **Limpeza**: views `limpeza_dados.vw_AAAA_acidentes_enriquecida`, que removem as colunas administrativas (`latitude`, `longitude`, `regional`, `delegacia`, `uop`) via `SELECT * EXCLUDE (...)`.
6. **Consultas analíticas**: 13 views em `consultas_analiticas`, em quatro níveis de complexidade, construídas sobre as views de limpeza.

## Bancos e objetos criados

| Banco | Conteúdo |
|---|---|
| `prf_2023`, `prf_2024`, `prf_2025` | Tabelas `acidentes_prf_AAAA` com as colunas originais e as derivadas |
| `feriados` | Tabelas `nacional_AAAA` e `comemorativa_AAAA`, além das consolidadas `feriado` e `comemorativa` |
| `limpeza_dados` | Views `vw_2023/2024/2025_acidentes_enriquecida` |
| `acidentes_prf_historico` | Tabela `resumo_geral_por_ano` e views `vw_historico_por_dia`, `_uf`, `_br`, `_causa`, `_tipo`, `_classificacao`, `_fase_dia`, `_tipo_pista`, `_sentido_via`, `_condicao_meteorologica` |
| `consultas_analiticas` | As 13 views analíticas descritas abaixo |

## Consultas analíticas

Definidas em `sql/01_ingestao_historico_e_views.sql`, no banco `consultas_analiticas`.

**Nível 1: tendência e fatores gerais**

- `vw_tendencia_anual_severidade`: evolução anual de acidentes fatais e da taxa de letalidade.
- `vw_sazonalidade_mensal`: distribuição e letalidade por mês, somando os três anos.
- `vw_influencia_luminosidade`: relação entre fase do dia e gravidade.
- `vw_impacto_finais_semana`: comparação de letalidade entre dias úteis e fins de semana.

**Nível 2: lift e comparações por categoria**

- `vw_lift_tipo_acidente`: lift de letalidade por tipo de acidente (somente tipos com ao menos 100 registros).
- `vw_top5_causas_letalidade`: 5 causas com maior lift.
- `vw_letalidade_tracado_via`: letalidade por traçado da via (reta × curva etc.).

**Nível 3: cruzamentos**

- `vw_pista_clima_letalidade`: letalidade por combinação de tipo de pista e condição meteorológica.
- `vw_top10_brs_mortes_noturnas`: BRs com mais mortes em período noturno.
- `vw_efeito_periodos_festivos`: períodos festivos × dias normais.

**Nível 4: altíssima gravidade**

Considera acidentes com 3 ou mais mortos.

- `vw_altissima_gravidade_por_uf`: concentração por UF.
- `vw_altissima_gravidade_por_causa`: concentração por causa.
- `vw_top5_municipios_fatais_pe`: municípios de Pernambuco com mais acidentes fatais (considera apenas 2024 e 2025).

## Resultados

Conclusões registradas como comentários no próprio roteiro SQL (base 2023-2025):

- **Tendência anual:** o número bruto de acidentes fatais sobe de 2023 para 2024 e cai pouco em 2025, mas a proporção de acidentes fatais aumenta em todos os anos.
- **Sazonalidade:** maio tem a maior taxa de letalidade (7,71%), fora dos períodos tradicionais de férias.
- **Luminosidade:** a taxa de acidentes fatais é de 5,02% em pleno dia e 10,09% em plena noite, cerca do dobro.
- **Fim de semana:** a taxa é de 6,86% em dias úteis e 8,72% em fins de semana, um aumento relativo de cerca de 27%.
- **Traçado da via:** curvas são mais letais (7,67%) que retas (7,13%), embora as retas concentrem muito mais acidentes.
- **Pista e clima:** a combinação mais letal é pista simples com nevoeiro/neblina (13,95%).
- **Períodos festivos:** o volume não sobe de forma expressiva, mas a taxa de letalidade é maior nos feriados.
- **Altíssima gravidade:** MG lidera em número de acidentes com 3 ou mais mortos (75); a principal causa é transitar na contramão.

A pasta `resultados/` guarda exports em CSV prontos para relatórios ou visualizações. `bivariada_tipo_acidente.csv` traz a análise bivariada de tipo de acidente × letalidade (17 tipos, base 2023-2025), com total de acidentes, acidentes fatais, mortos, taxa de acidentes fatais e lift em relação à taxa média. Os três tipos mais letais:

| Tipo de acidente | Total de acidentes | Taxa de acidentes fatais | Lift |
|---|---|---|---|
| Atropelamento de Pedestre | 3.057 | 29,51% | 4,11 |
| Colisão frontal | 4.739 | 29,46% | 4,10 |
| Colisão lateral sentido oposto | 2.152 | 9,85% | 1,37 |

## Observações e limitações

- **Definição de fim de semana:** o projeto classifica sexta-feira, sábado e domingo como fim de semana. Isso afeta `vw_impacto_finais_semana` e os campos de fim de semana nas views históricas.
- **Municípios de PE:** `vw_top5_municipios_fatais_pe` usa somente 2024 e 2025.
- **Roteiro SQL:** o arquivo `01_ingestao_historico_e_views.sql` preserva o histórico de trabalho (consultas exploratórias e ajustes pontuais). Por isso deve ser executado por blocos, como descrito em [Como reproduzir a análise](#como-reproduzir-a-análise).
- **Pasta `db/_revisar/`:** contém `feriado.duckdb` e `feriados.comemorativa_2024duckdb`, cujos nomes sugerem duplicidade ou erro de digitação em relação a `feriados.duckdb`. Foram mantidos para revisão antes de eventual remoção.
- **Tamanho dos arquivos:** os bancos `.duckdb` e os CSVs são relativamente grandes para o Git. Para não versionar, descomente as linhas correspondentes no `.gitignore` e disponibilize os dados por outro meio (link da fonte oficial, Git LFS ou release).
- **Configuração do editor:** o `.vscode/settings.json` contém caminhos absolutos da máquina local e não deve ser versionado; ao abrir o projeto, configure os aliases dos bancos na extensão DuckDB.
