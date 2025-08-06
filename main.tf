terraform {
  required_version = "= 1.5.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "6.47.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.47.0"
    }
  }

  backend "gcs" {
    bucket = "libops-public-microservices-terraform"
    prefix = "/microservices"
  }
}

provider "google" {
  alias   = "default"
  project = var.project
}

provider "google-beta" {
  alias   = "default"
  project = var.project
}

module "ocrpdf" {
  source = "./modules/cloudrun"

  name    = "ocrpdf"
  project = var.project
  containers = tolist([
    {
      name           = "ocrpdf",
      image          = "ghcr.io/lehigh-university-libraries/scyllaridae-ocrpdf:main"
      port           = 8080
      liveness_probe = "/healthcheck"
      memory         = "4Gi"
      cpu            = "2000m"
    }
  ])
  providers = {
    google = google.default
  }
}

module "pandoc" {
  source = "./modules/cloudrun"

  name    = "pandoc"
  project = var.project
  containers = tolist([
    {
      name           = "pandoc",
      image          = "ghcr.io/lehigh-university-libraries/scyllaridae-pandoc:main"
      port           = 8080
      liveness_probe = "/healthcheck"
      memory         = "4Gi"
      cpu            = "4000m"
    }
  ])
  providers = {
    google = google.default
  }
}

module "gpt-oss-20b" {
  source = "./modules/cloudrun-v2"

  name          = "gpt-20b"
  project       = var.project
  max_instances = 1
  containers = tolist([
    {
      name   = "openai",
      image  = "us-docker.pkg.dev/libops-public-microservices/shared/gpt-20b:main"
      port   = 8080
      memory = "32Gi"
      cpu    = "8000m"
      gpus   = 1
    }
  ])
  regions = ["us-central1"]
  providers = {
    google-beta = google-beta.default
  }
}

module "houdini" {
  source = "./modules/cloudrun"

  name    = "houdini"
  project = var.project
  containers = tolist([
    {
      name           = "houdini",
      image          = "ghcr.io/lehigh-university-libraries/scyllaridae-imagemagick:main"
      port           = 8080
      memory         = "8Gi"
      cpu            = "2000m"
      liveness_probe = "/healthcheck"
    }
  ])
  providers = {
    google = google.default
  }
}


module "libreoffice" {
  source = "./modules/cloudrun"

  name    = "libreoffice"
  project = var.project
  containers = tolist([
    {
      name           = "libreoffice",
      image          = "ghcr.io/lehigh-university-libraries/scyllaridae-libreoffice:main"
      port           = 8080
      memory         = "4Gi"
      cpu            = "1000m"
      liveness_probe = "/healthcheck"
    }
  ])
  providers = {
    google = google.default
  }
}

module "homarus" {
  source = "./modules/cloudrun"

  name    = "homarus"
  project = var.project
  containers = tolist([
    {
      name           = "homarus",
      image          = "ghcr.io/lehigh-university-libraries/scyllaridae-ffmpeg:main"
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
  source = "./modules/cloudrun"

  name    = "hypercube"
  project = var.project
  containers = tolist([
    {
      name           = "hypercube",
      image          = "ghcr.io/lehigh-university-libraries/scyllaridae-tesseract:main"
      port           = 8080
      memory         = "8Gi"
      cpu            = "2000m"
      liveness_probe = "/healthcheck"
    }
  ])
  providers = {
    google = google.default
  }
}

module "fits" {
  source = "./modules/cloudrun"

  name    = "fits"
  project = var.project
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
  source = "./modules/cloudrun"

  name    = "crayfits"
  project = var.project
  containers = tolist([
    {
      name           = "crayfits",
      image          = "ghcr.io/lehigh-university-libraries/scyllaridae-fits:main"
      memory         = "4Gi"
      cpu            = "2000m"
      liveness_probe = "/healthcheck"
    }
  ])
  addl_env_vars = tolist([
    {
      name  = "FITS_URI"
      value = "https://microservices.libops.site/fits/examine"
    }
  ])
  providers = {
    google = google.default
  }
}

module "lb" {
  source = "./modules/lb"

  project = var.project
  backends = {
    "homarus"     = module.homarus.backend,
    "houdini"     = module.houdini.backend,
    "hypercube"   = module.hypercube.backend,
    "fits"        = module.fits.backend
    "crayfits"    = module.crayfits.backend
    "gpt"         = module.gpt-oss-20b.backend
    "pandoc"      = module.pandoc.backend
    "ocrpdf"      = module.ocrpdf.backend
    "libreoffice" = module.libreoffice.backend
  }
}

resource "google_monitoring_uptime_check_config" "availability" {
  for_each = toset([
    "crayfits",
    "homarus",
    "houdini",
    "hypercube",
    "ocrpdf",
    "pandoc",
    "libreoffice"
  ])
  display_name = "${each.value}-availability"
  timeout      = "10s"
  period       = "60s"
  project      = var.project
  selected_regions = [
    "USA_OREGON",
    "USA_VIRGINIA",
    "USA_IOWA"
  ]
  http_check {
    path         = "/${each.value}/healthcheck"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project
      host       = "microservices.libops.site"
    }
  }
}
