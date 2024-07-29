{ lib }:

let helpers = {
  getBridgeName = name: "br-${name}";
  getVmVethName = name: "${name}-veth0";
  mapAttrsAndKeys = callback: list:
    (lib.foldl' (acc: value: acc // (callback value)) { } list);
};

in {
  inherit helpers;

  getBridgesFromVlans = vlans:
    let
      vlansWithoutIp = lib.filter (vlanName: vlans."${vlanName}".ip == "")
        (lib.attrNames vlans);
    in helpers.mapAttrsAndKeys (vlanName:
      let bridgeName = helpers.getBridgeName "${vlanName}";
      in { "${bridgeName}".interfaces = [ "${vlanName}" ]; }) vlansWithoutIp;

  getInterfacesWithIpsFromVlans = vlans:
    let
      vlansWithIp = lib.filter (vlanName: vlans."${vlanName}".ip != "")
        (lib.attrNames vlans);
    in helpers.mapAttrsAndKeys (vlanName:
      let vlan = vlans."${vlanName}";
      in {
        "${vlanName}".ipv4.addresses = [{
          address = vlan.ip;
          prefixLength = vlan.prefix;
        }];
      }) vlansWithIp;

  getGatewayFromFirstVlanWithIpAndGateway = vlans:
    let
      vlansWithIp = lib.filter (vlanName: vlans."${vlanName}".ip != "" && vlans."${vlanName}".gateway != "")
        (lib.attrNames vlans);
    in vlans.${builtins.head vlansWithIp}.gateway;

  getInterfacesWithIpsAndGatewaysFromVlansCount = vlans:
    let
      vlansWithIp = lib.filter (vlanName: vlans."${vlanName}".ip != "" && vlans."${vlanName}".gateway != "")
        (lib.attrNames vlans);
    in builtins.length vlansWithIp;

  disableDhcpForVlanParents = vlans:
    helpers.mapAttrsAndKeys (vlanName:
      let vlan = vlans."${vlanName}";
      in { "${vlan.parentInterface}".useDHCP = lib.mkForce false; }
    ) (lib.attrNames vlans);

  clearIpFromContainersVeths = containers:
    helpers.mapAttrsAndKeys (containerName:
      let vethName = helpers.getVmVethName containerName;
      in {
        "${vethName}" = {
          useDHCP = lib.mkForce false;
          ipv4.addresses = lib.mkForce [ ];
        };
      }) (lib.attrNames containers);

  disableSeccompForContainers = containers:
    helpers.mapAttrsAndKeys (containerName:
      let service = "container@${containerName}";
      in { "${service}".environment.SYSTEMD_SECCOMP = "0"; })
    (lib.attrNames containers);

  disableNetworkAddressesServices = vms:
    helpers.mapAttrsAndKeys (vmName:
      let service = "network-addresses-${helpers.getVmVethName vmName}";
      in { "${service}".enable = false; }) (lib.attrNames vms);

  generateRandomMac = name:
    let
      hash = builtins.hashString "sha256" name;
      c = off: builtins.substring off 2 hash;
    in
      "${builtins.substring 0 1 hash}2:${c 2}:${c 4}:${c 6}:${c 8}:${c 10}";

  getBridgesJsonFile = { vms }:
    let
      data = helpers.mapAttrsAndKeys (vmName: (
        let bridgeName = helpers.getBridgeName vms."${vmName}".vlan;
        in { "${helpers.getVmVethName vmName}" = bridgeName; }
      )) (lib.attrNames vms);

      json = builtins.toJSON data;
    in
      builtins.toFile "bridges.json" json;

  getDnsConfig = dns: {
    environment.etc."resolv.conf" = lib.mkForce {
      source = builtins.toFile "resolv.conf" "nameserver ${dns}";
      mode = "0644";
    };
  };
}
