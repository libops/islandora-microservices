terraform {
  required_version = "= 1.5.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "6.34.0"
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
      image          = "lehighlts/scyllaridae-imagemagick:main@sha256:d89070f5a39431c5ea2a1f176ed82bcc853553d0d5cd7dfa96a2905b2305da9a"
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
      image          = "lehighlts/scyllaridae-ffmpeg:main@sha256:7212f0e7488559080b091a8f435e26f142edbc7de5315b7838e3b472186c460b"
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
      image          = "lehighlts/scyllaridae-tesseract:main@sha256:d0091acdc9a44c4b48b752fe101c4b41ac2963a7b8360da5d4a4963bffd49385"
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
      image  = "islandora/fits:main@sha256:b793f1698fe1a8bc0cf23e386931ba8cbeb048eea482cb2d0ddd5a73d157f753"
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
      image          = "lehighlts/scyllaridae-fits:main@sha256:6f98aa2f942cf605caa2f6beac660b13a0e0b38bd5708788645edda93e724150"
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
