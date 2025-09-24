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
    prefix = "/microservices"
  }
}

provider "google" {
  alias   = "default"
  project = var.project
}

module "ocrpdf" {
  source = "git::https://github.com/libops/terraform-cloudrun-v2?ref=0.3.1"

  name    = "ocrpdf"
  project = var.project
  containers = tolist([
    {
      name   = "ocrpdf",
      image  = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-ocrpdf:main"
      port   = 8080
      memory = "4Gi"
      cpu    = "2000m"
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

module "pandoc" {
  source = "git::https://github.com/libops/terraform-cloudrun-v2?ref=0.3.1"

  name    = "pandoc"
  project = var.project
  containers = tolist([
    {
      name   = "pandoc",
      image  = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-pandoc:main"
      port   = 8080
      memory = "4Gi"
      cpu    = "4000m"
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

module "houdini" {
  source = "git::https://github.com/libops/terraform-cloudrun-v2?ref=0.3.1"

  name    = "houdini"
  project = var.project
  containers = tolist([
    {
      name   = "houdini",
      image  = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-imagemagick:main"
      port   = 8080
      memory = "8Gi"
      cpu    = "2000m"
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


module "libreoffice" {
  source = "git::https://github.com/libops/terraform-cloudrun-v2?ref=0.3.1"

  name    = "libreoffice"
  project = var.project
  containers = tolist([
    {
      name   = "libreoffice",
      image  = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-libreoffice:main"
      port   = 8080
      memory = "4Gi"
      cpu    = "1000m"
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

  name    = "homarus"
  project = var.project
  containers = tolist([
    {
      name   = "homarus",
      image  = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-ffmpeg:main"
      port   = 8080
      memory = "8Gi"
      cpu    = "4000m"
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

  name    = "hypercube"
  project = var.project
  containers = tolist([
    {
      name   = "hypercube",
      image  = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-tesseract:main"
      port   = 8080
      memory = "8Gi"
      cpu    = "2000m"
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
  source = "git::https://github.com/libops/terraform-cloudrun-v2?ref=0.3.1"

  name    = "crayfits"
  project = var.project
  containers = tolist([
    {
      name   = "crayfits",
      image  = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-fits:main"
      memory = "4Gi"
      cpu    = "2000m"
    }
  ])
  addl_env_vars = tolist([
    {
      name  = "FITS_URI"
      value = "https://microservices.libops.site/fits/examine"
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

module "lb" {
  source = "./modules/lb"

  project = var.project
  backends = {
    "homarus"     = module.homarus.backend,
    "houdini"     = module.houdini.backend,
    "hypercube"   = module.hypercube.backend,
    "fits"        = module.fits.backend
    "crayfits"    = module.crayfits.backend
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
