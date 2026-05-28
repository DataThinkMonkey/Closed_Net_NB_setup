#!/bin/bash
# pcpi_prepare.sh - Run this on PCpi (Trixie) while CONNECTED TO THE INTERNET

set -e

echo "=== Preparing clean offline staging directories ==="
mkdir -p ~/offline_assets/apt
mkdir -p ~/offline_assets/pip

# Purge any old data to ensure clean packaging
rm -rf ~/offline_assets/apt/*
rm -rf ~/offline_assets/pip/*

cd ~/offline_assets/apt

echo "--> Updating package definitions..."
sudo apt-get update

echo "--> Gathering lean system infrastructure packages..."
# By downloading only pip, venv, dev headers, and media-types,
# we bypass all desktop/IDLE GUI package dependency errors entirely.
PACKAGES="python3-pip python3-venv python3-dev media-types"

echo "--> Downloading system packages (.deb)..."
apt-get download $PACKAGES

# Double check files downloaded
FILE_COUNT=$(ls -1 *.deb 2>/dev/null | wc -l)
echo "--> System packages downloaded successfully: $FILE_COUNT files."

# 2. Download Python Packages natively
cd ~/offline_assets/pip
echo "--> Downloading Jupyter wheels and dependencies..."
python3 -m pip download --prefer-binary jupyter notebook

echo "========================================================="
echo "=== LEAN CACHING SUCCESSFUL! ==="
echo "========================================================="
echo "Disconnect PCpi, link to IoTpi, and spin up the server:"
echo "cd ~/offline_assets && python3 -m http.server 8080"
