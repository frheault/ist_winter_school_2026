#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Winter School - hands-on 4.4 (Part 1: Connectomics)
#
# Theme: Quantitative Analysis - From tracts to tables
#
# Goal: To generate a structural connectome matrix from a whole-brain
#       tractogram and an anatomical parcellation.
#
# Inputs:
#   - bids_data/sub-01/ses-01/anat/t1.nii.gz (T1w image)
#   - wb_100k.tck (Whole-brain tractogram from hands-on session 3.6)
#
# Outputs:
#   - aparc+aseg.nii.gz (Anatomical parcellation from FreeSurfer)
#   - connectome.csv (A node-by-node connectivity matrix)
# ======================================================================

T1_FILE="bids_data/sub-01/ses-01/anat/t1.nii.gz"
TRACTOGRAM="wb_100k.tck"

# Step 1: Generate an Anatomical Parcellation
#
echo "Step 1: Generating anatomical parcellation with FreeSurfer..."
echo "# In a real analysis, you would run the following command (takes several hours):"
echo "export SUBJECTS_DIR=."
echo "recon-all -s sub-01 -i $T1_FILE -all"
echo "mri_convert sub-01/mri/aparc+aseg.mgz aparc+aseg.nii.gz"
# For this hands-on session, we will use the segmentation we already generated from the FA map
# in hands-on session 2.6, as it is a good approximation.

mri_synthseg --i fa.nii.gz --o fa_synthseg.nii.gz --parc --robust 
# Go on https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/AnatomicalROI/FreeSurferColorLUT?action=raw and CTRL-S
# Delete the first and last few line to keep only the Table
echo "Using existing segmentation (aparc+aseg.nii.gz) as a stand-in for FreeSurfer output."
echo

# Step 2: Build the Connectivity Matrix
echo "Step 2: Building the streamline-count connectome..."
tck2connectome "$TRACTOGRAM" aparc+aseg.nii.gz connectome.csv -out_assignments assignments.txt
# scilpy alternative for tck2connectome (multi-step)
# scil_tractogram_segment_connections_from_labels "$TRACTOGRAM" aparc+aseg.nii.gz connections.h5
# scil_connectivity_compute_matrices connections.h5 aparc+aseg.nii.gz --streamline_count connectome.npy
echo "Generated connectome.csv"
echo

# QC Step: Inspect the Matrix
mkdir connections/
connectome2tck "$TRACTOGRAM" assignments.txt connections/edge-
# scilpy alternative
# scil_tractogram_convert_hdf5_to_trk connections.h5 connectome/

echo "hands-on session 4.4 (Part 1) complete. You have generated a structural connectome."
