provider "google" {
  credentials = var.GOOGLE_CREDENTIALS
  project    = "energy-stars"
  region     = "us-central1"
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "true"
}

resource "google_compute_instance" "example_vm" {
  name         = "example-vm"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"
  tags         = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Update the system
      sudo yum update -y

      # Install Python 3 and pip
      sudo yum install python3 python3-pip -y

      # Install FastAPI and Uvicorn
      pip3 install fastapi uvicorn

      # Create a directory for your FastAPI app
      mkdir /app
      cd /app

      # Create a simple FastAPI app in a Python script (e.g., main.py)
      cat <<EOL > main.py
      from fastapi import FastAPI

      app = FastAPI()

      @app.get("/")
      def read_root():
          return {"message": "Hello, FastAPI!"}
      EOL

      # Start the FastAPI app using Uvicorn
      uvicorn main:app --host 0.0.0.0 --port 80 --reload

      # Enable the Uvicorn service to start at boot
      cat <<EOF > /etc/systemd/system/uvicorn.service
      [Unit]
      Description=Uvicorn FastAPI

      [Service]
      ExecStart=/usr/local/bin/uvicorn main:app --host 0.0.0.0 --port 80 --reload
      Restart=always
      StartLimitInterval=0

      [Install]
      WantedBy=multi-user.target
      EOL

      # Enable and start the Uvicorn service
      sudo systemctl enable uvicorn
      sudo systemctl start uvicorn
  EOF
}

resource "google_sql_database_instance" "example_db_instance" {
  database_version = "MYSQL_8_0"
  region           = "us-central1"
  name             = "example-db-instance"

  settings {
    tier = "db-f1-micro"
  }

  deletion_protection = false
}

/* PULL REQUEST 1
resource "google_sql_firewall_rule" "example_db_firewall" {
  name        = "example-db-firewall"
  # instance    = google_sql_database_instance.example_db_instance.name
  instance = google_sql_database_instance.example_db_instance.name
  project     = var.project_id
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  source_ranges = [google_compute_instance.example_vm.network_interface[0].network_ip]
}
*/