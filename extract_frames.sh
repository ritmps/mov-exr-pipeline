#!/usr/bin/env bash

set -euo pipefail

INPUT_DIR="pro_res_files"
OCIO_CONFIG="./ocio_rec709_to_linear/config.ocio"
LOG_SPACE="srgb_display"
LINEAR_SPACE="linear"
DISPLAY_SPACE="srgb_display"

EXR_OUT_DIR="extracted_exrs"
PNG_OUT_DIR="extracted_pngs"

mkdir -p "$EXR_OUT_DIR" "$PNG_OUT_DIR"

for MOV in "$INPUT_DIR"/*.mov; do
  BASENAME=$(basename "$MOV" .mov)
  TIFF_TMP_DIR="${BASENAME}_tiffs_tmp"
  mkdir -p "$TIFF_TMP_DIR"

  echo "🎞️ Extracting frames from: $MOV"
  ffmpeg -hide_banner -loglevel error -y \
    -i "$MOV" -pix_fmt rgb48le \
    "$TIFF_TMP_DIR/${BASENAME}_%04d.tif"

  for TIFF in "$TIFF_TMP_DIR"/*.tif; do
    FRAME=$(basename "$TIFF" .tif | sed "s/${BASENAME}_//")

    EXR_OUT="$EXR_OUT_DIR/${BASENAME}_${FRAME}.exr"
    PNG_OUT="$PNG_OUT_DIR/${BASENAME}_${FRAME}.png"

    if [[ ! -f "$EXR_OUT" ]]; then
      echo "➤ Converting $TIFF → $EXR_OUT"
      oiiotool "$TIFF" \
        --colorconfig "$OCIO_CONFIG" \
        --colorconvert "$LOG_SPACE" "$LINEAR_SPACE" \
        -d half -o "$EXR_OUT"
    else
      echo "✔️  Skipping existing EXR: $EXR_OUT"
    fi

    if [[ ! -f "$PNG_OUT" ]]; then
      echo "➤ Converting $TIFF → $PNG_OUT"
      oiiotool "$TIFF" \
        --colorconfig "$OCIO_CONFIG" \
        --colorconvert "$LOG_SPACE" "$LINEAR_SPACE" \
        --colorconvert "$LINEAR_SPACE" "$DISPLAY_SPACE" \
        -o "$PNG_OUT"
    else
      echo "✔️  Skipping existing PNG: $PNG_OUT"
    fi
  done

  echo "🧹 Cleaning up TIFFs: $TIFF_TMP_DIR"
  rm -rf "$TIFF_TMP_DIR"
  echo "✅ Done with $BASENAME"
  echo "--------------------------------------------------"
done
