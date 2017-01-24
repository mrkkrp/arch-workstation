#!/bin/bash
#
# This script turns touchpad on and off
#

synclient TouchpadOff=$(synclient -l | grep -c 'TouchpadOff.*=.*0')
