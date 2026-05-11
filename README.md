# Localbox

Localbox is a collection of scripts and dotfiles intended to

- Install various formatters, linters, devops tools and apps
- Configure various applications and tools via dotfiles

## Provisioning

Process for provisioning the ubuntu desktop is taken in steps outlined
below.

### Preparation

```bash
sudo apt install -y make git
git clone https://github.com/stephenmoloney/localbox.git
cd localbox
```

### Provisioning with GUI apps

```bash
make provision
```

### Provisioning without GUI apps

```bash
make provision headless=true
```

### Provisioning using environment versions

The recommended way to install particular versions of the the dependencies
is to change the version specified in `.env`. However, it is possible to
use only the default fallback versions specified in the installation files.

To use the versions specified in the `.env` file

```bash
make provision
```

To use default fallback versions and ignore `.env`

```bash
make provision fallback_versions=true headless=false
```

### Emulate installation locally

To emulate the installation process locally, ideally a VM is used.
However, it is possible to emulate the installation process in a
docker container to some extent.

```bash
make provision_emulate
```

or alternatively

```bash
docker build \
  --tag local/shellspec-ubuntu:latest \
  -f shellspec.Dockerfile ./ &&
docker run \
  -ti \
  --kernel-memory=8g \
  --cpus=4 \
  -v $PWD:/localbox \
  --user ubuntu \
  local/shellspec-ubuntu:latest \
  bash -c 'sudo apt install -y make && make provision headless=true'
```

## Installation

Installation can be run as a distinct step before configuration

```bash
make install
```

## Configuration

Configuration can be run as a distinct step after installation

```bash
make configure
```

## Integration tests

### Running tests on a VM

While the command `source ./ci/test.sh "serial" && execute_tests` can
run the test suite sequentially on a single VM. It is not really
recommended due to

- The possibility on state being altered from one test to the next
- The time it would take to run them all on a single image

Instead, each test should be run in isolation on a new VM.

Running tests singularly

```bash
while IFS=' ' read -r -a specs; do
  make test_spec spec_file=spec/bin/${specs[0]}_spec.sh use_docker=false
done < <(ls -A ./spec/bin | sed 's/_spec//g' | sed 's/\.sh//g')
```

### Running tests on docker

Running tests locally on VMS would be time-consuming to setup.
An alternative approach which may suffice for local testing
would be to run the tests on local docker containers.

Running all tests locally using docker

```bash
make test_all_docker;
```

Running tests singularly using docker

```bash
while IFS=' ' read -r -a specs; do
  make test_spec spec_file=spec/bin/${specs[0]}_spec.sh use_docker=true
done < <(ls -A ./spec/bin | sed 's/_spec//g' | sed 's/\.sh//g')
```

or

```bash
docker build \
  --tag local/shellspec-ubuntu:latest \
  -f shellspec.Dockerfile ./ &&
docker run \
  -ti \
  --kernel-memory=8g \
  --cpus=4 \
  -v $PWD:/localbox \
  --user ubuntu \
  local/shellspec-ubuntu:latest \
  bash -c \
    'make test_spec spec_file=spec/bin/debian_pkgs_spec.sh use_docker=false'
```

## Nice themes

- [nord](https://github.com/arcticicestudio/nord-vim)
- [papercolor](https://github.com/NLKNguyen/papercolor-theme)
- [ayu-vim](https://github.com/ayu-theme/ayu-vim)

## License

[Mozilla Public License 2.0](LICENSE)
[MPL-2.0](https://opensource.org/licenses/MPL-2.0)
