# ---------------------------------------------------------------------------------------------------------------------
# CREATE SECURITY GROUPS
# 1 SGs (APP)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "app-sg" {
  name        = "app-data-sg-${random_id.deployment_id.hex}"
  description = "Allow inbound traffic only from Palo Alto Networks"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.app_mgmt_sg_list
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "app-sg-${random_id.deployment_id.hex}"
  }

  depends_on = [aws_vpc.app_vpc]
}