data "aws_availability_zones" "available" {}

variable "subnets" {
  type = "list"
}

variable "ready" {

}

resource "aws_instance" "vault" {
  count		    = "${length(data.aws_availability_zones.available.names)}"
  ami           = "ami-bb9a6bc2"
  instance_type = "t2.micro"
  subnet_id 	= "${var.subnets[count.index]}"
  tags {
    Name = "Vault-${count.index}"
  }
}
