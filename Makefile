PACKAGE := $(shell grep '^Package:' DESCRIPTION | sed -E 's/^Package:[[:space:]]+//')
RSCRIPT = Rscript --no-init-file

all: install

test:
	${RSCRIPT} -e 'library(methods); devtools::test()'

test_all:
	REMAKE_TEST_INSTALL_PACKAGES=true make test

autodoc:
	${RSCRIPT} autodoc.R process

roxygen:
	@mkdir -p man
	${RSCRIPT} -e "library(methods); devtools::document()"

staticdocs:
	@mkdir -p inst/staticdocs
	Rscript -e "library(methods); staticdocs::build_site()"
	rm -f vignettes/*.html

website: staticdocs
	./update_web.sh

install:
	R CMD INSTALL .

build:
	R CMD build .

check: build
	_R_CHECK_CRAN_INCOMING_=FALSE R CMD check --as-cran --no-manual `ls -1tr ${PACKAGE}*gz | tail -n1`
	@rm -f `ls -1tr ${PACKAGE}*gz | tail -n1`
	@rm -rf ${PACKAGE}.Rcheck

check_all:
	REMAKE_TEST_INSTALL_PACKAGES=true make check

README.md: README.Rmd
	Rscript -e 'library(methods); devtools::load_all(); knitr::knit("README.Rmd")'
	sed -i.bak 's/[[:space:]]*$$//' README.md
	rm -f $@.bak

vignettes/introduction.Rmd: vignettes/src/introduction.R
	${RSCRIPT} -e 'library(sowsear); sowsear("$<", output="$@")'
vignettes/messages.Rmd: vignettes/src/messages.R
	${RSCRIPT} -e 'library(sowsear); sowsear("$<", output="$@")'
vignettes: vignettes/introduction.Rmd vignettes/messages.Rmd
	${RSCRIPT} -e 'library(methods); devtools::build_vignettes()'

.PHONY: all test document install vignettes
