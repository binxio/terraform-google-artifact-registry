#######################################################################################################
#
# Terraform does not have a easy way to check if the input parameters are in the correct format.
# On top of that, terraform will sometimes produce a valid plan but then fail during apply.
# To handle these errors beforehad, we're using the 'file' hack to throw errors on known mistakes.
#
#######################################################################################################
locals {
  # Regular expressions
  regex_repository_id = "(([a-z0-9]|[a-z0-9][a-z0-9\\-]*[a-z0-9])\\.)*([a-z0-9]|[a-z0-9][a-z0-9\\-]*[a-z0-9])"

  # Terraform assertion hack
  assert_head = "\n\n-------------------------- /!\\ ASSERTION FAILED /!\\ --------------------------\n\n"
  assert_foot = "\n\n-------------------------- /!\\ ^^^^^^^^^^^^^^^^ /!\\ --------------------------\n"
  asserts = {
    for repository, settings in local.repositories : repository => merge({
      repositoryname_too_long = length(settings.repository_id) > 63 ? file(format("%srepository [%s]'s generated name is too long:\n%s\n%s > 63 chars!%s", local.assert_head, repository, settings.repository_id, length(settings.repository_id), local.assert_foot)) : "ok"
      repositoryname_regex    = length(regexall("^${local.regex_repository_id}$", settings.repository_id)) == 0 ? file(format("%srepository [%s]'s generated name [%s] does not match regex ^%s$%s", local.assert_head, repository, settings.repository_id, local.regex_repository_id, local.assert_foot)) : "ok"
      keytest = {
        for setting in keys(settings) : setting => merge(
          {
            keytest = lookup(local.repository_defaults, setting, "!TF_SETTINGTEST!") == "!TF_SETTINGTEST!" ? file(format("%sUnknown repository variable assigned - repository [%s] defines [%q] -- Please check for typos etc!%s", local.assert_head, repository, setting, local.assert_foot)) : "ok"
        }) if setting != "repository_id"
      }
    })
  }
}
