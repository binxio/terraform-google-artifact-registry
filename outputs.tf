output "repository_defaults" {
  description = "The generic defaults used for repository settings"
  value       = local.module_repository_defaults
}

output "map" {
  description = "outputs for all google_artifact_registry_repositories created"
  value       = google_artifact_registry_repository.map
}
