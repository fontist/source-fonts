#!/usr/bin/env python3
"""mn2pdf compatibility gate for source-fonts release archives.

Metanorma renders PDFs through mn2pdf, whose PDF engine is Apache FOP:
mn2pdf registers one static font file per weight/style triplet and its
fontConfig explicitly rejects variable fonts, while the flavor
stylesheets look families up under legacy names ("Source Han Sans",
"Source Sans Pro", ...). A release archive therefore ships acceptable
fonts only if, for every face in every file:

  * it is a parseable sfnt container (ttc/ttf/otf),
  * it carries no variable-font tables (fvar/gvar) — mn2pdf's filename
    heuristic (variablefont/wght) is checked too as defense in depth,
and the archive as a whole exposes, under the legacy family names,
at least Regular and Bold styles for every family the fleet needs,
plus the OFL license text for each of them (OFL-1.1 requires the
license to accompany any redistribution).

Usage: python3 test/mn2pdf_compat.py SOURCE-FONTS.zip [more.zip ...]
Exits nonzero if any check fails.
"""

import struct
import sys
import zipfile

REQUIRED_FAMILIES = {
    # metanorma flavor stylesheets (cc/csa/iho/ribose/...) and the ISO
    # sample renders hardcode these names; SC/TC/K/HC ride along in the
    # Han Sans TTCs and are pinned so a repack cannot silently drop them.
    "Source Han Sans",
    "Source Han Sans SC",
    "Source Han Sans TC",
    "Source Han Sans K",
    "Source Han Sans HC",
    "Source Sans Pro",
    "Source Serif Pro",
    "Source Code Pro",
}

REQUIRED_STYLES = {"Regular", "Bold"}

# OFL-1.1 requires the license text and copyright notice to accompany
# any redistribution; each required family must ship its license file
# next to the fonts (see the Makefile's LICENSES targets).
REQUIRED_LICENSES = {
    "fonts/LICENSE-SourceHanSans.txt": "Source Han Sans",
    "fonts/LICENSE-SourceSansPro.txt": "Source Sans Pro",
    "fonts/LICENSE-SourceSerifPro.txt": "Source Serif Pro",
    "fonts/LICENSE-SourceCodePro.txt": "Source Code Pro",
}

# The substring heuristic in mn2pdf fontConfig.java: a path containing
# either of these is refused as a variable font.
BANNED_NAME_SUBSTRINGS = ("variablefont", "wght")

VARIABLE_TABLES = ("fvar", "gvar")


class Face:
    def __init__(self, container, index, family, subfamily):
        self.container = container
        self.index = index
        self.family = family
        self.subfamily = subfamily


def u32(buf, off):
    return struct.unpack_from(">I", buf, off)[0]


def u16(buf, off):
    return struct.unpack_from(">H", buf, off)[0]


def sfnt_faces(buf, label):
    """Yield (table_tags, name_records) per face in a ttc/ttf/otf blob."""
    if buf[:4] == b"ttcf":
        num = u32(buf, 8)
        offsets = [u32(buf, 12 + 4 * i) for i in range(num)]
    else:
        offsets = [0]

    for i, off in enumerate(offsets):
        num_tables = u16(buf, off + 4)
        tags = []
        name_entry = None
        for t in range(num_tables):
            rec = off + 12 + 16 * t
            tag = buf[rec:rec + 4].decode("latin-1")
            tags.append(tag)
            if tag == "name":
                name_entry = (u32(buf, rec + 8), u32(buf, rec + 12))
        if name_entry is None:
            raise ValueError(f"{label} face {i}: no name table")
        table_off, table_len = name_entry
        yield i, set(tags), buf[table_off:table_off + table_len]


def decode_name(raw, platform):
    if platform in (0, 3):
        return raw.decode("utf-16-be", "replace").rstrip("\x00")
    return raw.decode("latin-1", "replace").rstrip("\x00")


def parse_names(buf):
    """Return {name_id: value} from a name table, English record preferred.

    CJK faces carry localized aliases (思源黑体, 源ノ角ゴシック, 본고딕)
    alongside the ASCII family; fontist indexes the English name, and the
    legacy contract is expressed in English names, so prefer an ASCII
    platform-3 record over a localized one.
    """
    count = u16(buf, 2)
    storage = u16(buf, 4)
    records = {}
    for i in range(count):
        rec = 6 + 12 * i
        platform, _encoding, _lang = u16(buf, rec), u16(buf, rec + 2), u16(buf, rec + 4)
        name_id = u16(buf, rec + 6)
        length, offset = u16(buf, rec + 8), u16(buf, rec + 10)
        raw = buf[storage + offset:storage + offset + length]
        if name_id not in (1, 2):
            continue
        value = decode_name(raw, platform)
        current = records.get(name_id)
        if current is None or (value.isascii() and not current.isascii()):
            records[name_id] = value
    return records


def fail_if(condition, message, failures):
    if condition:
        failures.append(message)
        print(f"FAIL: {message}")
    return condition


def check_archive(path, failures):
    print(f"== {path}")
    try:
        zf = zipfile.ZipFile(path)
    except (zipfile.BadZipFile, OSError) as e:
        fail_if(True, f"{path}: unreadable zip: {e}", failures)
        return

    families = {}
    checked = 0
    for member in zf.namelist():
        lower = member.lower()
        for needle in BANNED_NAME_SUBSTRINGS:
            if needle in lower:
                fail_if(True, f"{member}: filename contains '{needle}' "
                              f"(mn2pdf would refuse it as a variable font)", failures)
        if not lower.endswith((".ttf", ".otf", ".ttc", ".otc")):
            continue
        try:
            buf = zf.read(member)
        except zipfile.BadZipFile as e:
            fail_if(True, f"{member}: unreadable member: {e}", failures)
            continue
        try:
            for index, tags, name_buf in sfnt_faces(buf, member):
                checked += 1
                for vt in VARIABLE_TABLES:
                    fail_if(vt in tags,
                            f"{member} face {index}: contains '{vt}' table "
                            f"(variable font; FOP/mn2pdf render only the default instance)",
                            failures)
                names = parse_names(name_buf)
                family = names.get(1, "")
                subfamily = names.get(2, "")
                if not family:
                    fail_if(True, f"{member} face {index}: empty family name "
                                  f"(fontist cannot index it)", failures)
                    continue
                families.setdefault(family, set()).add(subfamily)
        except (ValueError, struct.error) as e:
            fail_if(True, f"{member}: not a parseable sfnt container: {e}", failures)

    fail_if(checked == 0, f"{path}: no sfnt font files found", failures)

    for family in sorted(REQUIRED_FAMILIES):
        styles = families.get(family)
        if styles is None:
            fail_if(True, f"{path}: required family '{family}' missing from the archive", failures)
            continue
        missing = REQUIRED_STYLES - styles
        fail_if(missing, f"{path}: family '{family}' missing styles {sorted(missing)} "
                         f"(mn2pdf registers one file per weight/style)", failures)

    license_names = set(zf.namelist())
    for license_path, family in sorted(REQUIRED_LICENSES.items()):
        if license_path not in license_names:
            fail_if(True, f"{path}: '{license_path}' missing "
                          f"(OFL-1.1 requires the license to accompany the {family} fonts)", failures)
            continue
        text = zf.read(license_path).decode("utf-8", "replace").lower()
        if len(text.strip()) == 0:
            fail_if(True, f"{path}: '{license_path}' is empty", failures)
        elif "open font license" not in text:
            fail_if(True, f"{path}: '{license_path}' does not look like an OFL text "
                          f"(no 'Open Font License' heading)", failures)

    print(f"checked {checked} faces, {len(families)} families, "
          f"{len(REQUIRED_FAMILIES)} required families, "
          f"{len(REQUIRED_LICENSES)} license files")


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    failures = []
    for path in argv[1:]:
        check_archive(path, failures)
    if failures:
        print(f"\nmn2pdf compatibility gate: {len(failures)} failure(s)")
        return 1
    print("\nmn2pdf compatibility gate: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
