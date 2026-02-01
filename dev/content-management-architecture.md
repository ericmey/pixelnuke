# Content Management Architecture

This document describes how Pixelnuke manages factory content vs user content across the partition scheme.

## Overview

Pixelnuke uses a **layered content system** where factory-provided content (samples, presets, kits) is read-only and bundled with firmware, while user content is fully editable on a separate partition.

## Partition Roles

| Partition | Content Type | Access |
|-----------|--------------|--------|
| PXNK_BOOT | WiFi config, GPU firmware | Static, user-editable config |
| PXNK_A/B | Kernel + factory content | Read-only (bundled with firmware) |
| PXNK_USER | User content | Full read/write |

## Directory Structure

### Active Boot Partition (A or B)
```
PXNK_A/
├── kernel8.img
├── config.txt
├── cmdline.txt
└── factory/                    # Read-only, bundled with firmware
    ├── samples/
    │   ├── kicks/
    │   │   ├── 808_kick.wav
    │   │   └── acoustic_kick.wav
    │   ├── snares/
    │   └── hihats/
    ├── presets/
    │   ├── default.json
    │   └── classic_808.json
    └── kits/
        ├── 808_kit.json
        └── acoustic_kit.json
```

### User Partition
```
PXNK_USER/
├── samples/                    # User's own samples
│   ├── kicks/
│   │   └── my_custom_kick.wav
│   └── snares/
├── presets/                    # User-created presets
│   └── my_preset.json
├── kits/                       # User-created kits
│   └── my_kit.json
├── projects/                   # User projects/songs
│   └── song_01.json
└── .overrides                  # Tracks user overrides of factory content
```

## Application-Level Implementation

Since we're bare metal with FAT32 (no symlinks, no overlay filesystem), content management is handled at the application layer.

### Content Index

At startup, the app builds an in-memory content index:

```cpp
struct ContentItem {
    const char* name;           // Display name
    const char* path;           // Full filesystem path
    ContentSource source;       // FACTORY or USER
    ContentType type;           // SAMPLE, PRESET, KIT
    bool isOverride;            // User item overriding factory item
    bool isHidden;              // Factory item hidden by user
};

class CContentManager {
public:
    void ScanContent(void);     // Scan both partitions

    // Get unified content list (factory + user, with overrides applied)
    ContentItem* GetSamples(unsigned* count);
    ContentItem* GetPresets(unsigned* count);
    ContentItem* GetKits(unsigned* count);

    // User operations
    bool SaveSample(const char* name, const void* data, size_t size);
    bool DeleteUserItem(const char* path);
    bool HideFactoryItem(const char* name);  // Can't delete, only hide
    bool UnhideFactoryItem(const char* name);

private:
    void MergeFactoryAndUser(void);  // Apply overrides, hidden items
};
```

### Scanning Algorithm

```
1. Mount active boot partition (A or B) as read-only
2. Scan factory/ directory, add all items with source=FACTORY
3. Mount PXNK_USER as read-write
4. Load .overrides file (list of hidden factory items)
5. Scan user directories, add items with source=USER
6. For each user item:
   - If same name exists in factory: mark as isOverride=true
   - Mark corresponding factory item as hidden (user version wins)
7. Mark hidden factory items from .overrides file
8. Build final unified index
```

### Override Behavior

| Scenario | Behavior |
|----------|----------|
| Factory sample "kick.wav" | Shown, read-only |
| User creates "kick.wav" | User version shown, factory hidden |
| User deletes "kick.wav" | Factory version reappears |
| User hides factory "kick.wav" | Hidden, can unhide later |

### File Formats

**.overrides file (on PXNK_USER):**
```
# Factory items hidden by user
samples/kicks/808_kick.wav
presets/default.json
```

## OTA Update Considerations

When firmware is updated via OTA:
- New factory content is part of the firmware image
- User content on PXNK_USER is untouched
- User overrides remain in effect
- New factory items appear automatically
- Removed factory items: user overrides become standalone user items

## Implementation Phases

### Phase 1: Basic Loading (MVP)
- Scan factory/samples/ for .wav files
- Load into sample slots
- No user content yet

### Phase 2: User Content
- Mount PXNK_USER
- Scan user samples
- Build unified index
- Support save/delete

### Phase 3: Presets & Kits
- JSON-based preset/kit files
- Factory defaults
- User customization

### Phase 4: Override System
- .overrides file
- Hide/unhide factory items
- Full content management UI

## Technical Notes

### FAT32 Limitations
- No symlinks (can't link factory→user)
- No permissions (can't mark read-only at filesystem level)
- 8.3 filename fallback (use long filename support in FatFs)

### Memory Constraints
- Pi Zero 2 W has 512MB RAM
- Content index should be lightweight (paths + metadata only)
- Load actual sample data on-demand
- Consider streaming for large samples

### FatFs Configuration
- Enable LFN (Long File Names) in ffconf.h
- Enable multiple volumes for mounting both partitions
- Consider read-only mount for factory partition

## Related Files

- `boot/setup-ab-boot.sh` - Creates factory/ placeholder structure
- `src/app/` - Application implementation (future)
- `docs/` - User documentation
