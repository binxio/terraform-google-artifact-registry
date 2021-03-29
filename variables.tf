#------------------------------------------------------------------------------------------------------------------------
# 
# Generic variables
#
#------------------------------------------------------------------------------------------------------------------------
variable "owner" {
  description = "Owner of the resource. This variable is used to set the 'owner' label. Will be used as default for each repository, but can be overridden using the repository settings."
  type        = string
}

variable "project" {
  description = "Company project name."
  type        = string
}

variable "environment" {
  description = "Company environment for which the resources are created (e.g. dev, tst, acc, prd, all)."
  type        = string
}

variable "gcp_project" {
  description = "GCP Project ID override - this is normally not needed and should only be used in tf-projects."
  type        = string
  default     = null
}

#------------------------------------------------------------------------------------------------------------------------
#
# Repository variables
#
#------------------------------------------------------------------------------------------------------------------------

variable "repositories" {
  description = <<EOF
Map of repositories to be created. The key will be used for the repository name so it should describe the repository purpose. The value can be a map with the following keys to override default settings:
  * owner
  * location
  * format
  * description
  * roles
  * labels
  * kms_key_name
EOF
  type        = any
}

variable "repository_defaults" {
  description = "Default settings to be used for your repositories so you don't need to provide them for each repository seperately."
  type = object({
    owner        = string
    location     = string
    format       = string
    description  = string
    roles        = map(map(string))
    labels       = map(string)
    kms_key_name = string
  })
  default = null
}
