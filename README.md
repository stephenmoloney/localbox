# Localbox

Localbox is a collection of scripts and dotfiles intended to

- Install various formatters, linters, devops tools and apps
- Configure various applications and tools via dotfiles
- Setup repetitive tasks via jobber (a cronjob alternative)

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
make provision fallback_versions=true
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
docker run \
  -ti \
  -v $PWD:/localbox \
  --user ubuntu \
  local/shellspec-ubuntu:latest \
  bash -c 'sudo apt install -y make && make provision'
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
docker run \
  -ti \
  -v $PWD:/localbox \
  --user ubuntu \
  local/shellspec-ubuntu:latest \
  bash -c \
    'make test_spec spec_file=spec/bin/debian_pkgs_spec.sh use_docker=false'
```

## Vim keys

**_Common Actions_**

| Key Pattern                        | Action                              | Notes                                                                         |
| ---------------------------------- | ----------------------------------- | ----------------------------------------------------------------------------- |
| <kbd>\\</kbd>                      | `Leader key`                        | Special vim precursor command key                                             |
| <kbd>↑</kbd> or <kbd>k</kbd>       | `Up arrow`                          | Move up                                                                       |
| <kbd>↓</kbd> or <kbd>j</kbd>       | `Down arrow`                        | Move down                                                                     |
| <kbd>←</kbd> or <kbd>h</kbd>       | `Left arrow`                        | Move left                                                                     |
| <kbd>→</kbd> or <kbd>l</kbd>       | `Right arrow`                       | Move right                                                                    |
| <kbd>:q⏎</kbd>                     | `Close window without saving`       | Will usually block you if there unsaved work                                  |
| <kbd>:qa⏎</kbd>                    | `Force close window without saving` | Quits without saving                                                          |
| <kbd>go</kbd>                      | `Open tab from nerdtree`            | Opens a vim tab in current window pane                                        |
| <kbd>gs</kbd>                      | `Open tab from nerdtree`            | Opens a new vertically split vim pane                                         |
| <kbd>control</kbd> + <kbd>ww</kbd> | `Toggle between vim panes`          | Handy when moving from nerdtree to the text editorpane                        |
| <kbd>za</kbd>                      | `Toggle open/close current fold`    | Toggles open/close the current fold in selection                              |
| <kbd>zc</kbd>                      | `Toggle close a fold`               | Closes the current fold in selection if open or parent fold if already closed |
| <kbd>zk</kbd>                      | `Moves cursor to next fold up`      | Moves cursor to next fold up                                                  |
| <kbd>zj</kbd>                      | `Moves cursor to next fold down`    | Moves cursor to next fold down                                                |
| <kbd>zR</kbd>                      | `Open all folds`                    | Opens all folds                                                               |
| <kbd>zM</kbd>                      | `Close all folds`                   | Closes all folds                                                              |
| <kbd>Shift</kbd><kbd>Tab</kbd>     | `Trigger open autocompelte menu`    | Triggers the opening of the autocompettion menu. Hand in yaml for example.    |

**_Plugin Actions_**

| Key Pattern                       | Action                  | Notes                                                                          |
| --------------------------------- | ----------------------- | ------------------------------------------------------------------------------ |
| <kbd>\ww</kbd>                    | `MarkdownPreviewToggle` | Toggles the markdown to be viewer in a newly opened browser window             |
| <kbd>\ee</kbd>                    | `NERDTreeToggle`        | Toggles open and close the nerdtree vim pane                                   |
| <kbd>\tt</kbd>                    | `NERDTreeRefreshRoot`   | Reload the nerdtree vim pane                                                   |
| <kbd>\uu</kbd>                    | `UndotreeToggle`        | Toggles the undotree menu to popup                                             |
| <kbd>\rr</kbd>                    | `TabBarToggle`          | Toggles the tagbar menu to popup                                               |
| <kbd>\nn</kbd>                    | `NnnPicker`             | Opens the Nnn file picker                                                      |
| <kbd>\aa</kbd>                    | `AnyFoldActivate`       | Toggles the anyfold activation. Action will depend on `set foldlevel` settings |
| <kbd>\\tm</kbd>                   | `ToggleTableMode`       | Enters into table mode making it easy for table formatting                     |
| <kbd>Control</kbd> + <kbd>k</kbd> | `Move selection up`     | Moves the selected text in visual mode up                                      |
| <kbd>Control</kbd> + <kbd>j</kbd> | `Move selection down`   | Moves the selected text in visual mode down                                    |
| <kbd>\\ff</kbd>                   | `Open esearch`          | Opens esearch at the selected folder in nerdtree                               |
| <kbd>\\cc</kbd>                   | `Comment code`          | Comments highlighted block of code in visual mode                              |
| <kbd>\\cu</kbd>                   | `Uncomments code`       | Uncomments highlighted block of code in visual mode                            |

## Nice themes

- [nord](https://github.com/arcticicestudio/nord-vim)
- [papercolor](https://github.com/NLKNguyen/papercolor-theme)
- [ayu-vim](https://github.com/ayu-theme/ayu-vim)

## License

[Mozilla Public License 2.0](LICENSE)
[MPL-2.0](https://opensource.org/licenses/MPL-2.0)
