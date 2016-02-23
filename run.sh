#!/usr/bin/env bash
#
# This file initializes things, copies "user-script.sh" to a new folder
# and runns it there
#

# Save current directory
root_dir=$(pwd)

# Load default config
source './defaults.cfg'

# Check if user config is present
if [[ -f 'user.cfg' ]]; then
    source './user.cfg'
fi

# Check that bookkeeping directory is present
if [[ ! -d "$bookkeeping_dir" ]]; then
    mkdir -p "./$bookkeeping_dir"
fi

# If repo url is not set as variable or environment variable, exit
if [[ -z "$repo_url" ]] && [[ -z "$REPO_URL" ]]; then
    >&2 echo 'Repo url not set in config or environment variable'
    exit 1;
fi

# Use hook for creating build dir if present
if [[ -f './hooks/build-dir' ]]; then
    source './hooks/build-dir'
else
    # Read last build number
    if [[ ! -f "$bookkeeping_dir/last-build" ]]; then
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
fi

# Make build directory
mkdir -p "$root_dir/$build_dir"

# Copy user script file
cp "$user_script_file" "$root_dir/$build_dir/"

# Change to build directory
cd "$root_dir/$build_dir"

# Export REPO_URL environment variable if not set
if [[ -z "$REPO_URL" ]]; then
    export REPO_URL="$repo_url"
fi

# Export CLONE_DIR environment variable if not set
if [[ -z "$CLONE_DIR" ]]; then
    export CLONE_DIR="$clone_dir"
fi

# Use hook to clone repo if available
if [[ -f './hooks/clone-repo' ]]; then
    source './hooks/clone-repo'
else
    # If no hook was available, do the clone
    git clone --depth 20 "$REPO_URL" "$CLONE_DIR"
fi

# Change directory to the cloned dir
cd "$root_dir/$build_dir/$CLONE_DIR"

# Extract some git data
git_sha1=$(git rev-parse HEAD 2>/dev/null)

# Run post clone hook if present
if [[ -f './hooks/post-clone' ]]; then
    source './hooks/post-clone'
fi

# Save timestamp before user script is run
timestamp_before=$(date -u +'%FT%T.000Z')

# Run user script in repo directory
/bin/bash -v "$root_dir/$build_dir/$user_script_file" 2>&1 | tee "$log_filename"

# Save exit code from user script
user_script_exit_code=$?

# Change directory to build dir
cd "$root_dir/$build_dir"

# Run post user script hook if present
if [[ -f './hooks/post-user-script' ]]; then
    $log_file="./$log_filename"
    source './hooks/post-user-script'
fi

# Get timestamp when run is done
timestamp_after=$(date -u +'%FT%T.000Z')

# Save results
cat <<EOF > "./result.json"
{
    "status": $user_script_exit_code,
    "timestamp_before": "$timestamp_before",
    "timestamp_after": "$timestamp_after",
    "git": {
        "HEAD": "$git_sha1"
    },
    "log": "$build_dir/$log_filename"
}
EOF

# Run post result hook if present
if [[ -f './hooks/post-result' ]]; then
    $log_file="$log_filename"
    $result_file='./result.json'
    source './hooks/post-result'
fi

# Change directory back to root dir
cd "$root_dir"

# Cleanup
if [[ -f './hooks/cleanup' ]]; then
    source './hooks/cleanup'
fi

# Exit with the same status code
exit $user_script_exit_status