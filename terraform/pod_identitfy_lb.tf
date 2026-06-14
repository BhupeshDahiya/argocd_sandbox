# local HTTP call to fetch the official JSON for AWS Load Balancer Controller IAM Policy
data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

# 2. create a local IAM policy resource using the fetched JSON
resource "aws_iam_policy" "lb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "Official IAM Policy for AWS Load Balancer Controller"
  policy      = data.http.lbc_iam_policy.response_body
}

# 3. Create IAM role for AWS Load Balancer Controller using EKS Pod Identity
resource "aws_iam_role" "lb_controller" {
  name = "AmazonEKSLoadBalancerControllerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

# 4. Attach the LB permissions policy to the IAM Role
resource "aws_iam_role_policy_attachment" "lb_controller_attach" {
  policy_arn = aws_iam_policy.lb_controller.arn
  role       = aws_iam_role.lb_controller.name
}

# 5. Create EKS Pod Identity association
resource "aws_eks_pod_identity_association" "lb_controller" {
  cluster_name    = aws_eks_cluster.argocd_sandbox.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.lb_controller.arn
}