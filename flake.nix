{
  description = "NixOS RPi3 - Adguard";

  # Build
  # nix build .#nixosConfigurations.adguard314.config.system.build.sdImage

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, nixpkgs, nixos-hardware, ... }: {
    nixosConfigurations.adguard314 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        nixos-hardware.nixosModules.raspberry-pi-3
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"

        ({ pkgs, lib, ... }: {
          sdImage.compressImage = false;
          image.fileName = "adguard314.img"; 
          boot.kernelPackages = pkgs.linuxPackages;
          boot.supportedFilesystems = lib.mkForce [ "vfat" "fat32" "exfat" "ext4" "btrfs" ];

          boot.loader.grub.enable = false;
          boot.loader.generic-extlinux-compatible.enable = true;

          zramSwap.enable = true; # Highly recommended for 4GB/8GB Pis
          networking.hostName = "adguard314";
          time.timeZone = "UTC";
          services.tailscale = {
            enable = true;
            #extraUpFlags = [ "--ssh" "--login-server=" ];
          };

          users.users.nixguard = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            initialPassword = "password";
            packages = with pkgs; [
              age
              btop
              tmux
            ];
          };

          services.adguardhome = {
            enable = true;
            host = "10.0.0.106";
            openFirewall = true;
            allowDHCP = false;
          };  

          networking.firewall.allowedTCPPorts = [ 
            80    # AdGuard UI (after setup)
            3000  # AdGuard Setup (initial)
          ];
          networking.firewall.allowedUDPPorts = [ 
            53    # DNS (Crucial for AdGuard to actually work)
          ];

          nix.settings.trusted-users = [ "root" "nixguard" ];
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          system.stateVersion = "25.11";
        })
      ];
    };
  };
}

