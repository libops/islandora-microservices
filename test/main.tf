terraform {
  required_version = "= 1.5.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "6.23.0"
    }
  }

  backend "gcs" {
    bucket = "libops-public-microservices-terraform"
    prefix = "/github-test"
  }
}

provider "google" {
  alias   = "default"
  project = var.project
}

resource "random_shuffle" "region" {
  input = [
    "us-east4",
    "us-east5",
    "us-central1",
    "us-west3",
    "us-west1",
    "us-west4",
    "us-south1"
  ]
  result_count = 1
}


module "houdini" {
  source = "../modules/cloudrun"

  name    = "houdini-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name           = "houdini",
      image          = "lehighlts/scyllaridae-imagemagick:main",
      port           = 8080
      liveness_probe = "/healthcheck"
    }
  ])
  providers = {
    google = google.default
  }
}

module "homarus" {
  source = "../modules/cloudrun"

  name    = "homarus-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name           = "homarus",
      image          = "lehighlts/scyllaridae-ffmpeg:main",
      port           = 8080
      liveness_probe = "/healthcheck"
    }
  ])
  providers = {
    google = google.default
  }
}

module "hypercube" {
  source = "../modules/cloudrun"

  name    = "hypercube-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name           = "hypercube",
      image          = "lehighlts/scyllaridae-tesseract:main",
      port           = 8080
      liveness_probe = "/healthcheck"
    }
  ])
  providers = {
    google = google.default
  }
}

module "fits" {
  source = "../modules/cloudrun"

  name    = "fits-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name   = "fits",
      image  = "islandora/fits:main",
      memory = "2Gi"
      cpu    = "2000m"
    }
  ])

  providers = {
    google = google.default
  }
}

module "crayfits" {
  source = "../modules/cloudrun"

  name    = "crayfits-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name           = "crayfits",
      image          = "lehighlts/scyllaridae-fits:main",
      liveness_probe = "/healthcheck"
    }
  ])
  addl_env_vars = tolist([
    {
      name  = "SCYLLARIDAE_YML"
      value = <<EOT
allowedMimeTypes:
  - "*"
cmdByMimeType:
  default:
    cmd: "curl"
    args:
      - "-X"
      - "POST"
      - "-F"
      - "datafile=@-"
      - "${module.fits.urls[random_shuffle.region.result[0]]}/fits/examine"
EOT
    }
  ])
  providers = {
    google = google.default
  }
}
