#!make
SHELL ?= /bin/bash
ifdef ComSpec
	PATHSEP2 := \\
else
	PATHSEP2 := /
endif
PATHSEP := $(strip $(PATHSEP2))

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
	SourceSans3-SemiboldIt.ttf \
	SourceSans3-Regular.ttf \
	SourceSans3-BlackIt.ttf \
	SourceSans3-It.ttf \
	SourceSans3-Black.ttf \
	SourceSans3-Bold.ttf \
	SourceSans3-LightIt.ttf \
	SourceSans3-ExtraLight.ttf \
	SourceSans3-Light.ttf \
	SourceSans3-Semibold.ttf \
	SourceSans3-BoldIt.ttf \
	SourceSans3-ExtraLightIt.ttf \
	SourceSerif4-Black.ttf \
	SourceSerif4-BlackIt.ttf \
	SourceSerif4-Bold.ttf \
	SourceSerif4-BoldIt.ttf \
	SourceSerif4-ExtraLight.ttf \
	SourceSerif4-ExtraLightIt.ttf \
	SourceSerif4-It.ttf \
	SourceSerif4-Light.ttf \
	SourceSerif4-LightIt.ttf \
	SourceSerif4-Regular.ttf \
	SourceSerif4-Semibold.ttf \
	SourceSerif4-SemiboldIt.ttf

CJK := \
	SourceHanSans-VF.ttf \
	SourceHanSerif-VF.ttf \
	SourceHanMono.ttc

FONTS_LATN := $(addprefix fonts-latn/,$(LATN))
FONTS_CJK := $(addprefix fonts-cjk/,$(notdir $(CJK)))

all: source-fonts-latn.zip source-fonts-cjk.zip

test:

clean:
	rm -rf source-fonts-*.zip fonts-latn fonts-cjk tmp

distclean: clean
	rm -rf .archive

source-fonts-latn.zip: $(FONTS_LATN)
	zip -9 -r $@ fonts-latn

source-fonts-cjk.zip: $(FONTS_CJK)
	zip -9 -r $@ fonts-cjk

fonts-%:
	mkdir -p $(subst /,$(PATHSEP),$@)

fonts-latn/SourceSans3-%: .archive/source-sans-pro.zip | fonts-latn
	mkdir -p tmp/source-sans-pro; \
	unzip -j $< '*$(notdir $@)' -d tmp/source-sans-pro ; \
	cp tmp/source-sans-pro/$(notdir $@) $@

fonts-latn/SourceSerif4-%: .archive/source-serif-pro.zip | fonts-latn
	mkdir -p tmp/source-serif-pro; \
	unzip -j $< '*$(notdir $@)' -d tmp/source-serif-pro ; \
	cp tmp/source-serif-pro/$(notdir $@) $@

fonts-latn/SourceCodePro-%: .archive/source-code-pro.zip | fonts-latn
	mkdir -p tmp/source-code-pro; \
	unzip -j $< '*$(notdir $@)' -d tmp/source-code-pro ; \
	cp tmp/source-code-pro/$(notdir $@) $@

fonts-cjk/SourceHanMono.ttc: | fonts-cjk
	curl -ssL -o $@ https://github.com/adobe-fonts/source-han-mono/releases/download/1.002/SourceHanMono.ttc

fonts-cjk/SourceHanSans-VF.ttf: .archive/source-han-sans.zip | fonts-cjk
	mkdir -p tmp/source-han-sans; \
	unzip -j $< '*$(notdir $@)' -d tmp/source-han-sans ; \
	cp tmp/source-han-sans/$(notdir $@) $@

fonts-cjk/SourceHanSerif-VF.ttf: .archive/source-han-serif.zip | fonts-cjk
	mkdir -p tmp/source-han-serif; \
	unzip -j $< '*$(notdir $@)' -d tmp/source-han-serif ; \
	cp tmp/source-han-serif/$(notdir $@) $@

tmp:
	mkdir -p $@

.archive:
	mkdir -p $@

.archive/source-sans-pro.zip: | .archive
	curl -ssL -o $@ https://github.com/adobe-fonts/source-sans/releases/download/3.046R/TTF-source-sans-3.046R.zip

.archive/source-serif-pro.zip: | .archive
	curl -ssL -o $@ https://github.com/adobe-fonts/source-serif/releases/download/4.004R/source-serif-4.004.zip

.archive/source-code-pro.zip: | .archive
	curl -ssL -o $@ https://github.com/adobe-fonts/source-code-pro/releases/download/2.038R-ro%2F1.058R-it%2F1.018R-VAR/TTF-source-code-pro-2.038R-ro-1.058R-it.zip

.archive/source-han-sans.zip: | .archive
	curl -ssL -o $@ https://github.com/adobe-fonts/source-han-sans/releases/download/2.004R/SourceHanSans-VF.zip

.archive/source-han-serif.zip: | .archive
	curl -ssL -o $@ https://github.com/adobe-fonts/source-han-serif/releases/download/2.001R/02_SourceHanSerif-VF.zip

# version:
# 	echo "${JAR_VERSION}"

.PHONY: all clean distclean test
