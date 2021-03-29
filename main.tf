#---------------------------------------------------------------------------------------------
# Define our locals for increased readability
#---------------------------------------------------------------------------------------------

locals {
  project     = var.project
  environment = var.environment

  gcp_project = (var.gcp_project == null ? null : (length(var.gcp_project) > 0 ? var.gcp_project : null))

  # Startpoint for our repository defaults
  module_repository_defaults = {
    owner        = var.owner
    location     = "europe-west4"
    format       = "DOCKER"
    description  = "Terrafrom managed repository"
    labels       = {}
    kms_key_name = null
    roles        = null
  }

  # Merge module defaults with the user provided defaults
  repository_defaults = var.repository_defaults == null ? local.module_repository_defaults : merge(local.module_repository_defaults, var.repository_defaults)

  labels = {
    "project" = substr(replace(lower(local.project), "/[^\\p{Ll}\\p{Lo}\\p{N}_-]+/", "_"), 0, 63)
    "env"     = substr(replace(lower(local.environment), "/[^\\p{Ll}\\p{Lo}\\p{N}_-]+/", "_"), 0, 63)
    "creator" = "terraform"
  }

  # Merge repository global default settings with repository specific settings and generate repository_id
  # Example generated repository_id: "data-dev-myapp"
  repositories = {
    for repository, settings in var.repositories : repository => merge(
      local.repository_defaults,
      {
        description = format("Terrafrom managed repository - %s %s", try(settings.format, local.repository_defaults.format), repository)
      },
      settings,
      {
        repository_id = replace(lower(repository), " ", "-")
        roles         = { for role, members in try(settings.roles, {}) : role => [for member, type in members : format("%s:%s", type, member)] }
        labels = merge(
          local.labels,
          {
            purpose = substr(replace(lower(repository), "/[^\\p{Ll}\\p{Lo}\\p{N}_-]+/", "_"), 0, 63)
            owner   = substr(replace(lower(try(settings.owner, local.repository_defaults.owner)), "/[^\\p{Ll}\\p{Lo}\\p{N}_-]+/", "_"), 0, 63)
          },
          try(settings.labels, {})
        )
      }
    )
  }
}

#---------------------------------------------------------------------------------------------
# GCP Resources
#---------------------------------------------------------------------------------------------

resource "google_artifact_registry_repository" "map" {
  provider = google-beta
  project  = local.gcp_project

  for_each = local.repositories

  location      = each.value.location
  repository_id = each.value.repository_id
  description   = each.value.description
  format        = each.value.format
  labels        = each.value.labels
}

data "google_iam_policy" "map" {
  for_each = { for repository, settings in local.repositories : repository => settings if settings.roles != null }

  dynamic "binding" {
    for_each = each.value.roles

    content {
      role    = binding.key
      members = binding.value
    }
  }
}

resource "google_artifact_registry_repository_iam_policy" "map" {
  provider = google-beta
  project  = local.gcp_project

  for_each = data.google_iam_policy.map

  repository = google_artifact_registry_repository.map[each.key].name
  location   = google_artifact_registry_repository.map[each.key].location

  policy_data = each.value.policy_data
}
