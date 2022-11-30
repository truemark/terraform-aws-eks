#######################
# Public loadbalancer #
#######################

resource "aws_lb" "public" {
  count              = var.public_alb ? 1 : 0
  name               = "${var.cluster_name}-public"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_alb[0].id]
  subnets            = var.public_subnets

  tags = var.tags
}

# Security Group
resource "aws_security_group" "public_alb" {
  count  = var.public_alb ? 1 : 0
  name   = "${var.cluster_name}-public-alb"
  vpc_id = var.vpc_id

  tags = var.tags
}

# Security Group Rules
resource "aws_security_group_rule" "public_alb_ingress_80" {
  count             = var.public_alb ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.public_alb[0].id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_alb_ingress_443" {
  count             = var.public_alb ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.public_alb[0].id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_alb_egress_allow_all" {
  count             = var.public_alb ? 1 : 0
  type              = "egress"
  security_group_id = aws_security_group.public_alb[0].id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_alb_ingress_80_worker" {
  count                    = var.public_alb ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public_alb[0].id
  security_group_id        = module.eks.node_security_group_id
  description              = "Rule to allow ALB to worker node group"
}

resource "aws_security_group_rule" "public_alb_ingress_443_worker" {
  count                    = var.public_alb ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public_alb[0].id
  security_group_id        = module.eks.node_security_group_id
  description              = "Rule to allow ALB to worker node group"
}

########################
# Private loadbalancer #
########################

resource "aws_lb" "private" {
  count              = var.private_alb ? 1 : 0
  name               = "${var.cluster_name}-private"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.private_alb[0].id]
  subnets            = var.private_subnets

  tags = var.tags
}

# Security Group
resource "aws_security_group" "private_alb" {
  count  = var.private_alb ? 1 : 0
  name   = "${var.cluster_name}-private-alb"
  vpc_id = var.vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "private_alb_allow_80_worker" {
  count                    = var.private_alb ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private_alb[0].id
  security_group_id        = module.eks.node_security_group_id
  description              = "Rule to allow public ALB to worker node group"
}

resource "aws_security_group_rule" "private_alb_allow_443_worker" {
  count                    = var.private_alb ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private_alb[0].id
  security_group_id        = module.eks.node_security_group_id
  description              = "Rule to allow public ALB to worker node group"
}

resource "aws_security_group_rule" "private_alb_egress_allow_all" {
  count             = var.private_alb ? 1 : 0
  type              = "egress"
  security_group_id = aws_security_group.private_alb[0].id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "private_alb_ingress_80_worker" {
  count                    = var.private_alb ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private_alb[0].id
  security_group_id        = module.eks.node_security_group_id
  description              = "Rule to allow private ALB to worker node group"
}

resource "aws_security_group_rule" "private_alb_ingress_443_worker" {
  count                    = var.private_alb ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private_alb[0].id
  security_group_id        = module.eks.node_security_group_id
  description              = "Rule to allow private ALB to worker node group"
}
