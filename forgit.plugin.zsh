# MIT (c) Wenxuan Zhang

forgit::warn() { printf "%b[Warn]%b %s\n" '\e[0;33m' '\e[0m' "$@" >&2; }
forgit::info() { printf "%b[Info]%b %s\n" '\e[0;32m' '\e[0m' "$@" >&2; }
forgit::inside_work_tree() { git rev-parse --is-inside-work-tree >/dev/null; }

# https://github.com/so-fancy/diff-so-fancy
hash diff-so-fancy &>/dev/null && forgit_fancy='|diff-so-fancy'
# https://github.com/wfxr/emoji-cli
hash emojify &>/dev/null && forgit_emojify='|emojify'

# git commit viewer
forgit::log() {
    forgit::inside_work_tree || return 1
    local cmd opts
    cmd="echo {} |grep -Eo '[a-f0-9]+' |head -1 |xargs -I% git show --color=always % $* $forgit_fancy"
    opts="
        $FORGIT_FZF_DEFAULT_OPTS
        +s +m --tiebreak=index --preview=\"$cmd\"
        --bind=\"enter:execute($cmd |LESS='-R' less)\"
        --bind=\"ctrl-y:execute-silent(echo {} |grep -Eo '[a-f0-9]+' | head -1 | tr -d '\n' |${FORGIT_COPY_CMD:-pbcopy})\"
        $FORGIT_LOG_FZF_OPTS
    "
    eval "git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr' $* $forgit_emojify" |
        FZF_DEFAULT_OPTS="$opts" fzf
}


forgit_diff_fancy_process(){

  echo "i have run:forgit_diff_fancy_process" > /tmp/abcde
}

# git choose to use git dt-kitty or other tools to do diff
# default enter => use fancy difftool to view only the commit changeset
# changeset from selected commit to master:
#            F2 => use kitty difftool
#            F3 => use icdiff difftool
#            F4 => use difffancy difftool
#            F5 => use macvim difftool
# the mode switch use the highlighted Capital letter as switch

forgit::diffbox() {
    forgit::inside_work_tree || return 1
    local dtfancydiffcmdsingle opts dtkittycmd dtmacvimcmd dticdiffcmd modefile shalistfile
    shalistfile=/tmp/shalist
    dtfancydiffcmdsingle="echo {} |grep -Eo '[a-f0-9]+' |head -1 |xargs -I% git show --color=always % $* $forgit_fancy"

    rm -f $gitdiffdebuglogfile
    dtkittycmd="echo {} |grep -Eo '[a-f0-9]+' |head -1 |xargs -I% git dt-kitty %"
    dtmacvimcmd="echo {} |grep -Eo '[a-f0-9]+' |head -1 |xargs -I% git dt %"
    dticdiffcmd="echo {} |grep -Eo '[a-f0-9]+' |head -1 |xargs -I% git icdiff %"
    dtfancydiffcmd="echo {} |grep -Eo '[a-f0-9]+' |head -1 |xargs -I% git diff --color=always % $* $forgit_fancy"

    workchangesmodecmd="echo 'working_changes' > $gitdiffmodefile && echo 'working_changes mode' && sleep 1"
    stagedchangesmodecmd="echo 'staged_changes' > $gitdiffmodefile && echo 'staged_changes mode' && sleep 1"
    showcommitmodecmd="echo 'show_commit' > $gitdiffmodefile && echo 'show_commit mode' && sleep 1"
    rangechangesmodecmd="echo 'range_changes' > $gitdiffmodefile && echo 'range_changes mode' && sleep 1"

    setuptoolkittycmd="echo 'kitty' > $gitdifftoolfile && echo 'set tool: kitty' && sleep 1"
    setuptoolicdiffcmd="echo 'icdiff' > $gitdifftoolfile && echo 'set tool: icdiff' && sleep 1"
    setuptoolfancydiffcmd="echo 'fancydiff' > $gitdifftoolfile && echo 'set tool: fancydiff' && sleep 1"
    setuptoolmacvimcmd="echo 'macvim' > $gitdifftoolfile && echo 'set tool: macvim' && sleep 1"

    execcmd="echo {} |grep -Eo '[a-f0-9]+' > $gitdifftoolshalistfile && $CM_SVC_DIR/forgit_diffbox.zsh && sleep 1"
    debugcmd="cat $gitdiffdebuglogfile|less -R"
    helpcmd="cat $gitdiffhelpfile|less -R"
    echo " $debugcmd" > /tmp/aaa
    echo """
          mode:
             ctrl-w: current work diff
             ctrl-s: staged diff
             1:      show single commit changes only
             0:      show ranged diff of two or current work to the selected single commit
          tool:
             F2 => use kitty difftool
             F3 => use icdiff difftool
             F4 => use fancy difftool'
             F5 => use macvim difftool
          ctrl-x:
             deselect all
          ctrl-h:
             help doc
          ctrl-d:
             show debug info
          ctrl-y:
             copy the commit SHA
          ?:
             toggle preview
          enter:
             to execute
    """ > $gitdiffhelpfile

    opts="
        $FORGIT_FZF_DEFAULT_OPTS
        +s -m --tiebreak=index --preview=\"$dtfancydiffcmdsingle\"
        --header='c-d: debug c-h: help'

        --bind=\"enter:execute($dtfancydiffcmdsingle|LESS='-R' less)\"

        --bind=\"F2:execute($setuptoolkittycmd)\"
        --bind=\"F3:execute($setuptoolicdiffcmd)\"
        --bind=\"F4:execute($setuptoolfancydiffcmd)\"
        --bind=\"F5:execute($setuptoolmacvimcmd)\"

        --bind=\"ctrl-w:execute($workchangesmodecmd)\"
        --bind=\"ctrl-s:execute($stagedchangesmodecmd)\"
        --bind=\"1:execute($showcommitmodecmd)\"
        --bind=\"0:execute($rangechangesmodecmd)\"

        --bind=\"enter:execute-multi($execcmd)\"
        --bind=\"ctrl-d:execute($debugcmd)\"
        --bind=\"ctrl-h:execute($helpcmd)\"
        --bind=\"ctrl-x:deselect-all\"

        --bind=\"ctrl-y:execute-silent(echo {} |grep -Eo '[a-f0-9]+' | head -1 | tr -d '\n' |${FORGIT_COPY_CMD:-pbcopy})\"

        --bind='?:toggle-preview'
        --no-cycle
        $FORGIT_LOG_FZF_OPTS
    "

    # eval "git log --graph --color=always --format='%C(auto)%h%d %C(cyan)%ad %C(green)%s %C(blue)%C(bold)%cr' $* $forgit_emojify --date short" |
    eval "git log --graph --color=always --format='%C(auto)%h%d %C(cyan)%ad %C(green)%s %C(blue)%C(bold)%cr %C(red)%an' $* $forgit_emojify --date short" |
    FZF_DEFAULT_OPTS="$opts" fzf
}


forgit::differ() {
    forgit::inside_work_tree || return 1
    local dtfancydiffcmdsingle opts dtkittycmd dtmacvimcmd dticdiffcmd modefile
    modefile=/tmp/forgit_diff_mode
    dtfancydiffcmdsingle="echo {} |grep -Eo '[a-f0-9]+' |head -1 |xargs -I% git show --color=always % $* $forgit_fancy"

    dtkittycmd="echo {} |grep -Eo '[a-f0-9]+' |head -1 |xargs -I% git dt-kitty %"
    dtmacvimcmd="echo {} |grep -Eo '[a-f0-9]+' |head -1 |xargs -I% git dt %"
    dticdiffcmd="echo {} |grep -Eo '[a-f0-9]+' |head -1 |xargs -I% git icdiff %"
    dtfancydiffcmd="echo {} |grep -Eo '[a-f0-9]+' |head -1 |xargs -I% git diff --color=always % $* $forgit_fancy"

    # debugcmd="echo {} |grep -Eo '[a-f0-9]+' |head -1 |xargs -I% git dt-kitty %"
    # debugcmd="echo {} > /tmp/abcde"
    # debugcmd="echo {} |grep -Eo '[a-f0-9]+' |head -1 > /tmp/abcde"
    # debugcmd="echo hahaha; read input;"
    opts="
        $FORGIT_FZF_DEFAULT_OPTS
        +s -m --tiebreak=index --preview=\"$dtfancydiffcmdsingle\"
        --header='usage:
          enter => use fancy difftool : single commit changes
          changes from selected commit to HEAD version:
             F2 => use kitty difftool
             F3 => use macvim difftool
             F4 => use icdiff difftool
             F5 => use fancy difftool'

        --bind=\"enter:execute($dtfancydiffcmdsingle|LESS='-R' less)\"
        --bind=\"F2:execute($dtkittycmd)\"
        --bind=\"F3:execute($dtmacvimcmd)\"
        --bind=\"F4:execute($dticdiffcmd)\"
        --bind=\"F5:execute($dtfancydiffcmd|less -R)\"

        --bind=\"ctrl-y:execute-silent(echo {} |grep -Eo '[a-f0-9]+' | head -1 | tr -d '\n' |${FORGIT_COPY_CMD:-pbcopy})\"
        --bind=\"ctrl-s:execute-silent(echo 'Single_commit_change_set_view-in-single-selection' > $modefile)\"
        --bind=\"ctrl-w:execute-silent(echo 'changes_betWeen_current_and_selected-in-single-selection' > $modefile)\"
        --bind=\"ctrl-r:execute-silent(echo 'changes_between_Range-in-multi-selection' > $modefile)\"

        --bind='?:toggle-preview'
        --no-cycle
        $FORGIT_LOG_FZF_OPTS
    "

    eval "git log --graph --color=always --format='%C(auto)%h%d %C(cyan)%ad %C(green)%s %C(blue)%C(bold)%cr' $* $forgit_emojify --date short" |
    FZF_DEFAULT_OPTS="$opts" fzf
}



# git diff viewer
forgit::diff() {
    forgit::inside_work_tree || return 1
    local cmd files opts commit
    [[ $# -ne 0 ]] && {
        if git rev-parse "$1" -- &>/dev/null ; then
            commit="$1" && files=("${@:2}")
        else
            files=("$@")
        fi
    }

    cmd="git diff --color=always $commit -- {} $forgit_fancy"
    opts="
        $FORGIT_FZF_DEFAULT_OPTS
        +m -0 --preview=\"$cmd\" --bind=\"enter:execute($cmd |LESS='-R' less)\"
        $FORGIT_DIFF_FZF_OPTS
    "
    eval "git diff --name-only --relative $commit -- ${files[*]}"|
        FZF_DEFAULT_OPTS="$opts" fzf
}


forgit::icdiff() {
    forgit::inside_work_tree || return 1
    local cmd files opts commit
    [[ $# -ne 0 ]] && {
        if git rev-parse "$1" -- &>/dev/null ; then
            commit="$1" && files=("${@:2}")
        else
            files=("$@")
        fi
    }

    cmd="git icdiff --color=always $commit -- {}"
    opts="
        $FORGIT_FZF_DEFAULT_OPTS
        +m -0 --preview=\"$cmd\" --preview-window=hidden --bind=\"enter:execute($cmd |LESS='-R' less)\"
        $FORGIT_DIFF_FZF_OPTS
    "

    eval "git diff --name-only --relative $commit -- ${files[*]}"|
        FZF_DEFAULT_OPTS="$opts" fzf
}

forgit::kittydiff() {
    forgit::inside_work_tree || return 1
    local cmd files opts commit
    [[ $# -ne 0 ]] && {
        if git rev-parse "$1" -- &>/dev/null ; then
            commit="$1" && files=("${@:2}")
        else
            files=("$@")
        fi
    }

    cmd="git dt-kitty --color=always $commit -- {}"

    opts="
        $FORGIT_FZF_DEFAULT_OPTS
        +m -0 --preview=\"$cmd\" --preview-window=hidden --bind=\"enter:execute($cmd |LESS='-R' less)\"
        $FORGIT_DIFF_FZF_OPTS
    "

    eval "git diff --name-only --relative $commit -- ${files[*]}"|
        FZF_DEFAULT_OPTS="$opts" fzf
}



# git add selector
forgit::add() {
    forgit::inside_work_tree || return 1
    local changed unmerged untracked files opts
    changed=$(git config --get-color color.status.changed red)
    unmerged=$(git config --get-color color.status.unmerged red)
    untracked=$(git config --get-color color.status.untracked red)

    opts="
        $FORGIT_FZF_DEFAULT_OPTS
        -0 -m --nth 2..,..
        --preview=\"git diff --color=always -- {-1} $forgit_fancy\"
        $FORGIT_ADD_FZF_OPTS
    "
    files=$(git -c color.status=always -c status.relativePaths=true status --short |
        grep -F -e "$changed" -e "$unmerged" -e "$untracked" |
        awk '{printf "[%10s]  ", $1; $1=""; print $0}' |
        FZF_DEFAULT_OPTS="$opts" fzf | cut -d] -f2 |
        sed 's/.* -> //') # for rename case
    [[ -n "$files" ]] && echo "$files" |xargs -I{} git add {} && git status --short && return
    echo 'Nothing to add.'
}

# git reset HEAD (unstage) selector
forgit::reset::head() {
    forgit::inside_work_tree || return 1
    local cmd files opts
    cmd="git diff --cached --color=always -- {} $forgit_fancy"
    opts="
        $FORGIT_FZF_DEFAULT_OPTS
        -m -0 --preview=\"$cmd\"
        $FORGIT_RESET_HEAD_FZF_OPTS
    "
    files="$(git diff --cached --name-only --relative | FZF_DEFAULT_OPTS="$opts" fzf)"
    [[ -n "$files" ]] && echo "$files" |xargs -I{} git reset -q HEAD {} && git status --short && return
    echo 'Nothing to unstage.'
}

# git checkout-restore selector
forgit::restore() {
    forgit::inside_work_tree || return 1
    local cmd files opts
    cmd="git diff --color=always -- {} $forgit_fancy"
    opts="
        $FORGIT_FZF_DEFAULT_OPTS
        -m -0 --preview=\"$cmd\"
        $FORGIT_CHECKOUT_FZF_OPTS
    "
    files="$(git ls-files --modified "$(git rev-parse --show-toplevel)"| FZF_DEFAULT_OPTS="$opts" fzf)"
    [[ -n "$files" ]] && echo "$files" |xargs -I{} git checkout {} && git status --short && return
    echo 'Nothing to restore.'
}

# git stash viewer
forgit::stash::show() {
    forgit::inside_work_tree || return 1
    local cmd opts
    cmd="git stash show \$(echo {}| cut -d: -f1) --color=always --ext-diff $forgit_fancy"
    opts="
        $FORGIT_FZF_DEFAULT_OPTS
        +s +m -0 --tiebreak=index --preview=\"$cmd\" --bind=\"enter:execute($cmd |LESS='-R' less)\"
        $FORGIT_STASH_FZF_OPTS
    "
    git stash list | FZF_DEFAULT_OPTS="$opts" fzf
}

# git clean selector
forgit::clean() {
    forgit::inside_work_tree || return 1
    local files opts
    opts="
        $FORGIT_FZF_DEFAULT_OPTS
        -m -0
        $FORGIT_CLEAN_FZF_OPTS
    "
    # Note: Postfix '/' in directory path should be removed. Otherwise the directory itself will not be removed.
    files=$(git clean -xdfn "$@"| awk '{print $3}'| FZF_DEFAULT_OPTS="$opts" fzf |sed 's#/$##')
    [[ -n "$files" ]] && echo "$files" |xargs -I% git clean -xdf % && return
    echo 'Nothing to clean.'
}

# git ignore generator
export FORGIT_GI_REPO_REMOTE=${FORGIT_GI_REPO_REMOTE:-https://github.com/dvcs/gitignore}
export FORGIT_GI_REPO_LOCAL=${FORGIT_GI_REPO_LOCAL:-~/.forgit/gi/repos/dvcs/gitignore}
export FORGIT_GI_TEMPLATES=${FORGIT_GI_TEMPLATES:-$FORGIT_GI_REPO_LOCAL/templates}

forgit::ignore() {
    [ -d "$FORGIT_GI_REPO_LOCAL" ] || forgit::ignore::update
    local IFS cmd args cat opts
    # https://github.com/sharkdp/bat.git
    hash bat &>/dev/null && cat='bat -l gitignore --color=always' || cat="cat"
    cmd="$cat $FORGIT_GI_TEMPLATES/{2}{,.gitignore} 2>/dev/null"
    opts="
        $FORGIT_FZF_DEFAULT_OPTS
        -m --preview=\"$cmd\" --preview-window='right:70%'
        $FORGIT_IGNORE_FZF_OPTS
    "
    # shellcheck disable=SC2206,2207
    IFS=$'\n' args=($@) && [[ $# -eq 0 ]] && args=($(forgit::ignore::list | nl -nrn -w4 -s'  ' |
        FZF_DEFAULT_OPTS="$opts" fzf  |awk '{print $2}'))
    [ ${#args[@]} -eq 0 ] && return 1
    # shellcheck disable=SC2068
    if hash bat &>/dev/null; then
        forgit::ignore::get ${args[@]} | bat -l gitignore
    else
        forgit::ignore::get ${args[@]}
    fi
}
forgit::ignore::update() {
    if [[ -d "$FORGIT_GI_REPO_LOCAL" ]]; then
        forgit::info 'Updating gitignore repo...'
        (cd "$FORGIT_GI_REPO_LOCAL" && git pull --no-rebase --ff) || return 1
    else
        forgit::info 'Initializing gitignore repo...'
        git clone --depth=1 "$FORGIT_GI_REPO_REMOTE" "$FORGIT_GI_REPO_LOCAL"
    fi
}
forgit::ignore::get() {
    local item filename header
    for item in "$@"; do
        if filename=$(find -L "$FORGIT_GI_TEMPLATES" -type f \( -iname "${item}.gitignore" -o -iname "${item}" \) -print -quit); then
            [[ -z "$filename" ]] && forgit::warn "No gitignore template found for '$item'." && continue
            header="${filename##*/}" && header="${header%.gitignore}"
            echo "### $header" && cat "$filename" && echo
        fi
    done
}
forgit::ignore::list() {
    find "$FORGIT_GI_TEMPLATES" -print |sed -e 's#.gitignore$##' -e 's#.*/##' | sort -fu
}
forgit::ignore::clean() {
    setopt localoptions rmstarsilent
    [[ -d "$FORGIT_GI_REPO_LOCAL" ]] && rm -rf "$FORGIT_GI_REPO_LOCAL"
}


FORGIT_FZF_DEFAULT_OPTS="
$FZF_DEFAULT_OPTS
--ansi
--bind='ctrl-p:preview-up,ctrl-n:preview-down'
--bind='ctrl-r:toggle-all'
--bind='ctrl-s:toggle-sort'
--bind='?:toggle-preview'
--bind='ctrl-w:toggle-preview-wrap'
--height='99%'
--preview-window='right:60%'
"
# --height='80%'

# register aliases
# shellcheck disable=SC2139
if [[ -z "$FORGIT_NO_ALIASES" ]]; then
    alias "${forgit_add:-ga}"='forgit::add'
    alias "${forgit_reset_head:-grh}"='forgit::reset::head'
    alias "${forgit_log:-glo}"='forgit::log'
    alias "${forgit_diff:-gd}"='forgit::diff'
    alias "${forgit_ignore:-gi}"='forgit::ignore'
    alias "${forgit_restore:-gcf}"='forgit::restore'
    alias "${forgit_clean:-gclean}"='forgit::clean'
    alias "${forgit_stash_show:-gss}"='forgit::stash::show'
fi
