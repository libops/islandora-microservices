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
      image          = "lehighlts/scyllaridae-imagemagick:main@sha256:39ff91047a6d20595cdd10d80e2aa3b3551a54ecf6da2bd675f42fd1c4783fb8"
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
      image          = "lehighlts/scyllaridae-tesseract:main@sha256:350b6c719ae62d0e3c578c990a91c94d760552130798e3703458d10939be9edd"
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
      image          = "lehighlts/scyllaridae-fits:main@sha256:559bec3b752ba407a25c0b452d09a0d868b4f1f8a5a9158597abcdcbce7e6239"
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
