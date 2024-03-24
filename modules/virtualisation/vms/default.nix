{ config, lib, pkgs, ... }:

let
  ServerLib = import ../../lib.nix { inherit lib; };
  VM = import ./vm.nix;

  vms = lib.mapAttrs (k: v:
    VM {
      name = k;
      args = v;
      vlan = config.server.network.vlans."${v.vlan}";
      dns = if (v.dns != "") then v.dns else config.server.network.dns;
      inherit pkgs;
    }) config.server.vms;

in {
  microvm = {
    inherit vms;
    autostart = lib.attrNames vms;
  };

  systemd.services = lib.mkMerge [
    (ServerLib.disableNetworkAddressesServices config.server.vms)

    {
      "watch-vm-interfaces" = {
        enable = true;
        serviceConfig.ExecStart = "/run/current-system/sw/bin/watch-interfaces";
        environment = {
          CONFIG_FILE = ServerLib.getBridgesJsonFile { vms = config.server.vms; };
          INTERVAL = "1";
        };
        preStart = "rm -rf /tmp/bridge-watch || true";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    }
  ];
}
