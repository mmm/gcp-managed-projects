
#terraform {
  #backend "gcs" {}
#}
provider "google" {
  region      = "${var.region}"
}

###################
# IAM role setup
###################
#
# In your billing org:
# - `billing_account_user` needs to be able to create billing accounts within
#   the billing org.  I'm not sure if they need to be a
#   `BillingAccountAdministrator` for the billing account within the billing org.
#
# In your gsuite org:
# - `gsuite_user` needs to be an `OrganizationAdministrator`
# - `billing_account_user` needs to be:
#     - a `BillingAccountAdministrator`
#     - a `ProjectCreator`
#     - and I added it as an `OrganizationAdministrator` for good measure
#

resource "google_project" "project_in_billing_folder" {
  name       = "mmm-yyyy-3"
  project_id = "mmm-yyyy-3"

  folder_id = "${var.billing_folder_id}"
  billing_account = "${var.billing_account_id}"
}

resource "google_project" "gsuite_project" {
  name       = "mmm-ad-zzzz-3"
  project_id = "mmm-ad-zzzz-3"

  org_id = "${var.gsuite_org_id}"
  billing_account = "${var.billing_account_id}"
}

resource "google_project_iam_binding" "gsuite_project_owner" {
  project = "${google_project.gsuite_project.project_id}"
  role    = "roles/owner"

  members = [
    "user:${var.gsuite_user}",
    "user:${var.billing_account_user}",
  ]
}
