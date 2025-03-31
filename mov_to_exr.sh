#!/bin/bash

# ---- Config ----
OCIO_CONFIG="./ocio_rec709_to_linear/config.ocio"
COLOR_IN="srgb_display"
COLOR_OUT="linear"

# Check for OCIO config
if [ ! -f "$OCIO_CONFIG" ]; then
    echo "❌ OCIO config not found at $OCIO_CONFIG"
    exit 1
fi

# ---- Main ----
for movfile in *.mov; do
    [ -e "$movfile" ] || continue # skip if no .mov files

    name="${movfile%.*}"
    echo "🎬 Processing: $movfile"

    # Create output dirs
    mkdir -p "tiff_frames/$name" "exr_frames/$name"

    # Step 1: Extract TIFFs
    echo "📥 Extracting TIFFs..."
    ffmpeg -hide_banner -loglevel error -i "$movfile" \
        -pix_fmt rgb48le -start_number 1 \
        "tiff_frames/$name/frame_%04d.tif"

    # Step 2: Convert to EXRs
    echo "🎨 Converting TIFFs to EXRs with OCIO..."
    for tif in tiff_frames/"$name"/*.tif; do
        out="exr_frames/$name/$(basename "${tif%.tif}.exr")"
        oiiotool "$tif" \
            --colorconfig "$OCIO_CONFIG" \
            --colorconvert "$COLOR_IN" "$COLOR_OUT" \
            -d half -o "$out"
    done

    # Optional: Generate display-ready 16-bit PNGs using display LUT
    DISPLAY_OUTDIR="png_frames/$name"
    mkdir -p "$DISPLAY_OUTDIR"

    echo "🖼️ Generating display-ready PNGs (gamma corrected)..."
    for exr in exr_frames/"$name"/*.exr; do
        png_out="$DISPLAY_OUTDIR/$(basename "${exr%.exr}.png")"
        oiiotool "$exr" \
            --colorconfig "$OCIO_CONFIG" \
            --colorconvert "$COLOR_OUT" "$COLOR_IN" \
            -d uint16 -o "$png_out"
    done
    echo "🖼️ PNGs written to $DISPLAY_OUTDIR"

    echo "✅ Done with $movfile → exr_frames/$name/"
done

echo "📝 Note: PNGs are display-referred with LUT applied (for student viewing)."
echo "🎉 All done!"
