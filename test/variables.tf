variable "environment" {
  description = "Environment for which the resources are created (e.g. dev, tst, acc or prd)"
  type        = string
}
variable "owner" {
  description = "Owner used for tagging"
  type        = string
}
variable "location" {
  description = "Allows us to use random location for our tests"
  type        = string
}
variable "sa_reader_email" {
  description = "The Reader SA used for testing bucket role assignment"
  type        = string
  default     = ""
}
variable "sa_owner_email" {
  description = "The Owner SA used for testing bucket role assignment"
  type        = string
  default     = ""
}
