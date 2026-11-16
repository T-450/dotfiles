#!/bin/sh
# Started by mango -s: the panel is off before sysc-greet picks the monitor for its prompt.
/etc/greetd/greeter-panel
exec /etc/greetd/mango-greeter-session.sh
