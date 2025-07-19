# dotfiles

The files in this project reflect the filesystem, e.g. `./.config/nvim/init.lua` is the same as `~/.config/nvim/init.lua`.

The valid configuration files can be synced to the filesystem by running
```shell
./_scripts/sync.sh
```

> [!note] Notable Exceptions
>
> - `_scripts/*` and "_repo_" files, e.g. `./.git/*`, are not synced
> - `@` is a placeholder for the root of the filesystem, e.g. `./@root/foo.txt` is the same as `/root/foo.txt`
