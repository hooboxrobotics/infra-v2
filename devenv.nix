{ pkgs, lib, config, inputs, ... }:

{
  packages = with pkgs; [
    argocd
    cue
    awscli2
    git
    kustomize
    kubernetes-helm
    opentofu
    starship
  ];

  languages.opentofu = {
    enable     = true;
    lsp.enable = true;
  };

  dotenv.enable   = true;
  starship.enable = true;
}
