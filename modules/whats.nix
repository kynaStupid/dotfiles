{ config, pkgs, lib, ... }:

{
  home.file.".local/bin/whats".source = ../config/whats/whats;
}
