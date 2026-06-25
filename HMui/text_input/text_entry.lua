-- Handles flashing cursor, text input hooks, key events, and clipboard paste
local C, tw_color = require("HMfns.animate.color.color_const"), require("HMfns.animate.transitions.tween_color")
local table_utils = require("HMfns.utils.table_utils")

local tween_color_to = tw_color.tween_color_to
local _copy, swap_at = table_utils.deep_copy, table_utils.swap_at
local cw = C.WHITE

local text_entry = {}

----------------------------------------------------
--- Build string from text input hook
----------------------------------------------------
function text_entry.read_input_text(hook)
	local new_text, hch = "", hook.children
	for i = 1, #hch do
        local hcfg = hch[i].config
        if not hcfg or hcfg.text == ""     then goto continue end
		if hcfg.id:sub(1, 7) ~= "letter_"  then goto continue end
		new_text = new_text .. hcfg.text
        ::continue::
    end
	return new_text
end

------------------------------------
--- Move cursor in text input
-----------------------------------
function text_entry.move_txt_cursor(hook, delta)
	local pos_child, text, hch = nil, hook.config.ref_table.text, hook.children
    local dir, trt, trv        = (delta/math.abs(delta)) or 0, text.ref_table, text.ref_value

	for i = 1, #hch do      -- Look for the position id 
        local cfg = hch[i].config   
        if cfg and cfg.id == "_1_position" then pos_child = i; break end
	end
	while delta ~= 0 do
        local shift = pos_child + dir
		if shift < 1 or shift >= #hch then break end
		
        local hcfg        = hch[shift].config
		local real_letter = (hcfg.id:sub(1, 7) == "letter_" and hcfg.text ~= "")
        swap_at(hook.children, pos_child, shift)

		if real_letter then delta = delta - dir end
		pos_child = shift
	end

	text.current_position = math.min(pos_child - 1, string.len(trt[trv]))
	hook.UIPanel:recalculate(true)
    trt[trv] = text_entry.read_input_text(hook)
end

---------------------------------------------------------------
--- Regarding on_text_input_keydown
---------------------------------------------------------------
--- Helper: modify text input (insert/delete/shift letters)
local function apply_text_edit(args)
    local letters, pos = {}, args.pos
    args = args or {}

	if args.delete and pos > 0 then 
        letters = args.text_table.letters
		if pos >= #letters then letters[pos] = ""
		else -- recursively modify
			letters[pos] = letters[pos+1]
			apply_text_edit({letter = args.letter, text_table = args.text_table, pos = pos+1, delete = args.delete})
		end
		return
	end

    letters = args.text_table.letters
	local swapped_letter = letters[pos]
	letters[pos] = args.letter
	if not swapped_letter or swapped_letter == "" then return end
    apply_text_edit({letter = swapped_letter, text_table = args.text_table, pos = pos+1})
end

-- Helper: apply_edit and move_txt_cursor
local function edit_and_move(hook, letter, text, cpos, delete, move)
    apply_text_edit({letter = letter, text_table = text, pos = cpos, delete = delete})
	text_entry.move_txt_cursor(hook, move)
end

-- Helper: handle the return key
local function handle_return(hrt, Ctrl)
    local hook = Ctrl.text_input_hook
    local hrtc = hrt.color
    if hrt.callback then hrt.callback() end
    hook.parent.parent.config.color = hrtc
    
    local temp_color = _copy(hrt.orig_color)
    hrtc[1], hrtc[2], hrtc[3] = cw[1], cw[2], cw[3]
    tween_color_to(hrt.color, temp_color)
    Ctrl.text_input_hook = nil
end

--________________________________________________________
--- Main: Handle key input for hooked text input
--________________________________________________________
function text_entry.on_text_input_keydown(Ctrl, args)
	if args.key == "[" or args.key == "]" then return end
	if args.key == "0" then args.key = "o" end

    local hook           = Ctrl.text_input_hook
    local hrt            = hook.config.ref_table
    local move_cursor    = text_entry.move_txt_cursor
	hrt.orig_color       = hrt.orig_color or _copy(hrt.color)
	args.key, args.caps  = args.key or "%", args.caps or Ctrl.capslock or hrt.all_caps
	local keymap         = { space = " ", backspace = "BACKSPACE", delete = "DELETE", ["return"] = "RETURN", right = "RIGHT", left = "LEFT" }

	local corpus = "123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" .. (hrt.extended_corpus and " 0!$&()<>?:{}+-=,.[]_" or "")

	local text      = hrt.text
    local tt        = text.ref_table
    local tv, key   = text.ref_value, args.key
    local cpos      = text.current_position

	args.key = keymap[key] or (args.caps and string.upper(key) or key)
	move_cursor(hook, 0)

    local key = args.key
	if     #tt[tv] > 0 and key == "BACKSPACE" then edit_and_move(hook, "", text, cpos,   true, -1)
	elseif #tt[tv] > 0 and key == "DELETE"    then edit_and_move(hook, "", text, cpos+1, true, 0)
	elseif key == "RETURN"                    then handle_return(hrt, Ctrl)
	elseif key == "LEFT"                      then move_cursor(hook, -1)
	elseif key == "RIGHT"                     then move_cursor(hook, 1)
	elseif hrt.max_length > #tt[tv] and 
        #key == 1 and 
        string.find(corpus, key, 1, true)     then edit_and_move(hook, key, text, text.current_position+1, false, 1) end
end


return text_entry