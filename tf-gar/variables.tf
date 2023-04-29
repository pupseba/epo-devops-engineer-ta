variable "repository_id" {
  type    = string
  default = "prod-01"
}

variable "description" {
  type    = string
  default = "Container repository"
}

variable "format" {
  type    = string
  default = "DOCKER"
}

variable "project" {
  type    = string
  default = "epo-technical-assessment"
}

variable "region" {
  type    = string
  default = "europe-west6"
}
