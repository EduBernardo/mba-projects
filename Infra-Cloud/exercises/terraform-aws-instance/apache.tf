
resource "aws_instance" "apache_ec2_server" {
  ami = "ami-090006f29ecb2d79a"
  instance_type = "t2.micro"
  key_name= "aws_keys"
  vpc_security_group_ids = [aws_security_group.apache_sg.id]
  subnet_id = aws_subnet.apache_subnet.id
  availability_zone= "sa-east-1a"
  associate_public_ip_address = true
  user_data = "${file(var.user_data_apache_path)}"
  tags = {
    Name = var.tag_name
  }
}

resource "aws_vpc" "apache_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = var.tag_name
  }
}

resource "aws_internet_gateway" "apache_igw" {
  vpc_id = aws_vpc.apache_vpc.id
}

resource "aws_subnet" "apache_subnet" {
  vpc_id     = aws_vpc.apache_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone= "sa-east-1a"
  depends_on = [aws_internet_gateway.apache_igw]

  tags = {
    Name = var.tag_name
  }
}

resource "aws_route_table" "apache_route_table" {
  vpc_id = aws_vpc.apache_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.apache_igw.id
    }
}
resource "aws_route_table_association" "apache_subnet_association" {
  subnet_id      = aws_subnet.apache_subnet.id
  route_table_id = aws_route_table.apache_route_table.id
}

resource "aws_eip" "apache_eip" {
  instance = aws_instance.apache_ec2_server.id
  vpc = true
  depends_on = [aws_internet_gateway.apache_igw]


    tags = {
    Name = var.tag_name
  }
}

resource "aws_security_group" "apache_sg" {
  name        = "apache_sg"
  description = "Configure public access"
  vpc_id      = aws_vpc.apache_vpc.id

  ingress {
    description      = "Internet Connection"
    cidr_blocks = ["0.0.0.0/0"]
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
  }

  ingress {
    description      = "SSH"
    cidr_blocks = ["0.0.0.0/0"]
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
  }

   ingress {
    description      = "SSH"
    cidr_blocks = ["0.0.0.0/0"]
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
  }
  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = var.tag_name
  }
}


##FORMA ALTERNATIVA DE INSTALACAO DO APACHE UTILIZANDO REMOTE_EXEC APOS SLEEP
##OBS: esta com erro no primeiro apply, sendo necessário executar o comando novamente para rodar o script corretamente
# resource "time_sleep" "wait_30_seconds" {
#     depends_on = [aws_instance.apache_ec2_server]
#     create_duration = "30s"
# }

# resource "null_resource" "install_apache" {
#   connection {
#     type     = "ssh"
#     user     = "ubuntu"
#     private_key = file(var.key_path)
#     host     = aws_eip.apache_eip.public_ip
#   }

#   provisioner "remote-exec" {
#     inline = [
#         "sleep 20s"
#         "sudo apt update",
#         "sudo apt install -y apache2",
#         "sudo service apache2 start"
#     ]
#   }
#   depends_on = [aws_instance.apache_ec2_server]
# }

# resource "null_resource" "upload-app" {
#   connection {
#     type     = "ssh"
#     user     = "ubuntu"
#     private_key = file(var.key_path)
#     host     = aws_eip.apache_eip.public_ip
#   }


#   provisioner "file" {
#     source = "files"
#     destination = "/home/ubuntu"
#   }

#   depends_on = [aws_instance.apache_ec2_server]

# }

