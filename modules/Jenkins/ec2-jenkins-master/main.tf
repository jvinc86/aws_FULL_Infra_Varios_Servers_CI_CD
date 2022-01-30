resource "aws_instance" "mis_vms" {
  ami                         = var.win_server_ami[var.region] #var.imagen_OS 
  instance_type               = var.tipo_instancia
  availability_zone           = var.AZs[0]
  # subnet_id                   = var.los_IDs_subredes[count.index]
  user_data                   = data.template_file.userdata_linux_ubuntu.rendered
  key_name                    = var.llave_ssh
  tags                        = { Name = "srv-${var.server_role}-${var.proyecto}" }

  network_interface {
    network_interface_id = "${aws_network_interface.mi_nic.id}"
    device_index = 0
  }
}

resource "aws_network_interface" "mi_nic" {
  subnet_id = var.los_IDs_subredes[0]
  private_ips = [var.ip_fija_privada]
  security_groups = [var.los_SG]
}

data "template_file" "userdata_linux_ubuntu" {
  template = <<-EOT
              #!/bin/bash
              INICIO=$(date "+%F %H:%M:%S")
              echo "Hora de inicio del script: $INICIO" > /home/ubuntu/a_${var.server_role}.txt

              hostnamectl set-hostname ${var.server_role}
              echo "ubuntu:123456" | chpasswd

              sudo apt update -y && sudo apt upgrade -y

              # sudo apt install xrdp -y
              # sudo systemctl enable xrdp
              # sudo apt install tightvncserver -y
              # sudo apt install ubuntu-gnome-desktop gnome-shell gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal -y

              sudo apt install openjdk-11-jdk -y
              sudo apt install git -y
              sudo apt install maven -y
              wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
              sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
              sudo apt update -y
              sudo apt install jenkins -y
              sudo systemctl start jenkins
              sudo cat /var/lib/jenkins/secrets/initialAdminPassword | sudo tee -a  /home/ubuntu/contrasena_de_Jenkins.txt
              
              sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
              sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
              sudo service sshd restart

              echo "El rol de este servidor Jenkins es: ${var.server_role}" > /home/ubuntu/b_${var.server_role}.txt
              FINAL=$(date "+%F %H:%M:%S")
              echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_role}.txt
              EOT
}

