module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

proxmox = var.proxmox

  image = {
    version        = "v1.8.0-alpha.1"
    schematic = file("${path.module}/talos/image/schematic.yaml")
  }

  cilium = {
    values = file("${path.module}/../../k8s/infra/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  cluster = {
    name            = "puppetmaster"
    endpoint        = "10.69.99.50"
    gateway         = "10.69.99.1"
    talos_version   = "v1.8"
    proxmox_cluster = "cauldron"
  }

  nodes = {
    "c01" = {
      host_node     = "hv01"
      machine_type  = "controlplane"
      ip            = "10.69.99.51"
      mac_address   = "BC:24:11:2E:C8:00"
      vm_id         = 800
      cpu           = 4
      ram_dedicated = 4096
    }
    "c02" = {
      host_node     = "hv02"
      machine_type  = "controlplane"
      ip            = "10.69.99.52"
      mac_address   = "BC:24:11:2E:C8:01"
      vm_id         = 801
      cpu           = 4
      ram_dedicated = 4096
    }
    "c03" = {
      host_node     = "hv03"
      machine_type  = "controlplane"
      ip            = "10.242.99.53"
      mac_address   = "BC:24:11:2E:C8:02"
      vm_id         = 802
      cpu           = 4
      ram_dedicated = 4096
    }
    "w01" = {
      host_node     = "hv01"
      machine_type  = "worker"
      ip            = "10.69.99.61"
      mac_address   = "BC:24:11:2E:A8:00"
      vm_id         = 810
      cpu           = 4
      ram_dedicated = 4096
    }
    "w02" = {
      host_node     = "hv02"
      machine_type  = "worker"
      ip            = "10.69.99.62"
      mac_address   = "BC:24:11:2E:A8:01"
      vm_id         = 811
      cpu           = 4
      ram_dedicated = 4096
    }
    "w3" = {
      host_node     = "hv03"
      machine_type  = "worker"
      ip            = "10.69.99.63"
      mac_address   = "BC:24:11:2E:A8:02"
      vm_id         = 812
      cpu           = 4
      ram_dedicated = 4096
    }
  }

}

module "sealed_secrets" {
  depends_on = [module.talos]
  source = "./bootstrap/sealed-secrets"

  providers = {
    kubernetes = kubernetes
  }

  // openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout sealed-secrets.key -out sealed-secrets.cert -subj "/CN=sealed-secret/O=sealed-secret"
  cert = {
    cert = file("${path.module}/bootstrap/sealed-secrets/sealed-secrets.cert")
    key = file("${path.module}/bootstrap/sealed-secrets/sealed-secrets.key")
  }
}

module "proxmox_csi_plugin" {
  depends_on = [module.talos]
  source = "./bootstrap/proxmox-csi-plugin"

  providers = {
    proxmox    = proxmox
    kubernetes = kubernetes
  }

  proxmox = var.proxmox
}

module "volumes" {
  depends_on = [module.proxmox_csi_plugin]
  source = "./bootstrap/volumes"

  providers = {
    restapi    = restapi
    kubernetes = kubernetes
  }
  proxmox_api = var.proxmox
  volumes = {
    pv-sonarr = {
      node = "hv01"
      size = "4G"
    }
    pv-radarr = {
      node = "hv01"
      size = "4G"
    }
    pv-lidarr = {
      node = "hv01"
      size = "4G"
    }
    pv-prowlarr = {
      node = "hv02"
      size = "1G"
    }
    pv-torrent = {
      node = "hv02"
      size = "1G"
    }
    pv-remark42 = {
      node = "hv02"
      size = "1G"
    }
    pv-keycloak = {
      node = "hv02"
      size = "2G"
    }
    pv-jellyfin = {
      node = "hv02"
      size = "12G"
    }
    pv-netbird-signal = {
      node = "hv03"
      size = "1G"
    }
    pv-netbird-management = {
      node = "hv03"
      size = "1G"
    }
    pv-plex = {
      node = "hv03"
      size = "12G"
    }
    pv-prometheus = {
      node = "hv03"
      size = "10G"
    }
  }
}
