output "sa_reader_email" {
  value = google_service_account.map["reader"].email
}
output "sa_owner_email" {
  value = google_service_account.map["owner"].email
}
