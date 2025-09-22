#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Winter School - hands-on 4.4 (Part 2: Tractometry) - SCILPY Version
#
# Theme: Quantitative Analysis - From tracts to tables with Scilpy
#
# Goal: To generate tract profiles for a set of segmented bundles using a
#       command-line pipeline, inspired by modern tractometry workflows.
#
# Inputs:
#   - A directory of segmented bundles (e.g., 'bundleseg_automated/')
#   - Scalar metric maps (fa.nii.gz, md.nii.gz)
#
# Outputs:
#   - A final 'tractometry_results.json' file containing both whole-bundle
#     statistics and per-point tract profiles for each bundle.
# ======================================================================

# ---
# Step 0: Setup and Configuration #
# ---
echo "Step 0: Setting up paths and creating output directories..."

# Input directory containing the segmented bundles from hands-on session 3.6
BUNDLE_DIR="bundleseg_automated"

# Input scalar metric maps from hands-on session 2.3
FA_MAP="fa.nii.gz"
MD_MAP="md.nii.gz"

# Output directory for all intermediate and final files
TRACTOMETRY_DIR="tractometry_results"
mkdir -p "${TRACTOMETRY_DIR}/json_tmp"

echo "Setup complete."
echo

# ---
# Main Loop: Process each bundle #
# ---

echo "Starting tractometry pipeline for all bundles in ${BUNDLE_DIR}..."
echo

for bundle_file in ${BUNDLE_DIR}/*.trk; do
    # Extract a clean base name for the bundle (e.g., "AF_left")
    bname=$(basename "$bundle_file" .trk)
    echo "--- Processing bundle: ${bname} ---"

# ---
# Step 1: Compute Bundle Centroid #
# ---
    echo "  Step 1.1: Computing centroid..."
    centroid_file="${TRACTOMETRY_DIR}/${bname}_centroid.trk"
    scil_bundle_compute_centroid "$bundle_file" "$centroid_file" --nb_points 100 -f

# ---
# Step 2: Create Label and Distance Maps #
# ---
    echo "  Step 1.2: Creating label map for profiling..."
    label_map_dir="${TRACTOMETRY_DIR}/${bname}_labelling"
    scil_bundle_label_map "$bundle_file" "$centroid_file" "$label_map_dir" -f
    label_map_file="${label_map_dir}/labels_map.nii.gz"

# ---
# Step 3: Calculate Whole-Bundle Statistics #
# ---
    echo "  Step 1.3: Calculating whole-bundle statistics..."
    whole_bundle_json="${TRACTOMETRY_DIR}/json_tmp/${bname}_whole_bundle.json"
    scil_bundle_mean_std "$bundle_file" "$FA_MAP" "$MD_MAP" \
        --out_json "$whole_bundle_json" --density_weighting

# ---
# Step 4: Calculate Tract Profiles (Per-Point Statistics) #
# ---
    echo "  Step 1.4: Calculating tract profiles (per-point stats)..."
    profile_json="${TRACTOMETRY_DIR}/json_tmp/${bname}_profile.json"
    scil_bundle_mean_std "$bundle_file" "$FA_MAP" "$MD_MAP" \
        --per_point "$label_map_file" --out_json "$profile_json" --density_weighting

    echo "--- Finished processing ${bname} ---"
    echo

done

# ---
# Step 5: Aggregate All Results #
# ---
echo "Step 5: Aggregating all results into a single JSON file..."
scil_json_merge_entries ${TRACTOMETRY_DIR}/json_tmp/*.json tractometry_results.json \
    --no_list --add_parent_key "sub-01"
echo "Aggregation complete."
echo

# ---
# Final Output #
# ---
echo "Tractometry pipeline finished!"
echo "The final results are in 'tractometry_results.json'."
# This file contains both whole-bundle and per-point profile data for all# bundles.
