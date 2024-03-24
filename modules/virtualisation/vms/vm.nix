{ name, args, vlan, name, pkgs }@params:

let
  lib = pkgs.lib;

  ServerLib = import ../../lib.nix { inherit lib; };
  common = import ../common.nix params;

  mac = ServerLib.generateRandomMac name;

in {
  inherit pkgs;

  config = lib.mkMerge [
    {
      microvm = {
        vcpu = args.vcpus;
        mem = args.ramMb;
        volumes = args.volumes;

        shares = [{
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          tag = "ro-store";
          proto = "virtiofs";
        }];

        interfaces = [{
          id = ServerLib.helpers.getVmVethName name;
          type = "tap";
          mac = mac;
        }];

        hypervisor = "qemu";
        kernelParams = [ "net.ifnames=0" ];
      };

      # Password: "1"
      users.users.root.initialHashedPassword =
        "$6$vPD6l5PMq6myZeh4$oVhUff6czEnW7o089D3CeXzrMt/yYwwXvjbK4HN3FHEUu3jQx0JUOygtLlIOK06V3W2S2iQM6IlYHKdv58nqj0";

      networking.defaultGateway.interface = "eth0";

      system.stateVersion = args.stateVersion;
    }

    common.all
    args.extraConfiguration
  ];
}
