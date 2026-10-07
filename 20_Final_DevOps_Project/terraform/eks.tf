# EKS control plane + managed node group in the private subnets.
# Disabled by default because LocalStack community does not emulate EKS (it is a Pro feature);
# `terraform plan -var enable_eks=true` still validates and plans it.
locals {
  eks_count = var.enable_eks ? 1 : 0
}

data "aws_iam_policy_document" "eks_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "node_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  count              = local.eks_count
  name               = "${var.project}-eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_trust.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  count      = local.eks_count
  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_nodes" {
  count              = local.eks_count
  name               = "${var.project}-eks-nodes"
  assume_role_policy = data.aws_iam_policy_document.node_trust.json
}

resource "aws_iam_role_policy_attachment" "eks_nodes" {
  for_each = var.enable_eks ? toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]) : toset([])
  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = each.value
}

resource "aws_eks_cluster" "main" {
  count    = local.eks_count
  name     = "${var.project}-${var.environment}"
  version  = var.eks_version
  role_arn = aws_iam_role.eks_cluster[0].arn

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    security_group_ids      = [aws_security_group.nodes.id]
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

resource "aws_eks_node_group" "main" {
  count           = local.eks_count
  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.eks_nodes[0].arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  depends_on = [aws_iam_role_policy_attachment.eks_nodes]
}
