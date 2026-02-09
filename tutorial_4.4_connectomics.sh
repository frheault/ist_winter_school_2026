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
TRACTOGRAM="wb_250k.tck"

# Step 1: Generate an Anatomical Parcellation
#
echo "Step 1: Generating anatomical parcellation with FreeSurfer..."
echo "# In a real analysis, you would run the following command (takes several hours):"
echo "export SUBJECTS_DIR=."
echo "recon-all -s sub-01 -i $T1_FILE -all"
echo "mri_convert sub-01/mri/aparc+aseg.mgz aparc+aseg.nii.gz"
# For this hands-on session, we will use an AI segmentation from an b0 we already generated in 3.6

echo "Using existing segmentation (aparc+aseg.nii.gz) as a stand-in for FreeSurfer output."
labelconvert b0_synthseg.nii.gz template/FreeSurferColorLUT.txt template/MrtrixLUT.txt synthseg_relabeled_nodes.nii.gz
echo

# Step 2: Build the Connectivity Matrix
echo "Step 2: Building the streamline-count connectome..."
tck2connectome "$TRACTOGRAM" synthseg_relabeled_nodes.nii.gz connectome.csv -out_assignments assignments.txt
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

# Step 3: Visualize the connectome
echo "Step 3: Visualizing the connectome..."
echo "Launching mrview to inspect the connectome."
echo "In the connectome tool window (could be hidden behind the main window):"
echo "  - Go to 'File' -> 'Load matrix' -> 'connectome.csv'"
echo "  - In 'Edge visualisation', change 'Visibility' to 'All'"
echo "  - To see anatomical labels, go to 'File' -> 'Load node stats' -> and select 'synthseg_relabeled_nodes.nii.gz'"
mrview fa.nii.gz -connectome.init synthseg_relabeled_nodes.nii.gz -connectome.load connectome.csv

echo "For more advanced visualization options, refer to the MRtrix3 documentation:"
echo "https://mrtrix.readthedocs.io/en/latest/quantitative_structural_connectivity/connectome_tool.html"
# Added per user request: https://mrtrix.readthedocs.io/en/latest/quantitative_structural_connectivity/connectome_tool.html
echo "For more advanced visualization options, refer to the MRtrix3 documentation: https://mrtrix.readthedocs.io/en/latest/quantitative_structural_connectivity/connectome_tool.html"