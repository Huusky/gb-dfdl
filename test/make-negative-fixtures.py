#!/usr/bin/env python3
"""Derive negative test fixtures by corrupting valid bundles.

Each corruption is a minimal byte edit aimed at the text header. The git
packfile that trails the header is opaque to the schema (parsed only as
PACK + version + count + verbatim body), so an edit that shifts the pack
does not affect what the fixture tests.
"""
import pathlib
import sys

DATA = pathlib.Path(__file__).resolve().parent / "data"
HEX = b"0123456789abcdef"


def read(name):
    return (DATA / name).read_bytes()


def write(name, data):
    (DATA / name).write_bytes(data)
    print(f"wrote {name} ({len(data)} bytes)")


def split_header(data):
    """Return (header, pack); pack begins at the PACK magic."""
    i = data.index(b"PACK")
    return data[:i], data[i:]


def header_lines(header):
    """Header text lines, excluding the trailing blank line.

    header ends with the last ref's LF followed by the blank-line LF."""
    return header[:-2].split(b"\n")


def first_ref_index(lines):
    """Index of the first reference line (hex id, no @/- prefix)."""
    for idx, line in enumerate(lines):
        if idx == 0 or not line or line[:1] in (b"@", b"-"):
            continue
        if b" " in line and all(c in HEX for c in line.split(b" ", 1)[0]):
            return idx
    raise AssertionError("no reference line found")


def rebuild(lines, pack):
    return b"\n".join(lines) + b"\n\n" + pack


def main():
    v2 = read("valid-v2-sha1.bundle")
    v3 = read("valid-v3-sha256.bundle")

    # rule 1 - bad-signature: version 2 -> 1, fails the [23] assert.
    header, pack = split_header(v2)
    assert header.startswith(b"# v2 git bundle\n"), "unexpected v2 signature"
    write("bad-signature.bundle", header.replace(b"# v2 ", b"# v1 ", 1) + pack)

    # rule 6 - ctrl-char-refname: an ESC (0x1B) inside the first refname.
    header, pack = split_header(v2)
    lines = header_lines(header)
    r = first_ref_index(lines)
    oid, name = lines[r].split(b" ", 1)
    assert len(name) >= 2, "refname too short to corrupt"
    lines[r] = oid + b" " + name[:1] + b"\x1b" + name[2:]
    write("ctrl-char-refname.bundle", rebuild(lines, pack))

    # rule 3 - unknown-capability: object-format -> xbject-format.
    header, pack = split_header(v3)
    assert b"@object-format=" in header, "v3 fixture lacks object-format"
    write("unknown-capability.bundle",
          header.replace(b"@object-format=", b"@xbject-format=", 1) + pack)

    # rule 8 - bad-pack-magic: PACK -> PXCK.
    header, pack = split_header(v2)
    assert pack.startswith(b"PACK")
    write("bad-pack-magic.bundle", header + b"PXCK" + pack[4:])

    # rule 5 - mixed-id-length: extend the first id to 64 hex in a v2
    #          (SHA-1, expected 40) bundle -> length assert fails.
    header, pack = split_header(v2)
    lines = header_lines(header)
    r = first_ref_index(lines)
    oid, name = lines[r].split(b" ", 1)
    assert len(oid) == 40, "expected a 40-hex SHA-1 id"
    lines[r] = (oid + HEX * 2)[:64] + b" " + name
    write("mixed-id-length.bundle", rebuild(lines, pack))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # noqa: BLE001
        sys.exit(f"negative fixture generation failed: {exc}")
