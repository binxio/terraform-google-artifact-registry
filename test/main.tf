locals {
  owner       = "myself"
  project     = "testapp"
  company     = "mycompany"
  environment = var.environment
  test_sas = {
    "reader" = format("reader-%s", replace(local.environment, " ", "-"))
    "owner"  = format("owner-%s", replace(local.environment, " ", "-"))
  }
}

resource "google_service_account" "map" {
  for_each = local.test_sas

  account_id   = each.value
  display_name = format("%s Terraform Test", each.value)
  description  = "Service Account to test assignment of repository roles"
}
