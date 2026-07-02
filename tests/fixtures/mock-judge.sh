#!/usr/bin/env bash
# Mock judge: ignore stdin, emit the canned headless-output file given as $1.
cat > /dev/null
cat "$1"
