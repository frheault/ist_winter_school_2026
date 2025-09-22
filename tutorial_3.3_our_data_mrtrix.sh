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

# ---
#
# ## Step 1: Estimate the Fiber Response Function (FRF)
#
# # Pedagogical Context:
# # As discussed in lecture 3.2, Constrained Spherical Deconvolution (CSD)
# # needs to know what the signal from a single, coherent fiber population
# # looks like. This is called the Fiber Response Function (FRF). We can
# # estimate this directly from the data by looking for voxels that most
# # resemble single-fiber white matter.
#
# # Command Explanation:
# # 'dwi2response' is the MRtrix3 tool for FRF estimation.
# # The 'tournier' algorithm is a robust method that iteratively finds
# # the most anisotropic voxels to build the response function.
#
echo "Step 1: Estimating the Single-Shell Single-Tissue (SSST) Fiber Response Function..."
dwi2response tournier "$DWI_BRAIN" frf.txt -fslgrad "$BVEC_FILE" "$BVAL_FILE" -mask "$MASK"
echo "Generated frf.txt"
echo

# # QC Step: Visualize the FRF
# # > shview frf.txt
# # Check that the response function looks like a sharp, prolate (cigar-shaped)
# # sphere. This confirms the algorithm found appropriate single-fiber voxels.

# ---
#
# ## Step 2: Fit the SSST-CSD Model
#
# # Pedagogical Context:
# # Now that we have the FRF, we can perform CSD. The algorithm "deconvolves"
# # the FRF from the signal in each voxel, leaving a function that describes
# # the orientation of all fiber populations in that voxel. This function is
# # the Fiber Orientation Distribution (fODF).
#
# # Command Explanation:
# # 'dwi2fod csd' is the tool for fitting the CSD model.
# # We provide the preprocessed DWI, the FRF, and a mask.
#
echo "Step 2: Fitting the SSST-CSD model to get fODFs..."
dwi2fod csd "$DWI_BRAIN" frf.txt wmfod.nii.gz -mask "$MASK" -fslgrad "$BVEC_FILE" "$BVAL_FILE"
echo "Generated wmfod.nii.gz"
echo

# # QC Step: Visualize the fODFs
# # > mrview fa.nii.gz -odf.load_sh wmfod.nii.gz
# #
# # Go to a known fiber crossing, like the intersection of the Corpus Callosum
# # and the Corticospinal tract. You should see fODF glyphs with multiple lobes,
# # representing the multiple fiber directions that the DTI tensor could not resolve.
# # Compare this to the single ellipsoid you saw with the DTI model on Day 2.

# ---
#
# ## Step 3: Run Probabilistic Tractography
#
# # Pedagogical Context:
# # Probabilistic tractography uses the fODF to generate streamlines. Instead
# # of just following the brightest peak (like deterministic tracking), it
# # samples from the full distribution of orientations provided by the fODF.
# # This allows it to better handle uncertainty and complex fiber architecture.
#
# # Command Explanation:
# # 'tckgen' is used again, but this time with the default iFOD2 algorithm.
# # -act 5tt.nii.gz : (Optional but recommended) Use anatomical constraints.
# #                   We will skip this for simplicity in this tutorial.
# # -seed_image : Our CC mask, same as before.
# # -mask : Our whole-brain mask, same as before.
# # wmfod.nii.gz : The input orientation data is now our fODF image.
#
echo "Step 3: Running probabilistic CSD tractography..."
tckgen -seed_image "$CC_SEED" \
       -mask "$MASK" \
       -select 10000 \
       wmfod.nii.gz csd_prob_cc_10k.tck
echo "Generated csd_prob_cc_10k.tck"
echo

# # QC Step: Compare Tractograms
# # > mrview fa.nii.gz -tractography.load dti_det_cc_10k.tck -tractography.load csd_prob_cc_10k.tck
# #
# # Load both the deterministic DTI tractogram from Day 2 and the new
# # probabilistic CSD tractogram. Notice how the probabilistic version may
# # appear "fuzzier" and have better coverage into the fanning fibers of the CC.
# # This reflects the algorithm's ability to explore multiple pathways based on
# # the fODF.

echo "Tutorial 3.3 complete. You have performed CSD modeling and probabilistic tractography."
