# slave_sync (one way sync)

I have music on my PC, sometimes I delete junk, sometimes I find new stuff. Every couple of months, I want to update the USB drive I have in my car to scrap what I disliked and add what's new. I wanted more granular control over which files are being touched (by manually touching the cache.jsons) and didn't want stuffups because of timestamps or sync conflicts (I know freefilesync or syncthing could probably be at least as good), so I worked with chatGPT to build this. It's comparing a source folder (on my thumb drive) recursively against a reference folder (on my PC), removing what's not (anymore) in the reference and copying what's more (regardless of new or old). ChatGPT came up with this readme:

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

3. **make it yours**
   - set execution policy to be able to execute ps1 in PowerShell
   - change source directory (this will be touched and should really be called slave, come to think of it)
   - change reference directory (this is the master that will not be altered)
   - change index and cache paths

## Usage
   Generate Index:
      The script will prompt if you want to refresh the index file if it already exists.
      
   Discover Unmatched Items:
      Identifies files and directories in the source that are not in the reference.
      Prompts to use existing cache or regenerate it if the cache is out-of-date.
      
   Discover Missing Items:
      Identifies files and directories in the reference that are missing in the source.
      Prompts to use existing cache or regenerate it if the cache is out-of-date.
      
   Proceed with Actions:
      Prompts for confirmation before proceeding with deletion or copying actions.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
Contributing

Feel free to open issues or submit pull requests if you have suggestions or improvements but don't expect quick responses.
