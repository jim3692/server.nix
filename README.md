# What is server.nix?

This flake is a framework for easy provisioning of [NixOS Containers](https://nixos.wiki/wiki/NixOS_Containers) and [NixOS MicroVMs](https://github.com/astro/microvm.nix).

It allows direct connection of any the containers or VMs to your network's VLANs, with streamlined network configuration syntax.

# Why?

I used to run Proxmox VE on home network, but it started getting too difficult to keep track of all static IPs in my network. So, I decided to slowly move my infrastructure to a NixOS-based environment. This change required better tooling for the management of the network.

# Notes

- It currently relies on [my personal fork of MicroVMs](https://github.com/jim3692/microvm.nix) as the official implementation does not allow the user to enter a VM.
My fork implements the `microvm -s <name>` command which opens a `screen` session to the VMs `tty0`.
Related issue: https://github.com/astro/microvm.nix/issues/123

- Some Docker images and Tailscale may not work on NixOS Containers without enabling USER_NS. Containers have a special option `enableUserNs` that enables USER_NS but may cause other permissions problems.
Related issue: https://github.com/moby/moby/issues/47620

- Docker Containers provisioned by NixOS seem to not be able to access each other using their names. Because of that, all Docker containers are passed the `--network=host` the argument by default, unless `docker.privateNetwork` is set to `true`.

- The default `root` password for the VMs is "1"

# Installation

Just add the following to your flake.nix

```nix
  inputs = {
    # ...
    server.url = "github:jim3692/server.nix";
  };

  outputs = { server, ... }@inputs:
    {
      nixosConfigurations."your-hostname" = nixpkgs.lib.nixosSystem {
        # ...
        modules = [
          # ...
          server.nixosModules.microvm
          server.nixosModules.server
        ];
      };
    };
```

# Example Configuration

```nix
{ pkgs, ... }: {
  config.server = {
    network = {
      hostName = "my-server";

      vlans = {
        management = {              # The name of the VLAN interface
          id = 90;                  # The VLAN ID
          ip = "10.0.90.2";         # The IP for the host
          prefix = 24;              # The prefix of the subnet (10.0.90.2/24)
          parentInterface = "eth0"; # The parent interface of the VLAN
        };

        my-vlan-10 = {              # The name of the VLAN interface
          id = 10;                  # The VLAN ID
          prefix = 24;              # The prefix of the subnet
          gateway = "10.0.10.1";    # The default gateway for any container/VM that gets attached to this VLAN
          parentInterface = "eth0"; # The parent interface of the VLAN
        };
      };

      defaultGateway = "10.0.90.1"; # The default gateway of the host
      dns = "10.90.0.1";            # The default DNS (Used for all host, containers and VMs)
    };

    containers = {p
      wordpress = {                 # The name of the container
        ip = "10.0.10.10";          # The IP of the container
        vlan = "my-vlan-10";        # The VLAN to which this container will get attached

        enableUserNs = false;       # Disable the USER_NS for this container (Default)

        docker = {
          enable = true;            # Enable Docker Engine for this container
          privateNetwork = true;    # All Docker containers will use the Docker's default bridge network

          containers = {            # Standard NixOS virtualisation.oci-containers.containers syntax (Docs: https://nixos.wiki/wiki/Docker)
            my-website = {
              image = "wordpress";
              # ...
            };

            my-database = {
              image: "mysql:8.0";
              # ...
            }
          };
      };

      extraConfiguration = {        # Additional NixOS config
        environment.systemPackages = with pkgs; [ vim wget ];
      };
    };

    vms = {
      some-vm = {
        vcpus = 1;                  # The number of vCPUs
        ramMb = 512;                # The amount of RAM in MB
        volumes = [{                # The MicroVM volumes to create for this VM (Docs: https://astro.github.io/microvm.nix/shares.html)
          image = "data.img";       # The file name (Stored in `/var/lib/microvms/<vm-name>/`)
          mountPoint = "/data";     # The mount point inside the VM
          size = 1024;              # The size of the volume in MB
        }];

        ip = "10.0.10.20";          # The IP of the VM
        vlan = "my-vlan-10";        # The VLAN to which this VM will get attached

        dns = "9.9.9.9";            # Override the DNS for this VM
        gateway = "10.0.10.100";    # Override the default gateway for this VM
      }
    };
  };
}
```
