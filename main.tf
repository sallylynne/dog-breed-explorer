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

# 3. BigQuery Dataset for Silver (Staging) Data
resource "google_bigquery_dataset" "silver" {
dataset_id = "silver"
location   = "US"
delete_contents_on_destroy = true
}

# 4. BigQuery Dataset for Gold (Marts) Data
resource "google_bigquery_dataset" "gold" {
dataset_id = "gold"
location   = "US"
delete_contents_on_destroy = true
}

# 4. Cloud Run Job — runs as data-pipeline-runner so ADC works inside the container
resource "google_cloud_run_v2_job" "ingestion_job" {
name                = "dog-ingestion-job"
location            = "us-central1"
deletion_protection = false

depends_on = [google_secret_manager_secret_iam_member.pipeline_runner_secret_access]

# The CD workflow updates the image tag after every push to main.
# Ignoring the template block prevents terraform apply from reverting it.
lifecycle {
  ignore_changes = [template]
}

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

# 11. IAM — allow data-pipeline-runner to submit Cloud Build jobs (CI/CD image builds)
resource "google_project_iam_member" "pipeline_runner_cloudbuild_editor" {
  project = "sally-pyne-2026"
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${data.google_service_account.pipeline_runner.email}"
}

# 12. IAM — allow data-pipeline-runner to update Cloud Run jobs (CD deployment)
resource "google_project_iam_member" "pipeline_runner_run_developer" {
  project = "sally-pyne-2026"
  role    = "roles/run.developer"
  member  = "serviceAccount:${data.google_service_account.pipeline_runner.email}"
}

# 13. IAM — allow data-pipeline-runner to push images to Artifact Registry
resource "google_project_iam_member" "pipeline_runner_artifactregistry_writer" {
  project = "sally-pyne-2026"
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_service_account.pipeline_runner.email}"
}

# 14. IAM — allow data-pipeline-runner to act as itself when updating the Cloud Run Job
# (required because the job's execution SA is data-pipeline-runner)
resource "google_service_account_iam_member" "pipeline_runner_act_as_self" {
  service_account_id = data.google_service_account.pipeline_runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${data.google_service_account.pipeline_runner.email}"
}

# 15. IAM — allow data-pipeline-runner to use GCP services (required for gcloud CLI)
resource "google_project_iam_member" "pipeline_runner_service_usage_consumer" {
  project = "sally-pyne-2026"
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${data.google_service_account.pipeline_runner.email}"
}

# 14. Cloud Scheduler — uses data-pipeline-runner OIDC token to invoke the job
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

# ── Observability (Task 5) ────────────────────────────────────────────────────

# Log-based metric: counts ERROR entries written to the dbt-test-failures log.
# The CD workflow writes here whenever `dbt test` fails in prod.
resource "google_logging_metric" "dbt_test_failure" {
  name   = "dbt_test_failure_count"
  filter = "logName=\"projects/sally-pyne-2026/logs/dbt-test-failures\" AND severity=ERROR"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# Email notification channel — GCP will send a verification email on first apply.
# Click the link in that email to activate the channel before alerts will fire.
resource "google_monitoring_notification_channel" "email" {
  display_name = "Data Engineering Alerts"
  type         = "email"
  labels = {
    email_address = "sally.isaacoff@gmail.com"
  }
}

# Alerting policy: fires if the dbt test failure metric count exceeds 0
# within a 5-minute window.
resource "google_monitoring_alert_policy" "dbt_test_failure_alert" {
  display_name = "dbt prod test failure"
  combiner     = "OR"

  conditions {
    display_name = "dbt test failure count > 0"
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/dbt_test_failure_count\" resource.type=\"global\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_COUNT"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    content = "A `dbt test` run failed in prod. Check the CD workflow logs for details."
  }
}