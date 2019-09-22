terraform {
  required_version = ">= 0.12"

  backend "gcs" {
  }
}

provider "random" {}

resource "random_id" "project_id_suffix" {
  byte_length = 8
}

resource "google_project" "gdrive_backup" {
  name            = "Google Drive backup"
  project_id      = "gdrive-backup-${random_id.project_id_suffix.hex}"
  org_id          = var.org_id
  billing_account = var.billing_account_id
}

resource "google_project_services" "project" {
  project = google_project.gdrive_backup.project_id
  services = [
    "oslogin.googleapis.com",
  ]
}

resource "random_id" "storage_bucket_suffix" {
  byte_length = 8
}

resource "google_storage_bucket" "gdrive_backup" {
  project  = google_project.gdrive_backup.project_id
  name     = "gdrive-backup-${random_id.storage_bucket_suffix.hex}"
  location = "${var.cloud_storage_location}"
}

resource "google_storage_bucket_object" "rclone_conf" {
  bucket = google_storage_bucket.gdrive_backup.name
  name   = "settings/rclone.conf"
  content = templatefile("docker_image/rclone.conf.tpl", {
    cloud_storage_location = var.cloud_storage_location
  })
}

output "rclone_conf_gs_url" {
  value = "gs://${google_storage_bucket_object.rclone_conf.bucket}/${google_storage_bucket_object.rclone_conf.output_name}"
}
