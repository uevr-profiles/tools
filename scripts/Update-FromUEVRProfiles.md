# UEVRProfiles API Logic

## Metadata Concept
The UEVRProfiles list is hosted via a Google Firestore database.

**Endpoint**: `https://firestore.googleapis.com/v1/projects/uevrprofiles/databases/(default)/documents/games?pageSize=50` (or similar page size limit)
**Headers Required**: None specific, typical browser `User-Agent` is fine.

The metadata is returned in the Google Firestore REST schema format. Each document has a `name` representing its collection path and a `fields` object containing strongly-typed property data (e.g., `stringValue`, `timestampValue`).

**Example Response Snippet**:
```json
{
  "documents": [
    {
      "name": "projects/uevrprofiles/databases/(default)/documents/games/some-document-guid",
      "fields": {
        "gameName": { "stringValue": "MyGame" },
        "author": { "stringValue": "VRUser" },
        "archiveFile": { "stringValue": "mygame_profile.zip" },
        "creationDate": { "timestampValue": "2024-03-10T15:22:00Z" }
      }
    }
  ]
}
```

## Download Concept
**Endpoint Form**: `https://firebasestorage.googleapis.com/v0/b/uevrprofiles.appspot.com/o/profiles%2F{archiveFile}?alt=media`
**Headers Required**: None specific

**Implementation Constraints**:
1. The target zip filename is parsed from the Firestore `fields.archiveFile.stringValue` property.
2. The endpoint retrieves files directly from Google Firebase Storage. The targeted object path within the bucket is `profiles/{archiveFile}`. This entire path must be URL-encoded in the route (which means `profiles/mygame_profile.zip` becomes `profiles%2Fmygame_profile.zip`).
3. The query parameter `?alt=media` **must** be appended. If omitted, the Google Storage API natively evaluates it as a request to return the JSON metadata of the file object instead of the actual file bytes.
