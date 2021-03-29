locals {
  owner       = "myself"
  project     = "testapp"
  environment = var.environment

  default_overrides = {
    location = var.location
    labels = {
      "extra_label_key" = "label_value"
    }
  }

  repositories = {
    "app" = {
      description = "test-override"
    }
    "app2" = {
      roles = {
        "roles/viewer" = { format("%s", var.sa_reader_email) = "serviceAccount" }
        "roles/editor" = { format("%s", var.sa_owner_email) = "serviceAccount" }
      }
    }
  }
}

module "repository" {
  source = "../../"

  owner       = local.owner
  environment = local.environment
  project     = local.project

  repositories        = local.repositories
  repository_defaults = merge(module.repository.repository_defaults, local.default_overrides)
}

output "map" {
  value = module.repository.map
}
