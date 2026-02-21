# DOG API CASE STUDY README

Project ID: sally-pyne-2026

Repository Link: [sally-pyne](https://github.com/sallylynne/sally-pyne)

## TASK 1: ENVIRONMENT & REPOSITORY

1. Project Initialization
    - GCP Setup: Created project sally-pyne-2026 and enabled core APIs (BigQuery, Cloud Storage, IAM, and Cloud Scheduler).

    - Dependency Management: Utilized uv for a high-performance, reproducible Python environment.

    - Compatibility: Pinned the project to Python 3.12 to ensure stable serialization for dbt-core and its dependencies.

2. Infrastructure & Security (Least-Privilege)

    - Service Account: Provisioned data-pipeline-runner@sally-pyne-2026.iam.gserviceaccount.com.

    - Granular RBAC: Assigned the following roles to satisfy security requirements:
        - roles/storage.objectAdmin: To manage the GCS staging area.
        - roles/bigquery.dataEditor: To materialize tables in the Bronze and Analytics layers.
        - roles/bigquery.jobUser: To execute compute workloads.

3. Deploy Infrastructure        
    - deploy python job
    	`gcloud run jobs deploy dog-ingestion-job --source . --region us-central1`
    - build terraform
    	`terraform apply`

BOOTSTRAP INSTRUCTIONS

1. Clone the Repo:
   
   `git clone https://github.com/sallylynne/sally-pyne.git`
   
   `cd my-dlt-project`

3. Install Dependencies:

    `uv sync`

4. Authentication:
Place your gcp-key.json in the root directory (this file is git-ignored).

    `export GOOGLE_APPLICATION_CREDENTIALS="gcp-key.json"`

5. Run Ingestion:
   
    `uv run python dog_pipeline.py`
