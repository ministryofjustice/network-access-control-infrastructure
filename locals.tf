locals {

  ## for resources which requires the tags map without the "Name" value
  ## It uses the "name" attribute internally and concatenates with other attributes
  tags_minus_name = { for k, v in module.label.tags : k => v if !contains(["Name"], k) }
}
