#!/usr/bin/env python3
# This script generates a ColorChecker image in EXR format using OpenImageIO.

import OpenImageIO as oiio
import numpy as np

W, H = 2048, 1536
cols, rows = 6, 4
patch_w, patch_h = W // cols, H // rows

# BabelColor sRGB values (normalized to 0–1), then linearized
def srgb_to_linear(c):
    a = []
    for v in c:
        if v <= 0.04045:
            a.append(v / 12.92)
        else:
            a.append(((v + 0.055) / 1.055) ** 2.4)
    return a

# sRGB 0–1 values from BabelColor Macbeth ColorChecker D65 reference
srgb_patches = [
    [0.400, 0.350, 0.290], [0.760, 0.470, 0.410], [0.385, 0.560, 0.750], [0.710, 0.710, 0.420],
    [0.270, 0.420, 0.190], [0.820, 0.370, 0.450], [0.240, 0.310, 0.600], [0.730, 0.480, 0.300],
    [0.260, 0.270, 0.280], [0.790, 0.790, 0.790], [0.320, 0.420, 0.660], [0.340, 0.660, 0.430],
    [0.650, 0.280, 0.300], [0.300, 0.400, 0.700], [0.700, 0.700, 0.100], [0.240, 0.600, 0.450],
    [0.400, 0.300, 0.500], [0.650, 0.550, 0.250], [0.300, 0.350, 0.750], [0.060, 0.060, 0.060],
    [0.200, 0.200, 0.200], [0.360, 0.360, 0.360], [0.520, 0.520, 0.520], [0.720, 0.720, 0.720]
]

patches = [srgb_to_linear(rgb) for rgb in srgb_patches]

img = np.zeros((H, W, 3), dtype=np.float32)

for i, rgb in enumerate(patches):
    col = i % cols
    row = i // cols
    x0 = col * patch_w
    y0 = row * patch_h
    img[y0:y0+patch_h, x0:x0+patch_w, :] = rgb

spec = oiio.ImageSpec(W, H, 3, "float")
buf = oiio.ImageBuf(spec)
buf.set_pixels(oiio.ROI(0, W, 0, H), img)
buf.write("test_frames/frame_0005.exr")
print("✅ Wrote ColorChecker to test_frames/frame_0005.exr")