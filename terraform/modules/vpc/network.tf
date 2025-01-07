# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "devops-project-public-rt"
    Type = "public"
  })
}

# Private Route Tables (one per AZ)
resource "aws_route_table" "private_rt" {
  count  = length(var.vpc_configuration.subnets.api)
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "devops-project-private-rt-${count.index + 1}"
    Type = "private"
  })
}

# Public subnet route table associations
resource "aws_route_table_association" "public_web" {
  count          = length(aws_subnet.subnet_web)
  subnet_id      = aws_subnet.subnet_web[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_alb" {
  count          = length(aws_subnet.subnet_alb)
  subnet_id      = aws_subnet.subnet_alb[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Private subnet route table associations
resource "aws_route_table_association" "private_api" {
  count          = length(aws_subnet.subnet_api)
  subnet_id      = aws_subnet.subnet_api[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

resource "aws_route_table_association" "private_db" {
  count          = length(aws_subnet.subnet_db)
  subnet_id      = aws_subnet.subnet_db[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

# NAT Gateway routes for private subnets
resource "aws_route" "private_nat" {
  count                  = length(aws_route_table.private_rt)
  route_table_id         = aws_route_table.private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw[count.index].id
}
