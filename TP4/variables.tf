variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.nano"
  #Pour surcharger terraform apply -var="instance_type=t2.micro"
}


# variable "prenom" {
#   description = "Prénom à utiliser pour le tag Name"
#   type        = string
#   default     = "Cheikh_Fall" 
#   #terraform apply -var="prenom=Cheikh_Fall"
# }

variable "aws_common_tags" {
  description = "Tags communs à toutes les ressources"
  type        = map(string)
  default = {
    Name = "ec2-cfk"
  }
}

