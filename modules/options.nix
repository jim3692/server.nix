{ config, lib, ... }:

let
  vmOptions = with lib; {
    ip = mkOption { type = types.str; };
    dns = mkOption { type = types.str; default = ""; };
    gateway = mkOption { type = types.str; default = ""; };
    vlan = mkOption { type = types.str; };
    extraConfiguration =  mkOption { type = types.attrs; default = { }; };
    stateVersion = mkOption { type = types.str; default = config.system.stateVersion; };
    docker = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      privateNetwork = mkOption {
        type = types.bool;
        default = false;
      };
      containers = mkOption { default = {}; };
    };
  };

in {
  config.warnings = lib.filter (w: w != null) [
    (if (config.server.network.defaultGateway != "") then "[DEPRECATION] Option 'config.server.network.defaultGateway' has been moved to 'server.network.vlans.<vlanName>.gateway'" else null)
  ];

  options = with lib; {
    server = {
      containers = mkOption {
        type = types.attrsOf (types.submodule ({ options, ... }: {
          options = vmOptions // {
            enableUserNs = mkOption { type = types.bool; default = false; };
          };
        }));
        default = {};
      };

      vms = mkOption {
        type = types.attrsOf (types.submodule ({ options, ... }: {
          options = vmOptions // {
            vcpus = mkOption { type = types.int; default = 1; };
            ramMb = mkOption { type = types.int; default = 512; };
            volumes = mkOption { default = []; };
          };
        }));
        default = {};
      };

      network = {
        hostName = mkOption { type = types.str; };

        vlans = mkOption {
          type = types.attrsOf (types.submodule ({ options, ... }: {
            options = {
              id = mkOption { type = types.int; };
              ip = mkOption { type = types.str; default = ""; };
              prefix = mkOption { type = types.int; };
              gateway = mkOption { type = types.str; default = ""; };
              parentInterface = mkOption { type = types.str; };
            };
          }));
        };

        defaultGateway = mkOption { type = types.str; default = ""; };
        dns = mkOption { type = types.str; };
      };
    };
  };
}
