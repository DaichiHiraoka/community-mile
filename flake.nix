{
  description = "Chiiki Kyosei dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };
        lib = pkgs.lib;

        mkDevImage = { name, packages, env ? { }, workdir ? "/workspace", cmd ? [ "bash" "-lc" "sleep infinity" ] }:
          pkgs.dockerTools.buildLayeredImage {
            name = name;
            tag = "dev";
            contents = packages ++ [
              pkgs.bashInteractive
              pkgs.coreutils
              pkgs.git
              pkgs.cacert
            ];
            config = {
              WorkingDir = workdir;
              Cmd = cmd;
              Env = lib.mapAttrsToList (k: v: "${k}=${v}") env;
            };
          };

        androidSdk = pkgs.androidenv.composeAndroidPackages {
          platformVersions = [ "34" ];
          buildToolsVersions = [ "34.0.0" ];
          includeEmulator = false;
          includeSystemImages = false;
        };

        androidSdkRoot = "${androidSdk.androidsdk}/libexec/android-sdk";

        apiImage = mkDevImage {
          name = "community-mile-api";
          packages = [ pkgs.jdk17 pkgs.gradle pkgs.maven ];
        };

        webImage = mkDevImage {
          name = "community-mile-web";
          packages = [ pkgs.nodejs_20 pkgs.pnpm ];
        };

        androidImage = mkDevImage {
          name = "community-mile-android";
          packages = [ pkgs.jdk17 pkgs.gradle androidSdk.androidsdk ];
          env = {
            ANDROID_SDK_ROOT = androidSdkRoot;
            ANDROID_HOME = androidSdkRoot;
          };
        };

        loadImages = pkgs.writeShellApplication {
          name = "load-images";
          runtimeInputs = [ pkgs.docker ];
          text = ''
            set -euo pipefail
            docker load < ${apiImage}
            docker load < ${webImage}
            docker load < ${androidImage}
          '';
        };
      in
      {
        packages = {
          api-image = apiImage;
          web-image = webImage;
          android-image = androidImage;
          load-images = loadImages;
        };

        apps.load-images = flake-utils.lib.mkApp {
          drv = loadImages;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.jdk17
            pkgs.gradle
            pkgs.maven
            pkgs.nodejs_20
            pkgs.pnpm
            pkgs.docker
            pkgs.docker-compose
          ];
        };
      });
}
