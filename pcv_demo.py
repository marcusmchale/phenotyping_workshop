#!./venv/bin/python
from plantcv import plantcv as pcv
from pathlib import Path
import argparse


def options():
    parser = argparse.ArgumentParser(description="Image processing")
    parser.add_argument("-i", "--image", help="Input image file", required=True)
    parser.add_argument("-o", "--outdir", help="Output directory", required=False)
    parser.add_argument("-D", "--debug", '--feature', action=argparse.BooleanOptionalAction, help="Turn on debug, prints intermediate images.")
    return parser.parse_args()


def main():
    args = options()
    if args.debug:
        pcv.params.debug = "plot"
    # Import the image file
    img, path, filename = pcv.readimage(args.image)
    # Convert RGB to HSV and extract the Saturation channel
    s = pcv.rgb2gray_hsv(img, 's')
    # Threshold the Saturation image
    s_thresh = pcv.threshold.binary(s, 50, 255)
    # Convert RGB to LAB and extract the Blue channel
    b = pcv.rgb2gray_lab(img, 'b')
    # Threshold the blue image
    b_thresh = pcv.threshold.binary(b, 125, 255)
    # Join the threshold images
    bs = pcv.logical_and(s_thresh, b_thresh)
    # Fill small holes
    bs_fill = pcv.fill_holes(bs)
    # Fill small objects
    bs_fill2 = pcv.fill(bs_fill, 40)
    # Apply as mask to img
    masked_img = pcv.apply_mask(img, bs_fill2, mask_color='white')
    # Output image to file
    mask_path = Path(args.outdir, "masked", Path(args.image).stem).with_suffix('.png')
    mask_path.parent.mkdir(parents=True, exist_ok=True)
    pcv.print_image(masked_img, str(mask_path))


main()
