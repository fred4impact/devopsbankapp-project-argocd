variable "vpc-name" {}
variable "igw-name" {}
variable "rt-name" {}
variable "subnet-name" {}
variable "sg-name" {}
variable "instance-name" {}
variable "key-name" {}
variable "iam-role" {}
# Variables



variable "eks-cluster-name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "main-cluster"
}

variable "eks-node-desired-size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "eks-node-max-size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "eks-node-min-size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "eks-node-instance-type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t2.medium"
}
variable "eks-node-volume-size" {
  description = "EBS volume size for worker nodes"
  type        = number
  default     = 20
}
variable "eks-node-volume-type" {
  description = "EBS volume type for worker nodes"
  type        = string
  default     = "gp2"
}
variable "eks-node-ami" {
  description = "AMI ID for worker nodes"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Example AMI ID, replace with your own
}
variable "eks-node-key-name" {
  description = "Key pair name for SSH access to worker nodes"
  type        = string
  default     = "ec2-aws-key" # Replace with your key pair name
}
