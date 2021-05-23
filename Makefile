SHELL = bash

install_args := --headless=false
ifeq ($(headless), "true")
	install_args := --headless=true
endif

preinstall_args := --use-fallback-versions=false
ifeq ($(fallback_versions), "true")
	preinstall_args := --use-fallback-versions=true
endif

ifndef spec_file
	spec_file := spec/bin/debian_pkgs_spec.sh
endif

ifndef use_docker
	use_docker := true
endif

.PHONY: \
	configure \
	init \
	install \
	format \
	lint \
	provision \
	provision_emulate \
	test_all_docker \
	test_spec

.ONESHELL:
init:
	echo "starting $@ process using $(SHELL) as user $$(whoami)"
	source ./ci/init.sh
	init

.ONESHELL:
format:
	echo "starting $@ process using $(SHELL) as user $$(whoami)"
	source ./ci/format.sh
	format_all

.ONESHELL:
lint:
	echo "starting $@ process using $(SHELL) as user $$(whoami)"
	source ./ci/lint.sh
	lint_all

.ONESHELL:
test_all_docker:
	sudo echo "starting $@ process using $(SHELL) as user $$(whoami)"
	source ./ci/test.sh "serial"
	execute_tests

.ONESHELL:
test_spec:
	sudo echo "starting $@ process using $(SHELL) as user $$(whoami)"
	source ./ci/test.sh "serial"
	execute_test $(spec_file) $(use_docker)

.ONESHELL:
install:
	sudo echo "starting $@ process using $(SHELL) as user $$(whoami)"
	set -eu; set -o pipefail;
	source ./bin/preinstall.sh
	preinstall $(preinstall_args)
	source ./bin/main.sh
	install $(preinstall_args) $(install_args)

.ONESHELL:
configure:
	sudo echo "starting $@ process using $(SHELL) as user $$(whoami)"
	set -eu; set -o pipefail;
	source ./bin/main.sh
	setup

.ONESHELL:
provision:
	sudo echo "starting $@ process using $(SHELL) as user $$(whoami)"
	set -eu; set -o pipefail;
	source ./bin/preinstall.sh
	preinstall $(preinstall_args)
	source ./bin/main.sh
	install $(preinstall_args) $(install_args)
	setup

.ONESHELL:
provision_emulate:
	sudo echo "starting $@ process using $(SHELL) as user $$(whoami)"
	set -eu; set -o pipefail;
	echo "This target runs the provision commandin a docker image"
	echo "The motivation for this is to emulate a CI run locally"
	source ./ci/provision_emulate.sh
	emulate_ci
