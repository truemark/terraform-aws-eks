variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "release_name" {
  type        = string
  default     = "aws-efs-csi-driver"
  description = "The name of the aws-efs-csi-driver helm release"
}

variable "chart_version" {
  type        = string
  default     = "3.0.8"
  description = "The version of aws-efs-csi-driver chart"
}

variable "chart_name" {
  type        = string
  default     = "aws-efs-csi-driver"
  description = "Helm chart name"
}

variable "helm_repo_name" {
  type        = string
  description = "Helm repository url"
  default     = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
}

variable "oidc_issuer_url" {
  type        = string
  description = "OIDC issuer url"
}

variable "storage_classes" {
  description = "List of objects defining storage classes to create. EFS volumes have to be created outside of this module. EFS Security groups need to allow access for EKS workers"
  type = list(object({
    name                  = string
    fileSystemId          = string
    provisioningMode      = optional(string, "efs-ap")
    reclaim_policy        = optional(string, "Retain")
    directoryPerms        = optional(string, "700")
    gidRangeStart         = optional(string, "1000")
    gidRangeEnd           = optional(string, "2000")
    basePath              = optional(string, "/")
    ensureUniqueDirectory = optional(bool, true)
    reuseAccessPoint      = optional(bool, false)
  }))

  validation {
    condition     = length(var.storage_classes) > 0
    error_message = "At least one storage class needs to be specifyed"
  }

  validation {
    condition     = alltrue([for sc in var.storage_classes : sc.provisioningMode == "efs-ap"])
    error_message = "The provisioningMode must be 'efs-ap' for all storage classes."
  }

  validation {
    condition     = alltrue([for sc in var.storage_classes : can(regex("^fs-[0-9a-f]+$", sc.fileSystemId))])
    error_message = "The EFS fileSystemId must be a valid EFS File System ID (starting with 'fs-')."
  }

  validation {
    condition     = alltrue([for sc in var.storage_classes : can(regex("^[0-7]{3}$", sc.directoryPerms))])
    error_message = "The directoryPerms must be a valid UNIX permission (e.g., '700' or '755')."
  }

  validation {
    condition     = alltrue([for sc in var.storage_classes : tonumber(sc.gidRangeStart) < tonumber(sc.gidRangeEnd)])
    error_message = "The gidRangeStart must be less than gidRangeEnd."
  }

  validation {
    condition     = alltrue([for sc in var.storage_classes : sc.reclaim_policy == "Retain" || sc.reclaim_policy == "Delete"])
    error_message = "The reclaim_policy must be either 'Retain' or 'Delete'."
  }
}
