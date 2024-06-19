data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }

}

resource "aws_iam_role" "eks_role" {
  name               = "eks-cluster-cloud"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "AmazonPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

#Networking VPC SUBNETS

data "aws_vpc" "vpc" {
  default = true
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

#EKS

resource "aws_eks_cluster" "cluster" {
  name     = "EKS_Cloud"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = ["subnet-0eebc86e1a8fee8be","subnet-00ada1410150ee356","subnet-053f76494c132e390"]
  }
  depends_on = [aws_iam_role_policy_attachment.AmazonPolicy]
}

#Node creation

resource "aws_iam_role" "noderole" {
  name = "eks-node-group-cloud"
  assume_role_policy = jsonencode({
    Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal ={
            Service = "ec2.amazonaws.com"
        }
    }]
    Version = "2012-10-17"
  })
}


resource "aws_iam_role_policy_attachment" "policy1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.noderole.name
}

resource "aws_iam_role_policy_attachment" "policy2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.noderole.name
}

resource "aws_iam_role_policy_attachment" "policy3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.noderole.name
}

#Create a Node Group 

resource "aws_eks_node_group" "nodegroup" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "Node-Cloud"
  node_role_arn   = aws_iam_role.noderole.arn
  subnet_ids      = ["subnet-0eebc86e1a8fee8be","subnet-00ada1410150ee356","subnet-053f76494c132e390"]
  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }
  instance_types = ["t2.medium"]
  depends_on = [aws_iam_role.noderole,
    aws_iam_role_policy_attachment.policy1,
    aws_iam_role_policy_attachment.policy2,
  aws_iam_role_policy_attachment.policy3]
}