data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["*ubuntu-xenial-16.04-amd64-server*"]
  }
}

# Let the instance read (only) the assets bucket - no access keys on the box.
resource "aws_iam_role" "web" {
  name = "${var.project}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "read_assets" {
  name = "read-assets"
  role = aws_iam_role.web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.assets.arn}/site/*"
    }]
  })
}

resource "aws_iam_instance_profile" "web" {
  name = "${var.project}-profile"
  role = aws_iam_role.web.name
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.web.name

  user_data = <<-EOT
    #!/bin/bash
    apt-get update -y && apt-get install -y nginx awscli
    aws s3 cp s3://${aws_s3_bucket.assets.bucket}/site/index.html /var/www/html/index.html
    systemctl enable --now nginx
  EOT

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = { Name = "${var.project}-server" }

  # Nothing in the arguments above references the route table association, so
  # Terraform could boot the instance before the subnet has a route to the
  # internet - and user_data's apt-get would fail. This makes the order explicit.
  depends_on = [aws_route_table_association.public, aws_s3_object.index]
}
