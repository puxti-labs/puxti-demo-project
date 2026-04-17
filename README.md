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

**Step 2 — Capture the change**
```
puxti capture --entity opportunity --before "Single amount field per opportunity" --after "Multiple order lines per opportunity — cardinality change" --description "Salesforce restructured opportunities to order line items" --dbt-project-dir . --repo puxti-labs/puxti-demo-project
```
Puxti captures what the change means, not just what changed structurally.

**Step 3 — Review the impact**

Puxti identifies `fct_revenue` and `fct_pipeline` as broken. `dim_accounts` is
unaffected — Puxti shows this explicitly so reviewers aren't chasing false positives.

**Step 4 — Review the generated PR**

Puxti opens a PR with suggested model updates and updated yml descriptions flagging
the assumption change. Nothing is applied without your review.

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

## Try it on your own project

https://getpuxti.com/docs

## License

MIT — Okolico Ventures UG, 2026
