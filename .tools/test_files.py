import pandas as pd

raw_data= sorted([
 ('3D-RCAN', 1, 1, 1, 0, 0, 0),
 ('CARE (2D)', 1, 1, 1, 0, 0, 1),
 ('CARE (3D)', 1, 1, 3, 0, 0, 3),
 ('Cellpose (2D and 3D)', 1, 1, 2, 1, 1, 2),
 ('CycleGAN', 1, 1, 1, 0, 0, 3),
 ('DFCAN', 1, 1, 1, 0, 0, 0),
 ('DRMIME', 1, 1, 1, 0, 0, 0),
 ('DecoNoising (2D)', 1, 1, 3, 0, 0, 0),
 ('Deep-STORM', 1, 1, 1, 0, 0, 1),
 ('DenoiSeg', 1, 1, 1, 0, 0, 0),
 ('Detectron2', 1, 1, 1, 0, 0, 0),
 ('EmbedSeg (2D)', 1, 1, 1, 0, 0, 0),
 ('FRUNet', 1, 1, 3, 0, 0, 0),
 # ('Interactive Segmentation - Kaibu (2D)', 0, 0, 0, 0, 0, 0),
 ('Label-free prediction (fnet) 2D', 1, 1, 2, 0, 0, 0),
 ('Label-free prediction (fnet) 3D', 1, 1, 2, 0, 0, 0),
 ('MaskRCNN (2D)', 1, 1, 1, 0, 0, 0),
 ('Noise2Void (2D)', 1, 1, 3, 0, 0, 0),
 ('Noise2Void (3D)', 1, 1, 3, 0, 0, 0),
 ('RetinaNet', 1, 1, 1, 0, 0, 0),
 ('SplineDist (2D)', 1, 1, 1, 0, 0, 0),
 ('StarDist (2D)', 1, 1, 3, 1, 1, 0),
 ('StarDist (3D)', 1, 1, 3, 0, 0, 0),
 ('U-Net (2D)', 1, 1, 2, 0, 0, 1),
 ('U-Net (2D) Multilabel', 1, 1, 2, 1, 1, 1),
 ('U-Net (3D)', 1, 1, 2, 0, 0, 0),
 ('WGAN', 1, 1, 1, 0, 0, 0),
 ('YOLOv2', 1, 1, 1, 0, 0, 0),
 ('pix2pix', 1, 1, 1, 1, 1, 1)]
)

data = {"Network": [], "configuration.yaml": [], "Building AMD64": [], "Building ARM64": [], "Working AMD64": [], "Working GPU": [], "Working ARM64": []}

for e in raw_data:
  for value, key in zip(e, data.keys()):
    if key == "Working GPU":
      if data["Working AMD64"][-1] == 1:
        value = 1
    if key == "Building ARM64" and data["Building AMD64"][-1] == 3:
      value = 3
    if key in ["Building AMD64","Building ARM64","Working AMD64","Working ARM64", "configuration.yaml", "Working GPU"]:
      if value == 0:
        data[key].append(" :small_orange_diamond: ")
      elif value == 1:
        data[key].append(" :white_check_mark: ")
      elif value == 2:
        data[key].append(" :apple: ")
      else:
        data[key].append(" :x: ")
    else:
      data[key].append(value)

df = pd.DataFrame(
    data=data
)

#print(df.to_markdown(tablefmt="grid"))
print(df.to_markdown())
