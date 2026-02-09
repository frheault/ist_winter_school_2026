#!/bin/bash

# This script checks for the required software for the dMRI Winter School tutorials.

LOG_FILE="installation_check.log"

# Clear the log file
> "$LOG_FILE"

echo "=================================================" | tee -a "$LOG_FILE"
echo " dMRI Winter School - Installation Check (v4)"    | tee -a "$LOG_FILE"
echo "=================================================" | tee -a "$LOG_FILE"
echo "Detailed log will be saved to: $LOG_FILE"

# Source FreeSurfer if FREESURFER_HOME is set
if [ -n "$FREESURFER_HOME" ]; then
    echo "Sourcing FreeSurfer environment from $FREESURFER_HOME/SetUpFreeSurfer.sh" | tee -a "$LOG_FILE"
    . "$FREESURFER_HOME/SetUpFreeSurfer.sh"
else
    echo "FREESURFER_HOME not set, skipping FreeSurfer environment setup." | tee -a "$LOG_FILE"
fi

# --- Helper Function ---
check_command() {
    local cmd_name=$1
    local version_arg=$2
    local tool_name=$3
    local env_var=$4

    if [ -n "$env_var" ]; then
        printf "Checking for %-40s ... " "$env_var variable"
        echo -n "Checking for $env_var variable ... " >> "$LOG_FILE"
        if [ -z "${!env_var}" ]; then
            printf "Not Set\n"
            echo "Not Set" >> "$LOG_FILE"
            return
        else
            printf "Set\n"
            echo "Set to ${!env_var}" >> "$LOG_FILE"
        fi
    fi

    printf "Checking for %-40s ... " "$tool_name command"
    echo -n "Checking for $tool_name command ... " >> "$LOG_FILE"
    if command -v "$cmd_name" &> /dev/null; then
        printf "Installed\n"
        echo -n "Installed" >> "$LOG_FILE"
        if [ -n "$version_arg" ]; then
            local version_info
            version_info=$("$cmd_name" "$version_arg" 2>&1)
            local first_line
            first_line=$(echo "$version_info" | head -n 1)
            echo " (version: $first_line)" >> "$LOG_FILE"
        else
            echo "" >> "$LOG_FILE"
        fi
    else
        printf "Not Found\n"
        echo "Not Found" >> "$LOG_FILE"
    fi
}

# --- FSL ---
echo -e "\n--- FSL ---" | tee -a "$LOG_FILE"
check_command "bet" "" "bet" "FSLDIR"
check_command "fslhd" "" "fslhd"

# --- MRtrix3 ---
echo -e "\n--- MRtrix3 ---" | tee -a "$LOG_FILE"
check_command "mrinfo" "--version" "mrinfo"
check_command "dwiextract" "--version" "dwiextract"
check_command "tckgen" "--version" "tckgen"

# --- ANTs ---
echo -e "\n--- ANTs ---" | tee -a "$LOG_FILE"
check_command "antsRegistrationSyNQuick.sh" "" "antsRegistrationSyNQuick.sh" "ANTSPATH"
check_command "antsApplyTransforms" "" "antsApplyTransforms"

# --- FreeSurfer ---
echo -e "\n--- FreeSurfer ---" | tee -a "$LOG_FILE"
check_command "mri_convert" "--version" "mri_convert" "FREESURFER_HOME"
check_command "recon-all" "" "recon-all"
check_command "mri_synthseg" "" "mri_synthseg"

# --- SCILPY ---
echo -e "\n--- SCILPY ---" | tee -a "$LOG_FILE"
check_command "scil_header_print_info" "" "scil_header_print_info"
check_command "scil_dwi_extract_b0" "" "scil_dwi_extract_b0"
check_command "scil_volume_math" "" "scil_volume_math"

# --- Other ---
echo -e "\n--- Other ---" | tee -a "$LOG_FILE"
check_command "unzip" "-v" "unzip"
check_command "dcm2niix" "-v" "dcm2niix"
check_command "curl" "--version" "curl"

echo "=================================================" | tee -a "$LOG_FILE"
echo " Check complete." | tee -a "$LOG_FILE"
echo "=================================================" | tee -a "$LOG_FILE"
