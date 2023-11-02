# Preparing Data 

The DL4MicEverywhere notebooks are designed to work with common microscopy image formats and require your data to be structured in a specific way. Here are some tips for preparing your data to use with the notebooks:

## Supported Image Formats

The notebooks support uncompressed image formats:

- TIFF (.tif)
- PNG (.png)
- JPEG (.jpg)

Other formats like proprietary microscope files or **compressed TIFFs** are not directly supported. You will need to convert these to one of the above formats first. Fiji/ImageJ could be useful for this. Check the [troubleshoot](TROUBLESHOOT.md) page.

## Data Organization 

Organize your image data into separate folders:

- `raw` - Contains the raw input images 
- `labels` - Contains any ground truth labels
- `train` - Training images (can symlink from raw)
- `test` - Test images (can symlink from raw)

This folder structure is expected by many of the notebooks. 

## Ground Truth

For supervised learning notebooks, you need ground truth labels, such as:

- Segmentation masks 
- Landmarks or contours
- Class labels

Store labels in common formats like PNG masks or CSV files. Ensure labels correspond to the right input images.

## Training vs Test Split 

Split your data into separate training and test sets. A common split is 80% training, 20% test.

Use symlinking to avoid duplicating data between the `train` and `test` folders.

## Resizing

Many notebooks require a consistent image size, typically 512x512 or 256x256 pixels. Resize your images to match the expected notebook input shape.

Use a Lanczos or cubic interpolation method for best results when downsizing.

## Normalization 

Normalize pixel values to the 0-1 range. This improves training stability.

In Python:

```python
img = img / 255.0
```

## Data Augmentation

Applying data augmentation (rotations, flips, zooms, etc) to your training data can help improve model robustness and prevent overfitting.

Use the Albumentations library to augment microscopy data.

## Review Data

Spot check images after preparation to ensure proper formats, clean labels, and no corruption or artifacts.

Fix any issues before starting training to avoid errors or poor results.
