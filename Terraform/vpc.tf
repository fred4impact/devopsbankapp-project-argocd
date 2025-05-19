
# VPC Resources
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.vpc-name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.igw-name
  }
}

resource "aws_subnet" "public-subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.subnet-name}-${count.index}"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.rt-name
  }
}

resource "aws_route_table_association" "rt-association" {
  count          = 2
  subnet_id      = aws_subnet.public-subnet[count.index].id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "security-group" {
  vpc_id      = aws_vpc.vpc.id
  description = "Allowing Jenkins, Sonarqube, Nexus, SSH Access"

  dynamic "ingress" {
    for_each = [
      { port = 22, description = "SSH Access" },
      { port = 80, description = "HTTP Access" },
      { port = 8080, description = "Jenkins Access" },
      { port = 8081, description = "Nexus Repository Access" },
      { port = 9000, description = "Sonarqube Access" },
      { port = 9090, description = "Prometheus Access" }
    ]
    content {
      description      = ingress.value.description
      from_port        = ingress.value.port
      to_port          = ingress.value.port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      self             = false
      prefix_list_ids  = []
      security_groups  = []
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg-name
  }
}

# EKS Cluster Resources
resource "aws_security_group" "eks_cluster_sg" {
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.sg-name}-eks-cluster"
  }
}

resource "aws_security_group" "eks_node_sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.sg-name}-eks-node"
  }
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.eks-cluster-name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.public-subnet[*].id
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_role_policy
  ]
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.eks-cluster-name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = aws_subnet.public-subnet[*].id

  scaling_config {
    desired_size = var.eks-node-desired-size
    max_size     = var.eks-node-max-size
    min_size     = var.eks-node-min-size
  }

  instance_types = [var.eks-node-instance-type]

  remote_access {
    ec2_ssh_key               = var.key-name
    source_security_group_ids = [aws_security_group.eks_node_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group_role_policy,
    aws_iam_role_policy_attachment.eks_node_group_cni_policy,
    aws_iam_role_policy_attachment.eks_node_group_registry_policy
  ]
}

# IAM Roles for EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.eks-cluster-name}-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.eks-cluster-name}-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_node_group_role_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_group_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_group_registry_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

