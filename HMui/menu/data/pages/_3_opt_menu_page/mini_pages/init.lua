local _mini_page_dir = "HMui.menu.data.pages._3_opt_menu_page.mini_pages."

------------------------------------
--- for the regions, plz refer to the main page 
------------------------------------

local M = {
    cascade_actions = require(_mini_page_dir .. "_3_2_cascade_actions"),
    tab_header      = require(_mini_page_dir .. "_3_1_tab_header"),   
}

M.root = {
    style  = "conceptual_box",                   id = "opt_mini_pages_root",
    T      = { x = 0, y = 0, w = 25, h = 10 },

    --- child mini-pages
    child_widgets = {
        M.cascade_actions,
        M.tab_header,
    },
}

return M
