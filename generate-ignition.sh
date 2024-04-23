#!/usr/bin/env bash
##########################
## Copyright (C) 2024 stendler
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.
##########################


# determine butane binary
if [ -z "$ign_butane_bin" ]; then
  if command -v butane &> /dev/null; then
    ign_butane_bin=$(command -v butane)
  elif command -v podman &> /dev/null; then
    ign_butane_bin="podman run -i --rm --volume ${PWD}:/pwd --workdir /pwd --security-opt label=disable quay.io/coreos/butane:release"
  elif command -v docker &> /dev/null; then
    ign_butane_bin="docker run -i --rm --volume ${PWD}:/pwd --workdir /pwd --security-opt label=disable quay.io/coreos/butane:release"
  else
    echo "ign_butane_bin is not set and could not find a butane or podman/docker binary."
    exit 1
  fi
fi

if ! command -v envsubst &> /dev/null; then
  echo "envsubst from the gettext package required for env substitute is missing. Aborting..."
  exit 1
fi

# source and export configuration
env_file="${1:-.env}"
if [ ! -f "$env_file" ]; then
  echo "File '${env_file}' not found. Aborting..."
  exit 1
fi
set -a
source "$env_file"
set +a


# go through required env vars and abort if not present
if [ -z "${ign_hostname}" ]; then
  echo "ign_hostname not set. Aborting.."
  exit 1
fi

if [ -z "${ign_user}" ]; then
    echo "ign_user not set. Aborting.."
    exit 1
fi

if [ -z "$ign_password_hash" ]; then
    echo "ign_password_hash not set. Aborting.."
    exit 1
fi

if [ -z "$ign_ssh_public_key" ]; then
  if [ -z "${ign_ssh_public_key_location}" ]; then
        echo "ign_ssh_public_key_location not set. Aborting.."
        exit 1
  fi
  export ign_ssh_public_key=$(cat "$ign_ssh_public_key_location")
fi


printf "\n---------\nUsing the following configuration:\n\n"
env | grep -e "ign_" -e "combustion_" | sort
printf "\n---------\n"
read -p "Continue with this configuration? [Y/n] " confirmation
case $confirmation in
  Y|y|'') echo ;;
  *) echo "Aborted..." ; exit 0 ;;
esac

envsubst <templates/sshd_server.conf '$ign_sshd_port $ign_user' >files/etc/ssh/sshd_config.d/sshd_server.conf

envsubst <templates/combustion.conf >disk/combustion/config

# substitute these variables via sed and feed it into butane
envsubst <templates/ignition.yaml '$ign_hostname $ign_user $ign_password_hash $ign_ssh_public_key $ign_keymap' \
  | $ign_butane_bin --pretty --strict --files-dir=files >disk/ignition/config.ign
