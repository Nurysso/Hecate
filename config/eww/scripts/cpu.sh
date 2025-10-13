#!/bin/bash
awk -v FS=" " '{usage=($2+$4)*100/($2+$4+$5)} END {print int(usage)}' /proc/stat
