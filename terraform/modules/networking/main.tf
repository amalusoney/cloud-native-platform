# 1. Custom VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                        = "${var.project_name}-${var.environment}-vpc"
    Environment                                 = var.environment
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# 2. Internet Gateway (for public internet access)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
  }
}

# 3. Public Subnets (Across 2 AZs)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
    Environment                                 = var.environment
    "kubernetes.io/role/elb"                    = "1" # Required for AWS public Load Balancers
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# 4. Private Subnets (Across 2 AZs - For EKS Nodes & DB)
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                        = "${var.project_name}-${var.environment}-private-${var.availability_zones[count.index]}"
    Environment                                 = var.environment
    "kubernetes.io/role/internal-elb"           = "1" # Required for AWS internal Load Balancers
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# 5. Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-eip"
    Environment = var.environment
  }
}

# 6. Single NAT Gateway (Cost-optimized: 1 NAT GW instead of 2)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Placed in the first public subnet

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.igw]
}

# 7. Public Route Table (Routes out to Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
  }
}

# 8. Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 9. Private Route Table (Routes out to NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-rt"
    Environment = var.environment
  }
}

# 10. Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}