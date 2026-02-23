# dog_transformations

dbt project for the Dog Breed Explorer pipeline. Transforms raw data from the `bronze` BigQuery dataset into analytics-ready mart tables.

## Model layers

| Layer | Materialization | BigQuery dataset | Description |
|---|---|---|---|
| `staging` | view | `dev_staging` / `analytics_staging` | Light cleaning and type casting of raw dlt data |
| `intermediate` | ephemeral | — (not written to DB) | Shared derived metrics and unnested structures |
| `marts` | table | `dev` / `analytics` | Consumption-ready tables for dashboards |

## Mart models

| Model | Grain | Description |
|---|---|---|
| `dim_breed` | one row per breed | Full breed profile including size, life span, weight, height, and 10 boolean temperament flags |
| `fact_weight_life_span` | one row per breed | Metric-focused: weight, height, life span, `weight_per_inch_lbs`, `life_span_category` |
| `fct_breed_temperament` | one row per breed × temperament trait | Unnested temperament tags for trait-level analysis |
| `fct_breed_group_summary` | one row per AKC breed group | Aggregated size and physical stats by group |
| `fct_origin_summary` | one row per country of origin | Aggregated stats by country, including most common size class |

## Running locally

```bash
# from the dog_transformations/ directory
uv run dbt run
uv run dbt test
```

Requires `~/.dbt/profiles.yml` with a `dog_transformations` profile. See the project README for setup instructions.

## CI/CD

- **CI:** each PR runs `dbt run` + `dbt test` against a throwaway dataset (`dbt_ci_pr<N>`), deleted after the job completes.
- **CD:** on merge to `main`, `dbt run --target prod` + `dbt test --target prod` deploys models to the `analytics` dataset.
