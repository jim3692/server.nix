{ config, lib, ... }:

  let
    ServerLib = import ./lib.nix { inherit lib; };

    defaultGateway =
      if config.server.network.defaultGateway != ""
      then config.server.network.defaultGateway
      else ServerLib.getGatewayFromFirstVlanWithIpAndGateway config.server.network.vlans;

  in {
    assertions = [
      { assertion = (if config.server.network.defaultGateway == "" then 0 else 1) + (ServerLib.getInterfacesWithIpsAndGatewaysFromVlansCount config.server.network.vlans) <= 1;
        message = "Default gateway is set multiple times";
      }
    ];

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

      defaultGateway = { address = defaultGateway; };
      nameservers = [ "${config.server.network.dns}" ];
    };
  }
