variable "azure_rbac_group_object_id" {
  description = "GUID of the AKS admin Group"
  default     = "15390134-7115-49f3-8375-da9f6f608dce"
}

variable "location" {
  default     = "southcentralus"
  description = "Azure Region"
}

variable "vnet_address" {
  default     = "10.16"
  description = "First two octets of the Azure virtual network"
}