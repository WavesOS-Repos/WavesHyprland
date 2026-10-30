#!/bin/bash
date +%^A | sed 's/./&\n/g' | sed '/^$/d'
