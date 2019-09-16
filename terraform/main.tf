
terraform {
  required_version = "~> 0.11"
}

provider "google" {
  version = "~> 2.12.0"
  access_token = "${var.access_token}"
  project = "${var.project_id}"
  region = "${var.region}"
  zone = "${var.region}-a"
}

resource "google_project_service" "sqladmin" {
  service = "sqladmin.googleapis.com"
  disable_dependent_services = true
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
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = "${google_storage_bucket.db_backup_store.name}"
  role = "roles/storage.legacyBucketWriter"
  member = "serviceAccount:${google_sql_database_instance.master.service_account_email_address}"
}

resource "google_service_account" "db_backup" {
  account_id = "db-backup-sa"
  display_name = "DB backup account"
}

resource "google_project_iam_member" "impersonater" {
  role = "roles/iam.serviceAccountTokenCreator"
  member = "user:${var.user_email}"
}

resource "google_project_iam_binding" "db_exporter" {
  role = "roles/cloudsql.viewer"
  members = [
    "serviceAccount:${google_service_account.db_backup.email}",
  ]
}
