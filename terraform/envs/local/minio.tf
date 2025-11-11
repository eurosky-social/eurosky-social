# MinIO S3-compatible storage for local development
# Runs as a standalone Docker container (not in Kubernetes)

locals {
  minio_root_user     = "minioadmin"
  minio_root_password = "minioadmin"
  minio_bucket_backups = "postgres-backups"
  minio_bucket_pds    = "pds-blobstore"
  minio_region        = "us-east-1"
  minio_api_port      = 9000
  minio_console_port  = 9001
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# MinIO Docker image
resource "docker_image" "minio" {
  name          = "minio/minio:RELEASE.2024-10-13T13-34-11Z"
  keep_locally  = false
}

# MinIO container
resource "docker_container" "minio" {
  name  = "minio-local"
  image = docker_image.minio.image_id

  # Environment variables
  env = [
    "MINIO_ROOT_USER=${local.minio_root_user}",
    "MINIO_ROOT_PASSWORD=${local.minio_root_password}",
  ]

  # Ports: API and console
  ports {
    internal = local.minio_api_port
    external = local.minio_api_port
  }

  ports {
    internal = local.minio_console_port
    external = local.minio_console_port
  }

  # Volume for persistent data
  volumes {
    host_path      = "${path.cwd}/.minio-data"
    container_path = "/data"
  }

  # Command to start MinIO server
  command = ["server", "/data", "--console-address", ":9001"]

  # Remove container when destroyed
  rm = true
}
