{ config, pkgs, lib, ... }:

{
  # Tmux configuration - force rebuild 2025-09-19
  programs.tmux = {
    enable = true;
    shell = "${pkgs.bash}/bin/bash";
    terminal = "tmux-256color";
    prefix = "`";
    baseIndex = 1;
    historyLimit = 10000;
    keyMode = "vi";
    mouse = true;
    aggressiveResize = false;  # Disabled to prevent window distortion between VS Code and Konsole

    plugins = with pkgs.tmuxPlugins; [
      # Removed sensible plugin as it overrides aggressive-resize setting
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
      pain-control
      prefix-highlight
      tmux-fzf
    ];

    extraConfig = ''
      # General settings
      set -g default-command "${pkgs.bash}/bin/bash"
      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -ga terminal-overrides ",screen-256color:Tc"
      set -ga terminal-overrides ",tmux-256color:Tc"
      set -sg escape-time 0
      set -g focus-events off
      set -g detach-on-destroy off
      set -g repeat-time 1000

      # Handle VS Code terminal properly
      # Note: aggressive-resize is already disabled globally above

      # Allow passthrough for proper color handling
      set -g allow-passthrough on
      set -ag terminal-overrides ',*:Ms@'

      # Basic terminal features
      set -as terminal-features ',*:RGB'

      # Pane settings
      set -g pane-base-index 1
      set -g renumber-windows on
      set -g pane-border-lines double  # Use double lines for visual separation
      set -g pane-border-status bottom

      # Pane borders with padding effect
      set -g pane-border-style "fg=colour238 bg=colour235"  # Subtle border with background
      set -g pane-active-border-style "fg=colour39 bg=colour235 bold"  # Active pane highlight
      set -g pane-border-format "  #P: #{pane_current_command}  "  # Add spaces for padding

      # Add visual spacing between panes
      set -g pane-border-indicators both  # Show arrows pointing to active pane
      set -g display-panes-colour "colour226"  # Bright color for pane numbers
      set -g display-panes-active-colour "colour39"  # Active pane number color

      # Status bar styling - simple and functional
      set -g status-position top
      set -g status-justify left
      set -g status-style "bg=colour235 fg=colour248"
      set -g status-left-length 40
      set -g status-right-length 60

      # Simple status left showing session name and mode
      set -g status-left "#{?client_prefix,#[fg=colour235 bg=colour203 bold] PREFIX ,#[fg=colour235 bg=colour40 bold] TMUX }#[fg=colour248 bg=colour237] #S #[default] "

      # Status right showing basic info
      set -g status-right "#[fg=colour248 bg=colour237] #H | %H:%M #[default]"

      # Window status - clean and simple
      set -g window-status-format "#[fg=colour248] #I:#W "
      set -g window-status-current-format "#[fg=colour235 bg=colour39 bold] #I:#W #[default]"
      set -g window-status-separator ""

      # Message styling
      set -g message-style "fg=colour235 bg=colour226 bold"

      # Key bindings
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Window and pane management
      bind c new-window -c "#{pane_current_path}"
      bind v split-window -v -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind h split-window -h -c "#{pane_current_path}"
      bind | split-window -h -c "#{pane_current_path}"
      bind f resize-pane -Z
      bind x kill-pane
      bind X kill-window

      # Pane navigation (without prefix)
      bind -n C-h select-pane -L
      bind -n C-j select-pane -D
      bind -n C-k select-pane -U
      bind -n C-l select-pane -R

      # Pane resizing
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Quick window switching
      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5

      # Copy mode
      bind Enter copy-mode
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind -T copy-mode-vi Escape send-keys -X cancel
      bind -T copy-mode-vi H send-keys -X start-of-line
      bind -T copy-mode-vi L send-keys -X end-of-line

      # Paste
      bind ] paste-buffer
      bind p paste-buffer
      bind P choose-buffer

      # Toggles
      bind S setw synchronize-panes \; display-message "Synchronize panes: #{?pane_synchronized,ON,OFF}"
      bind m set -g mouse \; display-message "Mouse: #{?mouse,ON,OFF}"

      # Mouse behavior
      unbind -n MouseDown3Pane
      unbind -T copy-mode-vi MouseDown3Pane
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection

      # Sesh session management
      bind -n C-t run-shell "bash -ic 'sesh_connect'"
      bind -N "last-session (via sesh)" l run-shell "sesh last"
      bind-key "T" run-shell "sesh connect \"\$(sesh list --icons | fzf-tmux -p 80%,70% --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' --bind 'tab:down,btab:up' --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' --preview-window 'right:55%' --preview 'sesh preview {}')\""
    '';
  };
}