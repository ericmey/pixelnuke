#!/bin/bash
#
# Partition SD card for Pixelnuke A/B boot scheme
#
# This is a wrapper that calls the appropriate OS-specific script.
# See tools/macos/, tools/linux/, tools/windows/ for implementations.
#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Detect OS and call appropriate script
case "$(uname)" in
    Darwin)
        exec "$PROJECT_ROOT/tools/macos/partition-sd.sh" "$@"
        ;;
    Linux)
        exec "$PROJECT_ROOT/tools/linux/partition-sd.sh" "$@"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "Windows detected. Please see tools/windows/README.md for instructions."
        exit 1
        ;;
    *)
        echo "Unknown operating system: $(uname)"
        echo "Please use the appropriate script from tools/<os>/partition-sd.sh"
        exit 1
        ;;
esac
