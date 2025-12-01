{ ... }:
{
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "ondemand";
        turbo = "auto";
      };
      battery = {
        governor = "schedutil";
        scaling_max_freq = 3800000;
        turbo = "never";
      };
    };
  };
}
