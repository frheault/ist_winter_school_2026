#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.

# ======================================================================
# dMRI Winter School - hands-on 2.3

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

# Step 1: Inspect Headers

echo "Step 1: Inspecting DWI data headers with mrinfo..."
mrinfo bids_data/sub-01/ses-01/dwi/dwi.nii.gz

echo "Step 1: Inspecting DWI data headers with fslhd..."
fslhd bids_data/sub-01/ses-01/dwi/dwi.nii.gz

echo "Step 1: Inspecting T1w data headers with mrinfo..."
mrinfo bids_data/sub-01/ses-01/anat/t1.nii.gz

# Step 2: Inspect and Visualize b-values and b-vectors

echo "Step 2: Displaying b-values and b-vectors (first few lines)..."
head -n 1 bids_data/sub-01/ses-01/dwi/dwi.bval
head -n 3 bids_data/sub-01/ses-01/dwi/dwi.bvec

# Step 3: Extract b0 image

echo "Step 3: Extracting b0 image..."
dwiextract -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval -bzero bids_data/sub-01/ses-01/dwi/dwi.nii.gz - | mrmath - mean b0.nii.gz -axis 3

# Step 4: Skull-Stripping (BET) of b0 and applying it to DWI


# Step 5: Fit the DTI model

echo "Step 5: Fitting the Diffusion Tensor model..."
dwi2tensor bids_data/sub-01/ses-01/dwi/dwi.nii.gz dti.nii.gz -mask b0_brain_mask.nii.gz -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval

# Step 6: Calculate Scalar Maps (FA, MD, RGB, EV)

echo "Tutorial 2.3 completed. Please inspect the generated FA and RGB maps in mrview for quality control."