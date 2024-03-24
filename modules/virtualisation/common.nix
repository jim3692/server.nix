{ args, pkgs, vlan, dns, ... }:
  let
    lib = pkgs.lib;
    ServerLib = import ../lib.nix { inherit lib; };
  in rec {
    docker = {
      virtualisation.docker.enable = args.docker.enable;

      virtualisation.oci-containers = lib.mkIf args.docker.enable {
        containers = lib.mkMerge [
          args.docker.containers

          (lib.mkIf (args.docker.privateNetwork == false) (
            ServerLib.helpers.mapAttrsAndKeys
              (containerName: { "${containerName}" = { extraOptions = [ "--network=host" ]; }; })
              (lib.attrNames args.docker.containers)
          ))
        ];
        backend = "docker";
      };
    };

    network = {
      networking = {
        defaultGateway = {
          address = (if args.gateway != "" then args.gateway else vlan.gateway);
        };

        firewall = { enable = false; };
      };
    } // (ServerLib.getDnsConfig dns);

    all = lib.mkMerge [ docker network ];
  }
