#!make
SHELL ?= /bin/bash
ifdef ComSpec
	PATHSEP2 := \\
else
	PATHSEP2 := /
endif
PATHSEP := $(strip $(PATHSEP2))

7ZEXE := $(which 7z)

FONTS := \
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
	SourceSerifPro-SemiboldIt.ttf \
	SourceHanSans.ttc

FONTS := $(addprefix fonts/,$(FONTS))

all: source-fonts.zip

test:

clean:
	rm -f source-fonts.zip

distclean:
	rm -rf fonts

source-fonts.zip: $(FONTS)
	zip -9 -r $@ fonts

fonts:
	mkdir -p $(subst /,$(PATHSEP),$@)

fonts/SourceSansPro-%: | fonts
	export TMPDIR=$(mktemp); \
	curl -sSL -o ${TMPDIR}/ssp.zip https://github.com/adobe-fonts/source-sans/releases/download/3.006R/source-sans-pro-3.006R.zip ; \
	unzip -j -f ${TMPDIR}/ssp.zip *.ttf -d ${TMPDIR}fonts ; \
	cp ${TMPDIR}fonts/SourceSansPro-*.ttf fonts/

fonts/SourceSerifPro-%: | fonts
	export TMPDIR=$(mktemp); \
	curl -sSL -o ${TMPDIR}ssp.zip https://github.com/adobe-fonts/source-serif/releases/download/3.001R/source-serif-pro-3.001R.zip ; \
	unzip -j -f ${TMPDIR}ssp.zip *.ttf -d ${TMPDIR}fonts ; \
	cp ${TMPDIR}fonts/SourceSerifPro-*.ttf fonts/

fonts/SourceCodePro-%: | fonts
	curl -sSL -o $@ https://github.com/adobe-fonts/source-code-pro/raw/2.030R-ro/1.050R-it/TTF/$(notdir $@)

# tmp:
# 	mkdir -p $@

# tmp/SourceHanSans.7z: | tmp
# 	curl -ssL -o $@ https://github.com/Pal3love/Source-Han-TrueType/raw/master/SourceHanSans.7z

fonts/SourceHanSans.ttc: | fonts
	curl -ssL -o $@ https://github.com/adobe-fonts/source-han-sans/releases/download/2.001R/SourceHanSans.ttc

# version:
# 	echo "${JAR_VERSION}"

.PHONY: all clean distclean test
