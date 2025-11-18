terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

variable "public_ip" {
  type = string
}

resource "null_resource" "arculus_provision" {

  # -------- SSH CONNECTION --------
  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = var.public_ip
    private_key = file("../infrastructure/arculus-key.pem")
    timeout     = "2m"
  }

  # -------- PROVISIONING --------
  provisioner "remote-exec" {
    inline = [
      "echo '============================='",
      "echo 'Starting Arculus Provisioning'",
      "echo '============================='",

      "echo '[1/8] Updating apt packages...'",
      "sudo apt-get update -y",

      "echo '[2/8] Changing directory to arculus-sw...'",
      "cd /home/ubuntu/arculus-sw",

      "echo '[3/8] Applying chmod permissions...'",
      "sudo chmod +x setup_controller.sh",
      "sudo chmod +x arculus-setup.sh",

      "echo '[4/8] Running setup_controller.sh...'",
      "sudo ./setup_controller.sh",

      "echo '[5/8] Running arculus-setup.sh with DB password vimanceri...'",
      "echo 'vimanceri' | sudo ./arculus-setup.sh",

      "echo '[6/8] Waiting for MySQL and backend...'",
      "sleep 20",

      "echo '[7/8] Building UI...'",
      "cd /home/ubuntu/arculus-sw/arculus-gcs-ui",
      "npm install",
      "npm run build",

      "echo '[8/8] Starting UI server with PM2...'",
      "sudo npm install -g pm2",
      "pm2 start server.js",

      "echo '=================================='",
      "echo 'Arculus Provision Completed'",
      "echo '=================================='"
    ]
  }
}

output "ui_url" {
  value = "http://${var.public_ip}:3000"
}
