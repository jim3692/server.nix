{
  description = "A flake providing a framework for steamlined declarative management of NixOS containers and VMs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    microvm = {
      url = "github:jim3692/microvm.nix/console-in-unix-sock";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, microvm, ... }@inputs:
    {
      nixosModules = {
        microvm = microvm.nixosModules.host;
        server = import ./modules;
      };
    };
}
