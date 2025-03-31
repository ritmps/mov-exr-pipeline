#!/usr/bin/env python3
# This script generates a ramp image in EXR format using OpenImageIO.

import OpenImageIO as oiio
import numpy as np

W, H = 2048, 1536
ramp = np.linspace(0, 1, W, dtype=np.float32)
ramp_2d = np.tile(ramp, (H, 1))
rgb = np.stack([ramp_2d]*3, axis=2)

spec = oiio.ImageSpec(W, H, 3, "float")
buf = oiio.ImageBuf(spec)
buf.set_pixels(oiio.ROI(0, W, 0, H), rgb)
buf.write("test_frames/frame_0004.exr")
