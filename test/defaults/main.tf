locals {
  owner       = "myself"
  project     = "testapp"
  environment = var.environment

  repositories = {
    "app" = {}
  }
}

module "repository" {
  source = "../../"

  owner       = local.owner
  environment = local.environment
  project     = local.project

  repositories = local.repositories
}

output "map" {
  value = module.repository.map
}
