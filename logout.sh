#!/bin/bash
onLogout() {

# Run the outset script with the logout parameter
/usr/bin/python /usr/local/outset/outset --logout

exit

}

trap 'onLogout' SIGINT SIGHUP SIGTERM
while true; do
sleep 86400 &
wait $!
done
