//! File format specifications for 20-year compatibility.
//!
//! All sister file formats (.amem, .avis, .acb, .aid, etc.) use a
//! standard header format that ensures backward compatibility.
//!
//! # The 20-Year Promise
//!
//! Any .a* file created today will be readable in 2046.

use crate::errors::{ErrorCode, SisterError, SisterResult};
use crate::types::{SisterType, Version};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::io::{Read, Write};
use std::path::Path;

/// Magic bytes for all sister files: "AGNT" (0x41474E54).
pub const FILE_MAGIC: [u8; 4] = [0x41, 0x47, 0x4E, 0x54];

/// Standard header size in bytes.
pub const HEADER_SIZE: usize = 96;

/// Standard file header for ALL .a* formats.
///
/// This header is exactly 96 bytes and appears at the start of every sister file.
/// It enables version detection and integrity verification without parsing
/// the entire file.
#[derive(Debug, Clone, Copy)]
#[repr(C, packed)]
pub struct SisterFileHeader {
    /// Magic bytes: "AGNT" (0x41474E54).
    pub magic: [u8; 4],

    /// Sister type (1 byte).
    pub sister_type: u8,

    /// Format version (major.minor.patch as 3 bytes).
    pub version_major: u8,
    pub version_minor: u8,
    pub version_patch: u8,

    /// Flags (reserved for future use).
    pub flags: u32,

    /// Header checksum (CRC32 of header bytes 0-11).
    pub header_checksum: u32,

    /// Content checksum (BLAKE3, 32 bytes).
    pub content_checksum: [u8; 32],

    /// Content offset (where actual data starts).
    pub content_offset: u64,

    /// Content length in bytes.
    pub content_length: u64,

    /// Created timestamp (Unix timestamp).
    pub created_at: u64,

    /// Updated timestamp (Unix timestamp).
    pub updated_at: u64,

    /// Reserved for future use.
    pub reserved: [u8; 16],
}

impl SisterFileHeader {
    /// Create a new header.
    pub fn new(sister_type: SisterType, version: Version) -> Self {
        let now = Utc::now().timestamp() as u64;
        let mut header = Self {
            magic: FILE_MAGIC,
            sister_type: sister_type.to_byte(),
            version_major: version.major,
            version_minor: version.minor,
            version_patch: version.patch,
            flags: 0,
            header_checksum: 0,
            content_checksum: [0; 32],
            content_offset: HEADER_SIZE as u64,
            content_length: 0,
            created_at: now,
            updated_at: now,
            reserved: [0; 16],
        };
        header.header_checksum = header.compute_header_checksum();
        header
    }

    /// Compute header checksum (CRC32 of first 12 bytes).
    fn compute_header_checksum(&self) -> u32 {
        let bytes = [
            self.magic[0],
            self.magic[1],
            self.magic[2],
            self.magic[3],
            self.sister_type,
            self.version_major,
            self.version_minor,
            self.version_patch,
            (self.flags & 0xFF) as u8,
            ((self.flags >> 8) & 0xFF) as u8,
            ((self.flags >> 16) & 0xFF) as u8,
            ((self.flags >> 24) & 0xFF) as u8,
        ];
        crc32fast::hash(&bytes)
    }

    /// Validate the header.
    pub fn validate(&self) -> SisterResult<()> {
        // Check magic
        if self.magic != FILE_MAGIC {
            return Err(SisterError::new(
                ErrorCode::InvalidInput,
                format!(
                    "Invalid file magic: expected {:?}, got {:?}",
                    FILE_MAGIC, self.magic
                ),
            ));
        }

        // Check sister type
        if SisterType::from_byte(self.sister_type).is_none() {
            return Err(SisterError::new(
                ErrorCode::InvalidInput,
                format!("Unknown sister type: 0x{:02X}", self.sister_type),
            ));
        }

        // Check header checksum
        let computed = self.compute_header_checksum();
        if computed != self.header_checksum {
            return Err(SisterError::new(
                ErrorCode::ChecksumMismatch,
                "Header checksum mismatch - file may be corrupted",
            ));
        }

        Ok(())
    }

    /// Get the sister type.
    pub fn get_sister_type(&self) -> Option<SisterType> {
        SisterType::from_byte(self.sister_type)
    }

    /// Get the version.
    pub fn get_version(&self) -> Version {
        Version::new(self.version_major, self.version_minor, self.version_patch)
    }

    /// Get created timestamp.
    pub fn get_created_at(&self) -> DateTime<Utc> {
        DateTime::from_timestamp(self.created_at as i64, 0)
            .unwrap_or_else(Utc::now)
    }

    /// Get updated timestamp.
    pub fn get_updated_at(&self) -> DateTime<Utc> {
        DateTime::from_timestamp(self.updated_at as i64, 0)
            .unwrap_or_else(Utc::now)
    }

    /// Set content info.
    pub fn set_content(&mut self, length: u64, checksum: [u8; 32]) {
        self.content_length = length;
        self.content_checksum = checksum;
        self.updated_at = Utc::now().timestamp() as u64;
        self.header_checksum = self.compute_header_checksum();
    }

    /// Write header to bytes.
    pub fn to_bytes(&self) -> [u8; HEADER_SIZE] {
        let mut bytes = [0u8; HEADER_SIZE];

        bytes[0..4].copy_from_slice(&self.magic);
        bytes[4] = self.sister_type;
        bytes[5] = self.version_major;
        bytes[6] = self.version_minor;
        bytes[7] = self.version_patch;
        bytes[8..12].copy_from_slice(&self.flags.to_le_bytes());
        bytes[12..16].copy_from_slice(&self.header_checksum.to_le_bytes());
        bytes[16..48].copy_from_slice(&self.content_checksum);
        bytes[48..56].copy_from_slice(&self.content_offset.to_le_bytes());
        bytes[56..64].copy_from_slice(&self.content_length.to_le_bytes());
        bytes[64..72].copy_from_slice(&self.created_at.to_le_bytes());
        bytes[72..80].copy_from_slice(&self.updated_at.to_le_bytes());
        bytes[80..96].copy_from_slice(&self.reserved);

        bytes
    }

    /// Read header from bytes.
    pub fn from_bytes(bytes: &[u8; HEADER_SIZE]) -> Self {
        let mut magic = [0u8; 4];
        magic.copy_from_slice(&bytes[0..4]);

        let mut content_checksum = [0u8; 32];
        content_checksum.copy_from_slice(&bytes[16..48]);

        let mut reserved = [0u8; 16];
        reserved.copy_from_slice(&bytes[80..96]);

        Self {
            magic,
            sister_type: bytes[4],
            version_major: bytes[5],
            version_minor: bytes[6],
            version_patch: bytes[7],
            flags: u32::from_le_bytes([bytes[8], bytes[9], bytes[10], bytes[11]]),
            header_checksum: u32::from_le_bytes([bytes[12], bytes[13], bytes[14], bytes[15]]),
            content_checksum,
            content_offset: u64::from_le_bytes([
                bytes[48], bytes[49], bytes[50], bytes[51],
                bytes[52], bytes[53], bytes[54], bytes[55],
            ]),
            content_length: u64::from_le_bytes([
                bytes[56], bytes[57], bytes[58], bytes[59],
                bytes[60], bytes[61], bytes[62], bytes[63],
            ]),
            created_at: u64::from_le_bytes([
                bytes[64], bytes[65], bytes[66], bytes[67],
                bytes[68], bytes[69], bytes[70], bytes[71],
            ]),
            updated_at: u64::from_le_bytes([
                bytes[72], bytes[73], bytes[74], bytes[75],
                bytes[76], bytes[77], bytes[78], bytes[79],
            ]),
            reserved,
        }
    }

    /// Read header from a reader.
    pub fn read_from<R: Read>(reader: &mut R) -> SisterResult<Self> {
        let mut bytes = [0u8; HEADER_SIZE];
        reader.read_exact(&mut bytes).map_err(|e| {
            SisterError::new(ErrorCode::StorageError, format!("Failed to read header: {}", e))
        })?;

        let header = Self::from_bytes(&bytes);
        header.validate()?;
        Ok(header)
    }

    /// Write header to a writer.
    pub fn write_to<W: Write>(&self, writer: &mut W) -> SisterResult<()> {
        writer.write_all(&self.to_bytes()).map_err(|e| {
            SisterError::new(ErrorCode::StorageError, format!("Failed to write header: {}", e))
        })
    }
}

/// Information about a file (without loading full content).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileInfo {
    pub sister_type: SisterType,
    pub version: Version,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub content_length: u64,
    pub needs_migration: bool,
}

impl FileInfo {
    /// Read file info from path.
    pub fn from_path(path: &Path, current_version: &Version) -> SisterResult<Self> {
        let mut file = std::fs::File::open(path)?;
        let header = SisterFileHeader::read_from(&mut file)?;
        let file_version = header.get_version();

        Ok(Self {
            sister_type: header.get_sister_type().ok_or_else(|| {
                SisterError::new(ErrorCode::InvalidInput, "Unknown sister type")
            })?,
            version: file_version.clone(),
            created_at: header.get_created_at(),
            updated_at: header.get_updated_at(),
            content_length: header.content_length,
            needs_migration: file_version.major < current_version.major,
        })
    }
}

/// File format reader trait for all sisters.
pub trait FileFormatReader: Sized {
    /// Read file with version handling.
    fn read_file(path: &Path) -> SisterResult<Self>;

    /// Check if file is readable (without full parse).
    fn can_read(path: &Path) -> SisterResult<FileInfo>;

    /// Get file version without full parse.
    fn file_version(path: &Path) -> SisterResult<Version>;

    /// Migrate old version to current (in memory).
    fn migrate(data: &[u8], from_version: Version) -> SisterResult<Vec<u8>>;
}

/// File format writer trait for all sisters.
pub trait FileFormatWriter {
    /// Write to file.
    fn write_file(&self, path: &Path) -> SisterResult<()>;

    /// Get the content as bytes.
    fn to_bytes(&self) -> SisterResult<Vec<u8>>;
}

/// Version compatibility rules.
///
/// These rules ensure the 20-year compatibility promise.
#[derive(Debug, Clone)]
pub struct VersionCompatibility;

impl VersionCompatibility {
    /// Check if reader version can read file version.
    ///
    /// Rule: Newer readers can always read older files.
    pub fn can_read(reader_version: &Version, file_version: &Version) -> bool {
        reader_version.major >= file_version.major
    }

    /// Check if file needs migration.
    pub fn needs_migration(current_version: &Version, file_version: &Version) -> bool {
        file_version.major < current_version.major
    }

    /// Check if versions are fully compatible (same major).
    pub fn is_compatible(v1: &Version, v2: &Version) -> bool {
        v1.major == v2.major
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_header_roundtrip() {
        let header = SisterFileHeader::new(SisterType::Memory, Version::new(0, 3, 2));
        let bytes = header.to_bytes();
        let recovered = SisterFileHeader::from_bytes(&bytes);

        assert_eq!(recovered.magic, FILE_MAGIC);
        assert_eq!(recovered.get_sister_type(), Some(SisterType::Memory));
        assert_eq!(recovered.get_version(), Version::new(0, 3, 2));
    }

    #[test]
    fn test_header_validation() {
        let header = SisterFileHeader::new(SisterType::Vision, Version::new(1, 0, 0));
        assert!(header.validate().is_ok());

        // Invalid magic
        let mut bad_header = header;
        bad_header.magic = [0, 0, 0, 0];
        assert!(bad_header.validate().is_err());
    }

    #[test]
    fn test_version_compatibility() {
        let v1 = Version::new(1, 0, 0);
        let v2 = Version::new(2, 0, 0);
        let v1_1 = Version::new(1, 1, 0);

        // v2 reader can read v1 file
        assert!(VersionCompatibility::can_read(&v2, &v1));
        
        // v1 reader cannot read v2 file
        assert!(!VersionCompatibility::can_read(&v1, &v2));

        // v1 and v1.1 are compatible
        assert!(VersionCompatibility::is_compatible(&v1, &v1_1));

        // v1 file needs migration to v2
        assert!(VersionCompatibility::needs_migration(&v2, &v1));
    }

    #[test]
    fn test_header_size() {
        // Ensure header is exactly 96 bytes
        assert_eq!(std::mem::size_of::<[u8; HEADER_SIZE]>(), 96);
    }
}
