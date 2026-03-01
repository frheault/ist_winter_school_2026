#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Winter School - Tutorial 3.6 (Our Data)
#
# Theme: Hands-on bundle segmentation
#
# Goal: To perform both manual-style and automated bundle segmentation to
#       extract anatomically meaningful pathways from a whole-brain
#       tractogram.
#
# Inputs:
#   - wmfod.nii.gz (fODFs from hands-on session 3.3)
#   - b0_mean_bet_mask.nii.gz (Brain mask from Day 2)
#   - fa_synthseg.nii.gz (Anatomical segmentation from hands-on session 2.6)
#
# Outputs:
#   - wb_100k.tck (A whole-brain tractogram)
#   - CST_L.tck (Left Corticospinal Tract, manually segmented)
#   - A directory ('bundleseg_automated') with automatically segmented bundles
# ======================================================================

# # Step 1: Generate a Whole-Brain Tractogram
# --> Run synthseg to extract rough anatomical segmentation for seeding and masking
mri_synthseg --i b0_mean_bet.nii.gz --o b0_synthseg.nii.gz --robust --parc --cpu
# If the previous command fail (on MacOS) or due to RAM usage, you can transform the labels
# from template/mni_synthseg.nii.gz using yesterday's flirt/ants command.

# --> Optional - Extract WM mask from the Syntheseg output to seed tractography
mri_extract_label b0_synthseg.nii.gz 2 41 -o wm_mask.nii.gz

# [MRtrix Version]
# mrcalc b0_synthseg.nii.gz 2 -eq wm_mask.nii.gz

# --> Generate whole-brain tractogram 
echo "Step 1: Generating a whole-brain tractogram (250k streamlines)..."
tckgen wmfod.nii.gz wb_250k.tck -seed_image wm_mask.nii.gz -mask b0_mean_bet_mask.nii.gz -select 250000
# scilpy alternative for tckgen
# scil_tracking_local wmfod.nii.gz b0_mean_bet_mask.nii.gz b0_mean_bet_mask.nii.gz wb_250k.tck --algo prob --nt 250000
echo "Generated wb_250k.tck"
echo

# # Step 2: Manual-Style Segmentation with ROIs
echo "Step 2: Performing manual-style segmentation of the Corticospinal Tract..."
# Fully manual: Transform tck to trk for track_vis virtual dissections
scil_tractogram_convert wb_250k.tck wb_250k.trk --reference b0_synthseg.nii.gz

# Semi-automated: Create the inclusion ROIs from the SynthSeg atlas
# Label 1024: Left Precentral Gyrus
# Label 16: Brainstem
mrcalc b0_synthseg.nii.gz 1024 -eq precentral_L_roi.nii.gz
# scilpy alternative for mrcalc
# scil_volume_math lower_threshold_eq b0_synthseg.nii.gz 1024 precentral_L_roi.nii.gz
# scil_volume_math upper_threshold_eq precentral_L_roi.nii.gz 1024 precentral_L_roi.nii.gz -f
mrcalc b0_synthseg.nii.gz 16 -eq brainstem_roi.nii.gz
# scilpy alternative for mrcalc
# scil_volume_math lower_threshold_eq b0_synthseg.nii.gz 16 brainstem_roi.nii.gz
# scil_volume_math upper_threshold_eq brainstem_roi.nii.gz 16 brainstem_roi.nii.gz -f

# --> Modify whole-brain tractogram to extract specific stremalines passing through both ROIs
# Command explanation: 'tckedit' is the MRtrix tool for filtering tractograms.
# -include : Specifies an inclusion ROI.
# The command below reads as: "From wb_250k.tck, keep only the
# streamlines that pass through precentral_L_roi.nii.gz AND also
# pass through brainstem_roi.nii.gz".
tckedit wb_250k.tck CST_L.tck -include precentral_L_roi.nii.gz -include brainstem_roi.nii.gz
# scilpy alternative for tckedit
# scil_tractogram_filter_by_roi wb_250k.tck CST_L.tck --drawn_roi precentral_L_roi.nii.gz either_end include --drawn_roi brainstem_roi.nii.gz either_end include --reference b0_mean_bet_mask.nii.gz
echo "Generated CST_L.tck"
echo

# # Step 3: Automated Segmentation with BundleSeg
echo "Step 3: Performing automated segmentation with BundleSeg..."

# Download the necessary model for BundleSeg
curl https://zenodo.org/records/10103446/files/config.zip?download=1 -o config.zip
curl https://zenodo.org/records/10103446/files/atlas.zip?download=1 -o atlas.zip
unzip -q config.zip -d zenodo_scil_atlas
unzip -q atlas.zip -d zenodo_scil_atlas
rm atlas.zip config.zip

# Command Explanation:
# 'scil_tractogram_segment_with_bundleseg.py' is the script for this task.
# It takes the whole-brain tractogram and a directory for the output bundles.
# --bdo : Specifies the output directory for bundle-specific data objects.
scil_tractogram_segment_with_bundleseg wb_250k.tck zenodo_scil_atlas/config_fss_1.json zenodo_scil_atlas/atlas/ from_mni_fsl_ras_fix.txt \
	--out_dir bundleseg_automated --modify_distance_thr 1 --inverse --processes 4 -v DEBUG --reference b0_mean_bet.nii.gz
echo "Automated segmentation complete. Results are in the 'bundleseg_automated' directory."
echo

echo "Tutorial 3.6 complete. You have extracted specific white matter bundles from a tractogram."
