provider "google" {
  credentials = file("../secrets/credential_01.json")
  project = "epo-technical-assessment"
  region  = "europe-west6"
  zone  = "europe-west6-a"
}
