terraform {
  required_version = "= 1.5.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "7.4.0"
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
  source = "git::https://github.com/libops/terraform-cloudrun-v2?ref=0.3.1"

  name    = "houdini-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name           = "houdini",
      image          = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-imagemagick:main"
      port           = 8080
      liveness_probe = "/healthcheck"
      memory         = "8Gi"
      cpu            = "2000m"
    }
  ])
  addl_env_vars = tolist([
    {
      name  = "SKIP_JWT_VERIFY"
      value = "true"
    }
  ])
  providers = {
    google = google.default
  }
}

module "homarus" {
  source = "git::https://github.com/libops/terraform-cloudrun-v2?ref=0.3.1"

  name    = "homarus-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name           = "homarus",
      image          = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-ffmpeg:main"
      port           = 8080
      liveness_probe = "/healthcheck"
      memory         = "8Gi"
      cpu            = "4000m"
    }
  ])
  addl_env_vars = tolist([
    {
      name  = "SKIP_JWT_VERIFY"
      value = "true"
    }
  ])
  providers = {
    google = google.default
  }
}

module "hypercube" {
  source = "git::https://github.com/libops/terraform-cloudrun-v2?ref=0.3.1"

  name    = "hypercube-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name           = "hypercube",
      image          = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-tesseract:main"
      port           = 8080
      liveness_probe = "/healthcheck"
      memory         = "8Gi"
      cpu            = "2000m"
    }
  ])
  addl_env_vars = tolist([
    {
      name  = "SKIP_JWT_VERIFY"
      value = "true"
    }
  ])
  providers = {
    google = google.default
  }
}

module "fits" {
  source = "git::https://github.com/libops/terraform-cloudrun-v2?ref=0.3.1"

  name    = "fits-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name   = "fits",
      image  = "islandora/fits:main@sha256:698971c83dfc7afd98926486700bb951498246503ca26bc8e7c3174d0e3df066"
      memory = "8Gi"
      cpu    = "2000m"
    }
  ])

  providers = {
    google = google.default
  }
}

module "crayfits" {
  source = "git::https://github.com/libops/terraform-cloudrun-v2?ref=0.3.1"

  name    = "crayfits-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name  = "crayfits",
      image = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-fits:main"
    }
  ])
  addl_env_vars = tolist([
    {
      name  = "FITS_URI"
      value = "${module.fits.urls[random_shuffle.region.result[0]]}/fits/examine"
    },
    {
      name  = "SKIP_JWT_VERIFY"
      value = "true"
    }
  ])
  providers = {
    google = google.default
  }
}
