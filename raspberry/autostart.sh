#!/bin/bash

export PATH=/usr/local/bin:$PATH
export DISPLAY=:0.0
sleep 5
python3 /home/pi/remote-landscapes/scrape.py
sclang /home/pi/remote-landscapes/remote-landscapes.scd
