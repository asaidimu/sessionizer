#!/usr/bin/env bash

FRAMEWORK_NAME="sessionizer"
FRAMEWORK_BRANCH="main"
FRAMEWORK_URL="https://github.com/augustinesaidimu/sessionizer"

FRAMEWORK_PATH="$HOME/.local/share/$FRAMEWORK_NAME"
FRAMEWORK_BINARY="$HOME/.local/bin/$FRAMEWORK_NAME"

_clean(){
    if [ -e "$FRAMEWORK_PATH" ]; then
        rm -rf "$FRAMEWORK_PATH"
    fi
    if [ -e "$FRAMEWORK_BINARY" ]; then
        rm -rf "$FRAMEWORK_BINARY"
    fi
}

_clone_repo() {
    sleep 0.2
    mkdir -p "$FRAMEWORK_PATH"

    git clone "$FRAMEWORK_URL" --branch="$FRAMEWORK_BRANCH" "$FRAMEWORK_PATH" --depth=1 &> /dev/null

    return $?
}

_install_script() {
    sleep 0.2
    chmod +x "$FRAMEWORK_PATH/$FRAMEWORK_NAME.sh"
    ln -sf "$FRAMEWORK_PATH/$FRAMEWORK_NAME.sh" "$FRAMEWORK_BINARY" > /dev/null  2>&1
}

_main(){
    # -- clean up --
    _clean &
    pid=$!
    _load "Initializing" $pid
    wait $pid
    [ $? -ne 0 ] && _abort

    # -- clone repo --
    _clone_repo &
    pid=$!
    _load "Fetching repo" $pid
    wait $pid
    [ $? -ne 0 ] && _abort

    # -- add command to path --
    _install_script &
    pid=$!
    _load "Installing script" $pid
    wait $pid
    [ $? -ne 0 ] && _abort

    FRAMEWORK_VERSION=$(git describe --tags)
    printf "$(green "[") Installed "$FRAMEWORK_NAME" $(bold "$FRAMEWORK_VERSION") $(green "]")\n"
}

# ---------------------------------------------------------------------------- #
_abort(){
    printf "$(red "[") Install failed ! $(red "]")\n"
    exit 27
}

bold(){
  echo "\033[1;37;48m%s\033[0m" "${*}";
}

red(){
  echo "\033[1;31;48m%s\033[0m" "${*}";
}

yellow(){
  printf "\033[1;33;48m%s\033[0m" "${*}";
}

green(){
  printf "\033[1;32;48m%s\033[0m" "${*}";
}

_clear_line(){
    printf "\033[1000D" # go to begining of line
    printf "\033[0K" # clear line
}

_move_left(){
    index="$1"
    printf "\033[${index}D"
}

_move_right(){
    index="$1"
    printf "\033[${index}C"
}

_load() {
    text="$1"
    pid="$2"

    waiting=1
    while [ $waiting -eq 1 ]; do
        green "[ "
        printf "${text}    "
        green " ]"
        sleep 0.3
        _clear_line

        green "[ "
        printf "${text} .  "
        green " ]"
        sleep 0.3
        _clear_line

        green "[ "
        printf "${text} .. "
        green " ]"
        sleep 0.3
        _clear_line

        green "[ "
        printf "${text} ..."
        green " ]"

        ps cax | grep -E "\s?$pid" > /dev/null  2>&1
        if [ $? -ne 0 ]; then
            waiting=0
        fi
        sleep 0.3
        _clear_line
    done
}

# ---------------------------------------------------------------------------- #

_main $@
