{ ... }:
{
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto";
      };
      battery = {
        governor = "ondemand";
        scaling_max_freq = 3800000;
        turbo = "auto";
      };
    };
  };
}
