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
      image          = "lehighlts/scyllaridae-imagemagick:main@sha256:856963354ae4e375ef2b540bc8d3bc29a69ef1255ea02f6a64e6a684cb190234"
      port           = 8080
      liveness_probe = "/healthcheck"
      memory         = "8Gi"
      cpu            = "2000m"
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
      image          = "lehighlts/scyllaridae-ffmpeg:main@sha256:5f8dd4f403a7427ec4e4f7a09dc9a2993d0e70465a72cc8de93c8f26a48a3f14"
      port           = 8080
      liveness_probe = "/healthcheck"
      memory         = "8Gi"
      cpu            = "4000m"
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
      image          = "lehighlts/scyllaridae-tesseract:main@sha256:de127924be7de7f307aac0f38d0ead41ffc9d305ff8f04efce673a3b7eac1e1c"
      port           = 8080
      liveness_probe = "/healthcheck"
      memory         = "8Gi"
      cpu            = "2000m"
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
      image  = "islandora/fits:main@sha256:a54023a0fffe5988e584dbea3897abcbabd3c09611836320a490f565d6349d15"
      memory = "8Gi"
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
      image          = "lehighlts/scyllaridae-fits:main@sha256:099259a5b59c5ba1f79a940b2e959a9b5517f7d1c93b8f62586717a584ebae05"
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
