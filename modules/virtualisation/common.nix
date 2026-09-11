{
  args,
  dns,
  name,
  pkgs,
  vlan,
  ...
}:
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

    network =
      let
        defaultGateway =
          if args.gateway != ""
          then args.gateway
          else vlan.gateway;
      in {
        imports = [
          (ServerLib.getDnsConfig dns)
        ];

        networking = {
          defaultGateway = {
            address = defaultGateway;
          };

          firewall = { enable = false; };

          interfaces."${ServerLib.helpers.getVmVethName name}".ipv4.routes = [{
            address = "0.0.0.0";
            prefixLength = 0;
            via = defaultGateway;
          }];

          resolvconf.enable = false;
        };
      };

    all = { imports = [ docker network ]; };
  }
