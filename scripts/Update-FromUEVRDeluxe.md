# UEVR Deluxe Profile Logic

## Metadata Concept
The UEVR Deluxe profiles are hosted on an Azure Function backend with an Azure Table Storage database.

**Endpoint**: `https://uevrdeluxefunc.azurewebsites.net/api/allprofiles`
**Headers Required**: 
- `Accept: application/json`
- `User-Agent: UEVRDeluxe`

The metadata is returned as a flat JSON array of objects.

**Example Response Snippet**:
```json
[
  {
    "ID": "09cfc6e4-b527-4290-9b75-5ec172dc69d2",
    "exeName": "AKA_RIP-Win64-Shipping",
    "gameName": "R.I.P.-Reincarnation Insurance Program",
    "gameVersion": "",
    "authorName": "Keyser-Soze",
    "modifiedDate": "2026-01-25T00:00:00",
    "remarks": "Basic Gamepad profile"
  }
]
```

## Download Concept
**Endpoint Form**: `https://uevrdeluxefunc.azurewebsites.net/api/profiles/{exeName}/{ID}`
**Headers Required**: same as Metadata

**Implementation Constraints**:
1. Both `exeName` and `ID` parameter properties must be extracted from the metadata object.
2. The `ID` property comes with hyphens. The Azure endpoint route specifically anticipates the `ID` formatted **without hyphens** (e.g., `09cfc6e4b52742909b755ec172dc69d2`).
3. The `exeName` must be fully URL-encoded in the route path.
4. Calling the URL natively returns the `.zip` archive bytes directly.
