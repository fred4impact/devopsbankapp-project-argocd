resource "aws_instance" "ec2" {
  count                       = 1
  ami                         = data.aws_ami.ami.image_id
  instance_type               = "t2.2xlarge"
  key_name                    = var.key-name
  subnet_id                   = aws_subnet.public-subnet[count.index].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.security-group.id]
  iam_instance_profile        = aws_iam_instance_profile.instance-profile.name
  root_block_device {
    volume_size = 30
  }
  user_data = templatefile("./tools-install.sh", {})

  tags = {
    Name = "${var.instance-name}-${count.index}"
  }
}
