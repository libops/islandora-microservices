terraform {
  required_version = "= 1.5.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "6.27.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.27.0"
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
      image          = "lehighlts/scyllaridae-ocrpdf:main@sha256:9f34d886385a3e552717d308d0165950341711e5d2bb03a4a789016acc8f1f36"
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
      image          = "lehighlts/scyllaridae-pandoc:main@sha256:f900152fbbc77724e40cc52c5810d931e3bc1605c225121574696118ad374157"
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
      image          = "lehighlts/scyllaridae-whisper:main@sha256:23a36b85188fbe94b4594320c556ae55911f50240127851fc1711bff5b8ff904"
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

module "gemma" {
  source = "./modules/cloudrun-v2"

  name          = "gemma"
  project       = var.project
  max_instances = 1
  containers = tolist([
    {
      name   = "gemma",
      image  = "us-docker.pkg.dev/libops-public-microservices/shared/gemma3-12b:main"
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
      image          = "lehighlts/scyllaridae-imagemagick:main@sha256:eb07db108bc7e9503c48d4c1d7a64097c15ab903303ed47a7a371dad04535e88"
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
      image          = "lehighlts/scyllaridae-libreoffice:main@sha256:59042c764e85e72c6c02adc8d4e08ba47578f5d2f38eae58e111733758a59048"
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
      image          = "lehighlts/scyllaridae-ffmpeg:main@sha256:0333c04f717ce3ef48e1b152facaca0ad355b06e27480ef42b0fd193cb3aac4b"
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
      image          = "lehighlts/scyllaridae-tesseract:main@sha256:3381d88e4996a7f252563f283777cf1874c2e2ce2751e37105edb25737148309"
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
      image  = "islandora/fits:main@sha256:66330f97cb73367b5edcb57d66a5ce35c34ddbf8fa950c60f24ed8cb8ef0c8b9"
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
      image          = "lehighlts/scyllaridae-fits:main@sha256:de8b726ff9a8917d895d9fabe25ac266733b04a7874a09c8bb96adfff5b3f2aa"
      memory         = "2Gi"
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
