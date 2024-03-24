{ name, args, vlan, dns, pkgs }@params:

let
  lib = pkgs.lib;
  ServerLib = import ../../lib.nix { inherit lib; };
  common = import ../common.nix params;

in {
  autoStart = true;
  privateNetwork = true;

  extraVeths."${ServerLib.helpers.getVmVethName name}" = {
    hostBridge = "${ServerLib.helpers.getBridgeName "${args.vlan}"}";
    localAddress = "${args.ip}/${toString vlan.prefix}";
  };

  additionalCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
  enableTun = true;
  extraFlags = lib.mkIf args.enableUserNs [ "-U" ];

  bindMounts = {
    "/run/proc" = lib.mkIf args.enableUserNs {
      hostPath = "/proc";
      isReadOnly = false;
    };

    "/run/sys" = lib.mkIf args.enableUserNs {
      hostPath = "/sys";
      isReadOnly = false;
    };

    "/tmp/net-cls-v1" = {
      hostPath = "/tmp/net-cls-v1";
      isReadOnly = false;
    };
  };

  config = { lib, ... }:
    (lib.mkMerge [
      {
        system.stateVersion = args.stateVersion;
      }

      common.all
      args.extraConfiguration
    ]);
}
