# 1. Specify the version of the AzureRM Provider to use
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.39.0"
    }
  }
}

# 2. Configure the AzureRM Provider
provider "azurerm" {
  features {}
}

# 3. Create an Azure Front Door resource

resource "azurerm_frontdoor" "frontdoor" {
  name                = var.frontdoor_name
  resource_group_name = var.resource_group_name

  # frontend endpoint for the Front Door instance
  frontend_endpoint {
    name      = "frontendEndpoint"
    host_name = "${var.frontdoor_name}.azurefd.net"
  }

  # health probe for the login service
  backend_pool_health_probe {
    name = "probelogin"
    path = "/login"
    protocol = "Http"
    probe_method = "HEAD"
    interval_in_seconds = 30
  }

  # health probe for the chat service
  backend_pool_health_probe {
    name = "probechat"
    path = "/chat"
    protocol = "Http"
    probe_method = "HEAD"
    interval_in_seconds = 30
  }

  # load balancing settings 
  backend_pool_load_balancing {
    name = "wecloudloadbalancer"
    sample_size = 4
    successful_samples_required = 2
    additional_latency_milliseconds = 50
  }

  # backend pool for the login and profile services
  backend_pool {
    name = "wecloudbackendloginprofile"

    # backend from gcp 
    backend {
      host_header = var.gcp_ingress_external_ip
      address     = var.gcp_ingress_external_ip
      http_port   = 80
      https_port  = 443
    }

    # backend from azure
    backend {
      host_header = var.azure_ingress_external_ip
      address     = var.azure_ingress_external_ip
      http_port   = 80
      https_port  = 443
    }

    health_probe_name = "probelogin"
  }

  # backend pool for the chat service
  backend_pool {
    name = "wecloudbackendchat"

    # backend from gcp
    backend {
      host_header = var.gcp_ingress_external_ip
      address     = var.gcp_ingress_external_ip
      http_port   = 80
      https_port  = 443
    }

    health_probe_name = "probechat"
  }

  # routing rule for login and profile services
  routing_rule {
    name               = "loginprofilerouting"
    accepted_protocols = ["Http"]
    patterns_to_match  = ["/login", "/profile"]
    frontend_endpoints = ["frontendEndpoint"]

    forwarding_configuration {
      backend_pool_name = "wecloudbackendloginprofile"
      forwarding_protocol = "HttpOnly"
    }
  }

  # routing rule for chat service
  routing_rule {
    name               = "chatrouting"
    accepted_protocols = ["Http"]
    patterns_to_match  = ["/chat", "/chat/*"]
    frontend_endpoints = ["frontendEndpoint"]

    forwarding_configuration {
      backend_pool_name = "wecloudbackendchat"
      forwarding_protocol = "HttpOnly"
    }
  }
  
}