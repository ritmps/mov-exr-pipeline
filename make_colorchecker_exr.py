#!/usr/bin/env python3
# This script generates a ColorChecker image in EXR format using OpenImageIO.

import OpenImageIO as oiio
import numpy as np

W, H = 2048, 1536
cols, rows = 6, 4
patch_w, patch_h = W // cols, H // rows

# sRGB linear values (approximate) for the 24 patches (R, G, B) in row-major order
# Source: BabelColor reference values (normalized to 0–1 linear sRGB)
# Note: These values are illustrative; feel free to adjust if you want true reference accuracy
patches = [
    [0.172, 0.084, 0.055], [0.566, 0.231, 0.196], [0.145, 0.208, 0.423], [0.506, 0.451, 0.124],
    [0.105, 0.187, 0.090], [0.550, 0.141, 0.201], [0.099, 0.122, 0.345], [0.435, 0.217, 0.112],
    [0.141, 0.135, 0.141], [0.594, 0.593, 0.593], [0.106, 0.147, 0.423], [0.141, 0.459, 0.134],
    [0.455, 0.115, 0.122], [0.090, 0.145, 0.408], [0.481, 0.459, 0.045], [0.105, 0.350, 0.234],
    [0.197, 0.112, 0.247], [0.447, 0.308, 0.129], [0.206, 0.225, 0.508], [0.059, 0.059, 0.059],
    [0.215, 0.215, 0.215], [0.404, 0.404, 0.404], [0.596, 0.596, 0.596], [0.797, 0.797, 0.797]
]

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