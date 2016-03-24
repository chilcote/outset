#!/bin/bash

# Replace this script with your scripts
# which you want to run on demand.

/usr/bin/osascript -e 'display notification "Replace this script with scripts of your own!" with title "Outset"'

# invoke login-once scripts during this on-demand run
/usr/local/outset/outset --login-once

# invoke login-every scripts during this on-demand run
/usr/local/outset/outset --login-every
