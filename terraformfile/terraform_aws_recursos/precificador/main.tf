# Provider utilizado
provider "aws" {
  region = "us-east-2"
  }

# Criar recurso S3

resource "aws_s3_bucket" "imovel_bucket_flask" {
 bucket = "<NOME DO SEU BUCKET>-bucket"
 
 tags = {
    Name = "Imovel Bucket"
    Environment  = "lab"
    }

  provisioner "local-exec" {
    command = "${path.module}/upload_to_s3.sh"
  }    

# Deleta todo conteudo do bucket quando o comando de destruir for chamado

 provisioner "local-exec" {
    when = destroy
    command = "aws s3 rm s3://<NOME DO SEU BUCKET>-bucket> --recursive"
  }
}

# Criar recruso EC2

resource "aws_instance" "precifica-imovel" {
  
  ami = "ami-01c265752adadcdf8"
  instance_type = "t3.micro"

  # Criar profile  EC2 que terá acesso  ao S3 
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name

  # Associar EC2 ao grupo de segurança que será configurado mais a frente
  vpc_security_group_ids = [aws_security_group.precifica_imovel_api_sg.id]

  # Script de inicialização - Instalação de Python e pacotes para rodar modelo
  # Criação do diretório ml para copiar modelo da maquina fisica e salvar no S3
  # Inicia o gunicorn WSGI para converter  python independente do servidor utilizado

  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install -y python3 python3-pip awscli
                sudo pip3 install flask joblib scikit-learn numpy scipy gunicorn
                sudo mkdir /ml
                sudo aws s3 sync s3://<NOME DO SEU BUCKET>-bucket> /ml
                cd /ml
                nohup gunicorn -w 4 -b 0.0.0.0:5000 app:app &
              EOF

 tags = {
   Name = "ImovelFlaskApp"
 }
}

#Configuração do grupo de segurança 

resource "aws_security_group" "precifica_imovel_api_sg" {

  name        = "precifica_imovel_api_sg"
  description = "Security Group for Flask App in EC2"

  # SSH somente do meu IP
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # HTTP público
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Não abrir 5000 para a Internet

  egress {
    description = "Outbound Rule"
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
} 

#Criação do recurso IAM para definir como EC2 vai acessar S3

resource "aws_iam_role" "ec2_s3_access_role" {
  
  name = "ec2_s3_access_role"

    assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

#Criação do recurso de politica que sera usada no IAM

resource "aws_iam_role_policy" "s3_access_policy" {

  name = "s3_access_policy"

  role = aws_iam_role.ec2_s3_access_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
          "${aws_s3_bucket.imovel_bucket_flask.arn}/*",
          "${aws_s3_bucket.imovel_bucket_flask.arn}"
        ]
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2_s3_profile"
  role = aws_iam_role.ec2_s3_access_role.name
}
