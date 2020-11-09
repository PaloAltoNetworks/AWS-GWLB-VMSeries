
# ---------------------------------------------------------------------------------------------------------------------
# CREATE NETWORK INTERFACES
# 2 NETWORK INTERFACES (MGMT and DATA) for each AZ
# 1 EIP (MGMT) for each  AZ
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_network_interface" "fw-mgmt-eni" {
  count = length(var.availability_zones)
  subnet_id         = aws_subnet.sec_mgmt_subnet[count.index].id
  security_groups   = [aws_security_group.fw-mgmt-sg.id]
  source_dest_check = "false"
  tags = {
    Name = "fw-mgmt-eni-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }
}

resource "aws_network_interface" "fw-data-eni" {
  count = length(var.availability_zones)
  subnet_id         = aws_subnet.sec_data_subnet[count.index].id
  security_groups   = [aws_security_group.fw-data-sg.id]
  source_dest_check = "false"
  tags = {
    Name = "fw-data-eni-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }
}

resource "aws_eip" "fw-mgmt-eip" {
  count = length(var.availability_zones)
  vpc               = true
  network_interface = aws_network_interface.fw-mgmt-eni[count.index].id
  tags = {
    Name = "fw-mgmt-eip-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }
  depends_on = [aws_network_interface.fw-mgmt-eni, aws_instance.firewall_instance]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE PREREQUISITES FOR FIREWALL
# 1 SSH KEY
# 1 IAM ROLE WITH POLICY
# 1 IAM INSTANCE PROFILE
# ---------------------------------------------------------------------------------------------------------------------

# Config SSH KEY for instance login
resource "aws_key_pair" "fw-ssh-keypair" {
  key_name   = "ssh-key-${random_id.deployment_id.hex}"
  public_key = var.public_key
}

# Config IAM role with policy
resource "aws_iam_role" "fw-iam-role" {
  name               = "iam-role-${random_id.deployment_id.hex}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy" "fw-iam-policy" {
  name = "iam-policy-${random_id.deployment_id.hex}"
  path = "/"
  description = "IAM Policy for VM-Series Firewall"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Action": "s3:ListBucket",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "s3:GetObject",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ec2:AttachNetworkInterface",
                "ec2:DetachNetworkInterface",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "policy-attachment" {
  role       = aws_iam_role.fw-iam-role.name
  policy_arn = aws_iam_policy.fw-iam-policy.arn
}

resource "aws_iam_instance_profile" "iam-instance-profile" {
  name = "iam-profile-${random_id.deployment_id.hex}"
  role = aws_iam_role.fw-iam-role.name
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE FIREWALL INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "firewall_instance" {
  count = length(var.availability_zones)
  ami        = var.firewall_ami_id
  instance_type   = var.instance_type

  network_interface {
    network_interface_id = aws_network_interface.fw-data-eni[count.index].id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.fw-mgmt-eni[count.index].id
    device_index         = 1
  }
  iam_instance_profile = aws_iam_instance_profile.iam-instance-profile.id
  user_data = "mgmt-interface-swap=enable\nplugin-op-commands=aws-gwlb-inspect:enable\n${var.user_data}"

  key_name        = aws_key_pair.fw-ssh-keypair.key_name
  tags = {
    Name = "FW-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
  }
}
