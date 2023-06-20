locals {
  ami_id = "ami-0261755bbcb8c4a84"
  vpc_id = "vpc-096fc5bdde341ca47"
  ssh_user = "ubuntu"
  key_name = "Demokey"
  private_key_path = "/home/labsuser/End_to_End_Test/Demokey.pem"
}

provider "aws" {
  access_key = "ASIAVFRRB5ZOGG7KAYX6" 
  secret_key = "5dZNB0BV1S4Se2mpTPOY97DV5a/8xAHprSWHUApM"
  token = "FwoGZXIvYXdzEFkaDBxjoxPytIf1iXVExyK4AYUfn5i3PD36+wzX9VpPTNkRPZmspB+RukC3Jx9hfn+16tFroQKw/XqxHNN4ihJ0ES2e//y6R0pDDTlZVnApLn5PoOG/cZ+sLgi+YHJ4p6MUzcHAMId7LEN05t5K2luU3iv8lzngFZbY2bSkwxrLannc34JtL2M1s2FpvSixMDMxVIlO65iurZJYcus4FE2djWNlbm03hkk8WdPp0zsK7nq/CxgPAm+oUY/9ItyQqUfkjc0RDvuvKIIog6PFpAYyLXIDVjT7dszO0RrNhYoPhMvSPgnLfqx49e3s6NtH94zTaF1ylM77i4P/5Z9wgQ=="
  region = "us-east-1"
}

resource "aws_security_group" "demoaccess" {
  name = "demoaccess"
  vpc_id = local.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }
  ingress { 
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { 
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
} 

resource "aws_instance" "WordPress" {
  ami = local.ami_id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.demoaccess.id]
  key_name = local.key_name

  tags = {
    name = "WordPress"
  }

  connection {
    type = "ssh"
    host = self.public_ip
    user = local.ssh_user
    private_key = file(local.private_key_path)
    timeout = "4m"
  } 

  provisioner "remote-exec" {
    inline = [
      "echo 'Wait for SSH connection to be ready ...'"
    ]
  }

  provisioner "local-exec" {
    #Populate Ansible inventory file
    command = "echo ${self.public_ip} > inventory"
  }

  provisioner "local-exec" {
    #Execute Ansible Playbook
    command = "ansible-playbook -i inventory --user ${local.ssh_user} --private-key ${local.private_key_path} test.yaml --vault-password-file ./vault-password"
  }
} 
 
output "instance_ip" {
  value = aws_instance.WordPress.public_ip
}
