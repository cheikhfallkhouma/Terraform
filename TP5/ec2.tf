terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #version = "~> 5.0" # This will allow any version from 5.0 to less than 6.0
      version = "5.65.0"
    }
  }

  required_version = ">= 1.0.0" #1.9.4
  #required_version = "1.9.4" 
}

provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["../.secrets/credentials"]
  profile                  = "cfk-credentials"
}

# Elastic IP
resource "aws_eip" "my_eip" {

}

resource "aws_instance" "myec2_TP4" {
  ami           = data.aws_ami.ami_amazon_linux.id
  instance_type = var.instance_type
  key_name      = "devops-Cheikh_Fall"
  tags          = var.aws_common_tags

  security_groups = [aws_security_group.my_sg_allow_http_https_ssh.name]

  # provisioner "local-exec" {
  #   command = <<EOT
  #     rm ../.secrets/infos_ec2.txt
  #     echo "Instance ID: ${self.id}" >> ../.secrets/infos_ec2.txt
  #     echo "Public IP: ${self.public_ip}" >> ../.secrets/infos_ec2.txt
  #     echo "AZ: ${self.availability_zone}" >> ../.secrets/infos_ec2.txt
  #     EOT
  # }

  provisioner "remote-exec" {
    inline = [
    "sudo yum update -y",
    "sudo amazon-linux-extras enable nginx1",
    "sudo yum install -y nginx",
    "sudo systemctl enable nginx",
    "sudo systemctl start nginx"
      ]
   }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("../.secrets/devops-Cheikh_Fall.pem")
    host        = self.public_ip
  }
}

resource "null_resource" "saved_infos" {
  depends_on = [aws_instance.myec2_TP4]
  provisioner "local-exec" {
    command = <<EOT
      rm ../.secrets/infos_ec2.txt
      echo "Instance ID: ${aws_instance.myec2_TP4.id}" >> ../.secrets/infos_ec2.txt
      echo "Public IP (EIP): ${aws_eip.my_eip.public_ip}" >> ../.secrets/infos_ec2.txt
      echo "AZ: ${aws_instance.myec2_TP4.availability_zone}" >> ../.secrets/infos_ec2.txt
      EOT
        }
      }

resource "aws_security_group" "my_sg_allow_http_https_ssh" {
  name        = "security_group-cfk"
  description = "Allow HTTP, HTTPS, and SSH traffic"

  # Permettre les connexions SSH sur le port 443
  ingress {
    description = "TLS from VPC"
    from_port   = 44
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permet l'accès depuis n'importe quelle adresse IP
  }

  # Permettre les connexions HTTP sur le port 80
  ingress {
    description = "SSH from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permet l'accès depuis n'importe quelle adresse IP
  }

  # Autoriser le SSH (port 22)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Ou utilise ton IP publique pour plus de sécurité
  }


  # Sortie autorisée pour toutes les connexions
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # Tout protocole
    cidr_blocks = ["0.0.0.0/0"] # Permet la sortie vers n'importe quelle adresse IP
  }
}

resource "aws_eip_association" "my_eip_att" {
  # On attend que l'instance EC2 soit créée avant d'associer l'Elastic IP
  depends_on = [aws_instance.myec2_TP4]
  instance_id = aws_instance.myec2_TP4.id
  # On associe l'Elastic IP à l'instance EC2
  allocation_id = aws_eip.my_eip.id
}


# Ce bloc permet de rechercher dynamiquement l'AMI Amazon Linux 2 la plus récente
data "aws_ami" "ami_amazon_linux" {
  # Indique qu'on veut récupérer l'AMI la plus récente correspondant aux filtres
  most_recent = true

  # Spécifie qu'on ne veut que les AMIs officielles publiées par Amazon
  owners = ["amazon"]

  # Premier filtre : on recherche les AMIs dont le nom commence par "amzn2-ami-hvm" et
  # se termine par "-x86_64-gp2" (ce sont les noms des AMIs Amazon Linux 2 classiques)
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  # Deuxième filtre : on s'assure que l'AMI utilise la virtualisation HVM (standard pour EC2        modernes)
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

terraform {
  backend "s3" {
    bucket     = "terraform-backend-cheikh-fall"  # doit correspondre au bucket ci-dessus
    key        = "cheikh-fall.tfstate"
    region     = "us-east-1"
  }
}
