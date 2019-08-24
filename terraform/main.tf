
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

locals {
  backup_job_name = "db_export"
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

resource "google_storage_bucket" "db_backup_store" {
  name = "${var.project_id}-db-backup-store"
  location = "${var.region}"
  storage_class = "REGIONAL"
  force_destroy = "true"
  versioning = {
    enabled = "true"
  }
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = "${google_storage_bucket.db_backup_store.name}"
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_sql_database_instance.master.service_account_email_address}"
}

resource "google_service_account" "db_backup" {
  account_id = "db-backup-sa"
  display_name = "DB backup account"
}

resource "google_project_iam_binding" "db_exporter" {
  role = "roles/cloudsql.viewer"
  members = [
    "serviceAccount:${google_service_account.db_backup.email}",
  ]
}

resource "null_resource" "export_db_scheduler" {
  triggers {
    foo = "0"
  }

  provisioner "local-exec" {
    command = <<EOF
        gcloud alpha scheduler jobs create http ${local.backup_job_name} \
            --description='Export CloudSQL DB to Storage Bucket' \
            --schedule='0 0 * * *' \
            --uri='https://www.googleapis.com/sql/v1beta4/projects/${var.project_id}/instances/${google_sql_database_instance.master.name}/export' \
            --http-method="post" \
            --headers=Content-Type=application/json \
            --time-zone=Australia/Melbourne \
            --oauth-service-account-email='${google_service_account.db_backup.email}' \
            --oauth-token-scope='https://www.googleapis.com/auth/cloud-platform' \
            --message-body="$$(cat << PAYLOAD
{
  "exportContext": {
    "fileType": "SQL",
    "uri": "gs://${google_storage_bucket.db_backup_store.name}/${google_sql_database_instance.master.name}/${google_sql_database.database.name}",
    "databases": ["${google_sql_database.database.name}"]
  }
}
PAYLOAD
)"
    EOF
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "gcloud alpha scheduler jobs delete ${local.backup_job_name} --quiet"
  }
}
