#!/bin/bash

set -x

find ../vhdl -type f | while read f
do
	vcom "$f" | grep "Errors: 0" >/dev/null || echo "ERROR compiling $f"
done
