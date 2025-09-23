# Diffusion MRI Winter School: PhD Study Guide (Revised)

This guide is a personal reference for the dMRI Winter School hands-on tutorials. It breaks down each step with its scientific context, a summary of the action performed, and essential quality control checks, incorporating the full details from the tutorial notes.

---

## Hands-on 1.0: Setup and data download

### Step 1: Create BIDS directory structure

* **Context**: The first step is to organize our data according to the Brain Imaging Data Structure (BIDS) standard. This standardized format is central for using many automated analysis tools and ensures our project is understandable and reproducible.
* **Action**: The script unzips the raw DICOM data, converts it to NIfTI format using `dcm2niix`, creates the BIDS directory structure (`sub-01/ses-01/anat` and `sub-01/ses-01/dwi`), and populates it with the appropriate T1w and DWI files.
* For a real database, you should look into [dcm2bids](https://unfmontreal.github.io/Dcm2Bids/3.2.0/)

---

## Hands-on 2.3: Basic processing and DTI fitting

### Step 1: Inspect headers and data

* **Context**: Before any processing, it's critical to inspect the data's metadata. We use tools like `mrinfo` and `fslhd` to verify image dimensions, voxel size, and the number of volumes to catch potential issues early. We also check the b-values and b-vectors to confirm the diffusion scheme is correct.
* **Action**: This step uses `mrinfo` and `fslhd` to print the header information for the DWI and T1w images and uses `head` to display the first few lines of the b-value and b-vector files.

### Step 2: Extract b0 image

* **Context**: The non-diffusion-weighted b0 image serves as a T2-weighted anatomical reference. It's essential for subsequent steps like skull-stripping and registration to other images.
* **Action**: The `dwiextract` command is used to pull out all volumes where the b-value is zero. These are then averaged together using `mrmath` to create a single, high-quality b0 image.

### Step 3: Brain extraction (skull-stripping)

* **Context**: Brain extraction is essential to remove non-brain tissue (skull, skin, etc.) from the image. This focuses subsequent analyses only on the brain. A good brain mask is critical for accurate results.
* **Action**: Although omitted in the final script, this step typically involves using FSL's `bet` tool on the b0 image to generate a brain mask.
* **Command explanation**: The `bet` command has a `-f` parameter that sets the fractional intensity threshold. This often needs to be adjusted for different datasets to avoid cutting off parts of the brain or including parts of the skull.
* **Quality control**: Load `b0.nii.gz` and the resulting `b0_brain_mask.nii.gz` in `mrview`. You must overlay the mask on the b0 image to ensure it accurately covers all brain tissue without including the skull or cutting into the cortex. A bad mask will negatively impact all following steps.

### Step 4: Fit the DTI model and calculate scalar maps

* **Context**: The Diffusion Tensor Model (DTI) simplifies diffusion into an ellipsoid in each voxel. From this model, we can derive key quantitative metrics like Fractional Anisotropy (FA), Mean Diffusivity (MD), and a color-coded RGB map, which are critical for QC and analysis.
* **Action**: The script fits the tensor model using `dwi2tensor`. Following this, `tensor2metric` would be used to generate the FA, MD, and RGB maps.
* **Quality control**: Visualize `fa.nii.gz` and `rgb.nii.gz` using `mrview`.
    * **FA map**: High intensity (brightness) is expected in major white matter tracts, with low intensity in gray matter and CSF.
    * **RGB map**: Colors correspond to principal fiber directions: red for left-right, green for anterior-posterior, and blue for superior-inferior. The corpus callosum should be distinctly red. Abrupt color changes could indicate b-vector orientation issues.

---

## Hands-on 2.6: Deterministic tractography

### Step 1: Generate an anatomical seed region

* **Context**: To perform targeted tractography, we need a "seed" region to tell the algorithm where to begin tracing streamlines. Here, we create a seed in the Corpus Callosum by registering an atlas to our subject's data.
* **Action**: The script uses `antsRegistrationSyNQuick.sh` to align a template to our subject's FA map and `antsApplyTransforms` to bring the Corpus Callosum label from the template into our subject's space, creating our seed mask.

### Step 2: Run deterministic DTI tractography

* **Context**: We now have all the necessary inputs for tractography: orientation information (from the DTI model), a seed region, and a brain mask. Deterministic tracking follows the primary diffusion direction from voxel to voxel to reconstruct a streamline.
* **Action**: This step uses the `tckgen` command with the `Tensor_Det` algorithm to generate 10,000 streamlines, using the Corpus Callosum mask as the seed region.
* **Quality control**: Use `mrview fa.nii.gz -tractography.load dti_det_cc_10k.tck` to visualize the output. The streamlines should form the distinct "U-shape" of the Corpus Callosum, connecting the two hemispheres.

---

## Hands-on 3.3: CSD and probabilistic tractography

### Step 1: Estimate the fiber response function (FRF)

* **Context**: Constrained Spherical Deconvolution (CSD) needs to know the signal profile of a single, coherent fiber population. This is the Fiber Response Function (FRF), which we can estimate directly from the data by finding voxels that are highly anisotropic.
* **Action**: The script uses the `dwi2response tournier` command. The 'tournier' algorithm is a robust method that iteratively finds the most appropriate single-fiber voxels to build the response function.
* **Quality control**: Visualize the output with `shview frf.txt`. The result should be a sharp, cigar-shaped glyph, confirming that appropriate single-fiber voxels were used for the estimation.

### Step 2: Fit the CSD model

* **Context**: With the FRF, we can perform CSD. The algorithm "deconvolves" the FRF from the signal in each voxel to produce a Fiber Orientation Distribution (fODF), which can represent multiple fiber populations in a single voxel.
* **Action**: The `dwi2fod csd` command fits the model, taking the DWI data and the FRF as input to produce the fODF map.
* **Quality control**: Use `mrview fa.nii.gz -odf.load_sh wmfod.nii.gz`. Navigate to a known fiber-crossing region (e.g., where the corticospinal tract and corpus callosum intersect). You should see fODF glyphs with multiple lobes, which the simpler DTI model could not resolve.

### Step 3: Run probabilistic tractography

* **Context**: Probabilistic tractography generates streamlines by sampling from the full distribution of orientations provided by the fODF, rather than just following the single brightest peak. This allows it to better handle uncertainty and complex fiber crossings.
* **Action**: The `tckgen` command is used again, but this time it operates on the fODF map, automatically using the default probabilistic iFOD2 algorithm to generate 10,000 streamlines from the Corpus Callosum seed.
* **Quality control**: Load both the deterministic and probabilistic tractograms in `mrview` for comparison. The probabilistic result will likely appear "fuzzier" and may show better coverage, especially in the fanning projections of the Corpus Callosum, reflecting the algorithm's ability to explore multiple possible pathways.

---

## Hands-on 3.6: Bundle segmentation

### Step 0: Generate a whole-brain tractogram

* **Context**: To segment specific anatomical tracts, we first need a dense, whole-brain tractogram (a "hairball") to select from. This tractogram will serve as the input for our segmentation algorithms.
* **Action**: The script uses `tckgen` to generate 100,000 streamlines, seeding from the entire brain mask.

### Step 1: Manual-style segmentation with ROIs

* **Context**: We can isolate a specific bundle by defining Regions of Interest (ROIs) that it must pass through. Here, we'll extract the left Corticospinal Tract (CST).
* **Action**: The script first uses `mrcalc` to create binary ROI masks for the left precentral gyrus and the brainstem from an atlas. It then uses `tckedit` to select only the streamlines from the whole-brain tractogram that pass through *both* of these ROIs.
* **Command explanation**: `tckedit` filters streamlines. Using the `-include` flag twice acts as a logical AND, meaning it keeps only streamlines that intersect both specified regions.
* **Quality control**: Visualize the result with `mrview fa.nii.gz -tractography.load CST_L.tck`. The bundle should be an anatomically plausible pathway running from the motor cortex superiorly down to the brainstem inferiorly.

### Step 2: Automated segmentation with BundleSeg

* **Context**: Automated methods use a pre-trained atlas of bundles to recognize and extract dozens of tracts from a whole-brain tractogram very quickly. This is much more efficient than manual segmentation.
* **Action**: After downloading the required model files, the script runs `scil_tractogram_segment_with_bundleseg` to automatically segment the whole-brain tractogram.
* **Quality control**: Use `mrview fa.nii.gz -tractography.load bundleseg_automated/AF_left.trk`. The output directory contains many tract files. Load a few (like the Arcuate Fasciculus or Corticospinal Tract) to confirm they are anatomically correct.

---

## Hands-on 4.4 (Part 1): Connectomics

### Step 1: Generate an anatomical parcellation

* **Context**: A connectome's "nodes" are typically anatomical gray matter regions. We generate these nodes by running a parcellation tool like FreeSurfer's `recon-all` on the T1w image, which assigns a unique label to each brain region.
* **Action**: A full `recon-all` run takes hours, so the script simulates this step by using a pre-existing segmentation file (`fa_synthseg.nii.gz`) as the parcellation atlas.
* **Command explanation**: The key output from a real `recon-all` run for this purpose is the `aparc+aseg.mgz` file, which contains the integer-labeled brain regions.

### Step 2: Build the connectivity matrix

* **Context**: With the nodes (parcellation) and the pathways (tractogram) defined, we can build the connectome by counting the number of streamlines that connect every pair of nodes.
* **Action**: The script uses `tck2connectome` to generate the connectivity matrix, taking the whole-brain tractogram and the parcellation file as input.
* **Command explanation**: The `-symmetric` flag ensures the connection from A to B is counted the same as B to A, and `-zero_diagonal` removes self-connections (streamlines starting and ending in the same node).
* **Quality control**: Open the output `connectome.csv`. It should be a large numerical matrix where each cell represents the streamline count between the two regions corresponding to that row and column.

---

## Hands-on 4.4 (Part 2): Tractometry

### Step 1: Compute bundle centroid

* **Context**: To create a tract profile, we need a consistent frame of reference. The first step is to compute a "centroid" streamline, which represents the average trajectory of all streamlines in a given bundle.
* **Action**: The script loops through each bundle file and uses `scil_bundle_compute_centroid` to generate this average streamline.

### Step 2: Create label and distance maps

* **Context**: Next, we map each point of each streamline in the bundle to the closest point on the centroid. This generates a "label map" which is essential for averaging metric values at corresponding points along the bundle's length.
* **Action**: Inside the loop, the script uses `scil_bundle_label_map` for this purpose.

### Step 3: Calculate whole-bundle statistics

* **Context**: As a first-pass analysis, we can compute the average metric value (e.g., FA) across the entire volume of the bundle. This gives us a single number per metric for the whole bundle.
* **Action**: The `scil_bundle_mean_std` command is used to calculate these whole-bundle averages.

### Step 4: Calculate tract profiles (per-point statistics)

* **Context**: This is the core of tractometry. Using the label map created in Step 2, we can now calculate the average metric value at each of the 100 points along the bundle's length, giving us a detailed profile of how the metric changes along the tract.
* **Action**: The script calls `scil_bundle_mean_std` again, but this time with the `--per_point` flag, to generate the tract profiles.

### Step 5: Aggregate all results

* **Context**: The loop has generated many small JSON files containing the results for each bundle. The final step is to merge them all into one comprehensive file for easy analysis.
* **Action**: After the loop finishes, the script uses `scil_json_merge_entries` to combine all the temporary JSON files into a final `tractometry_results.json`.