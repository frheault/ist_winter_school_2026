#!/bin/bash

# This script cleans the repository by deleting all files and folders except for a predefined list, using the 'find' command.

echo "Cleaning the repository..."

find . -maxdepth 1 \
    -not -name "template" \
    -not -name "dicom_filtered_sub01.zip" \
    -not -name "tutorial*" \
    -not -name "Dockerfile" \
    -not -name "NOTEBOOK.md" \
    -not -name "clean_repo.sh" \
    -not -name "check_installation.sh" \
    -not -name ".git" \
    -not -name ".gitignore" \
    -not -name "." \
    -exec rm -rf {} +

echo "Repository cleaned."