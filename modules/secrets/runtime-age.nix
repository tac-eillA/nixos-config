{ ... }:

{
  sops.age = {
    keyFile = "/var/lib/sops-nix/age-key.txt";
    generateKey = false;
  };
}
