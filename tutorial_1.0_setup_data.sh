#!/bin/bash
#
# ======================================================================
# dMRI Winter School - Tutorial 0.0
#
# Theme: Setup and Data Download
#
# Goal: To create a BIDS-compliant directory structure and simulate
#       the presence of our raw dataset for the hands-on sessions.
#
# Outputs:
#   - A 'winter_school_data' directory with a BIDS-like structure.
#   - Placeholder files for raw DWI and T1w data.
# ======================================================================

# ---
#
# ## Step 1: Create the BIDS Directory Structure
#
# # Pedagogical Context:
# # The Brain Imaging Data Structure (BIDS) is a standard for organizing
# # neuroimaging data. It makes datasets easy to understand and use with
# # automated analysis tools (like pyAFQ, which we'll use on Day 4).
# # A typical structure includes subject, session, and data type directories.
# #
# # - sub-01: Subject 01
# # - ses-01: Session 01
# # - dwi/:    Directory for Diffusion-Weighted Imaging data
# # - anat/:   Directory for Anatomical data (like a T1w image)
#

mkdir nifti_data
dcm2niix -o nifti_data/ -z y dicom_data/12_09_2023_MT_orientation_sub01/

echo "Step 1: Creating BIDS directory structure..."
mkdir -p bids_data/sub-01/ses-01/dwi
mkdir -p bids_data/sub-01/ses-01/anat
mrconvert nifti_data/12_09_2023_MT_orientation_sub01_WIP_DWI_20230912152935_1201.nii.gz bids_data/sub-01/ses-01/dwi/dwi.nii.gz -stride 1,2,3,4
cp nifti_data/12_09_2023_MT_orientation_sub01_WIP_DWI_20230912152935_1201.bval bids_data/sub-01/ses-01/dwi/dwi.bval
cp nifti_data/12_09_2023_MT_orientation_sub01_WIP_DWI_20230912152935_1201.bvec bids_data/sub-01/ses-01/dwi/dwi.bvec
cp nifti_data/12_09_2023_MT_orientation_sub01_WIP_3D_T1_20230912152935_201.nii.gz bids_data/sub-01/ses-01/anat/t1.nii.gz -stride 1,2,3,4