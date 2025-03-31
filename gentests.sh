#!/opt/homebrew/bin/bash

mkdir -p test_frames

#
echo "Creating test frames..."

# Create solid red (RGB)
oiiotool --pattern constant:2048x1536:3 2048x1536 3 --chnames R,G,B --ch R=1,G=0,B=0 -o test_frames/frame_0001.exr

# Solid green
oiiotool --pattern constant:2048x1536:3 2048x1536 3 --chnames R,G,B --ch R=0,G=1,B=0 -o test_frames/frame_0002.exr

# Solid blue
oiiotool --pattern constant:2048x1536:3 2048x1536 3 --chnames R,G,B --ch R=0,G=0,B=1 -o test_frames/frame_0003.exr

echo "Creating ColorChecker frame..."
# Approximate Macbeth ColorChecker with 24 color patches
# Each patch is 4x6 grid = 8 rows, 6 cols, each patch 256x256
python3 make_colorchecker_exr.py

echo "Creating ramp frame..."
echo "Creating quantized ramp frame..."
python3 make_quantized_ramp_exr.py

echo "Creating test video..."

ffmpeg -y -hide_banner -loglevel error -r 24 -start_number 1 -i test_frames/frame_%04d.exr -frames:v 6 \
    -c:v prores_ks -profile:v 4 -pix_fmt yuv444p10le test_output.mov

echo "Creating TIFF frames from MOV..."

mkdir -p tiff_frames
ffmpeg -y -hide_banner -loglevel error -i test_output.mov -pix_fmt rgb48le -start_number 1 tiff_frames/frame_%04d.tif

echo "Converting TIFF frames to EXR using OCIO config..."
mkdir -p exr_frames
for f in tiff_frames/*.tif; do
    oiiotool "$f" \
        --colorconfig ./ocio_rec709_to_linear/config.ocio \
        --colorconvert srgb_display linear \
        -d half -o "exr_frames/$(basename "${f%.tif}.exr")"
done

echo "Verifying EXR frames..."
# Includes RGB frames, ramp, colorchecker, and quantized ramp
for f in {1..6}; do
    orig="test_frames/frame_$(printf "%04d" $f).exr"
    roundtrip="exr_frames/frame_$(printf "%04d" $f).exr"
    echo "🔍 Comparing $orig to $roundtrip"
    oiiotool "$orig" "$roundtrip" --diff --fail 0.01
done
