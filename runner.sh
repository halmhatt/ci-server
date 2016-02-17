#!/usr/bin/env bash -v
#
# This file initializes things, copies "user-script.sh" to a new folder
# and runns it there
#

# Save current directory
root_dir=$(pwd)

# Load config
source ./config.cfg

# Read last build number
if [ ! -f "$last_build_filename" ];then
    # Use 0001 as starting value
    build_number="0001"
else
    # Read from file otherwise
    read build_number < "$last_build_filename"
    # Increment value
    ((build_number++))
    build_number="$(printf "%04d" $build_number)"
fi

# Save build number to file
printf "%04d" "$build_number" > "$last_build_filename"

# Create build dir name
build_dir="$build_dir_base/$build_number"

# Remove old dir
# rm -rf "./$build_dir"

# Make directory
mkdir -p "./$build_dir"

# Copy user script file
cp "user-script.sh" "$build_dir/"

# Change directory to user dir
cd "$build_dir"

# Export environment variables
export REPO_URL="$repo_url"
# export CLONE_DIR="$build_dir/$clone_dir"

# Clone repo
git clone --depth 20 "$REPO_URL" "$clone_dir"

# Change directory to the cloned dir
cd "$clone_dir"

# Extract some git data
git_sha1="$(git rev-parse HEAD 2>/dev/null)"

# Save timestamp before user script is run
timestamp_before=$(date -u +"%FT%T.000Z")

# Run user script
/bin/bash -v "../user-script.sh" 2>&1 | tee "$log_file"

# Save exit code from user script
test_exit_status=$?

# Change directory back to root dir
cd "$root_dir"

# Get timestamp when run is done
timestamp_after=$(date -u +"%FT%T.000Z")

# Save results
cat <<EOF > "./$build_dir/result.json"
{
    "status": $test_exit_status,
    "timestamp_before": "$timestamp_before",
    "timestamp_after": "$timestamp_after",
    "git": {
        "HEAD": "$git_sha1"
    },
    "log": "$build_dir/$log_file"
}
EOF

# Exit with the same status code
exit $test_exit_status