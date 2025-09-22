#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Winter School - hands-on 0.0
#
# Theme: Setup and Data Download
#
# Goal: To create a BIDS-compliant directory structure and simulate the
#       presence of our raw dataset for the hands-on sessions.
#
# Outputs:
#   - A 'bids_data' directory with a BIDS-like structure.
#   - Placeholder files for raw DWI and T1w data.
# ======================================================================

# Step 1: Create the BIDS Directory Structure

unzip dicom_filtered_sub01.zip -d data/
mkdir nifti_data
dcm2niix -o nifti_data/ -z y dicom_data/12_09_2023_MT_orientation_sub01/

echo "Step 1: Creating BIDS directory structure..."
mkdir -p bids_data/sub-01/ses-01/dwi
mkdir -p bids_data/sub-01/ses-01/anat
mrconvert nifti_data/12_09_2023_MT_orientation_sub01_WIP_DWI_20230912152935_1201.nii.gz bids_data/sub-01/ses-01/dwi/dwi.nii.gz -stride 1,2,3,4
cp nifti_data/12_09_2023_MT_orientation_sub01_WIP_DWI_20230912152935_1201.bval bids_data/sub-01/ses-01/dwi/dwi.bval
cp nifti_data/12_09_2023_MT_orientation_sub01_WIP_DWI_20230912152935_1201.bvec bids_data/sub-01/ses-01/dwi/dwi.bvec
cp nifti_data/12_09_2023_MT_orientation_sub01_WIP_3D_T1_20230912152935_201.nii.gz bids_data/sub-01/ses-01/anat/t1.nii.gz -stride 1,2,3,4