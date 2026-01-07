#!/bin/bash
# Fix Rocky template console settings

TEMPLATE_ID=9000
NODE="pve"

# Remove serial port
qm set $TEMPLATE_ID --delete serial0

# Set console to default (not serial)
qm set $TEMPLATE_ID --vga std

echo "Template $TEMPLATE_ID console fixed!"
