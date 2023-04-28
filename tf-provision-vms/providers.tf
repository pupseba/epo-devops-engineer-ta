provider "google" {
  credentials = file("../secrets/credential_01.json")
  project = "EPO-Technical-assessment"
  region  = "europe-west6"
  zone  = "europe-west6-a"
}
