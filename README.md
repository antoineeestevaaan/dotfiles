# dotfiles

The files in this project reflect the filesystem, e.g. `./.config/nvim/init.lua` is the same as `~/.config/nvim/init.lua`.

The valid configuration files can be synced to the filesystem by running
```shell
./_scripts/sync.sh
```

> [!NOTE]
> Some exceptions:
> - `_scripts/*` and "_repo_" files, e.g. `./.git/*`, are not synced
> - `@` is a placeholder for the root of the filesystem, e.g. `./@root/foo.txt` is the same as `/root/foo.txt`

## My software
```bash
make gh download-asset-from-release jesseduffield/horcrux v0.2 --no-gh --asset horcrux_0.2_Linux_armv6 --extract "/tmp/horcrux-0.2-armv6"
cp --verbose ("/tmp/horcrux-0.2-armv6/horcrux" | path expand) ("~/opt/bin/horcrux" | path expand)
```
```bash
make gh download-asset-from-release cli/cli v2.74.2 --no-gh --asset gh_2.74.2_linux_armv6
mkdir ("~/.local/share/man/man1" | path expand)
cp --verbose ("/tmp/gh_2.74.2_linux_armv6/bin/gh" | path expand) ("~/opt/bin/gh" | path expand)
cp --verbose ("/tmp/gh_2.74.2_linux_armv6/share/man/man1/*" | into glob) ("~/.local/share/man/man1" | path expand)
```
