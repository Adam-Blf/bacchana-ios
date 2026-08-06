#!/usr/bin/env python3
"""Release automation for bacchana-ios.

Bumps MARKETING_VERSION and CURRENT_PROJECT_VERSION in project.yml,
commits, creates an annotated tag, and pushes to origin.

Usage:
    python scripts/release.py --version 1.0.0          # Bump and tag
    python scripts/release.py --version 1.0.0 --dry-run # Preview only
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path


def run_cmd(cmd, check=True, capture=False):
    """Execute shell command."""
    if capture:
        return subprocess.run(cmd, shell=True, check=check, capture_output=True, text=True).stdout.strip()
    else:
        return subprocess.run(cmd, shell=True, check=check)


def bump_version_ios(version_str, dry_run=False):
    """Bump MARKETING_VERSION and CURRENT_PROJECT_VERSION in project.yml."""
    project_file = Path("project.yml")
    if not project_file.exists():
        print(f"Error: {project_file} not found")
        sys.exit(1)

    content = project_file.read_text()

    # Parse semantic version X.Y.Z
    match = re.match(r"(\d+)\.(\d+)\.(\d+)", version_str)
    if not match:
        print(f"Error: Invalid version format '{version_str}'. Use X.Y.Z")
        sys.exit(1)

    major, minor, patch = match.groups()
    # CURRENT_PROJECT_VERSION is a monotonic integer; use major*10000 + minor*100 + patch
    current_project_version = int(major) * 10000 + int(minor) * 100 + int(patch)

    # Replace MARKETING_VERSION (in settings > base)
    new_content = re.sub(
        r'MARKETING_VERSION: "[^"]+"',
        f'MARKETING_VERSION: "{version_str}"',
        content
    )

    # Replace CURRENT_PROJECT_VERSION (in settings > base)
    new_content = re.sub(
        r'CURRENT_PROJECT_VERSION: "\d+"',
        f'CURRENT_PROJECT_VERSION: "{current_project_version}"',
        new_content
    )

    if dry_run:
        print(f"[DRY RUN] Would update {project_file}:")
        print(f"  MARKETING_VERSION -> {version_str}")
        print(f"  CURRENT_PROJECT_VERSION -> {current_project_version}")
        return

    if new_content == content:
        print("No version changes needed")
        return

    project_file.write_text(new_content)
    print(f"Updated {project_file}: MARKETING_VERSION={version_str}, CURRENT_PROJECT_VERSION={current_project_version}")


def git_commit_and_tag(version_str, dry_run=False):
    """Commit version bump and create annotated tag."""
    if dry_run:
        print(f"[DRY RUN] Would create commit: 'chore: bump version to {version_str}'")
        print(f"[DRY RUN] Would create tag: v{version_str}")
        return

    # Commit
    run_cmd(
        'git -c user.name="Adam Beloucif" -c user.email="adam.beloucif@efrei.net" '
        f'commit -am "chore: bump version to {version_str}"'
    )
    print(f"Committed version bump")

    # Tag
    run_cmd(
        'git -c user.name="Adam Beloucif" -c user.email="adam.beloucif@efrei.net" '
        f'tag -a v{version_str} -m "release: v{version_str}"'
    )
    print(f"Created tag v{version_str}")


def git_push(dry_run=False):
    """Push commits and tags to origin."""
    if dry_run:
        print("[DRY RUN] Would push to origin (commits and tags)")
        return

    run_cmd("git push origin main")
    print("Pushed commits to origin/main")

    run_cmd("git push origin --tags")
    print("Pushed tags to origin")


def main():
    parser = argparse.ArgumentParser(
        description="Release automation for bacchana-ios"
    )
    parser.add_argument(
        "--version",
        required=True,
        help="Semantic version to release (X.Y.Z)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without committing"
    )

    args = parser.parse_args()

    print(f"Releasing version {args.version}...")
    if args.dry_run:
        print("[DRY RUN mode: no changes will be committed]\n")

    bump_version_ios(args.version, dry_run=args.dry_run)
    git_commit_and_tag(args.version, dry_run=args.dry_run)
    git_push(dry_run=args.dry_run)

    print("\nDone!")


if __name__ == "__main__":
    main()
