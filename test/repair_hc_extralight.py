#!/usr/bin/env python3
"""Repair the misnamed Hong Kong face in SourceHanSans-ExtraLight.ttc.

The Pal3love TrueType conversion of Source Han Sans 2.005 writes the
ExtraLight TTC's Hong Kong face with family and full name "SourceHanSansHC"
— concatenated, no weight, and unlike every other weight TTC, which names
the same face "Source Han Sans HC ExtraLight". The face's own name ID 3
(unique ID) and ID 6 (postscript name, SourceHanSansHC-ExtraLight) already
carry the ExtraLight identity, so only name records 1 and 4 are botched.
Left unfixed, fontist indexes the face under the concatenated name,
consumers looking up "Source Han Sans HC ExtraLight" miss it, and the
formulas regression spec (which locks the full legacy name set) fails.

Idempotent: exits 0 without rewriting when the face is already named
correctly. Fails when neither spelling is present.
"""

import sys

from fontTools.ttLib import TTCollection

GOOD = "Source Han Sans HC ExtraLight"
BAD = "SourceHanSansHC"


def main(path):
    collection = TTCollection(path)
    broken = None
    for font in collection.fonts:
        name_table = font["name"]
        family = name_table.getDebugName(1)
        if family == GOOD:
            print("already repaired")
            return 0
        if family == BAD and broken is None:
            broken = font
    if broken is None:
        print(f"ERROR: no face found with family {GOOD!r} or {BAD!r}")
        return 1

    name_table = broken["name"]
    for record in name_table.names:
        if record.nameID in (1, 4) and record.toUnicode() == BAD:
            name_table.setName(GOOD, record.nameID,
                               record.platformID, record.platEncID, record.langID)
    collection.save(path)
    print(f"repaired: name ID 1/4 -> {GOOD!r}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
