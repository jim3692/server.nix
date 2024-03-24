{ ... }: {
  imports = [ ./containers ./vms ];

  virtualisation.libvirtd.enable = true;

  fileSystems."/tmp/net-cls-v1" = {
    device = "none";
    fsType = "cgroup";
    options = [ "net_cls" ];
  };
}
