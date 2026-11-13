-- LibActionButton-1.0, as far as SaftUI-ActionBars' files use it when they
-- load: skin.lua and bars.lua take it from LibStub, and skin.lua registers its
-- OnButtonUpdate handler with the library's callbacks, made here with
-- CallbackHandler-1.0 as the library makes them. A test fires one as the
-- library does, with LAB.callbacks:Fire('OnButtonUpdate', button). What
-- bars.lua calls on it later (CreateButton, GetSpellFlyoutFrame) isn't here.
--
-- The real library (SaftUI-ActionBars/Libraries/LibActionButton-1.0) makes its
-- buttons from Blizzard's ActionButtonTemplate, which the stubs don't have, so
-- the tests make their buttons by hand. Real LibStub and CallbackHandler-1.0
-- (load_core_helpers loads both), so a method nothing gave the library errors.
local LAB = LibStub:NewLibrary('LibActionButton-1.0', 1)
LAB.callbacks = LibStub('CallbackHandler-1.0'):New(LAB)
return LAB
