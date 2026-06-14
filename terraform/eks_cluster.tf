resource "aws_eks_cluster" "argocd_sandbox" {
  name = "argocd_sandbox"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.eks_role.arn
  version  = "1.35"

  vpc_config {
    subnet_ids = [aws_subnet.private.id, aws_subnet.private_2.id]
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

resource "aws_iam_role" "eks_role" {
  name = "argocd_sandbox"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.argocd_sandbox.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.argocd_sandbox.name
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.argocd_sandbox] # Needs nodes to run on!
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.argocd_sandbox.name
  addon_name   = "kube-proxy"
}

# add on the pod identity agent for IRSA support, which is required for ArgoCD to manage AWS resources on the cluster
resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.argocd_sandbox.name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [aws_eks_node_group.argocd_sandbox]
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.argocd_sandbox.name}"
}
