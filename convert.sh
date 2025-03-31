#!/bin/bash
# convert

#!/bin/bash
# Batch convert all .mov files in the current directory to .mp4

for file in *.mov; do
    # Extract the filename without extension
    filename="${file%.*}"

    # Convert the file
    ffmpeg -i "$file" \
        -c:v libx265 \
        -tag:v hvc1 \
        -crf 28 \
        -preset slow \
        -pix_fmt yuv420p \
        -an \
        "${filename}.mp4"
done
