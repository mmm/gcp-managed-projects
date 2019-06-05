# Projects in GCP using Central Billing Accounts

Many organizations recognize the benefits of empowering their developers. In a
cloud environment, that often means giving developers the ability to create and
manage their own infrastructure.

Of course, developers can easily create their own individual or G-Suite GCP
accounts.  They can take advantage of the free trial that Google Cloud offers.
That's great, and everything's hunky-dory until the credit runs out. What then?

In this post I describe a really simple way to set up and use centralized
billing on GCP... even across external development accounts.  Way better than
trying to get me to fill out expense reports for infradev!

<!--more-->

## Contents

- Organizations and account setup
- Users and IAM roles
- Terraform templates
- Try it out


## Organizations and account setup

Let's consider a common example with two separate organizations in the mix.

1. A `bigcorp.com` organization that's footing the bill for everything

2. An individual developer's G-Suite organization, `pinkponies.io`, where
   we'll be doing the development

In this example, we're assuming the developer organization `pinkponies.io` is a
full G-Suite account and not just an ordinary GCP account created using a
single email.

It's easy for an individual developer to create a new G-Suite account and that
turns out to be the more typical situation for this kind of cross billing
example. I also really recommend using developer G-Suite accounts for cloud
development in general since they'll have the same IAM capabilities and
concerns as the `bigcorp.com` account.


## Users and IAM roles

Each developer will need accounts in both orgs to start with.

Take Sam for example. Sam's already an Owner of `pinkponies.io`...  with
`sam@pinkponies.io` as a login.

Sam works for BigCorp and is also `sam@bigcorp.com` where they live in some
folder within the `bigcorp.com` organization's GCP IAM.

### In your billing org: `bigcorp.com`

So the `billing_account_user` (`sam@bigcorp.com`) needs to be able to create
billing accounts within the BigCorp org.

Sam will need to be assigned a `BillingAccountCreator` role within the
`bigcorp.com` org's IAM on GCP.


### In your gsuite org: `pinkponies.io`

It's no surprise, the `gsuite_user` (`sam@pinkponies.io`) needs to be an
`OrganizationAdministrator` on that org.

The `billing_account_user` (`sam@bigcorp.com`) needs permissions on the
`pinkponies.io` org too. They need to be:

- a `BillingAccountAdministrator` for the `pinkponies.io` org
- a `ProjectCreator` on the `pinkponies.io` org
- and I added them as an `OrganizationAdministrator` on `pinkponies.org` for
  good measure


## Terraform templates

I like to manage infrastructure using [Terraform](terraform.io) and keep
all my templates and modules checked into GitHub.

The Terraform templates to create these projects are super simple. There's a
provider, a resource for the managed project we want to create, and then a
couple of role binding resources

```
provider "google" {
  region      = "${var.region}"
}

resource "google_project" "gsuite_project" {
  name       = "gsuite-project-0"
  project_id = "gsuite-project-0"

  org_id = "${var.gsuite_org_id}"
  billing_account = "${var.billing_account_id}"
}

resource "google_project_iam_binding" "gsuite_project_owner" {
  project = "gsuite-project-0"
  role    = "roles/owner"

  members = [
    "user:${var.gsuite_user}",
    "user:${var.billing_account_user}",
  ]
}
```

There's no need to get Terraform to slurp in data sources for the GCP orgs,
folders, billing accounts, etc. In this example, we'll just create variables
for them

```
variable "region" {
  default = "us-central1"
}

variable "billing_account_user" {}
variable "billing_folder_id" {}
variable "billing_account_id" {}

variable "gsuite_user" {}
variable "gsuite_org_id" {}
```

and look up the values from the cloud consoles for both our `bigcorp.com` and
`pinkponies.io` accounts.  We'll add these to `terraform.tfvars`

```
billing_account_user = "sam@bigcorp.com"
billing_folder_id = "234567890123" # my-billing-folder
billing_account_id = "aaaaaa-bbbbbb-cccccc" # my-billing-account

gsuite_user = "sam@pinkponies.io"
gsuite_org_id = "345678901234" # pinkponies.io
```

Note that there's a `terraform.tfvars.template` included in the example repo
but the actual `*.tfvars` files, with sensitive account details, are ignored by
revision control so you'll have to copy the template and create your own
`terraform.tfvars`.


## Try it out

### Example repo

You can clone and configure the example templates

- clone <https://github.com/mmm/gcp-managed-projects>
- copy the tfvars template over to `terraform.tfvars` and edit it with your info


### `gcloud`

Terraform's provider for GCP needs GCP credentials for your account.  The
easiest thing to do to get that working before trying to run Terraform is to
make sure gcloud is working correctly.

You can do that by installing gcloud and running `gcloud init` to go through
the oauth dance... that works.  You'd need to export your
`GOOGLE_APPLICATION_CREDENTIALS` as well... usual stuff.

However, as an easier alternative, use the cloud shell in the cloud console for
your `bigcorp.com` equivalent account.  The gcloud config and applcation
credentials are all already set up for you.

Side note: The cloud shell is _really_ useful... check it out if you haven't!

Make sure you're driving terraform using credentials (your `gcloud` config)
from the equivalent of your `bigcorp.com` account and _not_ your
`pinkponies.io` G-Suite org account.


### Terraform

Download Terraform from <https://terraform.io/>.  Terraform is a standalone
binary so it's simple to install... even in your GCP Cloud Shell.

Init terraform's providers and state management

    terraform init

Then check out what changes we're _plan_ning to make

    terraform plan

If all looks good from there, then _apply_ that plan to actually create our
project

    terraform apply

Check out the project we just created

    gcloud beta billing projects list --billing-account=<billing_account_id>

Check out the same project from the Cloud Console for your `pinkponies.io`
G-Suite account.

Now you can use that account within your `pinkponies.io` G-Suite account and
any charges go straight to your BigCorp billing account.

### Cleanup

When you're all done, you can clean up after yourself by removing the project
and role bindings we created

    terraform destroy

then deleting the billing account through the Cloud Console.  You could (and
should) totally manage the billing accounts themselves in the bigcorp.org using
Terraform templates as well, but that's another story.

## Disclaimer

No big corps or pink ponies were harmed in the production of this post.
