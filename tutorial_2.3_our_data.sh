!/bin/bash

# ======================================================================
# dMRI Winter School - Tutorial 2.3

# Theme: Hands-on quality assurance (Our Data)

# Goal: To apply basic processing steps to a clean, provided dataset,
#       learn commands for brain extraction and DTI fitting, and
#       practice visualizing and quality-checking DTI outputs.

# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz (DWI data)
#   - bids_data/sub-01/ses-01/dwi/dwi.bval (b-values)
#   - bids_data/sub-01/ses-01/dwi/dwi.bvec (b-vectors)
#   - bids_data/sub-01/ses-01/anat/t1.nii.gz (T1w anatomical data)

# Outputs:
#   - dwi_denoised.nii.gz (Denoised DWI data)
#   - dwi_preproc.nii.gz (Preprocessed DWI data after denoising, unringing, and bias field correction)
#   - b0.nii.gz (Extracted b0 image)
#   - b0_brain.nii.gz (Skull-stripped b0 image)
#   - b0_brain_mask.nii.gz (Brain mask from b0)
#   - dti.nii.gz (Diffusion Tensor Image)
#   - fa.nii.gz (Fractional Anisotropy map)
#   - md.nii.gz (Mean Diffusivity map)
#   - rgb.nii.gz (RGB map of principal diffusion directions)
#   - ev.nii.gz (Eigenvector map)
# ======================================================================

## Step 1: Inspect Headers

# Pedagogical Context:
# As discussed in Session 2.1, data inspection is the first critical step.
# 'mrinfo' (MRtrix3) and 'fslhd' (FSL) allow us to check image dimensions,
# voxel size, number of volumes, and other crucial metadata. This helps
# ensure consistency with bval/bvec files and identify potential issues early.

echo "Step 1: Inspecting DWI data headers with mrinfo..."
mrinfo bids_data/sub-01/ses-01/dwi/dwi.nii.gz

echo "Step 1: Inspecting DWI data headers with fslhd..."
fslhd bids_data/sub-01/ses-01/dwi/dwi.nii.gz

echo "Step 1: Inspecting T1w data headers with mrinfo..."
mrinfo bids_data/sub-01/ses-01/anat/t1.nii.gz

---

## Step 2: Inspect and Visualize b-values and b-vectors

# Pedagogical Context:
# The b-values and b-vectors are fundamental to dMRI analysis, defining
# the strength and direction of diffusion weighting. Visual inspection
# helps confirm their integrity and proper orientation.

echo "Step 2: Displaying b-values and b-vectors (first few lines)..."
head -n 1 bids_data/sub-01/ses-01/dwi/dwi.bval
head -n 3 bids_data/sub-01/ses-01/dwi/dwi.bvec

## Step 3: Extract b0 image

# Pedagogical Context:
# The b0 image (non-diffusion weighted image) is crucial for many
# preprocessing steps, especially skull-stripping and registration.
# It provides a T2-weighted anatomical reference.

echo "Step 3: Extracting b0 image..."
dwiextract -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval -bzero bids_data/sub-01/ses-01/dwi/dwi.nii.gz - | mrmath - mean b0.nii.gz -axis 3

## Step 4: Skull-Stripping (BET) of b0 and applying it to DWI

# Pedagogical Context:
# Brain Extraction (skull-stripping) is essential to remove non-brain
# tissue (skull, skin, etc.) from the image. This focuses subsequent
# analyses on the brain itself and prevents artifacts from non-brain
# tissue. We use FSL's 'bet' tool.
# As discussed in Session 2.1, a good brain mask is critical.

echo "Step 4: Performing skull-stripping on the b0 image with FSL's BET..."
bet b0.nii.gz b0_brain.nii.gz -m -f 0.2

# Command Explanation:
# 'bet': Brain Extraction Tool from FSL.
# '-m': Generates a binary brain mask.
# '-f 0.2': Sets the fractional intensity threshold. This parameter is crucial
#         and often needs adjustment for different datasets. A value of 0.2
#         is a common starting point, but if the brain is under- or over-stripped,
#         this value should be changed (e.g., lower for more aggressive stripping,
#         higher for less aggressive).
#
# QC Step:
# Load 'b0.nii.gz' and 'b0_brain_mask.nii.gz' in `mrview`.
# Overlay the mask on the b0 image. Ensure the mask accurately covers
# the brain tissue without including non-brain regions or cutting into
# brain matter. A bad BET can severely impact downstream results.

---

## Step 5: Fit the DTI model

# Pedagogical Context:
# As discussed in Session 2.2, the Diffusion Tensor Model simplifies
# complex fiber architecture into a single ellipsoid per voxel. Fitting
# this model allows us to derive quantitative metrics like FA and MD.

echo "Step 5: Fitting the Diffusion Tensor model..."
dwi2tensor bids_data/sub-01/ses-01/dwi/dwi.nii.gz dti.nii.gz -mask b0_brain_mask.nii.gz -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval

## Step 6: Calculate Scalar Maps (FA, MD, RGB, EV)

# Pedagogical Context:
# From the fitted Diffusion Tensor, we can calculate various scalar maps
# that provide insights into tissue microstructure.
# - Fractional Anisotropy (FA): Measures the degree of directionality of
#   diffusion, reflecting white matter integrity.
# - Mean Diffusivity (MD): Measures the average magnitude of diffusion,
#   sensitive to overall water content and cellularity.
# - RGB map: Visualizes the primary diffusion direction, with red for
#   left-right, green for anterior-posterior, and blue for superior-inferior.
# - Eigenvector (EV): The principal eigenvector, representing the main
#   direction of diffusion.
# These maps are critical for quality control and quantitative analysis.

echo "Step 6: Calculating Fractional Anisotropy (FA) map..."
tensor2metric -fa fa.nii.gz \
  -adc md.nii.gz \
  -vector rgb.nii.gz \
  dti.nii.gz \
  -mask b0_brain_mask.nii.gz

# QC Step:
# Load 'fa.nii.gz' and 'rgb.nii.gz' in `mrview`.
# - FA map: Inspect for expected white matter tracts (high FA) and gray matter/CSF (low FA).
# - RGB map: The colors should correspond to the principal diffusion directions.
#   For example, the corpus callosum (connecting hemispheres) should appear red (left-right).
#   Ensure there are no abrupt color changes or inconsistencies, which could indicate
#   issues with b-vector orientation (as discussed in Session 2.4).
# A bad DTI fit or incorrect b-vectors will manifest as unusual patterns in these maps.

echo "Tutorial 2.3 completed. Please inspect the generated FA and RGB maps in mrview for quality control."