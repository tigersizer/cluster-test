    function set-title() {
      if [[ -z "$ORIG" ]]; then
        ORIG=$PS1
      fi
      TITLE="\[\e]2;$@\a\]"
      PS1=${ORIG}${TITLE}
    }
    function title { echo -en "\033]2;$1\007"; }

# start the Prometheus OS monitor
.~/bin/pnodeup
