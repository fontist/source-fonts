SHELL ?= /bin/bash
ifdef ComSpec
	PATHSEP2 := \\
else
	PATHSEP2 := /
endif
PATHSEP := $(strip $(PATHSEP2))

# v1.4 contract: single fonts/ flat layout (v1.0), all fonts static.
# TrueType outlines only — Apache FOP (mn2pdf's PDF engine) cannot use
# variable fonts, and the metanorma flavor stylesheets hardcode the
# legacy family names (Source Sans Pro / Source Serif Pro / Source Han Sans).
# Latin pins the last legacy-named Adobe builds (3.006R / 3.001R); Code Pro
# never renamed, so it tracks the current static release.

LATN := \
	SourceCodePro-Black.ttf \
	SourceCodePro-BlackIt.ttf \
	SourceCodePro-Bold.ttf \
	SourceCodePro-BoldIt.ttf \
	SourceCodePro-ExtraLight.ttf \
	SourceCodePro-ExtraLightIt.ttf \
	SourceCodePro-It.ttf \
	SourceCodePro-Light.ttf \
	SourceCodePro-LightIt.ttf \
	SourceCodePro-Medium.ttf \
	SourceCodePro-MediumIt.ttf \
	SourceCodePro-Regular.ttf \
	SourceCodePro-Semibold.ttf \
	SourceCodePro-SemiboldIt.ttf \
	SourceSansPro-Black.ttf \
	SourceSansPro-BlackIt.ttf \
	SourceSansPro-Bold.ttf \
	SourceSansPro-BoldIt.ttf \
	SourceSansPro-ExtraLight.ttf \
	SourceSansPro-ExtraLightIt.ttf \
	SourceSansPro-It.ttf \
	SourceSansPro-Light.ttf \
	SourceSansPro-LightIt.ttf \
	SourceSansPro-Regular.ttf \
	SourceSansPro-Semibold.ttf \
	SourceSansPro-SemiboldIt.ttf \
	SourceSerifPro-Black.ttf \
	SourceSerifPro-BlackIt.ttf \
	SourceSerifPro-Bold.ttf \
	SourceSerifPro-BoldIt.ttf \
	SourceSerifPro-ExtraLight.ttf \
	SourceSerifPro-ExtraLightIt.ttf \
	SourceSerifPro-It.ttf \
	SourceSerifPro-Light.ttf \
	SourceSerifPro-LightIt.ttf \
	SourceSerifPro-Regular.ttf \
	SourceSerifPro-Semibold.ttf \
	SourceSerifPro-SemiboldIt.ttf

CJK := \
	SourceHanSans-Bold.ttc \
	SourceHanSans-ExtraLight.ttc \
	SourceHanSans-Heavy.ttc \
	SourceHanSans-Light.ttc \
	SourceHanSans-Medium.ttc \
	SourceHanSans-Normal.ttc \
	SourceHanSans-Regular.ttc

FONTS := $(addprefix fonts/,$(LATN) $(CJK))

all: source-fonts.zip

test: source-fonts.zip
	python3 test/mn2pdf_compat.py source-fonts.zip

clean:
	rm -rf source-fonts.zip fonts tmp

distclean: clean
	rm -rf .archive

source-fonts.zip: $(FONTS)
	zip -9 -r $@ fonts

fonts:
	mkdir -p $(subst /,$(PATHSEP),$@)

fonts/SourceSansPro-%: .archive/source-sans-pro.zip | fonts tmp
	unzip -o -j $< '*TTF/$(notdir $@)' -d tmp/sanspro ; \
	cp tmp/sanspro/$(notdir $@) $@

fonts/SourceSerifPro-%: .archive/source-serif-pro.zip | fonts tmp
	unzip -o -j $< '*TTF/$(notdir $@)' -d tmp/serifpro ; \
	cp tmp/serifpro/$(notdir $@) $@

fonts/SourceCodePro-%: .archive/source-code-pro.zip | fonts tmp
	unzip -o -j $< '*TTF/$(notdir $@)' -d tmp/codepro ; \
	cp tmp/codepro/$(notdir $@) $@

fonts/SourceHanSans-%.ttc: .archive/source-han-sans-ttf.zip | fonts
	unzip -o -j $< '$(notdir $@)' -d fonts

.archive:
	mkdir -p $@

tmp:
	mkdir -p $@

# TrueType conversions of Source Han Sans 2.005 (TrueType outlines, legacy
# family names, per-weight TTCs — the shape v1.0 shipped). Adobe's own
# 2.005R assets are variable-font or CFF-only; FOP renders the TrueType
# TTCs that every metanorma render since v1.0 has been built on.
.archive/source-han-sans-ttf.zip: | .archive
	curl -ssL -o $@ https://github.com/Pal3love/Source-Han-TrueType/releases/download/2.005-2.003-1.002-R/SourceHanSans.zip

# Last "Source Sans Pro"-named release (the family was renamed to
# "Source Sans 3" in later releases, which metanorma stylesheets do not
# reference).
.archive/source-sans-pro.zip: | .archive
	curl -ssL -o $@ https://github.com/adobe-fonts/source-sans/releases/download/3.006R/source-sans-pro-3.006R.zip

# Last "Source Serif Pro"-named release (renamed to "Source Serif 4"
# afterwards).
.archive/source-serif-pro.zip: | .archive
	curl -ssL -o $@ https://github.com/adobe-fonts/source-serif/releases/download/3.001R/source-serif-pro-3.001R.zip

.archive/source-code-pro.zip: | .archive
	curl -ssL -o $@ https://github.com/adobe-fonts/source-code-pro/releases/download/2.042R-u%2F1.062R-i%2F1.026R-vf/TTF-source-code-pro-2.042R-u_1.062R-i.zip

.PHONY: all test clean distclean
