
terraform {
  required_version = "~> 0.11"
  required_providers {
    google = "2.13.0"
    random_id = "2.2.0"
  }
}

provider "google" {
  access_token = "${var.access_token}"
  project = "${var.project_id}"
  region = "${var.region}"
  zone = "${var.region}-a"
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "master" {
  name = "master-instance-${random_id.db_name_suffix.hex}"
  database_version = "POSTGRES_9_6"
  region = "australia-southeast1"
  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "database" {
  name = "shops"
  instance = "${google_sql_database_instance.master.name}"
}

resource "google_cloud_scheduler_job" "db_export" {
  name = "export-db"
  description = "Export DB to Cloud Storage"
  schedule = "0 0 * * *"
  time_zone = "Australia/Melbourne"

  http_target {
    http_method = "POST"
    uri = "https://www.googleapis.com/sql/v1beta4/projects/${var.project_id}/instances/${google_sql_database_instance.master.name}/export"

    # XXX: Access token here is useless. It's only effective for an hour after the schedule creation
    headers = "${map(
      "Content-Type", "application/json",
      "Authorization", "Bearer ${data.google_service_account_access_token.db_backup.access_token}"
    )}"
    body = <<EOF
{
  "exportContext": {
    "fileType": "SQL",
    "uri": "gs://${google_storage_bucket.db_backup_store.name}/${google_sql_database_instance.master.name}/${google_sql_database.database.name}",
    "databases": ["${google_sql_database.database.name}"]
  }
}
EOF
  }
}

resource "google_storage_bucket" "db_backup_store" {
  name = "${var.project_id}-db-backup-store"
  location = "${var.region}"
  storage_class = "REGIONAL"
  force_destroy = "true"
  versioning = {
    enabled = "true"
  }
}

resource "google_service_account" "db_backup" {
  account_id = "db-backup-sa"
  display_name = "DB backup account"
}

data "google_service_account_access_token" "db_backup" {
  target_service_account = "${google_service_account.db_backup.email}"
  scopes = ["cloud-platform"]
  lifetime = "3600s"
}
