#!/bin/bash

COMPRESSION_LEVEL=3
OUTPUT_FILE=all_text.tar.xz

find websites -not -path '*/\.*' -type f | rev | sort | rev | tar cf - -T -  | xz -${COMPRESSION_LEVEL} -v -T0 > "$OUTPUT_FILE"
