

resource "aws_instance" "ansible_ec2_server" {
  ami = "ami-090006f29ecb2d79a"
  instance_type = "t2.micro"
  key_name= "aws_keys"
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]
  subnet_id = aws_subnet.ansible_subnet.id
  availability_zone= "sa-east-1a"
  associate_public_ip_address = true


  user_data = "${file(var.user_data_ansible_path)}"
  tags = {
    Name = var.tag_name
  }
}

resource "aws_vpc" "ansible_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = var.tag_name
  }
}

resource "aws_internet_gateway" "ansible_igw" {
  vpc_id = aws_vpc.ansible_vpc.id
}

resource "aws_subnet" "ansible_subnet" {
  vpc_id     = aws_vpc.ansible_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone= "sa-east-1a"
  depends_on = [aws_internet_gateway.ansible_igw]

  tags = {
    Name = var.tag_name
  }
}

resource "aws_route_table" "ansible_route_table" {
  vpc_id = aws_vpc.ansible_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.ansible_igw.id
    }
}
resource "aws_route_table_association" "ansible_subnet_association" {
  subnet_id      = aws_subnet.ansible_subnet.id
  route_table_id = aws_route_table.ansible_route_table.id
}

resource "aws_eip" "ansible_eip" {
  instance = aws_instance.ansible_ec2_server.id
  vpc = true


  depends_on = [aws_internet_gateway.ansible_igw]

    tags = {
    Name = var.tag_name
  }
}

resource "aws_security_group" "ansible_sg" {
  name        = "ansible_sg"
  description = "Configure public access"
  vpc_id      = aws_vpc.ansible_vpc.id

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

resource "time_sleep" "wait_30_seconds" {
    depends_on = [aws_instance.ansible_ec2_server]
    create_duration = "30s"
}

resource "local_file" "create-inventory"{
    filename = "./ansible/hosts"
    content = <<EOF
        [web]
        ${aws_eip.ansible_eip.public_ip}

        [web:vars]
        ansible_user=ubuntu
        ansible_ssh_pass=${file(var.key_path)}
        ansible_ssh_common_args="-o StrictHostKeyChecking=no"
        ansible_python_interpreter=/usr/bin/python3
    EOF

    depends_on = [aws_instance.ansible_ec2_server, aws_eip.ansible_eip]
}

resource "null_resource" "upload_ansible"{
  provisioner "file" {
    connection {
        type     = "ssh"
        user     = "ubuntu"
        private_key = file(var.key_path)
        host     = aws_eip.ansible_eip.public_ip
    }

    source = "ansible"
    destination = "/home/ubuntu"
  }

    depends_on = [local_file.create-inventory]
}

resource "null_resource" "run_ansible" {
    provisioner "remote-exec" {
        connection {
            type     = "ssh"
            user     = "ubuntu"
            private_key = file(var.key_path)
            host     = aws_eip.ansible_eip.public_ip
        }
        inline = [
            "ansible-playbook -i /home/ubuntu/ansible/hosts /home/ubuntu/ansible/playbook.yaml"
        ]
    }
    
    depends_on = [aws_instance.ansible_ec2_server, null_resource.upload_ansible ]
}






