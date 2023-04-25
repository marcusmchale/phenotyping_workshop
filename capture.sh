#!/bin/bash 

libcamera-jpeg -t 10 -q 100 --shutter 1000 --gain 0 --awbgains 0,0 –immediate -o ~/raw/$(date +%F_%Hh%Mm)_${HOSTNAME}.jpg
