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


# # Step 1: Setup and Configuration
echo "Step 1: Setting up paths and creating output directories..."

# Output directory for all intermediate and final files
mkdir -p "tractometry_results/json_tmp"

# # Main Loop: Process each bundle
for bundle_file in bundleseg_automated/AF_*.tck; do
    # Extract a clean base name for the bundle (e.g., "AF_left")
    bname=$(basename "$bundle_file" .tck)
    echo "--- Processing bundle: ${bname} ---"


    # # Step 2: Compute Bundle Centroid
    # [scilpy Version]
    centroid_file="tractometry_results/${bname}_centroid.tck"
    scil_bundle_compute_centroid "$bundle_file" "$centroid_file" --nb_points 10 --reference fa.nii.gz -f
    scil_bundle_uniformize_endpoints "$centroid_file" "$centroid_file" --auto --reference fa.nii.gz -f

    # # Step 3: Create Label and Distance Maps
    # [scilpy Version]
    label_map_dir="tractometry_results/${bname}_labelling"
    scil_bundle_label_map "$bundle_file" "$centroid_file" "$label_map_dir" -f --reference fa.nii.gz
    label_map_file="${label_map_dir}/labels_map.nii.gz"


    # # Step 4: Calculate Whole-Bundle Statistics
    # [scilpy Version]
    whole_bundle_json="tractometry_results/json_tmp/${bname}_whole_bundle.json"
    scil_bundle_mean_std "$bundle_file" fa.nii.gz md.nii.gz \
        --out_json "$whole_bundle_json" --density_weighting --reference fa.nii.gz

    # # Step 5: Calculate Tract Profiles (Per-Point Statistics)
    # [scilpy Version]
    profile_json="tractometry_results/json_tmp/${bname}_profile.json"
    scil_bundle_mean_std "$bundle_file" fa.nii.gz md.nii.gz \
        --per_point "$label_map_file" --out_json "$profile_json" --density_weighting --reference fa.nii.gz
    echo
done

# # Step 6: Aggregate All Results
echo "Step 6: Aggregating all results into a single JSON file..."
# [scilpy Version]
scil_json_merge_entries tractometry_results/json_tmp/*_profile.json tractometry_profiles.json \
    --no_list --add_parent_key "sub-01"
scil_json_merge_entries tractometry_results/json_tmp/*_whole_bundle.json tractometry_whole_bundles.json \
    --no_list --add_parent_key "sub-01"
scil_plot_stats_per_point tractometry_profiles.json tractometry_profiles_plot/
echo "The final results are in 'tractometry_profiles.json' and 'tractometry_whole_bundles.json'."
echo "Plots have been generated in the 'tractometry_profiles_plot/' directory."