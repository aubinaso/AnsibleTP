variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "virtual_machine_name" {
  type = string
}

variable "virtual_machine_size" {
  type    = string
  default = "Standard_F2"
}

variable "credentials" {
  type = object({
    username = string
    password = string
  })
}