# Puxti Demo Project — Clariva SaaS

```
git clone https://github.com/puxti-labs/puxti-demo-project
```

## What this is

A realistic dbt project for a fictional SaaS company (Clariva), built to demonstrate
Puxti's active change propagation. Clariva sells B2B software subscriptions and
ingests data from Salesforce CRM and a Postgres app database.

The companion [airflow-demo-project](https://github.com/puxti-labs/airflow-demo-project)
contains the upstream Airflow DAGs that feed this project's dbt sources. You can run
this demo standalone or with both repos together for the full cross-system scenario.

## The scenario

Clariva's Salesforce instance has been restructured. Opportunities now contain multiple
order lines instead of a single `amount` field. This is a breaking cardinality change
that silently corrupts revenue and pipeline models — they still sum `amount` but now
double-count because each opportunity has multiple rows.

`dim_accounts` is unaffected. Puxti shows this too — it only flags what actually breaks.

## Requirements

- Python 3.12 or 3.13 (dbt-duckdb does not support Python 3.14 yet)
- dbt Core: `pip install dbt-duckdb`
- `ANTHROPIC_API_KEY` — [get one at console.anthropic.com](https://console.anthropic.com)
- `GITHUB_TOKEN` — personal access token with `repo` scope, needed only if you want Puxti to open real PRs

## Setup

**1. Install Puxti and dbt**

```bash
pip install puxti==0.7.0
pip install dbt-duckdb
```

**2. Set environment variables**

```bash
export ANTHROPIC_API_KEY=sk-ant-...
export GITHUB_TOKEN=ghp_...           # needed only for --repo / PR creation
```

Or copy `.env.example` to `.env` and fill in the values — Puxti reads it automatically.

**3. Run the dbt project**

```bash
cp profiles.yml.example ~/.dbt/profiles.yml
dbt seed
dbt run
dbt test
```

**4. Verify Puxti is configured**

```bash
puxti config    # shows resolved env vars and .puxti.yml location
puxti health    # checks Knowledge Graph, Anthropic key, dbt manifest, GitHub token
```

---

## The walkthrough

**Step 1 — Scan the project**

```bash
puxti scan --dbt-project-dir .
```

Puxti maps the semantic graph: models, columns, relationships, and business definitions.
It will propose definitions via the LLM and ask you to confirm before writing anything.

**Step 1b — Link upstream Airflow tasks** *(optional — requires [airflow-demo-project](https://github.com/puxti-labs/airflow-demo-project))*

```bash
puxti link \
  --from task.airflow.salesforce_sync.extract_opportunities \
  --to source.clariva.raw_opportunities \
  --description "Extracts Salesforce opportunities. amount is a roll-up of OpportunityLineItem.TotalPrice post Q1 2024 migration."
```

Creates a cross-system FEEDS edge so Puxti can trace changes from the Airflow task
all the way through to dbt marts. See [airflow-demo-project](https://github.com/puxti-labs/airflow-demo-project)
for the companion DAG setup.

**Step 2 — Capture the change**

```bash
puxti capture \
  --entity source.clariva.raw_opportunities.amount \
  --before "Manually entered deal value" \
  --after "Salesforce roll-up: SUM(OpportunityLineItem.TotalPrice)" \
  --description "Q1 2024 migration to line-item pricing changed how Amount is populated" \
  --repo puxti-labs/puxti-demo-project
```

(`--repo` is optional when set in `.puxti.yml` — see Workspace config below.)

Puxti captures what the change means, not just what changed structurally.

**Step 3 — Review the impact**

Puxti identifies `stg_opportunities`, `fct_revenue`, and `fct_pipeline` as affected
downstream, and `task.airflow.salesforce_sync.extract_opportunities` as the upstream
producer. `dim_accounts` is unaffected — Puxti shows this explicitly so reviewers
aren't chasing false positives.

**Step 4 — Review the generated PRs**

When `.puxti.yml` includes `connectors.airflow`, Puxti opens two coordinated PRs:
- **dbt PR** (`puxti-labs/puxti-demo-project`) — SQL diffs for affected models
- **Airflow PR** (`puxti-labs/airflow-demo-project`) — docstring annotation on `extract_opportunities`

Each PR references the other with a suggested merge order (Airflow annotation first,
then dbt). Nothing is applied without your review.

---

## Workspace config (`.puxti.yml`)

If you're running both this dbt project and the companion [airflow-demo-project](https://github.com/puxti-labs/airflow-demo-project)
together, place a `.puxti.yml` one level above both clones:

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

With this in place, `--repo` and `--dbt-project-dir` resolve automatically from any
subdirectory inside the workspace.

---

## Further reading

- [Puxti CLI — full command reference](https://github.com/puxti-labs/puxti)
- [airflow-demo-project](https://github.com/puxti-labs/airflow-demo-project) — companion Airflow DAGs for the cross-system scenario

## License

MIT — Okolico Ventures UG, 2026
