-- LibActionButton-1.0, as far as SaftUI-ActionBars/skin.lua uses it when it
-- loads: the library's callbacks, made with CallbackHandler-1.0 as the library
-- makes them, which skin.lua registers its OnButtonUpdate handler with. A test
-- fires one as the library does, with LAB.callbacks:Fire('OnButtonUpdate', button).
--
-- The real library (SaftUI-ActionBars/Libraries/LibActionButton-1.0) makes its
-- buttons from Blizzard's ActionButtonTemplate, which the stubs don't have, so
-- the tests make their buttons by hand. Real LibStub and CallbackHandler-1.0
-- (load_core_helpers loads both), so a method nothing gave the library errors.
local LAB = LibStub:NewLibrary('LibActionButton-1.0', 1)
LAB.callbacks = LibStub('CallbackHandler-1.0'):New(LAB)
return LAB
