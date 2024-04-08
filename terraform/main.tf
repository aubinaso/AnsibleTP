module "rg" {
  source   = "./modules/resource_group"
  name     = var.general.rg_name
  location = var.general.location
}

module "virtual_network" {
  source               = "./modules/network"
  resource_group_name  = module.rg.resource_group_name
  virtual_network_name = var.general.virtual_network_name
  location             = var.general.location
  subnet_name          = var.general.subnet_name
  subnet_prefix        = var.general.subnet_prefix
  address_space        = var.general.address_space
}

module "virtual_machine" {
  count                = 2
  source               = "./modules/virtual_machine"
  resource_group_name  = module.rg.resource_group_name
  subnet_id            = module.virtual_network.subnet_id
  location             = var.general.location
  virtual_machine_name = "${var.general.virtual_machine_name}-${count.index}"
  virtual_machine_size = var.general.virtual_machine_size
  credentials          = var.general.credentials
  publicIPName          = "myPublicIp-${count.index}"
}
