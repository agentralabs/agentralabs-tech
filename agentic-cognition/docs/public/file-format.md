---
status: stable
---

# The .acog File Format

The `.acog` format is a custom binary format with integrity protection designed for long-term persistence of living user models.

## Binary Layout

The file begins with a 4-byte magic number (`ACOG`), followed by a 2-byte version, 2-byte feature flags, 4-byte body length, 32-byte BLAKE3 checksum, and the variable-length JSON body.

## Integrity Guarantees

- BLAKE3 checksums verify file integrity on every read
- Atomic writes use temp-file-plus-rename to prevent partial write corruption
- Per-project isolation allows separate `.acog` files for different contexts

## Capacity

A year of intensive modeling produces approximately 2 MB. A decade of modeling produces approximately 20 MB. No external database dependencies are required.

## Portability

One `.acog` file holds the complete user model. It survives restarts, model switches, and months between sessions. Load it into any LLM and it instantly understands who the user is.
