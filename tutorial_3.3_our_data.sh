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
#   - b0_mean_bet_mask.nii.gz (Brain mask from Day 2)
#   - cc_mask.nii.gz (Corpus Callosum seed from Day 2)
#   - bids_data/sub-01/ses-01/dwi/dwi.bval
#   - bids_data/sub-01/ses-01/dwi/dwi.bvec
#
# Outputs:
#   - wmfod.nii.gz (White Matter Fiber Orientation Distribution)
#   - csd_prob_cc_10k.tck (Probabilistic tractogram of the CC)
# ======================================================================

# # Step 1: Estimate the Fiber Response Function (FRF)
echo "Step 1: Estimating the Single-Shell Single-Tissue (SSST) Fiber Response Function..."
dwi2response tournier dwi_brain.nii.gz frf.txt -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval -mask b0_mean_bet_mask.nii.gz

# [scilpy Version]
# scil_frf_ssst dwi_brain.nii.gz bids_data/sub-01/ses-01/dwi/dwi.bval bids_data/sub-01/ses-01/dwi/dwi.bvec frf.txt --mask b0_mean_bet_mask.nii.gz

echo "Generated frf.txt"
echo

# # Step 2: Fit the SSST-CSD Model
echo "Step 2: Fitting the SSST-CSD model to get fODFs..."
dwi2fod csd dwi_brain.nii.gz frf.txt wmfod.nii.gz -mask b0_mean_bet_mask.nii.gz -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval

# [scilpy Version]
# scil_fodf_ssst dwi_brain.nii.gz bids_data/sub-01/ses-01/dwi/dwi.bval bids_data/sub-01/ses-01/dwi/dwi.bvec frf.txt wmfod.nii.gz --mask b0_mean_bet_mask.nii.gz

echo "Generated wmfod.nii.gz"
echo

# # Step 3: Run Probabilistic Tractography
echo "Step 3: Running probabilistic CSD tractography..."
tckgen -seed_image fa_cc.nii.gz -mask b0_mean_bet_mask.nii.gz -select 10000 wmfod.nii.gz csd_prob_cc_10k.tck

# [scilpy Version]
# scil_tracking_local wmfod.nii.gz fa_cc.nii.gz fa_thr.nii.gz csd_prob_cc_10k.tck --algo prob --nt 10000 --sh_basis tournier07

# [FSL Version]
#(See alternative below for the FSL workflow)

echo "Tutorial 3.3 complete. You have performed CSD modeling and probabilistic tractography."

# [FSL Version]
# Step 2 Alternative: Fit Tensor and cleanup
# dtifit -k dwi_brain.nii.gz -m b0_mean_bet_mask.nii.gz -r bids_data/sub-01/ses-01/dwi/dwi.bvec -b bids_data/sub-01/ses-01/dwi/dwi.bval -o dti
# rm -f dti_L2.nii.gz dti_L3.nii.gz dti_V2.nii.gz dti_V3.nii.gz dti_MO.nii.gz dti_S0.nii.gz

# Step 3 Alternative: Standard FSL workflow (bedpostx + probtrackx2)
# 1. Prepare directory for bedpostx (FSL expects specific filenames)
# mkdir -p fsl_data
# cp dwi_brain.nii.gz fsl_data/data.nii.gz
# cp b0_mean_bet_mask.nii.gz fsl_data/nodif_brain_mask.nii.gz
# cp bids_data/sub-01/ses-01/dwi/dwi.bval fsl_data/bvals
# cp bids_data/sub-01/ses-01/dwi/dwi.bvec fsl_data/bvecs
#
# 2. Run bedpostx (WARNING: This takes a long time on CPU, use -n 1 for 1 fiber to speed up)
# bedpostx fsl_data -n 1
#
# 3. Run deterministic FACT-style tracking (nsamples=1)
# probtrackx2 -x fa_cc.nii.gz -m fsl_data.bedpostX/nodif_brain_mask -s fsl_data.bedpostX/merged --dir=probtrackx_results --nsamples=1 --opd --forcedir
#
# 4. Run standard probabilistic tracking (default nsamples=5000)
# probtrackx2 -x fa_cc.nii.gz -m fsl_data.bedpostX/nodif_brain_mask -s fsl_data.bedpostX/merged --dir=probtrackx_results_prob --opd --forcedir
