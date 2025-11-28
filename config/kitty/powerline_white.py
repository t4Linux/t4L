# powerline_white.py

from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title
from kitty.utils import color_as_int

# Stały biały kolor dla separatora
WHITE_COLOR = color_as_int(as_rgb(0xFFFFFF))

def draw_tab(draw_data: DrawData, screen, tab: TabBarData,
             before: TabBarData | None, after: TabBarData | None,
             is_last: bool) -> int:
    # Używamy własnych kolorów tła i pierwszego planu
    # Tab colors are defined in kitty.conf: inactive_tab_background, active_tab_background, etc.
    
    active_bg = draw_data.active_bg
    active_fg = draw_data.active_fg
    inactive_bg = draw_data.inactive_bg
    inactive_fg = draw_data.inactive_fg

    if tab.is_active:
        current_bg = active_bg
        current_fg = active_fg
    else:
        current_bg = inactive_bg
        current_fg = inactive_fg

    # Rysowanie separatora po lewej
    if before:
        # Tło separatora jest kolorem tła karty 'before'
        separator_bg = inactive_bg if before.is_active is False else active_bg
        
        # Kolor pierwszego planu separatora to nasz biały kolor
        screen.cursor.fg = WHITE_COLOR
        screen.cursor.bg = separator_bg
        screen.draw('') # Symbol Powerline 
        
    
    # Rysowanie tytułu karty
    screen.cursor.fg = current_fg
    screen.cursor.bg = current_bg
    screen.draw(draw_title(draw_data, tab))

    # Rysowanie separatora po prawej
    if after:
        # Tło separatora to nasz biały kolor
        separator_bg = WHITE_COLOR 
        
        # Kolor pierwszego planu separatora to kolor tła karty 'after'
        next_bg = inactive_bg if after.is_active is False else active_bg
        screen.cursor.fg = next_bg
        screen.cursor.bg = separator_bg
        screen.draw('') # Symbol Powerline 

    return screen.cursor.x

def draw_tab_bar(data: TabBarData) -> str:
    # Zwrócenie niestandardowej funkcji rysowania
    return 'custom'
