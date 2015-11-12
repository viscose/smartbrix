#!/bin/sh

# Cleans up everything

fleetctl list-units | awk '/running/ {print $1}' | xargs fleetctl destroy
fleetctl destroy *.service
fleetctl unload *.service
fleetctl load -no-block *.service



exit