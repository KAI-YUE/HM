local Card = require("HMEng.entities.card")

local TextFX = require("HMEng.ui_actors.card_textfx")
-- -- local UIPanel     = require("HMEng.ui_actors.ui_panel")     = require("HMEng.ui_actors.ui_panel") require("HMEng.ui_actors.ui_panel")

local EM = G.E_MANAGER

function ease_dollars(mod, instant)         G.Fs.add_money(G, mod, instant) end
function ease_discard(mod, instant, silent) G.Fs.HUD_add_discard(G, mod, silent) end
function ease_hands_played(mod, instant)    G.Fs.HUD_add_hands(G, mod) end
function ease_ante(mod)                     G.Fs.HUD_add_ante(G, mod) end
function ease_round(mod)                    G.Fs.HUD_add_round(G, mod) end
function ease_value(ref_table, ref_value, mod, floored, timer_type, not_blockable, delay, ease_type) return G.Fs.tween_field_by(G, ref_table, ref_value, mod, floored, timer_type, not_blockable, delay, ease_type) end
function ease_background_color(args)        G.Fs.tween_background_palette(G, args) end
function ease_color(old, new, delay)        G.Fs.tween_color_to(G, old, new, delay) end
function ease_background_color_blind(st, b) G.Fs.tween_background_blind(G, st, b)  end
function delay(time, queue)                 G.Fs.sleep(G, time, queue) end
function level_up_hand(card, hand, instant, amount) G.Fs.upgrade_hand(G, card, hand, instant, amount) end
function update_hand_text(config, vals) G.Fs.HUD_update_hand_label(G, config, vals)  end
function card_eval_status_text(card, eval_type, amt, percent, dir, extra) G.Fs.show_card_status_text(G, card, eval_type, amt, percent, dir, extra) end
function change_shop_size(mod)  G.Fs.inc_shop_size(G, mod) end
function juice_card(card) local EM = G.E_MANAGER; EM:enqueue_event({ func = (function() card:jitter_me(0.7);return true end) }) end
function update_canvas_juice(dt) G.Fs.jitter_canvas(G, dt) end
function juice_card_until(card, eval_func, first, delay) G.E_MANAGER:enqueue_event({ trigger = 'after',delay = delay or 0.1, blocking = false, blockable = false, timer = 'real_s', func = (function() if eval_func(card) then if not first or first then card:jitter_me(0.1, 0.1) end;juice_card_until(card, eval_func, nil, 0.8) end return true end) }) end
function check_for_unlock(args) G.Fs.handle_unlock_request(G, args) end
function unlock_card(card) G.Fs.unlock(G, card) end
function fetch_achievements() G.Fs.init_achievements(G) end
function unlock_achievement(ach_name) G.Fs.grant_achievements(G, ach_name) end
function notify_alert(_achievement, _type) G.Fs.enqueue_alert(G, _achievement, _type) end
function create_unlock_overlay(key) G.Fs.unlock_ntf_overlay(G, key) end
function discover_card(card)        G.Fs.register_card_discovery(G, card) end
function get_deck_from_name(_name)  for k, v in pairs(G.CMod) do if v.name == _name then return v end end end
function get_current_pool(_type, _rarity, _legendary, _append) return G.Fs.fetch_current_pool(G, _type, _rarity, _legendary, _append) end
function poll_edition(_mod, _no_neg, _guaranteed) return G.Fs.roll_edition(G, _mod, _no_neg, _guaranteed) end
function create_card(_type, zone, legendary, _rarity, skip_materialize, soluble, forced_key, key_append) return G.Fs.spawn_card(G, _type, zone, legendary, _rarity, skip_materialize, soluble, forced_key, key_append) end
function copy_card(other, new_card, card_scale, playing_card, strip_edition) return G.Fs.clone_card(G, other, new_card, card_scale, playing_card, strip_edition) end
function tutorial_info(args) return G.Fs.disp_tutorial_info(G, args) end 
function calculate_reroll_cost(skip_increment) G.Fs.reroll_cost(G, skip_increment) end
function get_new_boss() return G.Fs.fetch_new_boss(G) end
function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end) return G.Fs.build_card_ui(G, _c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end) end

function eval_card(card, context)
    context = context or {}
    local ret = {}

    if context.repetition_only then
        local seals = card:calculate_seal(context)
        if seals then
            ret.seals = seals
        end
        return ret
    end
    
    if context.cardarea == G.play then
        local chips = card:get_chip_bonus()
        if chips > 0 then 
            ret.chips = chips
        end

        local mult = card:get_chip_mult()
        if mult > 0 then 
            ret.mult = mult
        end

        local x_mult = card:get_chip_x_mult(context)
        if x_mult > 0 then 
            ret.x_mult = x_mult
        end

        local p_dollars = card:get_p_dollars()
        if p_dollars > 0 then 
            ret.p_dollars = p_dollars
        end

        local jokers = card:calculate_joker(context)
        if jokers then 
            ret.jokers = jokers
        end

        local edition = card:get_edition(context)
        if edition then 
            ret.edition = edition
        end
    end

    if context.cardarea == G.hand then
        local h_mult = card:get_chip_h_mult()
        if h_mult > 0 then 
            ret.h_mult = h_mult
        end

        local h_x_mult = card:get_chip_h_x_mult()
        if h_x_mult > 0 then 
            ret.x_mult = h_x_mult
        end

        local jokers = card:calculate_joker(context)
        if jokers then 
            ret.jokers = jokers
        end
    end

    if context.cardarea == G.jokers or context.card == G.consumables then
        local jokers = nil
        if context.edition then
            jokers = card:get_edition(context)
        elseif context.other_joker then
            jokers = context.other_joker:calculate_joker(context)
        else
            jokers = card:calculate_joker(context)
        end
        if jokers then 
            ret.jokers = jokers
        end
    end

    return ret
end

function inc_steam_stat(stat_name)
    if not G.STEAM then return end
    local success, current_stat = G.STEAM.userStats.getStatInt(stat_name)
    if success then
        G.STEAM.userStats.setStatInt(stat_name, current_stat+1)
        G.STEAM.send_control.update_queued = true
    end
end

function reset_idol_card()
    G.GAME.current_round.idol_card.rank = 'Ace'
    G.GAME.current_round.idol_card.suit = 'spade'
    local valid_idol_cards = {}
    for k, v in ipairs(G.run_card_id) do
        if v.ability.effect ~= 'Stone Card' then
            valid_idol_cards[#valid_idol_cards+1] = v
        end
    end
    if valid_idol_cards[1] then 
        local idol_card = pseudorandom_element(valid_idol_cards, pseudoseed('idol'..G.GAME.round_resets.ante))
        G.GAME.current_round.idol_card.rank = idol_card.base.value
        G.GAME.current_round.idol_card.suit = idol_card.base.suit
        G.GAME.current_round.idol_card.id = idol_card.base.id
    end
end

function reset_mail_rank()
    G.GAME.current_round.mail_card.rank = 'Ace'
    local valid_mail_cards = {}
    for k, v in ipairs(G.run_card_id) do
        if v.ability.effect ~= 'Stone Card' then
            valid_mail_cards[#valid_mail_cards+1] = v
        end
    end
    if valid_mail_cards[1] then 
        local mail_card = pseudorandom_element(valid_mail_cards, pseudoseed('mail'..G.GAME.round_resets.ante))
        G.GAME.current_round.mail_card.rank = mail_card.base.value
        G.GAME.current_round.mail_card.id = mail_card.base.id
    end
end

function reset_ancient_card()
    local ancient_suits = {}
    for k, v in ipairs({'spade','heart','club','diamond'}) do
        if v ~= G.GAME.current_round.ancient_card.suit then ancient_suits[#ancient_suits + 1] = v end
    end
    local ancient_card = pseudorandom_element(ancient_suits, pseudoseed('anc'..G.GAME.round_resets.ante))
    G.GAME.current_round.ancient_card.suit = ancient_card
end

function reset_castle_card()
    G.GAME.current_round.castle_card.suit = 'spade'
    local valid_castle_cards = {}
    for k, v in ipairs(G.run_card_id) do
        if v.ability.effect ~= 'Stone Card' then
            valid_castle_cards[#valid_castle_cards+1] = v
        end
    end
    if valid_castle_cards[1] then 
        local castle_card = pseudorandom_element(valid_castle_cards, pseudoseed('cas'..G.GAME.round_resets.ante))
        G.GAME.current_round.castle_card.suit = castle_card.base.suit
    end
end

function reset_blinds()
    G.GAME.round_resets.blind_states = G.GAME.round_resets.blind_states or {Small = 'Select', Big = 'Upcoming', Boss = 'Upcoming'}
    if G.GAME.round_resets.blind_states.Boss == 'Defeated' then
        G.GAME.round_resets.blind_states.Small = 'Upcoming'
        G.GAME.round_resets.blind_states.Big = 'Upcoming'
        G.GAME.round_resets.blind_states.Boss = 'Upcoming'
        G.GAME.blind_on_deck = 'Small'
        G.GAME.round_resets.blind_choices.Boss = get_new_boss()
        G.GAME.round_resets.boss_rerolled = false
    end
end

function get_next_voucher_key(_from_tag)
    local _pool, _pool_key = get_current_pool('Voucher')
    if _from_tag then _pool_key = 'Voucher_fromtag' end
    local center = pseudorandom_element(_pool, pseudoseed(_pool_key))
    local it = 1
    while center == 'UNAVAILABLE' do
        it = it + 1
        center = pseudorandom_element(_pool, pseudoseed(_pool_key..'_resample'..it))
    end

    return center
end

function get_next_tag_key(append)
    if G.FORCE_TAG then return G.FORCE_TAG end
    local _pool, _pool_key = get_current_pool('Tag', nil, nil, append)
    local _tag = pseudorandom_element(_pool, pseudoseed(_pool_key))
    local it = 1
    while _tag == 'UNAVAILABLE' do
        it = it + 1
        _tag = pseudorandom_element(_pool, pseudoseed(_pool_key..'_resample'..it))
    end

    return _tag
end

function get_pack(_key, _type)
    if not G.GAME.first_shop_buffoon and not G.GAME.banned_keys['p_buffoon_normal_1'] then
        G.GAME.first_shop_buffoon = true
        return G.CMod['p_buffoon_normal_'..(math.random(1, 2))]
    end
    local cume, it, center = 0, 0, nil
    for k, v in ipairs(G.P_CPools['Booster']) do
        if (not _type or _type == v.kind) and not G.GAME.banned_keys[v.key] then cume = cume + (v.weight or 1 ) end
    end
    local poll = pseudorandom(pseudoseed((_key or 'pack_generic')..G.GAME.round_resets.ante))*cume
    for k, v in ipairs(G.P_CPools['Booster']) do
        if not G.GAME.banned_keys[v.key] then 
            if not _type or _type == v.kind then it = it + (v.weight or 1) end
            if it >= poll and it - (v.weight or 1) <= poll then center = v; break end
        end
    end
    return center
end

function highlight_card(card, percent, dir)
    local EM, percent = G.E_MANAGER, percent or 0.5
    local highlight = true
    if dir == 'down' then percent = 1-percent; highlight = false end

    EM:enqueue_event({
        trigger = 'before',
        delay = 0.1,
        func = function()
            card:highlight(highlight)
            play_sound('cardSlide1', 0.85 + percent*0.2)
            return true
        end
      })
end

function play_area_status_text(text, silent, delay)
    local EM = G.E_MANAGER
    local delay = delay or 0.6
    EM:enqueue_event({
    trigger = (delay==0 and 'immediate' or 'before'),
    delay = delay,
    func = function()
        attention_text({
            scale = 0.9, text = text, hold = 0.9, align = 'tm',
            major = G.play, offset = {x = 0, y = -1}
        })
        if not silent then 
            G._room.jiggle = G._room.jiggle + 2
            play_sound('cardFan2')
        end
      return true
    end
    })
end
