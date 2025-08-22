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
- install everything
```nushell
make install applications.nuon
```
- select what to install
```nushell
open applications.nuon | where name == neovim | make install --from-stdin
```

> [!important] IMPORTANT
> run the following after install `fd-find` (see https://github.com/sharkdp/fd#on-debian)
> ```shell
> ln -sf $(which fd-find) ~/opt/bin/fd
> ```
