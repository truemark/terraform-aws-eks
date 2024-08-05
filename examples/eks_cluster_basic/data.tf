data "aws_caller_identity" "current" {}

data "aws_vpc" "services" {
  tags = {
    Name = "services"
  }
}

data "aws_subnets" "private" {
  tags = {
    network = "private"
  }
}