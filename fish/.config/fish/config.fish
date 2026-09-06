if status is-interactive
    if type -q starship
        starship init fish | source
    end

    if type -q fnm
        fnm env --use-on-cd | source
    end

    if type -q rbenv
        rbenv init - fish | source
    end

    if test -x ~/.local/bin/mise
        ~/.local/bin/mise activate fish | source
    end
end

fish_add_path /home/end/.spicetify

# pnpm
set -gx PNPM_HOME "/home/end/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

alias packettracer="QT_QPA_PLATFORM=xcb /usr/lib/packettracer/packettracer.AppImage"
