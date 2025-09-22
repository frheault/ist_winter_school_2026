#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Winter School - hands-on 3.6 (Our Data)
#
# Theme: Hands-on bundle segmentation
#
# Goal: To perform both manual-style and automated bundle segmentation to
#       extract anatomically meaningful pathways from a whole-brain
#       tractogram.
#
# Inputs:
#   - wmfod.nii.gz (fODFs from hands-on session 3.3)
#   - dwi_b0_brain_mask.nii.gz (Brain mask from Day 2)
#   - fa_synthseg.nii.gz (Anatomical segmentation from hands-on session 2.6)
#
# Outputs:
#   - wb_100k.tck (A whole-brain tractogram)
#   - CST_L.tck (Left Corticospinal Tract, manually segmented)
#   - A directory ('bundleseg_automated') with automatically segmented bundles
# ======================================================================

WMFOD="wmfod.nii.gz"
MASK="b0_brain_mask.nii.gz"
ATLAS="fa_cc.nii.gz"

# ---
#
# Step 0: Generate a Whole-Brain Tractogram
#
mri_synthseg --i b0_brain.nii.gz --o b0_synthseg.nii.gz --robust --parc --cpu
ATLAS="b0_synthseg.nii.gz.nii.gz"

echo "Step 0: Generating a whole-brain tractogram (100k streamlines)..."
# Create a whole-brain seed mask (in this case, the brain mask is sufficient)
tckgen "$WMFOD" wb_100k.tck -seed_image "$MASK" -mask "$MASK" -select 100000
echo "Generated wb_100k.tck"
echo

# ---
#
# Step 1: Manual-Style Segmentation with ROIs
#
echo "Step 1: Performing manual-style segmentation of the Corticospinal Tract..."

# Create the inclusion ROIs from the SynthSeg atlas
# Label 1024: Left Precentral Gyrus
# Label 16: Brainstem
mrcalc "$ATLAS" 1024 -eq precentral_L_roi.nii.gz
mrcalc "$ATLAS" 16 -eq brainstem_roi.nii.gz

# Command Explanation:
# 'tckedit' is the MRtrix tool for filtering tractograms.
# -include : Specifies an inclusion ROI.
# The command below reads as: "From wb_100k.tck, keep only the
# streamlines that pass through precentral_L_roi.nii.gz AND also
# pass through brainstem_roi.nii.gz".
tckedit wb_100k.tck CST_L.tck -include precentral_L_roi.nii.gz -include brainstem_roi.nii.gz
echo "Generated CST_L.tck"
echo

# ---
#
# Step 2: Automated Segmentation with BundleSeg
#
# echo "Step 2: Performing automated segmentation with BundleSeg..."

# Download the necessary model for BundleSeg
curl https://zenodo.org/records/10103446/files/config.zip?download=1 -o config.zip
curl https://zenodo.org/records/10103446/files/atlas.zip?download=1 -o atlas.zip
unzip config.zip -d zenodo_scil_atlas 
unzip atlas.zip -d zenodo_scil_atlas
rm atlas.zip config.zip

# Command Explanation:
# 'scil_tractogram_segment_with_bundleseg.py' is the script for this task.
# It takes the whole-brain tractogram and a directory for the output bundles.
# --bdo : Specifies the output directory for bundle-specific data objects.
scil_tractogram_segment_with_bundleseg wb_100k.tck zenodo_scil_atlas/config_fss_1.json zenodo_scil_atlas/atlas/ from_mni0GenericAffine.mat --out_dir bundleseg_automated --inverse --processes 4
echo "Automated segmentation complete. Results are in the 'bundleseg_automated' directory."
echo

echo "hands-on session 3.6 complete. You have extracted specific white matter bundles from a tractogram."
