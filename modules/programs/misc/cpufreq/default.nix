{ ... }:
{
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";
        turbo = "always";
      };
      battery = {
        governor = "ondemand";
        turbo = "always";
      };
    };
  };
}
