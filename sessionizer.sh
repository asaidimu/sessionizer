#!/usr/bin/env sh
set -eu

# use default value if the are not set elsewhere
SESSIONIZER_TARGET_LIST=${SESSIONIZER_TARGET_LIST:-"${HOME}/.cache/sessionizer.targets"}
SESSIONIZER_LIST_GENERATOR=${SESSIONIZER_LIST_GENERATOR:-""}

# target list generator
_generate_list(){
  # implement your own algorithm in the SESSIONIZER_LIST_GENERATOR file

  if [ -n "$SESSIONIZER_LIST_GENERATOR" ] && [ -e "$SESSIONIZER_LIST_GENERATOR" ]; then
    # if the SESSIONIZER_LIST_GENERATOR file exists, source it
    . "$SESSIONIZER_LIST_GENERATOR"
  else
    echo "$HOME" > "$SESSIONIZER_TARGET_LIST"
  fi
}

# use fzf to list and select a session target
_select_target(){
  [ -e "$SESSIONIZER_TARGET_LIST" ] || _generate_list

  # it is possible to theme fzf
  target=$(\
    fzf --border=rounded --preview 'tree --dirsfirst -C -L 1 {}' --margin=0%\
    --color fg:#cdcecf,bg:#131A24,gutter:#131A24,hl:#f6a878,hl+:#f6a878,bg+:#283648\
    --with-nth=-2.. --delimiter="/"\
    < "$SESSIONIZER_TARGET_LIST"\
  )

  echo "$target"
}

# create a tmux session
_create_session(){
  path="$1"
  session_name="$2"

  # a script that takes the two params above. Use them as you may
  setup="$path/.project"

  # a file with enviroment variables, with the following specs:
  # entries are formatted as ENV_VARIABLE=myValue
  # comments start with a '#' on a new line.
  env="$path/.env"

  cmd="new-session -ds $session_name -c $path"

  # build the tmux options add env variables
  if [ -e "$env" ]; then
    # strip comments and blank lines from the env file
    sed -E '/^(#.*)?$/d; s/^(.*)(=)(.*)$/\1\2"\3"/g;' "$env" | while IFS= read -r var
    do
      cmd="$cmd -e $var"
    done
  fi

  # run tmux with the commands
  eval "tmux $cmd"

  # execute the setup script
  [ -x "$setup" ] && $setup "$session_name" "$path"
}

# go to the selected target session
_goto_session() {
  session_name="$1"

  # if we are in a tmux session, switch to the session, otherwise attach to the
  # session

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$session_name"
  else
    tmux attach-session -t "$session_name"
  fi
}

# start a session or switch to one.
_sessionize(){
  target=$(_select_target)
  session_name=$(basename "$target" | sed -E "s/^(\.)+//; s/\./_/g" )

  # create a session if it does not exist
  if ! tmux has -t "$session_name" 2> /dev/null; then
    _create_session "$target" "$session_name"
  fi

  _goto_session "$session_name"
 }


_help(){
  cat <<EOF
$(bold RATIONALE)
  $(grey "# forget the find window.  That is for chumps")
                 from $(blue "ThePrimeagen's") .tmux.conf

$(bold USAGE)
  sessionizer [options]

$(bold ENV)
  SESSIONIZER_TARGET_LIST     a path to a file containing a list of paths.
  SESSIONIZER_LIST_GENERATOR  a shell script used to generate the list of paths.

$(bold OPTIONS)
  -h  --help     show help.
  -r  --refresh  regenerate list of session targets.

$(bold DEPENDS)
  fzf, tmux, tree, sed

$(bold SUGGESTION)
Add a binding to your tmux.conf.
  example:
  $(grey 'bind-key -r f run-shell "tmux neww ~/.local/bin/sessionizer"')

EOF
}

main(){
  option="${*}"
  case "$option" in
    -h | --help)
      _help
      ;;
    -r | --refresh)
      _generate_list
      ;;
    "" )
      _sessionize
      ;;
    * )
    {
      _help
      exit 1
    }
      ;;
  esac
}

bold(){
  printf "\033[1;37;48m%s\033[0m" "${*}"
}
blue(){
  printf "\033[0;34;48m%s\033[0m" "${*}"
}
grey(){
  printf "\033[0;37;48m%s\033[0m" "${*}"
}

main "$@"
