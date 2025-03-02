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
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.23.0"
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
      image          = "lehighlts/scyllaridae-ocrpdf:main@sha256:17ccea54e89e4134be72512baa91271c71c926e8e5952c8f5e39c88c63bc63e4"
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
      image          = "lehighlts/scyllaridae-pandoc:main@sha256:3bd4f2182caa51bc10832dbf9c46c1e95a07dbf1e6c4439d51a11ea6d8a4ce3a"
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

module "whisper" {
  source = "./modules/cloudrun-v2"

  name          = "whisper"
  project       = var.project
  max_instances = 3
  containers = tolist([
    {
      name           = "whisper",
      image          = "lehighlts/scyllaridae-whisper:main@sha256:872472685ea93198181e2ccc5fe2b3494ee2b9c8d5fb1ed21481a6359186c45f"
      port           = 8080
      liveness_probe = "/healthcheck"
      memory         = "16Gi"
      cpu            = "4000m"
      gpus           = 1
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
      image          = "lehighlts/scyllaridae-imagemagick:main@sha256:39ff91047a6d20595cdd10d80e2aa3b3551a54ecf6da2bd675f42fd1c4783fb8"
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
      image          = "lehighlts/scyllaridae-libreoffice:main@sha256:fa67802b653c77fe8a07873f8f0c4033aa5909cc5410c70422c230d48a867d41"
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
      image          = "lehighlts/scyllaridae-ffmpeg:main@sha256:3c4b8a65a3b6cdd74bf4c69c17eb8ad492b3807f6fa6df7f3577193e89f7ad67"
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

module "hypercube" {
  source = "./modules/cloudrun"

  name    = "hypercube"
  project = var.project
  containers = tolist([
    {
      name           = "hypercube",
      image          = "lehighlts/scyllaridae-tesseract:main@sha256:350b6c719ae62d0e3c578c990a91c94d760552130798e3703458d10939be9edd"
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
  source = "./modules/cloudrun"

  name    = "crayfits"
  project = var.project
  containers = tolist([
    {
      name           = "crayfits",
      image          = "lehighlts/scyllaridae-fits:main@sha256:559bec3b752ba407a25c0b452d09a0d868b4f1f8a5a9158597abcdcbce7e6239"
      memory         = "4Gi"
      cpu            = "2000m"
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
      - "https://microservices.libops.site/fits/examine"
EOT
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
    "whisper"     = module.whisper.backend
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
