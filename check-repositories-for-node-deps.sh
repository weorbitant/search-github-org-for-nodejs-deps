#!/usr/bin/env bash
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/repos_with_package_json"
DEPENDENCIES_TO_FIND=(
    "react-server-dom-parcel"
    "react-server-dom-turbopack"
    "react-server-dom-webpack"
    "next"
)

# Display usage information
usage() {
    echo "📖 Usage: $0 <organization-name> [dependencies]"
    echo ""
    echo "📋 Description:"
    echo "  Scans all repositories in a GitHub organization for package.json files"
    echo "  and searches for specific dependencies."
    echo ""
    echo "📝 Arguments:"
    echo "  organization-name  The GitHub organization to scan"
    echo "  dependencies       (Optional) Comma-separated list of dependencies to search for"
    echo "                     If not provided, uses default: ${DEPENDENCIES_TO_FIND[*]}"
    echo ""
    echo "💡 Examples:"
    echo "  $0 my-org"
    echo "  $0 my-org \"lodash,express,axios\""
    exit 1
}

# Check that required tools are installed and authenticated
check_prerequisites() {
    if ! command -v gh &> /dev/null; then
        echo "❌ Error: 'gh' CLI is not installed or not in PATH."
        echo "   💡 Install it from: https://cli.github.com/"
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        echo "❌ Error: Not authenticated with GitHub CLI."
        echo "   💡 Run 'gh auth login' to authenticate."
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "❌ Error: 'jq' is not installed or not in PATH."
        exit 1
    fi
}

# Fetch all repository names from an organization
fetch_repositories() {
    local org="$1"
    echo "🔄 Fetching repositories for organization: ${org}..." >&2
    gh repo list "$org" --json name --limit 1000 | jq -r '.[].name'
}

# Check if a repo has package.json at root and download it
check_and_download_package_json() {
    local org="$1"
    local repo="$2"
    local output_dir="$3"

    local response
    if response=$(gh api "repos/${org}/${repo}/contents/package.json" 2>/dev/null); then
        local content
        content=$(echo "$response" | jq -r '.content' | base64 -d)

        local repo_dir="${output_dir}/${repo}"
        mkdir -p "$repo_dir"
        echo "$content" > "${repo_dir}/package.json"

        echo "$repo"
        return 0
    fi
    return 1
}

# Search for specific dependencies in all downloaded package.json files
search_dependencies() {
    local output_dir="$1"
    shift
    local deps=("$@")

    echo ""
    echo "=========================================="
    echo "🔍 Dependency Search Results"
    echo "=========================================="

    local found_any=false

    for dep in "${deps[@]}"; do
        echo ""
        echo "🔎 Searching for: ${dep}"
        echo "------------------------------------------"

        local found=false
        for pkg_file in "${output_dir}"/*/package.json; do
            if [[ -f "$pkg_file" ]]; then
                if grep -q "\"${dep}\"" "$pkg_file"; then
                    local repo_name
                    repo_name=$(dirname "$pkg_file" | xargs basename)

                    # Determine which section contains the dependency and get version
                    local sections=""
                    local version=""
                    if version=$(jq -r ".dependencies.\"${dep}\" // empty" "$pkg_file" 2>/dev/null) && [[ -n "$version" ]]; then
                        sections="dependencies"
                    fi
                    if dev_version=$(jq -r ".devDependencies.\"${dep}\" // empty" "$pkg_file" 2>/dev/null) && [[ -n "$dev_version" ]]; then
                        [[ -n "$sections" ]] && sections="${sections}, "
                        sections="${sections}devDependencies"
                        [[ -z "$version" ]] && version="$dev_version"
                    fi
                    if peer_version=$(jq -r ".peerDependencies.\"${dep}\" // empty" "$pkg_file" 2>/dev/null) && [[ -n "$peer_version" ]]; then
                        [[ -n "$sections" ]] && sections="${sections}, "
                        sections="${sections}peerDependencies"
                        [[ -z "$version" ]] && version="$peer_version"
                    fi

                    echo "  ⚠️  Found in: ${repo_name} @ ${version} (${sections})"
                    found=true
                    found_any=true
                fi
            fi
        done

        if [[ "$found" == "false" ]]; then
            echo "  ✅ No repositories found with this dependency."
        fi
    done

    if [[ "$found_any" == "false" ]]; then
        echo ""
        echo "✅ No repositories contain any of the specified dependencies."
    fi
}

# Main function
main() {
    local org="$1"

    # Clean up previous run
    if [[ -d "$OUTPUT_DIR" ]]; then
        echo "🧹 Cleaning previous output directory..."
        rm -rf "$OUTPUT_DIR"
    fi
    mkdir -p "$OUTPUT_DIR"

    # Fetch all repositories
    local repos
    repos=$(fetch_repositories "$org")

    if [[ -z "$repos" ]]; then
        echo "ℹ️  No repositories found in organization: ${org}"
        exit 0
    fi

    local total_repos
    total_repos=$(echo "$repos" | wc -l)
    echo "📊 Found ${total_repos} repositories in ${org}"
    echo ""

    # Process each repository
    local repos_with_package_json=()
    local current=0

    while IFS= read -r repo; do
        ((current++)) || true
        printf "\r⏳ [%d/%d] Checking: %-50s" "$current" "$total_repos" "$repo"

        if result=$(check_and_download_package_json "$org" "$repo" "$OUTPUT_DIR"); then
            repos_with_package_json+=("$result")
        fi
    done <<< "$repos"

    echo ""
    echo ""
    echo "=========================================="
    echo "📦 Repositories with package.json"
    echo "=========================================="

    if [[ ${#repos_with_package_json[@]} -eq 0 ]]; then
        echo "ℹ️  No repositories found with package.json at root."
    else
        echo "✅ Found ${#repos_with_package_json[@]} repositories with package.json:"
        echo ""
        for repo in "${repos_with_package_json[@]}"; do
            echo "  📁 ${repo}"
        done
    fi

    # Search for dependencies
    if [[ ${#repos_with_package_json[@]} -gt 0 ]]; then
        search_dependencies "$OUTPUT_DIR" "${DEPENDENCIES_TO_FIND[@]}"
    fi

    echo ""
    echo "=========================================="
    echo "📊 Summary"
    echo "=========================================="
    echo "🏢 Organization: ${org}"
    echo "📚 Total repositories: ${total_repos}"
    echo "📦 Repositories with package.json: ${#repos_with_package_json[@]}"
    echo "📂 Downloaded to: ${OUTPUT_DIR}"
}

# Argument validation
if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
    usage
fi

ORG_NAME="$1"

# Validate organization name format
if [[ ! "$ORG_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "❌ Error: Invalid organization name format."
    exit 1
fi

# If second argument is provided, use it as dependencies list
if [[ $# -eq 2 ]]; then
    IFS=',' read -ra DEPENDENCIES_TO_FIND <<< "$2"
    echo "🔧 Using custom dependencies: ${DEPENDENCIES_TO_FIND[*]}"
fi

# Run prerequisites check
check_prerequisites

# Execute main function
main "$ORG_NAME"
