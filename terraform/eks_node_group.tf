resource "aws_eks_node_group" "argocd_sandbox" {
  cluster_name    = aws_eks_cluster.argocd_sandbox.name
  node_group_name = "argocd_sandbox"
  node_role_arn   = aws_iam_role.argocd_sandbox.arn
  subnet_ids      = data.aws_subnets.default.ids

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.argocd_sandbox-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.argocd_sandbox-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.argocd_sandbox-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "argocd_sandbox" {
  name = "eks-node-group-argocd_sandbox"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "argocd_sandbox-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.argocd_sandbox.name
}

resource "aws_iam_role_policy_attachment" "argocd_sandbox-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.argocd_sandbox.name
}

resource "aws_iam_role_policy_attachment" "argocd_sandbox-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.argocd_sandbox.name
}