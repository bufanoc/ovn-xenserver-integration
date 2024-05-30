#!/bin/bash

# Variables (set these as per your environment)
OVN_NB_IP="192.168.3.100"  # IP address of the OVN Northbound database
OVN_SB_IP="192.168.3.100"  # IP address of the OVN Southbound database

# Install necessary packages (update this if needed for your distribution)
echo "=== Installing necessary packages ==="
sudo yum install -y openvswitch ovn-central ovn-host

# Enable and start the OVS and OVN services
echo "=== Enabling and starting services ==="
sudo systemctl enable openvswitch
sudo systemctl start openvswitch
sudo systemctl enable ovn-controller
sudo systemctl start ovn-controller

# Configure OVS to use OVN
echo "=== Configuring OVS ==="
sudo ovs-vsctl set open . external_ids:ovn-remote="tcp:$OVN_SB_IP:6642"
sudo ovs-vsctl set open . external_ids:ovn-nb="tcp:$OVN_NB_IP:6641"
sudo ovs-vsctl set open . external_ids:ovn-encap-ip="$HOST_IP"
sudo ovs-vsctl set open . external_ids:ovn-encap-type="geneve"

# Verify the OVN configuration
echo "=== Verifying OVN configuration ==="
sudo ovs-vsctl show

# Create OVN logical networks (run this part only once on the central node)
if [ "$(hostname)" == "central-node" ]; then
  echo "=== Setting up OVN logical networks ==="
  
  # Create logical switches and ports
  ovn-nbctl lswitch-add ls0
  ovn-nbctl lport-add ls0 lsp-port1
  ovn-nbctl lport-set-addresses lsp-port1 00:00:00:00:00:01

  # Create logical router and connect it to the logical switch
  ovn-nbctl lr-add lr0
  ovn-nbctl lrp-add lr0 lrp-port0 00:00:00:00:00:02 192.168.3.1/24
  ovn-nbctl lsp-add ls0 lsp-port0
  ovn-nbctl lsp-set-type lsp-port0 router
  ovn-nbctl lsp-set-addresses lsp-port0 00:00:00:00:00:02
  ovn-nbctl lsp-set-options lsp-port0 router-port=lrp-port0
fi

echo "=== OVN setup completed ==="
