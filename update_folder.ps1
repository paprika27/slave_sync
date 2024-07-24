# Define Paths
$sourceDir = "D:\Music"
$referenceDir = "M:\Music"
$indexFile = "D:\index.json"
$unmatchedCacheFile = "D:\unmatched_cache.json"
$missingCacheFile = "D:\missing_cache.json"

function Test-NetworkPath {
    param (
        [string]$path
    )
    Test-Path -Path $path
}

function Generate-IndexFile {
    param (
        [string]$sourcePath,
        [string]$referencePath,
        [string]$indexPath
    )

    Write-Output "Generating index file..."

    $sourceItems = Get-ChildItem -Path $sourcePath -Recurse -File
    $referenceItems = Get-ChildItem -Path $referencePath -Recurse -File

    $index = @{
        SourceBasePath = $sourcePath
        ReferenceBasePath = $referencePath
        Source = @()
        Reference = @()
    }

    $totalItems = $sourceItems.Count + $referenceItems.Count
    $currentItem = 0

    foreach ($item in $sourceItems) {
        $currentItem++
        Write-Progress -Activity "Generating index file" -Status "Processing source item $item" -PercentComplete (($currentItem / $totalItems) * 100)
        $index.Source += $item.FullName
    }

    foreach ($item in $referenceItems) {
        $currentItem++
        Write-Progress -Activity "Generating index file" -Status "Processing reference item $item" -PercentComplete (($currentItem / $totalItems) * 100)
        $index.Reference += $item.FullName
    }

    $index | ConvertTo-Json | Set-Content -Path $indexPath

    Write-Output "Index file generated at $indexPath"
}

function Load-IndexFile {
    param (
        [string]$indexPath
    )
    if (Test-Path $indexPath) {
        $indexContent = Get-Content -Path $indexPath -Raw | ConvertFrom-Json
        return $indexContent
    } else {
        Write-Output "Index file not found. Please generate it first."
        return $null
    }
}

function Save-Cache {
    param (
        [object]$data,
        [string]$cachePath
    )
    $data | ConvertTo-Json | Set-Content -Path $cachePath
    Write-Output "Cache file saved at $cachePath"
}

function Load-Cache {
    param (
        [string]$cachePath
    )
    if (Test-Path $cachePath) {
        $cacheContent = Get-Content -Path $cachePath -Raw | ConvertFrom-Json
        return $cacheContent
    } else {
        Write-Output "Cache file not found."
        return $null
    }
}

function Discover-UnmatchedItems {
    param (
        [object]$index
    )

    function Get-RelativePath {
        param (
            [string]$basePath,
            [string]$fullPath
        )
        $relativePath = $fullPath.Substring($basePath.Length).TrimStart('\')
        return $relativePath
    }

    $sourceBasePath = $index.SourceBasePath
    $referenceBasePath = $index.ReferenceBasePath

    if ([string]::IsNullOrEmpty($sourceBasePath) -or [string]::IsNullOrEmpty($referenceBasePath)) {
        Write-Output "Base paths are missing. Please regenerate the index file."
        return
    }

    $cacheExists = Test-Path $unmatchedCacheFile

    if ($cacheExists) {
        $useCache = Read-Host "Unmatched cache file already exists. Do you want to use it? (yes/no)"
        if ($useCache -eq "yes") {
            $unmatchedItems = Load-Cache -cachePath $unmatchedCacheFile
            Write-Output "Using existing cache for unmatched items."
        } else {
            # Extract relative paths for comparison
            $sourceItems = $index.Source | ForEach-Object { Get-RelativePath -basePath $sourceBasePath -fullPath $_ }
            $referenceItems = $index.Reference | ForEach-Object { Get-RelativePath -basePath $referenceBasePath -fullPath $_ }

            $unmatchedRelativeItems = $sourceItems | Where-Object { $_ -notin $referenceItems }

            if ($unmatchedRelativeItems.Count -eq 0) {
                Write-Output "No unmatched items found."
                return
            }

            # Convert relative paths back to full paths
            $unmatchedItems = $unmatchedRelativeItems | ForEach-Object {
                $fullPath = Join-Path -Path $sourceBasePath -ChildPath $_
                if (Test-Path $fullPath) {
                    return $fullPath
                }
            } | Where-Object { $_ -ne $null }

            Write-Output "The following items will be deleted:"
            $unmatchedItems | ForEach-Object { Write-Output $_ }

            # Save or update the cache
            Save-Cache -data $unmatchedItems -cachePath $unmatchedCacheFile

            $confirmation = Read-Host "Do you want to proceed with deletion? (yes/no)"
            if ($confirmation -ne "yes") {
                Write-Output "Deletion process cancelled."
                return
            }
        }
    } else {
        # If cache does not exist, perform discovery and create cache
        # Extract relative paths for comparison
        $sourceItems = $index.Source | ForEach-Object { Get-RelativePath -basePath $sourceBasePath -fullPath $_ }
        $referenceItems = $index.Reference | ForEach-Object { Get-RelativePath -basePath $referenceBasePath -fullPath $_ }

        $unmatchedRelativeItems = $sourceItems | Where-Object { $_ -notin $referenceItems }

        if ($unmatchedRelativeItems.Count -eq 0) {
            Write-Output "No unmatched items found."
            return
        }

        # Convert relative paths back to full paths
        $unmatchedItems = $unmatchedRelativeItems | ForEach-Object {
            $fullPath = Join-Path -Path $sourceBasePath -ChildPath $_
            if (Test-Path $fullPath) {
                return $fullPath
            }
        } | Where-Object { $_ -ne $null }

        Write-Output "The following items will be deleted:"
        $unmatchedItems | ForEach-Object { Write-Output $_ }

        # Save or update the cache
        Save-Cache -data $unmatchedItems -cachePath $unmatchedCacheFile

        $confirmation = Read-Host "Do you want to proceed with deletion? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-Output "Deletion process cancelled."
            return
        }
    }

    # Delete the unmatched items
    $totalItems = $unmatchedItems.Count
    $currentItem = 0

    foreach ($item in $unmatchedItems) {
        if (![string]::IsNullOrEmpty($item) -and (Test-Path $item)) {
            $currentItem++
            Write-Progress -Activity "Deleting unmatched items" -Status "Deleting $item" -PercentComplete (($currentItem / $totalItems) * 100)

            try {
                if (Test-Path -PathType Container $item) {
                    Remove-Item -Path $item -Recurse -Force
                    Write-Output "Deleted directory $item"
                } elseif (Test-Path -PathType Leaf $item) {
                    Remove-Item -Path $item -Force
                    Write-Output "Deleted file $item"
                }
            } catch {
                Write-Output "Error deleting item $item"
            }
        } else {
            Write-Output "Item '$item' is invalid or does not exist, skipping."
        }
    }
}


function Discover-MissingItems {
    param (
        [object]$index,
        [string]$sourcePath,
        [string]$referencePath
    )

    function Get-RelativePath {
        param (
            [string]$basePath,
            [string]$fullPath
        )
        $relativePath = $fullPath.Substring($basePath.Length).TrimStart('\')
        return $relativePath
    }

    function Get-FullPath {
        param (
            [string]$basePath,
            [string]$relativePath
        )
        $fullPath = Join-Path -Path $basePath -ChildPath $relativePath
        return $fullPath
    }

    $sourceBasePath = $index.SourceBasePath
    $referenceBasePath = $index.ReferenceBasePath

    if ([string]::IsNullOrEmpty($sourceBasePath) -or [string]::IsNullOrEmpty($referenceBasePath)) {
        Write-Output "Base paths are missing. Please regenerate the index file."
        return
    }

    $cacheExists = Test-Path $missingCacheFile

    if ($cacheExists) {
        $useCache = Read-Host "Missing cache file already exists. Do you want to use it? (yes/no)"
        if ($useCache -eq "yes") {
            $missingItems = Load-Cache -cachePath $missingCacheFile
            Write-Output "Using existing cache for missing items."
        } else {
            # Extract relative paths for comparison
            $sourceItems = $index.Source | ForEach-Object { Get-RelativePath -basePath $sourceBasePath -fullPath $_ }
            $referenceItems = $index.Reference | ForEach-Object { Get-RelativePath -basePath $referenceBasePath -fullPath $_ }

            $missingRelativeItems = $referenceItems | Where-Object { $_ -notin $sourceItems }

            if ($missingRelativeItems.Count -eq 0) {
                Write-Output "No missing items found."
                return
            }

            # Convert relative paths back to full paths
            $missingItems = $missingRelativeItems | ForEach-Object {
                $fullPath = Get-FullPath -basePath $referenceBasePath -relativePath $_
                if (Test-Path $fullPath) {
                    return $fullPath
                }
            } | Where-Object { $_ -ne $null }

            Write-Output "The following items will be copied:"
            $missingItems | ForEach-Object { Write-Output $_ }

            # Save or update the cache
            Save-Cache -data $missingItems -cachePath $missingCacheFile

            $confirmation = Read-Host "Do you want to proceed with copying? (yes/no)"
            if ($confirmation -ne "yes") {
                Write-Output "Copying process cancelled."
                return
            }
        }
    } else {
        # If cache does not exist, perform discovery and create cache
        # Extract relative paths for comparison
        $sourceItems = $index.Source | ForEach-Object { Get-RelativePath -basePath $sourceBasePath -fullPath $_ }
        $referenceItems = $index.Reference | ForEach-Object { Get-RelativePath -basePath $referenceBasePath -fullPath $_ }

        $missingRelativeItems = $referenceItems | Where-Object { $_ -notin $sourceItems }

        if ($missingRelativeItems.Count -eq 0) {
            Write-Output "No missing items found."
            return
        }

        # Convert relative paths back to full paths
        $missingItems = $missingRelativeItems | ForEach-Object {
            $fullPath = Get-FullPath -basePath $referenceBasePath -relativePath $_
            if (Test-Path $fullPath) {
                return $fullPath
            }
        } | Where-Object { $_ -ne $null }

        Write-Output "The following items will be copied:"
        $missingItems | ForEach-Object { Write-Output $_ }

        # Save or update the cache
        Save-Cache -data $missingItems -cachePath $missingCacheFile

        $confirmation = Read-Host "Do you want to proceed with copying? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-Output "Copying process cancelled."
            return
        }
    }

    # Copy the missing items
    $totalItems = $missingItems.Count
    $currentItem = 0

    foreach ($item in $missingItems) {
        if (![string]::IsNullOrEmpty($item) -and (Test-Path $item)) {
            $currentItem++
            Write-Progress -Activity "Copying missing items" -Status "Copying $item" -PercentComplete (($currentItem / $totalItems) * 100)

            try {
                $relativePath = Get-RelativePath -basePath $referenceBasePath -fullPath $item
                $destination = Get-FullPath -basePath $sourcePath -relativePath $relativePath

                # Ensure the destination directory exists
                $destinationDir = [System.IO.Path]::GetDirectoryName($destination)
                if (-not (Test-Path $destinationDir)) {
                    Write-Output "Creating destination directory $destinationDir"
                    New-Item -Path $destinationDir -ItemType Directory -Force
                }

                Copy-Item -Path $item -Destination $destination -Force
                Write-Output "Copied file $item to $destination"
            } catch {
                Write-Output "Error copying item $item"
            }
        } else {
            Write-Output "Item '$item' is null, empty, or does not exist, skipping."
        }
    }
}


# Main logic
if (Test-NetworkPath -path $referenceDir) {
    if (Test-Path $indexFile) {
        $refreshIndex = Read-Host "Index file exists. Do you want to refresh it? (yes/no)"
        if ($refreshIndex -eq "yes") {
            Generate-IndexFile -sourcePath $sourceDir -referencePath $referenceDir -indexPath $indexFile
        }
    } else {
        Generate-IndexFile -sourcePath $sourceDir -referencePath $referenceDir -indexPath $indexFile
    }

    $index = Load-IndexFile -indexPath $indexFile

    if ($index -ne $null) {
        $operation = Read-Host "Choose an operation: (a) Discover unmatched items, (b) Discover missing items"

        switch ($operation) {
            "a" {
                Discover-UnmatchedItems -index $index
            }
            "b" {
                Discover-MissingItems -index $index -sourcePath $sourceDir -referencePath $referenceDir
            }
            default {
                Write-Output "Invalid operation selected."
            }
        }
    } else {
        Write-Output "Index file could not be loaded."
    }
} else {
    Write-Output "Network path not accessible."
}
