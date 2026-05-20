# Git Bundle DFDL Schema

A pure [DFDL 1.0](https://daffodil.apache.org/docs/dfdl/) schema that parses
GitLab `project.bundle` files — git bundles (`gitformat-bundle`) — into an
Apache Daffodil infoset and unparses them back byte-for-byte. It adds git
bundle as an inspectable file type for Arcfield PuriFile.

Developed and verified against Apache Daffodil 4.1.0.

## Layout

| Path | What it is |
|---|---|
| `schema/gitbundle.dfdl.xsd` | The schema. Single self-contained DFDL file. |
| `test/gitbundle.tdml` | Daffodil TDML test suite (2 positive, 5 negative). |
| `test/data/` | Test fixtures — valid and negative bundles. |
| `test/generate-fixtures.sh` | Regenerates every fixture from scratch. |
| `docs/superpowers/` | Design spec and implementation plan. |

## What it parses

The git bundle text header is parsed into structured fields: signature, v3
capabilities, prerequisites, references, and the packfile's `PACK` magic,
version and object count. Every attacker-controllable header field is checked
with a hard DFDL assertion (or a structural length pattern), so a malformed or
suspicious bundle becomes a Daffodil processing error — the signal PuriFile
uses to reject a file.

Supported: bundle v2 and v3; SHA-1 (40-hex) and SHA-256 (64-hex) object ids.

## Running it

Requires the Apache Daffodil 4.1.0 CLI and Java 11+.

Parse a bundle to an infoset:

    daffodil parse -s schema/gitbundle.dfdl.xsd -r gitBundle project.bundle

Unparse an infoset back to a bundle:

    daffodil unparse -s schema/gitbundle.dfdl.xsd -r gitBundle infoset.xml

Run the test suite:

    daffodil test test/gitbundle.tdml

Regenerate fixtures (needs `git` >= 2.45 and `python3`):

    test/generate-fixtures.sh

## Validation rules

A bundle is rejected (processing error) if any of these fail:

1. Signature is exactly `# v2 git bundle` or `# v3 git bundle`.
2. `@capability` lines appear only in v3 — present in v2 is an error.
3. Capability key is one of `object-format`, `filter` (unknown is rejected).
4. An `object-format` value is `sha1` or `sha256`.
5. Object ids are lowercase hex, length 40 or 64, consistent with the
   bundle's hash format and each other.
6. Header free-text fields (`refName`, `comment`, capability `value`)
   contain no control characters (`0x00`-`0x1F`, `0x7F`).
7. `refName` is non-empty.
8. Packfile magic is `PACK`.
9. Packfile version is 2 or 3.

## Scope and limitations

- **The packfile body is opaque.** Git objects are zlib-compressed
  (RFC 1950); Daffodil ships no zlib layer and the deployment forbids custom
  layer JARs. After `PACK` magic, version and object count, the remaining
  bytes (objects + checksum trailer) are consumed as one opaque `hexBinary`
  element — round-tripped exactly, but individual objects are not
  decompressed or walked. That element uses `lengthKind="delimited"` with no
  in-scope delimiter to read to end-of-data: Daffodil 4.1.0 does not implement
  `lengthKind="endOfParent"` for simple types, and this is the documented
  fallback.
- **The pack checksum trailer is not isolated.** Splitting off the final
  20/32 bytes needs the total file length or a full object walk, neither
  available in pure DFDL; the trailer lives inside the opaque body.
- **PuriFile packaging.** Any root-element, namespace or registration-manifest
  conventions PuriFile requires are out of scope; the schema is standard
  DFDL 1.0 in namespace `urn:gitlab:git-bundle:1.0`.

See `docs/superpowers/specs/2026-05-20-git-bundle-dfdl-design.md` for the full
design and `docs/superpowers/plans/` for the implementation plan, including
notes on Daffodil 4.1.0 compatibility.
