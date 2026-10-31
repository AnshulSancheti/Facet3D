#!/usr/bin/env python3
"""Detect the observed solid-black mobile rendering regression in gameplay captures.
Requires Pillow. This complements visual inspection; it is not general visual QA.
"""
from pathlib import Path
import json
import sys
from PIL import Image

results=[]
for name in sys.argv[1:]:
    image=Image.open(name).convert('RGB')
    w,h=image.size
    region=image.crop((round(w*.1),round(h*.2),round(w*.9),round(h*.8)))
    pixels=region.get_flattened_data()
    count=sum(max(pixel)<3 for pixel in pixels)
    fraction=count/(region.width*region.height)
    results.append({'capture':str(Path(name)), 'black_pixels':count, 'central_black_fraction':fraction,'passed':fraction<0.003})
print(json.dumps(results,indent=2))
if not results or not all(result['passed'] for result in results):
    raise SystemExit(1)
