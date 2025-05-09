#-------------------------------------------------------
# Includes Block 
#-------------------------------------------------------

include "cloud" {
  path   = find_in_parent_folders("locals-cloud.hcl")
  expose = true
}

include "env" {
  path   = find_in_parent_folders("locals-env.hcl")
  expose = true
}

#-------------------------------------------------------
# Locals 
#-------------------------------------------------------
locals {
  region_context = "primary"
  region = local.region_context == "primary" ? include.cloud.locals.region.primary : include.cloud.locals.region.secondary
  deployment_name = "terraform-${include.env.locals.name_abr}-deploy-shared-base-${local.region_context}"

  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      ManagedBy = "terraform"
    }
  )
}