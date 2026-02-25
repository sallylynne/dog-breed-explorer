# Trade-offs & Future Improvements

## Presentation Structure (30 min)

1. **Architecture diagram** (5 min) — walk through the Mermaid diagram left to right
2. **Dashboard demo** (7 min) — follow the narrative: lifespan → size distribution → family-friendly temperaments
3. **Code walk-through** (12 min) — follow the data through the stack (see below)
4. **Trade-offs & future improvements** (6 min) — see below, flows into Q&A

---

## Code Walk-through Order

1. `dog_pipeline.py` — dlt ingestion; explain `staging="filesystem"` (writes parquet to GCS first, then BigQuery load job) and `write_disposition="replace"` (full reload each run)
2. `main.tf` — Cloud Run Job, Cloud Scheduler, IAM bindings; mention least-privilege design
3. `dbt_project.yml` — the three materialisation choices:
   - **Views** (silver/staging) — `stg_dog_breeds` is never queried directly; no data stored, runs on demand
   - **Ephemeral** (intermediate) — `int_breed_base` and `int_breed_temperament_unnested` don't exist in BigQuery; dbt inlines them as CTEs inside mart models; keeps gold clean with only tables analysts actually use
   - **Tables** (gold/marts) — physically stored; Looker Studio connects here; needed so the dashboard doesn't re-run the full transformation chain on every load
4. `models/staging/stg_dog_breeds.sql` — regex parsing of life span and weight strings, `size_class` derivation
5. `models/marts/` — explain different grains: `dim_breed` (one row per breed) vs `fct_breed_temperament` (one row per breed × trait, unnested for trait-level analysis)
6. `.github/workflows/ci.yml` — throwaway dataset pattern per PR (`dbt_ci_pr<N>_silver/gold`), pytest runs before dbt
7. `.github/workflows/cd.yml` — `continue-on-error` pattern for observability hook: dbt test fails → Cloud Logging → log-based metric → alerting policy → email
8. `dog_transformations/tests/` — four singular tests: row count, life span range, weight positive, null rate threshold; contrast with generic schema tests in YAML files

---

## Deliberate Simplifications

**`write_disposition="replace"` — full table reload each run**
Acceptable for 169 static breeds. For mutable data you'd use `write_disposition="merge"` with dlt (incremental loads) or dbt snapshots for SCD2 history tracking — closing old rows and inserting new ones with `valid_from` / `valid_to` timestamps.

**No orchestration between ingestion and dbt**
Cloud Scheduler triggers ingestion and CD triggers dbt independently — there's no guarantee dbt runs after ingestion completes. Would use Cloud Workflows to chain them: ingest → dbt run → dbt test, with each step only running if the previous one succeeded.

**Terraform state stored locally**
`terraform.tfstate` lives on a single machine. In a team environment you'd store it in a GCS bucket (remote state backend) so multiple people can run Terraform without overwriting each other's state.

**Single service account for pipeline and CI/CD**
`data-pipeline-runner` currently does everything: runs the dlt pipeline at runtime, pushes Docker images, updates the Cloud Run Job, and runs dbt in prod. This means the `GCP_SA_KEY` stored in GitHub Actions has both deploy and data access. If that secret were compromised, an attacker would have access to both.

In production you'd split into two accounts:
- **Runtime account** (`pipeline-runner`) — only what the container needs: BigQuery dataEditor, GCS objectAdmin, Secret Manager accessor
- **Deploy account** (`cicd-deployer`) — only what GitHub Actions needs: Artifact Registry writer, Cloud Run developer, IAM serviceAccountUser on the runtime account

The key principle: the deploy account can update *what runs*, but the runtime account is what actually touches your data. There would be separate blast radii.

---

## Known Gaps

**No ingestion failure alerting**
Cloud Run Job failures don't trigger an alert — we only alert on dbt test failures. If the Dog API went down and the ingestion job failed silently, the bronze table would go stale with no notification. Would add dbt source freshness checks (`warn_after: 25h, error_after: 48h` on `bronze.dog_api_raw`) and Cloud Run Pub/Sub failure notifications.

**No data retention policy**
GCS staged parquet files accumulate indefinitely. Would add a GCS lifecycle policy to delete files after 30 days — they're not needed once loaded into BigQuery.

**Local dbt credentials use a hardcoded keyfile path**
`~/.dbt/profiles.yml` references `gcp-key.json` by absolute path. CI/CD handles credentials correctly via ADC. Local setup could be improved but is standard practice for local development.

---

## Natural Next Steps

- Cloud Workflows DAG: ingest → dbt run → dbt test
- Incremental loading with dlt merge mode or dbt snapshots (SCD2)
- dbt source freshness monitoring on `bronze.dog_api_raw`
- Separate runtime and deploy service accounts
- Enrich with adoption availability and regional popularity data to unlock demand-side insights
- Terraform remote state in GCS
