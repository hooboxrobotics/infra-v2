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

  env = {
    AWS_DEFAULT_REGION = "sa-east-1";
  };

  languages.opentofu = {
    enable     = true;
    lsp.enable = true;
  };

  dotenv.enable   = true;
  starship.enable = true;
}
