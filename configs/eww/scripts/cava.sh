#!/bin/bash
# Clean previous pipe if exists
[ -p /tmp/cava.fifo ] && rm /tmp/cava.fifo
mkfifo /tmp/cava.fifo

# Minimal high-framerate config piped to cava
printf "[general]
framerate = 60
bars = 40
sleep_timer = 3
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
" | cava -p /dev/stdin | sed -u 's/;//g;s/0/▁/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g'
