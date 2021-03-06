# Tmux Sessionizer

[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)
![license](https://img.shields.io/github/license/augustinesaidimu/sessionizer)
![tag](https://img.shields.io/github/v/tag/augustinesaidimu/sessionizer?sort=semver)
![release](https://img.shields.io/github/workflow/status/augustinesaidimu/sessionizer/Release)

## Origins

The idea originally belongs to [ThePrimeagen](https://github.com/ThePrimeagen).
Read the original [here](https://github.com/ThePrimeagen/.dotfiles/blob/5cd09f06d6683b91c26822a73b40e3d7fb9af57a/bin/.local/bin/tmux-sessionizer) and see how it's used [here](https://github.com/ThePrimeagen/.dotfiles/blob/5cd09f06d6683b91c26822a73b40e3d7fb9af57a/tmux/.tmux.conf#L25)

## Algorithm:

**Pseudo Code** in JavaScript:

```javascript
function configureSession ({ name, path }){
    if (existsInPath(path, ".project")) {
        execute(path, ".project");
    }

    if (existsInPath(path, ".env")) {
        getEnv(path).forEach((v) =>
            tmux.setEnvironmentVar({
                variable: v,
                session: name,
            })
        );
    }
};

function sessionize(){
    const list = readOrGenerate();
    const { name, path } = getSelectionFrom(list);

    if (!tmux.hasSession(name)) {
        tmux.createSession(name);
        configureSession({ name, path });
    }

    switchToSession(name);
};
```

Put simply, the script allows the user to select a path from a list.
Using the selected path, it switches to an existing tmux session, or
creates and configures a session before switching to it. The are two ways
provided of populating the target list. Typing into a text file the list
of paths, or extending the tool by providing the implementation of
a generator. Configuring the session involves invoking an executible named
`.project` and setting session-wide environment variables as defined in
a `.env` file within the target directory.

## Usage

#### Installation

```
sh <(curl -fsSL https://tinyurl.com/4t2cbsh8)
```

#### Help

```
sessionizer --help
```

#### Example configuration

~/.zshrc

```zsh
# sessionizer
export SESSIONIZER_TARGET_LIST=~/.config/sessionizer/paths
export SESSIONIZER_LIST_GENERATOR=~/.config/sessionizer/generator
export SESSIONIZE="$HOME/projects:$HOME/work:$HOME/study"
```

~/.tmux.conf

```tmux
bind-key -r f run-shell "tmux neww -n sessionizer ~/.local/bin/sessionizer"
```

~/.config/sessionizer/generator

```sh
: > $SESSIONIZER_TARGET_LIST

for target in $(echo $SESSIONIZE | sed "s/:/ /g"); do
    find $target -mindepth 1 -maxdepth 1 -type d >> $SESSIONIZER_TARGET_LIST
done
```

## Screenshot

![screenshot](https://github.com/augustinesaidimu/sessionizer/blob/main/screenshot.png?raw=true)

## License

[MIT](https://choosealicense.com/licenses/mit/)
