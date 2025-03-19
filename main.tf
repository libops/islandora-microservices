terraform {
  required_version = "= 1.5.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "6.25.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.25.0"
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
      image          = "lehighlts/scyllaridae-ocrpdf:main@sha256:5ac583a8227ae22d316d17c283282c753ef2631e7acbd3ea741f70c18fb3ada6"
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
      image          = "lehighlts/scyllaridae-pandoc:main@sha256:68cf79d129b5fbf3e0d1d3bf89c69298324e0a16608af9d38c0fb726ccf35514"
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
      image          = "lehighlts/scyllaridae-whisper:main@sha256:07457b0fb04fa1b9163bccb6416a37744c3e0c98c44a0b68d116e330c68e15b7"
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

module "mistral" {
  source = "./modules/cloudrun-v2"

  name          = "mistral"
  project       = var.project
  max_instances = 1
  containers = tolist([
    {
      name   = "mistral",
      image  = "us-docker.pkg.dev/libops-public-microservices/shared/mistral-small-24b:main"
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
      image          = "lehighlts/scyllaridae-imagemagick:main@sha256:ea88146452f43d1217b61ec8597957f8ec3da71f8abf1b6b027d91ce92e2cbca"
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
      image          = "lehighlts/scyllaridae-libreoffice:main@sha256:70c78b32889d40470a7c6b4c1b1c5b65d5e03f168df35b5544ee71a3299a4e11"
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
      image          = "lehighlts/scyllaridae-ffmpeg:main@sha256:4705374d22da9e566baed3e7eb53d48ade105978410a3fcaad4688c66fa39c14"
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
      image          = "lehighlts/scyllaridae-tesseract:main@sha256:41e6978353a4275fa60089d3c6e5c0cc6a7ca8d3cdfaddb2886812eae2385efd"
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
      image  = "islandora/fits:main@sha256:b00c88bcff7300cb1783f2ed0b2a97aeec61e23e169aa70e5481566c95f56046"
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
      image          = "lehighlts/scyllaridae-fits:main@sha256:963e6d28626c428a870a460f790643f92e6682ff0aa33cf38a89bb37baf18ca1"
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
