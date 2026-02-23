# Dog Breed Explorer — Data Engineering Case Study

**Project ID:** sally-pyne-2026
**Repository:** [sallylynne/dog-breed-explorer](https://github.com/sallylynne/dog-breed-explorer)

![CI](https://github.com/sallylynne/dog-breed-explorer/actions/workflows/ci.yml/badge.svg)
![CD](https://github.com/sallylynne/dog-breed-explorer/actions/workflows/cd.yml/badge.svg)

**dbt docs:** https://sallylynne.github.io/dog-breed-explorer/

---

## Architecture Overview

```
Dog API → dlt pipeline → GCS (raw) → BigQuery bronze → dbt → BigQuery silver / gold
```

| Layer | GCP Resource | dbt Dataset (dev) | dbt Dataset (prod) |
|---|---|---|---|
| Bronze | GCS bucket + BigQuery `bronze` | — | — |
| Silver | — | `dev_silver` | `silver` |
| Gold | — | `dev_gold` | `gold` |

Infrastructure is managed with Terraform. The ingestion pipeline runs as a Cloud Run Job triggered daily by Cloud Scheduler.

---

## Bootstrap Instructions

### Prerequisites
- GCP project with billing enabled
- `gcloud` CLI authenticated (`gcloud auth login`)
- `terraform` CLI installed
- `uv` Python package manager

### 1. Clone the repo

```bash
git clone https://github.com/sallylynne/dog-breed-explorer.git
cd dog-breed-explorer
```

### 2. Install Python dependencies

```bash
uv sync
```

### 3. GCP credentials

Place your `gcp-key.json` service account key in the project root (it is git-ignored):

```bash
export GOOGLE_APPLICATION_CREDENTIALS="gcp-key.json"
```

### 4. Provision infrastructure

```bash
terraform init
terraform apply
```

This creates the GCS bucket, BigQuery datasets (`bronze`, `gold`), Cloud Run Job, and Cloud Scheduler trigger.

### 5. Build and push the ingestion image

```bash
gcloud builds submit \
  --config cloudbuild.yaml \
  --substitutions _COMMIT_SHA=local \
  --project sally-pyne-2026 \
  .
```

### 6. Run the ingestion pipeline (ad-hoc)

```bash
uv run python dog_pipeline.py
```

Or trigger the Cloud Run Job directly:

```bash
gcloud run jobs execute dog-ingestion-job --region us-central1
```

### 7. Run dbt transformations (local dev)

```bash
cd dog_transformations
uv run dbt run
uv run dbt test
```

Requires `~/.dbt/profiles.yml` to be configured with a `dog_transformations` profile pointing to your `gcp-key.json`.

---

## CI/CD (GitHub Actions)

| Workflow | Trigger | What it does |
|---|---|---|
| `ci.yml` | Pull request → `main` | Runs `dbt run` + `dbt test` in a throwaway BigQuery dataset (`dbt_ci_pr<N>`), then cleans it up |
| `cd.yml` | Push to `main` | Builds + pushes Docker image via Cloud Build, updates the Cloud Run Job, runs `dbt run/test --target prod` |

### Required GitHub secret

Add a secret named **`GCP_SA_KEY`** in **Settings → Secrets and variables → Actions**:

- Value: the full JSON contents of `gcp-key.json`

This is the only manual step required after cloning the repo.

---

## Service Account Roles

`data-pipeline-runner@sally-pyne-2026.iam.gserviceaccount.com` holds the following roles:

| Role | Purpose |
|---|---|
| `roles/storage.objectAdmin` | Read/write GCS staging bucket |
| `roles/bigquery.dataEditor` | Materialize tables in Bronze and Analytics |
| `roles/bigquery.jobUser` | Execute BigQuery compute jobs |
| `roles/run.invoker` | Allow Cloud Scheduler to trigger the Cloud Run Job |
| `roles/artifactregistry.writer` | Push Docker images to Artifact Registry |
| `roles/cloudbuild.builds.editor` | Submit Cloud Build jobs (manual ad-hoc builds) |
| `roles/run.developer` | Update Cloud Run Job after image push |
| `roles/iam.serviceAccountUser` (on itself) | Required to update the Cloud Run Job whose execution SA is itself |
| `roles/serviceusage.serviceUsageConsumer` | Use GCP APIs via gcloud CLI |
| `roles/secretmanager.secretAccessor` | Read the Dog API key from Secret Manager |
