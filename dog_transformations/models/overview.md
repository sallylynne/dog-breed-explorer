{% docs __overview__ %}
# Dog Breed Explorer

End-to-end data pipeline and analytics layer for the [Dog API](https://thedogapi.com),
built on GCP with dlt, dbt, and Looker Studio.

**Dashboard:** https://lookerstudio.google.com/s/juYH956Ggv8

**Repo:** https://github.com/sallylynne/dog-breed-explorer

---

## Architecture

Raw breed data is ingested daily from the Dog API via a dlt pipeline running as a
Cloud Run Job, staged in GCS, and loaded into BigQuery. dbt transforms the raw data
through three medallion layers:

| Layer | Dataset | Description |
|---|---|---|
| Bronze | `bronze` | Raw schema-on-read data loaded by dlt |
| Silver | `silver` | Staged and normalised views (`stg_dog_breeds`) |
| Gold | `gold` | Mart tables ready for analytics and visualisation |

## Models

**Staging (`silver`)**
- `stg_dog_breeds` — parses and type-casts the raw Dog API payload; derives `size_class` and life span bounds

**Marts (`gold`)**
- `dim_breed` — breed dimension with descriptive attributes
- `fct_weight_life_span` — per-breed weight, height, life span metrics and derived flags
- `fct_breed_temperament` — one row per breed × temperament trait
- `fct_breed_group_summary` — aggregated stats per AKC breed group
- `fct_origin_summary` — aggregated stats by country of origin

{% enddocs %}
