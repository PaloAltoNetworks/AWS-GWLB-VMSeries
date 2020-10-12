
# ---------------------------------------------------------------------------------------------------------------------
# CREATE NETWORK INTERFACES
# 1 NETWORK INTERFACES (APP)
# 1 EIP (APP)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_network_interface" "app-eni" {
  subnet_id         = aws_subnet.app_subnet.id
  security_groups   = [aws_security_group.app-sg.id]
  source_dest_check = "false"
  tags = {
    Name = "app-eni-${random_id.deployment_id.hex}"
  }
}

resource "aws_eip" "app-mgmt-eip" {
  vpc               = true
  network_interface = aws_network_interface.app-eni.id
  tags = {
    Name = "app-mgmt-eip-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_instance.app_instance]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE WEB SERVER INSTANCE
# 1 SSH KEY
# 1 UBUNTU INSTANCE WITH APACHE RUNNING
# ---------------------------------------------------------------------------------------------------------------------

# Config SSH KEY for instance login
resource "aws_key_pair" "app-ssh-keypair" {
  key_name   = "ssh-key-${random_id.deployment_id.hex}"
  public_key = var.public_key
}

resource "aws_instance" "app_instance" {
  ami        = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type

  network_interface {
    network_interface_id = aws_network_interface.app-eni.id
    device_index         = 0
  }
  user_data = file("web_server.sh")
  key_name        = aws_key_pair.app-ssh-keypair.key_name
  tags = {
    Name = "app-${random_id.deployment_id.hex}"
  }
}