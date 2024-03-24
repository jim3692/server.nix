{ config, lib, ... }:

  let
    ServerLib = import ./lib.nix { inherit lib; };

  in {
    networking = {
      hostName = config.server.network.hostName;

      vlans = lib.mapAttrs (k: v: {
        id = v.id;
        interface = v.parentInterface;
      }) config.server.network.vlans;

      bridges =
        ServerLib.getBridgesFromVlans config.server.network.vlans;

      interfaces = lib.mkMerge [
        (ServerLib.getInterfacesWithIpsFromVlans config.server.network.vlans)
        (ServerLib.disableDhcpForVlanParents config.server.network.vlans)
      ];

      defaultGateway = { address = "${config.server.network.defaultGateway}"; };

      nameservers = [ "${config.server.network.dns}" ];
    };
  }
