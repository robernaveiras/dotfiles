-- Personal Quake console sizing.
-- Omarchy's default/hypr/qconsole.lua keeps `share` (height as a fraction of
-- the usable screen) and `box` (width:height ratio when one window is open)
-- module-private and loads its own copy unconditionally, so a user file on the
-- require path cannot replace it. Overriding package.loaded first makes this
-- user file the module that omarchy.lua requires, and the default never runs.
package.preload["default.hypr.qconsole"] = function()
  return dofile(os.getenv("HOME") .. "/.config/default/hypr/qconsole.lua")
end
