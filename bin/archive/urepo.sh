#!/bin/bash

# zsh
rsync -cavu -delete $HOME/.t4Linux/zsh/plugins/ $HOME/t4Linux/dfiles/zsh/plugins
rsync -cavu -delete $HOME/.t4Linux/zsh/settings/ $HOME/t4Linux/dfiles/zsh/settings
rsync -cavu -delete $HOME/.t4Linux/zsh/.zshrc $HOME/t4Linux/dfiles/zsh/.zshrc
rsync -cavu -delete $HOME/.t4Linux/zsh/zshenv $HOME/t4Linux/dfiles/zsh/zshenv
rsync -cavu -delete $HOME/.t4Linux/aliases/ $HOME/t4Linux/dfiles/aliases
# dk window manager
rsync -cavu -delete $HOME/.config/dk/ $HOME/t4Linux/dfiles/wm/dk
rsync -cavu -delete $HOME/.config/polybar/ $HOME/t4Linux/dfiles/wm/polybar
# dk window manager
rsync -cavu -delete $HOME/.config/herbstluftwm/ $HOME/t4Linux/dfiles/wm/herbstluftwm
# rest of dfiles
rsync -cavu -delete $HOME/.config/dunst/ $HOME/t4Linux/dfiles/wm/dunst
rsync -cavu -delete $HOME/.t4Linux/ranger/ $HOME/t4Linux/dfiles/ranger
rsync -cavu -delete $HOME/.t4Linux/kitty/ $HOME/t4Linux/dfiles/kitty
rsync -cavu -delete $HOME/.t4Linux/nvim/lua/ $HOME/t4Linux/dfiles/nvim/lua
