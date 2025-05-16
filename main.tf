terraform {
  required_version = "= 1.5.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "6.35.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.35.0"
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
      image          = "lehighlts/scyllaridae-ocrpdf:main@sha256:68c1b7f5d0697943cb6e89112b8c405edd884886d082e18bed8b7bd476cc59b0"
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
      image          = "lehighlts/scyllaridae-pandoc:main@sha256:e752b026196982462203a836b51e7fba19b9f2a9b08c7d3ed673a8efa341c617"
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
      image          = "lehighlts/scyllaridae-whisper:main@sha256:d58ebadbb9d46500cf7be81f380028e81c60f140c9749ab611ebb9d06475da70"
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
      image          = "lehighlts/scyllaridae-imagemagick:main@sha256:128b9e625c8f2da71e612fb23d00b76bb23a5d24306267caeb3aa08f01ccea44"
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
      image          = "lehighlts/scyllaridae-libreoffice:main@sha256:81dfdd3f87af07f78538e13ff40120c35e5e3182e57bcca69715f018994f1a3f"
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
      image          = "lehighlts/scyllaridae-ffmpeg:main@sha256:a2c82625fa9b87f140a6fbe407b8f68a244051503f88cbab783911db35d519bc"
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
      image          = "lehighlts/scyllaridae-tesseract:main@sha256:a1ba0d64ee5a4a986fcf26a093b3b508b51e72726100fba58f19fa22c0f25933"
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
      image  = "islandora/fits:main@sha256:97c955ec722f13d05dbf4136a605335e4f674ef03cd096c1e0209fae0b553959"
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
      image          = "lehighlts/scyllaridae-fits:main@sha256:05e519b432f27178711582c7f04d85e3a73282d3ae0fe33e6cbad5a611539b66"
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
