# Initial server configuration with ignition and combustion

This repository contains a template configuration to initially setup a machine using
[ignition](https://en.opensuse.org/Portal:MicroOS/Ignition) & [combustion](https://en.opensuse.org/Portal:MicroOS/Combustion),
and a script to generate a configuration from based on a `.env` file.

This configuration can then be [embedded into a qcow2 image](https://www.matthiaspreu.com/posts/fedora-coreos-embed-ignition-config/) and tested with qemu,
or further modified to your liking,
or put on a USB-drive with the label `ignition` to be supplied to a system on its first boot.

## Requirements

- gettext for the `envsubst` command
- butane (or podman/docker) to generate the ignition config 
- guestfs-tools (to edit the qcow2 image) 

## Usage

Create a copy of `example.env` and fill its values.
Run `./generate-ignition.sh` to generate the missing config files from the templates.

