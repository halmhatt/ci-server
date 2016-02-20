#!/usr/bin/env bash -v
#
# This file initializes things, copies "user-script.sh" to a new folder
# and runns it there
#

# Save current directory
root_dir=$(pwd)

# Load default config
source "./defaults.cfg"

# Check if user config is present
if [ -f "user.cfg" ]; then
    source "./user.cfg"
fi

# Check that bookkeeping directory is present
if [ ! -d "$bookkeeping_dir" ]; then
    mkdir -p "./$bookkeeping_dir"
fi

# If repo url is not set as variable or environment variable, exit
if [ -z "$repo_url" ] && [ -z "$REPO_URL"]; then
    >&2 echo "Repo url not set in config or environment variable"
    exit 1;
fi

# Read last build number
if [ ! -f "$bookkeeping_dir/last-build" ];then
    # Use 0001 as starting value
    build_number=1
else
    # Read from file otherwise
    read build_number < "$bookkeeping_dir/last-build"
    # Increment value
    ((build_number++))
fi

# Save build number to file
echo "$build_number" > "$bookkeeping_dir/last-build"

# Create build dir name
build_dir="$build_dir_base/$(printf %04d $build_number)"

# Make directory
mkdir -p "./$build_dir"

# Copy user script file
cp "user-script.sh" "./$build_dir/"

# Change directory to user dir
cd "./$build_dir"

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

# Run user script in repo directory
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