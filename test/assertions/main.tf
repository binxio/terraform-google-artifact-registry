locals {
  owner       = "myself"
  project     = "testapp"
  environment = var.environment

  repositories = {
    "trigger-assertions for repository 'cause this name is too long and has invalid chars" = {
      not_existing = "should-fail"
    }
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
