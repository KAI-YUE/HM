-- atlas.lua
-- Loads atlas PNG + JSON and provides quads by key.

local class       = require("core.class")
local json        = require("lib.dkjson")
local LG, LI, LF  = love.graphics, love.image, love.filesystem

local IMAGE_SETTING_KEYS = { "mipmaps", "linear", "dpiscale", "format" }

local Y, N = true, false

local Atlas = class:extend()
-----------------------------------------------
--- Load 
-----------------------------------------------
--- Helper: sanitize_image_settings
local function sanitize_image_settings(image_settings)
	if not image_settings then return end

	local settings = {}
	for _, key in ipairs(IMAGE_SETTING_KEYS) do local value = image_settings[key]; if value ~= nil then settings[key] = value end end
	return next(settings) and settings 
end

---__________________________________________
--- main: init
---__________________________________________
function Atlas:init(dir, asset, filter_min, filter_mag, image_settings)
    local atlas_png_path, atlas_json_path = dir..asset..".png", dir..asset..".json"
	local png_data = LF.read(atlas_png_path)
	assert(png_data, "Atlas PNG not found: "..tostring(atlas_png_path))

	local img_data  = LI.newImageData(LF.newFileData(png_data, atlas_png_path))
	local image     = LG.newImage(img_data, sanitize_image_settings(image_settings))

	if filter_min or filter_mag then image:setFilter(filter_min or "linear", filter_mag or "linear") end
	if image_settings and image_settings.mipmaps and image.setMipmapFilter then
		image:setMipmapFilter(image_settings.mipmap_filter or "linear", image_settings.mipmap_sharpness or 0)
	end

	local json_text = LF.read(atlas_json_path)
	assert(json_text, "Atlas JSON not found: "..tostring(atlas_json_path))

	local data, _, err = json.decode(json_text, 1, nil)
	assert(data and not err, "JSON decode failed: "..tostring(err))

	local aw,    ah      = image:getWidth(), image:getHeight()
	local quads, frames  = {}, data.frames or data

	for key, entry in pairs(frames) do
		local fr = entry.frame or entry
		assert(fr and fr.x and fr.y and fr.w and fr.h, "Bad frame entry for key: "..tostring(key))
		quads[key] = LG.newQuad(fr.x, fr.y, fr.w, fr.h, aw, ah)
	end

    self.image, self.quads, self.meta, self.data = image, quads, data.meta or {}, data
end

------------------------------
--- Get quad 
------------------------------
function Atlas:get_quad(key) local q = self.quads[key]; assert(q, "Missing quad key: "..tostring(key)); return q end

------------------------------
--- draw
------------------------------
function Atlas:draw(key, x, y, r, sx, sy, ox, oy)
	local q = self:get_quad(key)
	LG.draw(self.image, q, x, y, r or 0, sx or 1, sy or 1, ox or 0, oy or 0)
end

return Atlas
