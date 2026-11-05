#!/usr/bin/bash
# Clean logout: stop the session's user units while Wayland is still up,
# then quit mango. Quitting first makes every unit exit with a display error.
systemctl --user stop graphical-session.target
exec mmsg dispatch quit
