general = {
  rg_name  = "RG-AUBIN"
  location = "North Europe"

  virtual_network_name = "testvnet"
  address_space        = ["10.0.0.0/16"]
  subnet_prefix        = ["10.0.1.0/24"]
  subnet_name          = "testsubnet"

  virtual_machine_name = "testaubin"
  virtual_machine_size = "Standard_D2s_v3"

  credentials = {
    username = "aubin"
    password = "P@ssw0rd1234P@ssw0rd1234P@ssw0rd1234"
  }
}