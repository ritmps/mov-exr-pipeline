#!/usr/bin/env python3

import OpenImageIO as oiio
import numpy as np
import sys

W, H = 2048, 1536
levels = 1024  # Simulate 10-bit ProRes quantization

# Create a quantized horizontal ramp
ramp = np.linspace(0, 1, levels, endpoint=True, dtype=np.float32)
ramp = np.repeat(ramp, W // levels + 1)[:W]  # Extend to W pixels
ramp_2d = np.tile(ramp, (H, 1))
rgb = np.stack([ramp_2d] * 3, axis=2)

spec = oiio.ImageSpec(W, H, 3, "float")
buf = oiio.ImageBuf(spec)
buf.set_pixels(oiio.ROI(0, W, 0, H), rgb)

output_filename = sys.argv[1] if len(sys.argv) > 1 else "quantized_ramp.exr"
buf.write(output_filename)
print("✅ Wrote quantized ramp to "+output_filename)