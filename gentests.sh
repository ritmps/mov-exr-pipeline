#!/bin/bash

mkdir -p test_frames

#
echo "Creating test frames..."

# Create solid red (RGB)
oiiotool --pattern constant:2048x1536:3 2048x1536 3 --chnames R,G,B --ch R=1,G=0,B=0 -o test_frames/frame_0001.exr

# Solid green
oiiotool --pattern constant:2048x1536:3 2048x1536 3 --chnames R,G,B --ch R=0,G=1,B=0 -o test_frames/frame_0002.exr

# Solid blue
oiiotool --pattern constant:2048x1536:3 2048x1536 3 --chnames R,G,B --ch R=0,G=0,B=1 -o test_frames/frame_0003.exr

echo "Creating ColorChecker frame from Lab TIFF..."

# Download BabelColor ColorChecker Lab TIFF only if necessary
TIF_PATH="ColorChecker_Lab_from_X-Rite_16bit_AfterNov2014/ColorChecker_Lab_from_X-Rite_16bit_AfterNov2014.tif"
ZIP_PATH="ColorChecker_Lab.zip"
if [ ! -f "$TIF_PATH" ]; then
    echo "ColorChecker TIFF not found. Downloading and extracting..."
    if [ ! -f "$ZIP_PATH" ]; then
        curl -sSL -o "$ZIP_PATH" "https://babelcolor.com/index_htm_files/ColorChecker_Lab_from_X-Rite_16bit_AfterNov2014.zip"
    fi
    unzip -o "$ZIP_PATH" -d ColorChecker_Lab_from_X-Rite_16bit_AfterNov2014
fi

# Convert the Lab TIFF to linear RGB EXR using ImageMagick and oiiotool
magick "$TIF_PATH" -colorspace sRGB -depth 16 -define quantum:format=floating-point \
    EXR:test_frames/frame_0004_tmp.exr

oiiotool test_frames/frame_0004_tmp.exr --resize 2048x1536 -d half -o test_frames/frame_0004.exr
rm test_frames/frame_0004_tmp.exr

echo "Creating quantized ramp frame..."
python3 make_quantized_ramp_exr.py test_frames/frame_0005.exr

echo "Creating ramp frame..."
python3 make_ramp_exr.py test_frames/frame_0006.exr

echo "Creating test video..."
ffmpeg -hide_banner -loglevel error -y -r 24 -start_number 1 -i test_frames/frame_%04d.exr -frames:v 6 \
    -c:v prores_ks -profile:v 4 -pix_fmt yuv444p10le test_output.mov

echo "Creating TIFF frames from MOV..."
mkdir -p tiff_frames
ffmpeg -hide_banner -loglevel error -y -i test_output.mov -pix_fmt rgb48le -start_number 1 tiff_frames/frame_%04d.tif

echo "Converting TIFF frames to EXR using OCIO config..."
mkdir -p exr_frames
for f in tiff_frames/*.tif; do
    oiiotool "$f" \
        --colorconfig ./ocio_rec709_to_linear/config.ocio \
        --colorconvert srgb_display linear \
        -d half -o "exr_frames/$(basename "${f%.tif}.exr")"
done

echo "Verifying EXR frames..."
mkdir -p diff_frames
mkdir -p diff_data

THRESH=0.002
CSV=diff_data/diff_summary.csv
echo "frame,mean,rms,psnr,max_error,x,y,channel,orig,roundtrip" > $CSV

# Includes RGB frames, ramp, colorchecker, and quantized ramp
for f in {1..6}; do
    orig="test_frames/frame_$(printf "%04d" $f).exr"
    roundtrip="exr_frames/frame_$(printf "%04d" $f).exr"
    diffimg="diff_frames/frame_$(printf "%04d" $f)_diff.exr"

    echo "🔍 Comparing $orig to $roundtrip"

    oiiotool "$orig" "$roundtrip" --diff --fail $THRESH > diff_data/tmp_diff.txt
    oiiotool "$orig" "$roundtrip" --sub --abs -o "$diffimg"

    # Emphasize differences and render to PNG
    pngimg="diff_frames/frame_$(printf "%04d" $f)_diff.png"
    oiiotool "$diffimg" --mulc 50 --clamp:low=0 --clamp:high=1 -o "$pngimg"

    MEAN=$(grep 'Mean error' diff_data/tmp_diff.txt | awk '{print $4}')
    RMS=$(grep 'RMS error' diff_data/tmp_diff.txt | awk '{print $4}')
    PSNR=$(grep 'Peak SNR' diff_data/tmp_diff.txt | awk '{print $4}')
    MAXERR=$(grep 'Max error' diff_data/tmp_diff.txt | awk '{print $5}')
    MAXINFO=$(grep 'Max error' diff_data/tmp_diff.txt | sed -n 's/.*@ (\(.*\), \(.*\), \(.*\))  values are \(.*\),.* vs \(.*\),.*/\1,\2,\3,"\4","\5"/p')

    echo "$f,$MEAN,$RMS,$PSNR,$MAXERR,$MAXINFO" >> $CSV
    cat diff_data/tmp_diff.txt
    echo ""
done

rm -f diff_data/tmp_diff.txt