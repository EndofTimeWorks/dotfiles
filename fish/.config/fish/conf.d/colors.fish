# Fish syntax highlighting — Mariana×Purple palette
# Explicit hex values so terminal ANSI remapping doesn't break them

set -g fish_color_command          89DDFF    # cyan — commands
set -g fish_color_builtin          C3A6FF    # purple — builtins
set -g fish_color_keyword          C3A6FF    # purple — keywords (if, for, etc.)
set -g fish_color_param            D4D4D4    # text — args
set -g fish_color_option           A6ACCD    # subtext — flags (--foo)
set -g fish_color_quote            BAE67E    # green — strings
set -g fish_color_redirection      FFD580    # yellow — > >> | etc.
set -g fish_color_end              FFD580    # yellow — ; &
set -g fish_color_error            F28779    # pink — errors / bad commands
set -g fish_color_comment          626880    # muted — # comments
set -g fish_color_operator         C3A6FF    # purple — operators
set -g fish_color_escape           FFD580    # yellow — \n \t etc.
set -g fish_color_autosuggestion   4A4F6A    # dim — ghost text
set -g fish_color_selection        --background=3A3F5C  # visual selection bg
set -g fish_color_search_match     --background=3A3F5C
set -g fish_color_valid_path       --underline
set -g fish_color_cancel           F28779

# Pager (tab completion menu)
set -g fish_pager_color_prefix        C3A6FF --bold --underline
set -g fish_pager_color_completion    D4D4D4
set -g fish_pager_color_description  A6ACCD
set -g fish_pager_color_progress     A6ACCD --background=1E2030
set -g fish_pager_color_selected_background --background=3A3F5C
