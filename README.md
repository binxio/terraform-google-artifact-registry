
# Module `terraform-google-artifact-registry`

Core Version Constraints:
* `>= 0.14`

Provider Requirements:
* **google (`hashicorp/google`):** (any version)
* **google-beta (`hashicorp/google-beta`):** (any version)

## Input Variables
* `environment` (required): Company environment for which the resources are created (e.g. dev, tst, acc, prd, all).
* `gcp_project` (default `null`): GCP Project ID override - this is normally not needed and should only be used in tf-projects.
* `owner` (required): Owner of the resource. This variable is used to set the 'owner' label. Will be used as default for each repository, but can be overridden using the repository settings.
* `project` (required): Company project name.
* `repositories` (required): Map of repositories to be created. The key will be used for the repository name so it should describe the repository purpose. The value can be a map with the following keys to override default settings:
  * owner
  * location
  * format
  * description
  * roles
  * labels
  * kms_key_name

* `repository_defaults` (default `null`): Default settings to be used for your repositories so you don't need to provide them for each repository seperately.

## Output Values
* `map`: outputs for all google_artifact_registry_repositories created
* `repository_defaults`: The generic defaults used for repository settings

## Managed Resources
* `google_artifact_registry_repository.map` from `google-beta`
* `google_artifact_registry_repository_iam_policy.map` from `google-beta`

## Data Resources
* `data.google_iam_policy.map` from `google`

## Creating a new release
After adding your changed and committing the code to GIT, you will need to add a new tag.
```
git tag vx.x.x
git push --tag
```
If your changes might be breaking current implementations of this module, make sure to bump the major version up by 1.

If you want to see which tags are already there, you can use the following command:
```
git tag --list
```
Required APIs
=============
For the Storage Buckets to deploy, the following APIs should be enabled in your project:
 * `iam.googleapis.com`
 * `storage.googleapis.com`

Testing
=======
This module comes with [terratest](https://github.com/gruntwork-io/terratest) scripts for both unit testing and integration testing.
A Makefile is provided to run the tests using docker, but you can also run the tests directly on your machine if you have terratest installed.

### Run with make
Make sure to set GOOGLE_CLOUD_PROJECT to the right project and GOOGLE_CREDENTIALS to the right credentials json file
You can now run the tests with docker:
```
make test
```

### Run locally
From the module directory, run:
```
cd test && TF_VAR_owner=$(id -nu) go test
```
