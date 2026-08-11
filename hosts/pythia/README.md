# Pythia

Pythia is a remote workstation for the GMKtec EVO-X2.

The host starts Hyprland automatically. It locks the session after startup.
Sunshine streams that session through Moonlight.
T3 Code listens only on the Tailscale address.

## Hardware setup

Replace `hardware-configuration.nix` with data from the EVO-X2 before deployment.
The current file is a copy of the Athena hardware file.

Set the firmware UMA frame buffer to its smallest value.
Use 512 MB when that value is available.
The NixOS configuration gives TTM 100 GB of shared memory.
This value requires the 128 GB EVO-X2 model.

Use the factory power supply.
Select the firmware performance mode when sustained cooling is available.
Enable automatic startup after a power failure.

## First connection

Join the private Headscale network:

```console
sudo tailscale up --login-server=https://headscale.allie.sh
```

Open `https://pythia.tailnet.allie.sh:47990` from the tailnet.
Create the first Sunshine account.
Add `pythia.tailnet.allie.sh` to Moonlight and complete pairing.

Create a T3 Code pairing link:

```console
t3 pair
```

Enter the link in the T3 Code desktop client.
The direct endpoint uses `http://pythia.tailnet.allie.sh:3773`.

## GPU checks

Run these checks after the first boot:

```console
uname -r
rocminfo
clinfo
vainfo
amd-smi metric
```

Open LM Studio and install its AMD ROCm runtime.
Select that runtime before loading a model.
