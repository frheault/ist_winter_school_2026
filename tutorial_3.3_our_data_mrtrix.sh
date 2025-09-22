#!/bin/bash
#
# ======================================================================
# dMRI Winter School - Tutorial 3.3 (Our Data) - MRtrix Version
#
# Theme: Hands-on fODF and Tractography
#
# Goal: To fit a CSD model to resolve crossing fibers, and to perform
#       probabilistic tractography from the CSD result.
#
# Inputs:
#   - dwi_brain.nii.gz (Skull-stripped DWI from Day 2)
#   - dwi_b0_brain_mask.nii.gz (Brain mask from Day 2)
#   - cc_mask.nii.gz (Corpus Callosum seed from Day 2)
#   - bids_data/sub-01/ses-01/dwi/dwi.bval
#   - bids_data/sub-01/ses-01/dwi/dwi.bvec
#
# Outputs:
#   - wmfod.nii.gz (White Matter Fiber Orientation Distribution)
#   - csd_prob_cc_10k.tck (Probabilistic tractogram of the CC)
# ======================================================================

DWI_BRAIN="dwi_brain.nii.gz"
MASK="b0_brain_mask.nii.gz"
BVAL_FILE="bids_data/sub-01/ses-01/dwi/dwi.bval"
BVEC_FILE="bids_data/sub-01/ses-01/dwi/dwi.bvec"
CC_SEED="fa_cc.nii.gz"

# Step 1: Estimate the Fiber Response Function (FRF)
echo "Step 1: Estimating the Single-Shell Single-Tissue (SSST) Fiber Response Function..."
dwi2response tournier "$DWI_BRAIN" frf.txt -fslgrad "$BVEC_FILE" "$BVAL_FILE" -mask "$MASK"
echo "Generated frf.txt"
echo

# Step 2: Fit the SSST-CSD Model
echo "Step 2: Fitting the SSST-CSD model to get fODFs..."
dwi2fod csd "$DWI_BRAIN" frf.txt wmfod.nii.gz -mask "$MASK" -fslgrad "$BVEC_FILE" "$BVAL_FILE"
echo "Generated wmfod.nii.gz"
echo

# Step 3: Run Probabilistic Tractography
echo "Step 3: Running probabilistic CSD tractography..."
tckgen -seed_image "$CC_SEED" \
       -mask "$MASK" \
       -select 10000 \
       wmfod.nii.gz csd_prob_cc_10k.tck
echo "Generated csd_prob_cc_10k.tck"
echo

echo "Tutorial 3.3 complete. You have performed CSD modeling and probabilistic tractography."
