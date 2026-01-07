#!/bin/bash
# Start all VMs created by Terraform

echo "Starting VMs..."

# Learning VMs
qm start 7001
qm start 7002

# Production VMs
# qm start 1001

echo "VMs started!"
