#!/usr/bin/env sh

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

# go through required env vars and ask for value if not set
if [ -z "${ign_hostname}" ]; then
  read -p "ign_hostname is not set. Set value: " ign_hostname
  export ign_hostname
fi

if [ -z "${ign_user}" ]; then
  read -p "ign_user is not set. Set value: " ign_user
  export ign_user
fi

if [ -z "$ign_password_hash" ]; then
  echo "No password hash set in ign_password_hash - generating a new one?"
  if command -v mkpasswd &> /dev/null; then
    export ign_password_hash=$(mkpasswd --method=yescrypt)
  elif command -v openssl &> /dev/null; then
    export ign_password_hash=$(openssl passwd -6)
  else
    echo "Neither mkpasswd nor openssl found for generating a password. Exiting."
    exit 1
  fi
fi

if [ -z "$ign_ssh_public_key" ]; then
  if [ -z "${ign_ssh_public_key_location}" ]; then
    read -p "ign_ssh_public_key_location is not set. Set value: " ign_ssh_public_key_location
  fi
  export ign_ssh_public_key=$(cat "$ign_ssh_public_key_location")
fi


printf "\n---------\nUsing the following configuration:\n\n"
env | grep ign_
printf "\n---------\n"
read -p "Continue with this configuration? [Y/n] " confirmation
case $confirmation in
  Y|y|'') echo ;;
  *) echo "Aborted..." ; exit 0 ;;
esac

envsubst <templates/sshd_server.conf '$ign_sshd_port $ign_user' >files/etc/ssh/sshd_config.d/sshd_server.conf

# substitute these variables via sed and feed it into butane
envsubst <templates/ignition.yaml '$ign_hostname $ign_user $ign_password_hash $ign_ssh_public_key' \
  | $ign_butane_bin --pretty --strict --files-dir=files >ignition/config.ign
