# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
   enable_dns_support = true
     tags = {
    Name = "dev"
  }
}


resource "aws_subnet" "my_public_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availibility_zone = "us-west-2a" 

  tags = {
    Name = "dev-public"
  }
}


resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "dev_igw"
  }
}


resource "aws_route_table" "my_public_route_table" {
    vpc_id = aws_vpc.my_vpc.id
   
    tags = {
    Name = "dev_public_rt"
  }
}


resource "aws_route" "my_default_route" {
  route_table_id            = aws_route_table.my_public_route_table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.my_internet_gateway.id
   
    tags = {
    Name = "dev_rt"
  }
}

resource "aws_route_table_association" "my_public_association" {
  subnet_id      = aws_subnet.my_public_subnet.id
  route_table_id = aws_route_table.my_public_route_table.id
}

resource "aws_security_group" "my_security_group" {
  name        = "dev_security"
  description = "Dev security group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["111.111.11.1/32"]
  }

    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "my_auth" {
  key_name   = "my_key"
  public_key = file("C:\Users\gheza\.ssh\myTerraformAWSkey.pub")
}


resource "aws_instance" "dev_node" {
  instance_type   = "t2.micro"
  ami = data.aws_ami.server_ami.id
  key_name = aws_key_pair.my_auth.id
  my_security_group_ids= [my_security_group.my_security_group.id]
  subnet_id = aws_subnet.my_public_subnet.id
  user_data= file("userdata.tpl")

  root_block_device = {
    volume_size = 10
  }
  
  tags = {
    Name = "dev_node"
  }

  provisioner "local-exec" {
    command = templatfile("${var.host_os}-ssh-config.tpl", {
      hostname = self.public_ip, 
      user = "ubuntu",
      identityfile = "~/.ssh/myTerraformAWSkey"
    })
    interpreter = var.host_os == "windows" ? ["powershell", "-command"] :  ["bash", "-c"]
    
      vars = {
        var = value
      }
    }
    
  }
  



}