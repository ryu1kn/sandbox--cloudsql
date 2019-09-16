
output "export_command" {
  value = <<EOF

      gcloud sql export sql ${google_sql_database_instance.master.name} \
          gs://${google_storage_bucket.db_backup_store.name}/${google_sql_database.database.name} \
          --database=${google_sql_database.database.name} \
          --impersonate-service-account ${google_service_account.db_backup.email}
  EOF
}
