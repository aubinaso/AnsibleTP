variable "general" {
  type = object({
    rg_name  = string
    location = string

    virtual_network_name = string
    address_space        = list(string)
    subnet_prefix        = list(string)
    subnet_name          = string

    virtual_machine_name = string
    virtual_machine_size = string

    credentials = object({
      username = string
      password = string
    })
  })
}