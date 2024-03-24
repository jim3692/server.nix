{ config, lib, pkgs, ... }:

let
  ServerLib = import ../../lib.nix { inherit lib; };
  Container = import ./container.nix;

  containers = lib.mapAttrs (k: v:
    Container {
      name = k;
      args = v;
      vlan = config.server.network.vlans."${v.vlan}";
      dns = if (v.dns != "") then v.dns else config.server.network.dns;
      inherit pkgs;
    }) config.server.containers;

in {
  inherit containers;

  networking.interfaces =
    ServerLib.clearIpFromContainersVeths containers;

  systemd.services = lib.mkMerge [
    # https://github.com/containers/podman/issues/7013#issuecomment-1003525924
    (ServerLib.disableSeccompForContainers config.server.containers)

    (ServerLib.disableNetworkAddressesServices config.server.containers)
  ];
}
