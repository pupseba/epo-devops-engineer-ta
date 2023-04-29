# Configure GAR

## Prod
### Configures #01 hosted container repository
resource "google_artifact_registry_repository" "container-prod-01" {
  provider      = google
  location      = var.region
  repository_id = "container-prod-01"
  description   = var.description
  format        = upper(var.format)

}
