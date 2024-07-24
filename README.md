# slave_sync

I have music on my PC, sometimes I delete junk, sometimes I find new stuff. Every couple of months, I want to update the USB drive I have in my car to scrap what I disliked and add what's new. I wanted more granular control over which files are being touched (by manually touching the cache.jsons) and didn't want stuffups because of timestamps or sync conflicts, so I worked with chatGPT to build this. It's comparing a source folder (on my thumb drive) recursively against a reference folder (on my PC), removing what's not (anymore) in the reference and copying what's more (regardless of new or old). ChatGPT came up with this readme:

# Music Database Sync Script

This PowerShell script helps manage and synchronize files between a source directory and a reference directory. It supports detecting unmatched files in the source directory and missing files in the source directory from the reference directory. The script includes functionality to cache discovered items and handle long paths efficiently.

## Features

- **Index Generation**: Create an index of files and directories from source and reference paths.
- **Unmatched Items**: Detect files and directories present in the source but not in the reference, with options to delete them.
- **Missing Items**: Detect files and directories present in the reference but missing in the source, with options to copy them.
- **Cache Management**: Save and reuse caches of unmatched and missing items to improve performance.
- **Progress Reporting**: Show progress bars during index generation, discovery, and actions (copying and deletion).

## Installation

1. **Prerequisites**: 
   - PowerShell 7 or later.

2. **Clone the Repository**:
   ```bash
   git clone https://github.com/paprika27/slave_sync.git
   cd slave_sync
