#!/usr/bin/env sh

mkisofs -max-iso9660-filenames \
        -untranslated-filenames \
        -allow-multidot \
        -omit-period \
        -V ignition \
        -o "${1:-ignition.iso}" disk
