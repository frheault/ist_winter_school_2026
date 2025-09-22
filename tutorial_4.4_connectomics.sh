#!/bin/bash
#
# ======================================================================
# dMRI Winter School - Tutorial 4.4 (Part 1: Connectomics)
#
# Theme: Quantitative Analysis - From tracts to tables
#
# Goal: To generate a structural connectome matrix from a whole-brain
#       tractogram and an anatomical parcellation.
#
# Inputs:
#   - bids_data/sub-01/ses-01/anat/t1.nii.gz (T1w image)
#   - wb_100k.tck (Whole-brain tractogram from Tutorial 3.6)
#
# Outputs:
#   - aparc+aseg.nii.gz (Anatomical parcellation from FreeSurfer)
#   - connectome.csv (A node-by-node connectivity matrix)
# ======================================================================

T1_FILE="bids_data/sub-01/ses-01/anat/t1.nii.gz"
TRACTOGRAM="wb_100k.tck"

# ---
#
# ## Step 1: Generate an Anatomical Parcellation
#
# # Pedagogical Context:
# # To build a connectome, we need to define the "nodes" of the network.
# # These nodes are typically anatomical regions of gray matter. We can
# # generate these regions by running a FreeSurfer parcellation on the
# # subject's T1-weighted anatomical image.
#
# # Command Explanation:
# # 'recon-all' is the main FreeSurfer processing pipeline. Running the
# # full pipeline can take many hours. For this tutorial, we will simulate
# # its output. In a real analysis, you would run the command below.
# # The key output we need is 'aparc+aseg.nii.gz', which is a NIfTI file
# # where each cortical and subcortical region is labeled with a unique integer.
#
echo "Step 1: Generating anatomical parcellation with FreeSurfer..."
echo "# ---"
echo "# In a real analysis, you would run the following command (takes several hours):"
echo "# export SUBJECTS_DIR=."
echo "# recon-all -s sub-01 -i $T1_FILE -all"
echo "# mri_convert sub-01/mri/aparc+aseg.mgz aparc+aseg.nii.gz"
echo "# ---"
# For this tutorial, we will use the segmentation we already generated from the FA map
# in tutorial 2.6, as it is a good approximation.
cp fa_synthseg.nii.gz aparc+aseg.nii.gz
echo "Using existing segmentation (aparc+aseg.nii.gz) as a stand-in for FreeSurfer output."
echo

# ---
#
# ## Step 2: Build the Connectivity Matrix
#
# # Pedagogical Context:
# # Now that we have the network nodes (from the parcellation) and the
# # pathways between them (the tractogram), we can build the connectome.
# # The 'tck2connectome' tool counts how many streamlines connect every
# # pair of regions in our parcellation atlas.
#
# # Command Explanation:
# # 'tck2connectome' is the MRtrix tool for this task.
# # -symmetric : Makes the output matrix symmetric (connection A->B is the same as B->A).
# # -zero_diagonal : Sets the diagonal of the matrix to zero (connections from a region to itself).
# # The inputs are the tractogram and the parcellation file.
# # The output is a CSV file that can be opened in any spreadsheet or data analysis software.
#
echo "Step 2: Building the streamline-count connectome..."
tck2connectome "$TRACTOGRAM" aparc+aseg.nii.gz connectome.csv -symmetric -zero_diagonal
echo "Generated connectome.csv"
echo

# # QC Step: Inspect the Matrix
# # You can open 'connectome.csv' in a spreadsheet program. It will be a large
# # matrix of numbers, where the rows and columns correspond to the integer labels
# # in the 'aparc+aseg.nii.gz' file. The value in each cell is the number of
# # streamlines connecting those two brain regions.
# #
# # For more advanced analysis, you would load this matrix into Python or R to
# # perform graph theory analysis, as discussed in lecture 4.2.

echo "Tutorial 4.4 (Part 1) complete. You have generated a structural connectome."
