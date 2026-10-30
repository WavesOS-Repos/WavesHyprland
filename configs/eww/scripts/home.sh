#!/bin/bash
df -P "$HOME" | awk 'END {printf "%d", $5}' | tr -d '%'
