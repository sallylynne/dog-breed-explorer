provider "google" {
project = "sally-pyne-2026"
region  = "us-central1"
}

# Reference the existing service account (created manually)
data "google_service_account" "pipeline_runner" {
  account_id = "data-pipeline-runner"
  project    = "sally-pyne-2026"
}

# 1. GCS Bucket for Raw Data
resource "google_storage_bucket" "raw_data" {
name          = "sally-pyne-raw-data-2026"
location      = "US"
force_destroy = true
}

# 2. BigQuery Dataset for Raw (Bronze) Data
resource "google_bigquery_dataset" "bronze" {
dataset_id = "bronze"
location   = "US"
delete_contents_on_destroy = true
}

# 3. BigQuery Dataset for Transformed (Analytics) Data
resource "google_bigquery_dataset" "analytics" {
dataset_id = "analytics"
location   = "US"
delete_contents_on_destroy = true
}

# 4. Cloud Run Job — runs as data-pipeline-runner so ADC works inside the container
resource "google_cloud_run_v2_job" "ingestion_job" {
name                = "dog-ingestion-job"
location            = "us-central1"
deletion_protection = false

depends_on = [google_secret_manager_secret_iam_member.pipeline_runner_secret_access]

template {
template {
  service_account = data.google_service_account.pipeline_runner.email
  containers {
    image = "us-central1-docker.pkg.dev/sally-pyne-2026/cloud-run-source-deploy/dog-ingestion-job"
    env {
      name  = "DESTINATION__FILESYSTEM__BUCKET_URL"
      value = "gs://${google_storage_bucket.raw_data.name}"
    }
    env {
      name = "SOURCES__REST_API__API_KEY"
      value_source {
        secret_key_ref {
          secret  = data.google_secret_manager_secret.dog_api_key.secret_id
          version = "latest"
        }
      }
    }
  }
}
}
}

# 5. IAM — allow data-pipeline-runner to execute the Cloud Run Job (scoped to the job, not the whole project)
resource "google_cloud_run_v2_job_iam_member" "scheduler_can_run_job" {
  project  = "sally-pyne-2026"
  location = "us-central1"
  name     = google_cloud_run_v2_job.ingestion_job.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${data.google_service_account.pipeline_runner.email}"
}

# 6. IAM — allow data-pipeline-runner to write/read BigQuery data
resource "google_project_iam_member" "pipeline_runner_bq_data_editor" {
  project = "sally-pyne-2026"
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${data.google_service_account.pipeline_runner.email}"
}

# 7. IAM — allow data-pipeline-runner to submit BigQuery jobs (required for dlt loads)
resource "google_project_iam_member" "pipeline_runner_bq_job_user" {
  project = "sally-pyne-2026"
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${data.google_service_account.pipeline_runner.email}"
}

# 8. IAM — allow data-pipeline-runner to read/write objects in GCS (staging bucket)
resource "google_project_iam_member" "pipeline_runner_gcs_object_admin" {
  project = "sally-pyne-2026"
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${data.google_service_account.pipeline_runner.email}"
}

# 9. Secret Manager — reference the dog API key (created via gcloud)
data "google_secret_manager_secret" "dog_api_key" {
  secret_id = "dog-api-key"
  project   = "sally-pyne-2026"
}

# 10. IAM — allow data-pipeline-runner to read the secret
resource "google_secret_manager_secret_iam_member" "pipeline_runner_secret_access" {
  secret_id = data.google_secret_manager_secret.dog_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_service_account.pipeline_runner.email}"
}

# 9. Cloud Scheduler — uses data-pipeline-runner OIDC token to invoke the job
resource "google_cloud_scheduler_job" "daily_sync" {
name             = "dog-api-daily-sync"
description      = "Triggers the dlt ingestion job"
schedule         = "0 2 * * *"
time_zone        = "UTC"
region           = "us-central1"

http_target {
http_method = "POST"
uri         = "https://us-central1-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/sally-pyne-2026/jobs/${google_cloud_run_v2_job.ingestion_job.name}:run"
oidc_token {
  service_account_email = data.google_service_account.pipeline_runner.email
  audience              = "https://us-central1-run.googleapis.com/"
}
}
}