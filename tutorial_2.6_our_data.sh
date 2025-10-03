#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Winter School - hands-on 2.6 (Our Data) - EXECUTABLE VERSION
#
# Theme: Hands-on deterministic tractography
#
# Goal: To perform a first whole-brain deterministic tractography, learn how
#       to use a segmentation mask as a seed region, and practice basic
#       visualization and quality control of a tractogram.
#
# Inputs:
#   - fa.nii.gz (Fractional Anisotropy map from hands-on session 2.3)
#   - b0_mean_bet_mask.nii.gz (Brain mask from hands-on session 2.3)
#
# Outputs:
#   - fa_synthseg.nii.gz (Anatomical segmentation)
#   - cc_mask.nii.gz (Corpus Callosum seed mask)
#   - dti_det_cc_10k.tck (Tractogram of the Corpus Callosum)
# ======================================================================

# 
#
# Step 1: Generate an Anatomical Segmentation
#
echo "Step 1: Generating anatomical segmentation from the FA map..."
# Step 1: Generate an Anatomical Segmentation (Skipped due to issues)
antsRegistrationSyNQuick.sh -d 3 -f fa.nii.gz -m template/mni_masked.nii.gz -o from_mni
antsApplyTransforms -d 3 -i template/cc.nii.gz -o fa_cc.nii.gz -r fa.nii.gz -t from_mni1Warp.nii.gz from_mni0GenericAffine.mat -u char -n NearestNeighbor


# Step 2: Run Deterministic DTI Tractography (Whole-brain for testing)

echo "Step 3: Running whole-brain deterministic DTI tractography for testing..."

mrcalc bids_data/sub-01/ses-01/dwi/dwi.nii.gz b0_mean_bet_mask.nii.gz -mult dwi_brain.nii.gz
# scilpy alternative for mrcalc
# scil_volume_math multiplication bids_data/sub-01/ses-01/dwi/dwi.nii.gz b0_mean_bet_mask.nii.gz dwi_brain.nii.gz
mrconvert dwi_brain.nii.gz dwi_brain.mif -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval -force
mrthreshold fa.nii.gz fa_thr.nii.gz -abs 0.1 -force
# scilpy alternative for mrthreshold
# scil_volume_math lower_threshold fa.nii.gz 0.1 fa_thr.nii.gz
tckgen -algorithm Tensor_Det \
       -seed_image fa_cc.nii.gz \
       -mask fa_thr.nii.gz \
       -select 10000 \
       dwi_brain.mif \
       dti_det_cc_10k.tck -force

# SCILPY alternative:
# scil_dti_metrics dwi_brain.nii.gz bids_data/sub-01/ses-01/dwi/dwi.bval bids_data/sub-01/ses-01/dwi/dwi.bvec -mask dwi_b0_mean_bet_mask.nii.gz
# scil_volume_math lower_threshold fa.nii.gz 0.1 fa_thr.nii.gz --data_type uint8
#scil_tracking_local tensor_evecs_v1.nii.gz fa_cc.nii.gz fa_thr.nii.gz dti_det_cc_10k.tck --algo eudx --nt 10000 -f
# scil_tractogram_convert dti_det_cc_10k.trk dti_det_cc_10k.tck -f
echo "Generated dti_det_cc_10k.tck"
echo

echo "hands-on session 2.6 complete. You have generated your first tractogram."
