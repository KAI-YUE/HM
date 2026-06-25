local CameraPrep   = require("HMGplay.run_flow.prep.field.camera")
local PawnPrep     = require("HMGplay.run_flow.prep.field.pawns")
local GridzonePrep = require("HMGplay.run_flow.prep.field.gridzone")
local ShaderFxPrep = require("HMGplay.run_flow.prep.field.shader_fx")

local M = {}

-----------------------------
--- install
----------------------------------
--- Helper: install module exports
local function install(pkg) for k, v in pairs(pkg) do M[k] = v end end

install(CameraPrep)
install(PawnPrep)
install(GridzonePrep)
install(ShaderFxPrep)

return M
