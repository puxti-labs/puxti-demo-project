# Puxti Demo Project — Clariva SaaS

```
git clone https://github.com/puxti-labs/puxti-demo-project
```

## What this is

A realistic dbt project for a fictional SaaS company (Clariva), built to demonstrate
Puxti's active change propagation. Clariva sells B2B software subscriptions and
ingests data from Salesforce CRM and a Postgres app database.

## The scenario

Clariva's Salesforce instance has been restructured. Opportunities now contain multiple
order lines instead of a single `amount` field. This is a breaking cardinality change
that silently corrupts revenue and pipeline models — they still sum `amount` but now
double-count because each opportunity has multiple rows.

`dim_accounts` is unaffected. Puxti shows this too — it only flags what actually breaks.

## What you'll see

**Step 1 — Scan the project**
```
puxti scan --dbt-project-dir .
```
Puxti maps the semantic graph: models, columns, relationships, and business definitions.

**Step 1b — Link upstream Airflow tasks (if using the companion airflow-demo-project)**
```
puxti link --from task.airflow.salesforce_sync.extract_opportunities --to source.clariva.raw_opportunities --description "Extracts Salesforce opportunities. amount is a roll-up of OpportunityLineItem.TotalPrice post Q1 2024 migration."
```
Creates a cross-system FEEDS edge so puxti can trace changes from the Airflow task all the way through to dbt marts.

**Step 2 — Capture the change**
```
puxti capture --entity source.clariva.raw_opportunities.amount --before "Manually entered deal value" --after "Salesforce roll-up: SUM(OpportunityLineItem.TotalPrice)" --description "Q1 2024 migration to line-item pricing changed how Amount is populated"
```
(`--repo` is optional when set in `.puxti.yml` — see Workspace config below)

Puxti captures what the change means, not just what changed structurally.

**Step 3 — Review the impact**

Puxti identifies `stg_opportunities`, `fct_revenue`, and `fct_pipeline` as affected downstream,
and `task.airflow.salesforce_sync.extract_opportunities` as the upstream producer. `dim_accounts`
is unaffected — Puxti shows this explicitly so reviewers aren't chasing false positives.

**Step 4 — Review the generated PRs**

When `.puxti.yml` includes `connectors.airflow`, Puxti opens two coordinated PRs:
- **dbt PR** (`puxti-labs/puxti-demo-project`) — SQL diffs for affected models
- **Airflow PR** (`puxti-labs/airflow-demo-project`) — docstring annotation on `extract_opportunities`

Each PR references the other with a suggested merge order (Airflow annotation first, then dbt).
Nothing is applied without your review.

## Requirements

- Python 3.12+
- `pip install puxti`
- dbt Core: `pip install dbt-duckdb`
- DuckDB — no warehouse credentials needed, runs fully locally

## Running the project locally

```
pip install dbt-duckdb
cp profiles.yml.example ~/.dbt/profiles.yml
dbt seed
dbt run
dbt test
```

## Workspace config (`.puxti.yml`)

If you're running both this dbt project and the companion [airflow-demo-project](https://github.com/puxti-labs/airflow-demo-project) together, place a `.puxti.yml` one level above both clones:

```yaml
version: 1

connectors:
  dbt:
    project_dir: ./puxti-demo-project
    repo: puxti-labs/puxti-demo-project
    base_branch: main

  airflow:
    project_dir: ./airflow-demo-project
    repo: puxti-labs/airflow-demo-project
    dags_dir: dags/
    base_branch: main
```

With this in place, `--repo` and `--dbt-project-dir` resolve automatically from any subdirectory.

## Try it on your own project

https://getpuxti.com/docs

## License

MIT — Okolico Ventures UG, 2026
