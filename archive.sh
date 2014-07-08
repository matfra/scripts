#!/bin/sh
find /cygdrive/c/Mathieu/tools/kitty/logs -mtime +2 -name "*.log" -exec gzip {} \;
