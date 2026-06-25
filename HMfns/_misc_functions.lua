local Card = require("HMEng.entities.card")
local CardZone = require("HMEng.entities.board.cardzone")

local Gate = require("HMEng.controller.input_gate")

local LG = love.graphics
local class = require("core.class")

function timer_checkpoint(label, type, reset) G.Fs.timer_cpt(G, label, type, reset) end
function GET_DISPLAYINFO(screenmode, display) return G.Fs.fetch_display_info(G, screenmode, display) end 
function EMPTY(t) return G.Fs.wipe(t) end
function interp(per, max, min) return G.Fs.lerp(per, max, min) end
function remove_all(t) G.Fs.destroy_tree(t) end
function Vector_Dist(t1, t2, mid) return G.Fs.xf_dist(t1, t2, mid) end
function Vector_Len(t1) return G.Fs.vec_len(t1) end
function Vector_Sub(trans1, trans2) return G.Fs.vec_sub(t1, t2) end
function get_index(t, val) return G.Fs.index_of(t, val) end
function remove_nils(t) local ans = {}; for _,v in pairs(t) do ans[ #ans+1 ] = v end; return ans end
function SWAP(t, i, j) if not t or not i or not j then return end; local temp = t[i]; t[i] = t[j]; t[j] = temp end
function pseudoshuffle(list, seed) G.Fs.shuffle_in_place(list, seed) end
function get_first_legendary(_key) local _t, key = pseudorandom_element(G.P_JOKER_RARITY_POOLS[4], pseudoseed('Joker4', _key)); return _t.key end
function pseudorandom_element(_t, seed) return G.Fs.random_pick(_t, seed) end
function rand_str(length, seed) return G.Fs.rand_str(length, seed) end
function pseudohash(str) return G.Fs.hash_string32(str) end
function pseudoseed(key, salt) return G.Fs.hash_unit32(G, key, salt) end
function pseudorandom(seed, min, max) return G.Fs.seeded_random(G, seed, min, max) end
function sortingFunction(e1, e2) return e1.order < e2.order end
function HEX(hex) return G.Fs.hex_to_rgba(hex) end
function get_blind_main_color(blind) return G.Fs.blind_color(G, blind) end
function evaluate_poker_hand(hand) return G.Fs.evaluate_hand(G, hand) end
function get_flush(hand)    return G.Fs.fetch_flush(G, hand) end 
function get_straight(hand) return G.Fs.fetch_straight(G, hand) end
function get_highest(hand)  return G.Fs.fetch_highest(G, hand) end
function get_X_same(num, hand) return G.Fs.fetch_N_of_Akind(G, num, hand) end
function nuGC(time_budget, memory_ceiling, disable_otherwise) G.Fs.tick_gc(G, time_budget, memory_ceiling, disable_otherwise) end 
function add_to_drawhash(obj) G.Fs.add_to_drawable(G, obj) end 
function reset_drawhash() G.Fs.wipe_drawable(G) end
function mix_colors(C1, C2, proportionC1) return G.Fs.lerp_colors(C1, C2, proportionC1) end
function mod_chips(_chips) if G.GAME.modifiers.chips_dollar_cap then _chips = math.min(_chips, math.max(G.GAME.dollars, 0)) end; return _chips end
function prep_draw(actor, scale, rotate, offset) G.Fs.push_draw_transform(actor, scale, rotate, offset) end
function get_chosen_triangle_from_rect(x, y, w, h, vert) return G.Fs.sel_triangle(G, x, y, w, h, vert) end
function point_translate(_T, delta) G.Fs.vec_translate_inplace(_T, delta) end
function point_rotate(_T, angle) G.Fs.vec_rotate_inplace(_T, angle) end
function lighten(color, percent, no_tab) return G.Fs.tint(color, percent) end
function darken(color, percent, no_tab)  return G.Fs.shade(color, percent) end
function adjust_alpha(color, new_alpha)  return G.Fs.set_alpha(color, new_alpha) end
function alert_no_space(card, zone)            G.Fs.toast_alter_no_space(G, card, zone) end
function find_joker(name, non_debuff)   return G.Fs.fetch_joker(G, name, non_debuff) end
function get_blind_amount(ante)         return G.Fs.blind_score_target(G, ante) end
function number_format(num)             return G.Fs.format_num(G, num) end
function score_number_scale(scale, amt) return G.Fs.scale4score(scale, amt) end
function copy_table(O)                  return G.Fs.deep_copy(O) end
function check_and_set_high_score(score, amt)  G.Fs.update_high_score(G, score, amt) end
function set_joker_usage() G.Fs.inc_joker_usage(G) end
function set_joker_win() G.Fs.inc_joker_win(G) end
function get_joker_win_sticker(_center, index) return G.Fs.fetch_joker_win_sticker(G, _center, index) end
function get_deck_win_stake(_deck_key) return G.Fs.deck_max_win_stake(G, _deck_key) end
function get_deck_win_sticker(_center) G.Fs.fetch_deck_win_sticker(G, _center) end
function set_consumable_usage(card) G.Fs.log_consumable_usage(G, card) end
function set_voucher_usage(card)    G.Fs.log_voucher_usage(G, card) end
function set_profile_progress()     G.Fs.set_progress(G) end
function stop_use()                 Gate.suspend_interaction(G)  end
function inc_career_stat(stat, mod) G.Fs.update_career(G, stat, mod) end
function save_with_action(action)   G.action = action; save_run(); G.action = nil end
function save_run()                 G.Fs.save_state_dict(G) end
function remove_save()              G.Fs.delete_state_dict(G) end
function loc_color(_c, _default)    return G.Fs.loc_color(G, _c, _default) end
function init_localization()        G.Fs.init_i18n_dict(G) end 
function playing_card_joker_effects(cards) return G.Fs.trigger_jokers(G, cards) end
function localize(args, misc) return G.Fs.i18n(G, args, misc) end
function get_stake_sprite(_stake, _scale) return G.Fs.stake_icon(G, _stake, _scale) end
function get_challenge_int_from_id(_id) for k, v in pairs(G.CHALLENGES or {}) do if v.id == _id then return k end end; return 0 end
function get_challenge_rule(_challenge, _type, _id)  if _challenge and _challenge.rules and _challenge.rules[_type] then for k, v in ipairs(_challenge.rules[_type]) do if _id == v.id then return v.value end end end end

function stop_audio()
  for _, source in pairs(SOURCES) do
      for _, s in pairs(source) do
          if s.sound:isPlaying() then
              s.sound:stop()
          end
      end
  end
end


function set_deck_loss()
  if G.GAME.selected_back and G.GAME.selected_back.effect and G.GAME.selected_back.effect.template and G.GAME.selected_back.effect.template.key then
    local deck_key = G.GAME.selected_back.effect.template.key
    if not G.g_profile[G.SET.profile].deck_usage[deck_key] then G.g_profile[G.SET.profile].deck_usage[deck_key] = {count = 1, order = G.GAME.selected_back.effect.template.order, wins = {}, losses = {}} end
    if G.g_profile[G.SET.profile].deck_usage[deck_key] then
      G.g_profile[G.SET.profile].deck_usage[deck_key].losses[G.GAME.stake] = (G.g_profile[G.SET.profile].deck_usage[deck_key].losses[G.GAME.stake] or 0) + 1
    end
    G:save_settings()
  end
end
function set_hand_usage(hand)
  local hand_label = hand
  hand = hand:gsub("%s+", "")
  if G.g_profile[G.SET.profile].hand_usage[hand] then
    G.g_profile[G.SET.profile].hand_usage[hand].count = G.g_profile[G.SET.profile].hand_usage[hand].count + 1
  else
    G.g_profile[G.SET.profile].hand_usage[hand] = {count = 1, order = hand_label}
  end
  if G.GAME.hand_usage[hand] then
    G.GAME.hand_usage[hand].count = G.GAME.hand_usage[hand].count + 1
  else
    G.GAME.hand_usage[hand] = {count = 1, order = hand_label}
  end
  G:save_settings()
end

function set_joker_loss()
  for k, v in pairs(G.jokers.cards) do
    if v.config.center_key and v.ability.set == 'Joker' then
      if G.g_profile[G.SET.profile].joker_usage[v.config.center_key] then
        G.g_profile[G.SET.profile].joker_usage[v.config.center_key].losses = G.g_profile[G.SET.profile].joker_usage[v.config.center_key].losses or {}
        G.g_profile[G.SET.profile].joker_usage[v.config.center_key].losses[G.GAME.stake] = (G.g_profile[G.SET.profile].joker_usage[v.config.center_key].losses[G.GAME.stake] or 0) + 1
      end
    end
  end
  G:save_settings()
end

function set_deck_usage()
  if G.GAME.selected_back and G.GAME.selected_back.effect and G.GAME.selected_back.effect.template and G.GAME.selected_back.effect.template.key then
    local deck_key = G.GAME.selected_back.effect.template.key
    if G.g_profile[G.SET.profile].deck_usage[deck_key] then
      G.g_profile[G.SET.profile].deck_usage[deck_key].count = G.g_profile[G.SET.profile].deck_usage[deck_key].count + 1
    else
      G.g_profile[G.SET.profile].deck_usage[deck_key] = {count = 1, order = G.GAME.selected_back.effect.template.order, wins = {}, losses = {}}
    end
    G:save_settings()
  end
end

function set_deck_win()
  if G.GAME.selected_back and G.GAME.selected_back.effect and G.GAME.selected_back.effect.template and G.GAME.selected_back.effect.template.key then
    local deck_key = G.GAME.selected_back.effect.template.key
    if not G.g_profile[G.SET.profile].deck_usage[deck_key] then G.g_profile[G.SET.profile].deck_usage[deck_key] = {count = 1, order = G.GAME.selected_back.effect.template.order, wins = {}, losses = {}} end
    if G.g_profile[G.SET.profile].deck_usage[deck_key] then
      G.g_profile[G.SET.profile].deck_usage[deck_key].wins[G.GAME.stake] = (G.g_profile[G.SET.profile].deck_usage[deck_key].wins[G.GAME.stake] or 0) + 1
      for i = 1, G.GAME.stake do
        G.g_profile[G.SET.profile].deck_usage[deck_key].wins[i] = (G.g_profile[G.SET.profile].deck_usage[deck_key].wins[i] or 1)
      end
    end
    set_challenge_unlock()
    G:save_settings()
  end
end

function set_challenge_unlock()
  if G.g_profile[G.SET.profile].all_unlocked then return end
  if G.g_profile[G.SET.profile].challenges_unlocked then
    local _ch_comp, _ch_tot = 0,#G.CHALLENGES
    for k, v in ipairs(G.CHALLENGES) do
      if v.id and G.g_profile[G.SET.profile].challenge_progress.completed[v.id or ''] then
        _ch_comp = _ch_comp + 1
      end
    end
    G.g_profile[G.SET.profile].challenges_unlocked = math.min(_ch_tot, _ch_comp+5)
  else
    local deck_wins = 0
    for k, v in pairs(G.g_profile[G.SET.profile].deck_usage) do
      if v.wins and v.wins[1] then
        deck_wins = deck_wins + 1
      end
    end
    if deck_wins >= G.c_wins and not G.g_profile[G.SET.profile].challenges_unlocked then
      G.g_profile[G.SET.profile].challenges_unlocked = 5
      notify_alert('b_challenge', "Deck")
    end
  end
end

function play_sound(sound_code, per, vol)
  if sound_code and G.SET.s_snd.volume > 0.001 then
    G.args.play_sound = G.args.play_sound or {}
    G.args.play_sound.type = 'sound'
    G.args.play_sound.time = G._T.real_s
    G.args.play_sound.crt = G.SET.s_graphics.crt
    G.args.play_sound.sound_code = sound_code
    G.args.play_sound.per = per
    G.args.play_sound.vol = vol
    G.args.play_sound.pitch_mod = G.s_pitch
    G.args.play_sound.state = G.g_state
    G.args.play_sound.music_control = G.SET.music_control
    G.args.play_sound.sound_settings = G.SET.s_snd
    G.args.play_sound.splash_vol = G.SPLASH_VOL
    G.args.play_sound.overlay_menu = not (not G.UI.overlay_menu)
    G.args.play_sound.tag = nil
    G.args.play_sound.voice = nil
    G.SndMgr.channel:push(G.args.play_sound)
  end
end
