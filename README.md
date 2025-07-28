# dotfiles

The files in this project reflect the filesystem, e.g. `./.config/nvim/init.lua` is the same as `~/.config/nvim/init.lua`.

> [!NOTE]
> Some exceptions:
> - `_scripts/*` and "_repo_" files, e.g. `./.git/*`, are not synced
> - `@` is a placeholder for the root of the filesystem, e.g. `./@root/foo.txt` is the same as `/root/foo.txt`

> [!TIP]
> The following uses [Nushell](https://nushell.sh) quite intesively because it is very convenient over Bash.
>
> In order to be able to run the snippets below, one has to perform the following actions:
> - install Nushell, e.g. by running `./bootstrap.sh`
> - activate the `make.nu` module from inside Nushell

## Bookkeeping
```nushell
make link --config --system
```

## My software
```nushell
yes | sudo apt install ...[
    tmux,
    tldr,
    ripgrep,
    fd-find,
    sd,
    lm-sensors,
    ttyplot,
]
```
```nushell
make gh download-asset-from-release jesseduffield/horcrux v0.2 --no-gh --asset horcrux_0.2_Linux_armv6 --extract "/tmp/horcrux-0.2-armv6"
cp --verbose ("/tmp/horcrux-0.2-armv6/horcrux" | path expand) ("~/opt/bin/horcrux" | path expand)
```
```nushell
make gh download-asset-from-release cli/cli v2.74.2 --no-gh --asset gh_2.74.2_linux_armv6
mkdir ("~/.local/share/man/man1" | path expand)
cp --verbose ("/tmp/gh_2.74.2_linux_armv6/bin/gh" | path expand) ("~/opt/bin/gh" | path expand)
cp --verbose ("/tmp/gh_2.74.2_linux_armv6/share/man/man1/*" | into glob) ("~/.local/share/man/man1" | path expand)
```

```nushell
use git *
cd (git clone https://github.com/antoineeestevaaan/find-git-repos)
yes | sudo apt install libssl-dev
cc -o nob nob.c -lssl -lcrypto
git checkout bbb78cc
./nob
cp  build/find-git-repos-f74da46dd63b5118ab8cf499124a92902bfecc1b18609f9d6e32e395d8a44e10 ~/opt/bin/
```

```nushell
use git *
use misc "make"

const OPT_DIR = $nu.home-path | path join opt

cd (git clone https://github.com/neovim/neovim)
git checkout nightly

yes | sudo apt install cmake

let nvim_install_dir = $OPT_DIR | path join $"nvim-(git rev-parse HEAD)"

make -V { CMAKE_BUILD_TYPE: Release }
make -V { CMAKE_INSTALL_PREFIX: $nvim_install_dir} install

ln --force --symbolic ($nvim_install_dir | path join bin nvim) ($OPT_DIR | path join bin nvim)
```
