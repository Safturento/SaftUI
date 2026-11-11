--[[
	The atlases the Blizzard theme names (st:ThemeAtlases, SaftUI-Core/themeart.lua),
	as each client's atlas tables have them, for C_Texture.GetAtlasInfo
	(tests/wow/blizzard.lua). Data, not a stub: blizzard.lua loads it.

	Source: the clients' UiTextureAtlasElement and UiTextureAtlasMember tables
	from wago.tools, at the builds the Blizzard theme's spec names: Forever
	1.60.1.70888 and retail 12.1.5.70783. Every name is the theme's own spelling;
	the game looks atlases up ignoring case (the tables spell the Edit Mode and
	class power ones in other cases), and so does the stub.

	Each entry is { width, height, tiles }:
	  - width and height in UI units: the member's override size where it has
	    one, else its texture size, halved for art that exists only at double
	    resolution (a -2x member);
	  - tiles is 'h' (tiled across), 'v' (tiled down), 'hv' (both) or nil, from
	    the member's flags (0x4 across, 0x2 down).
	Forever draws the Camelot member (-c60) of an atlas where there is one, so
	its entries are those members'. When the theme names a new atlas, add it to
	both clients from the same tables.
]]
return {
	forever = {
		-- The tooltip border (panel, bar, tooltip)
		['Tooltip-NineSlice-CornerTopLeft'] = { 7, 7 },
		['Tooltip-NineSlice-CornerTopRight'] = { 7, 7 },
		['Tooltip-NineSlice-CornerBottomLeft'] = { 7, 7 },
		['Tooltip-NineSlice-CornerBottomRight'] = { 7, 7 },
		['_Tooltip-NineSlice-EdgeTop'] = { 16, 7, 'h' },
		['_Tooltip-NineSlice-EdgeBottom'] = { 16, 7, 'h' },
		['!Tooltip-NineSlice-EdgeLeft'] = { 7, 16, 'v' },
		['!Tooltip-NineSlice-EdgeRight'] = { 7, 16, 'v' },
		-- The character frame's metal (window)
		['UI-Frame-Metal-CornerTopLeft'] = { 95, 95 },
		['UI-Frame-Metal-CornerTopRight'] = { 95, 95 },
		['UI-Frame-Metal-CornerBottomLeft'] = { 95, 100 },
		['UI-Frame-Metal-CornerBottomRight'] = { 95, 100 },
		['_UI-Frame-Metal-EdgeTop'] = { 128, 95, 'h' },
		['_UI-Frame-Metal-EdgeBottom'] = { 128, 100, 'h' },
		['!UI-Frame-Metal-EdgeLeft'] = { 95, 128, 'v' },
		['!UI-Frame-Metal-EdgeRight'] = { 95, 128, 'v' },
		-- The action button (action), its border and its states
		['UI-HUD-ActionBar-IconFrame'] = { 46, 45 },
		['UI-HUD-ActionBar-IconFrame-Background'] = { 46, 45 },
		['UI-HUD-ActionBar-IconFrame-Slot'] = { 64, 62 },
		['UI-HUD-ActionBar-IconFrame-Border'] = { 46, 45 },
		['UI-HUD-ActionBar-IconFrame-Mouseover'] = { 46, 45 },
		['UI-HUD-ActionBar-IconFrame-Down'] = { 46, 45 },
		['UI-HUD-ActionBar-IconFrame-Flash'] = { 46, 45 },
		-- The item button's empty slot (slot)
		['bags-item-slot64'] = { 32, 32, 'hv' },
		-- The close button
		['RedButton-Exit'] = { 32, 32 },
		['RedButton-exit-pressed'] = { 32, 32 },
		['RedButton-Highlight'] = { 32, 32 },
		['RedButton-Exit-Disabled'] = { 32, 32 },
		-- Controls: the check box
		['checkbox-minimal'] = { 30, 29 },
		['checkmark-minimal'] = { 30, 29 },
		['checkmark-minimal-disabled'] = { 30, 29 },
		-- Controls: the tabs of a radio group
		['uiframe-activetab-left'] = { 35, 42 },
		['_uiframe-activetab-center'] = { 1, 42, 'h' },
		['uiframe-activetab-right'] = { 37, 42 },
		['uiframe-tab-left'] = { 35, 36 },
		['_uiframe-tab-center'] = { 1, 36, 'h' },
		['uiframe-tab-right'] = { 37, 36 },
		-- Controls: the dropdown and its list
		['common-dropdown-textholder'] = { 54, 41 },
		['common-dropdown-a-button'] = { 27, 27 },
		['common-dropdown-a-button-hover'] = { 27, 27 },
		['common-dropdown-a-button-pressed'] = { 27, 27 },
		['common-dropdown-a-button-open'] = { 27, 27 },
		['common-dropdown-a-button-disabled'] = { 27, 27 },
		['common-dropdown-bg'] = { 68, 68 },
		-- Controls: the slider
		['Minimal_SliderBar_Left'] = { 11, 17 },
		['_Minimal_SliderBar_Middle'] = { 1, 17, 'h' },
		['Minimal_SliderBar_Right'] = { 11, 17 },
		['Minimal_SliderBar_Button'] = { 20, 19 },
		-- Controls: the text box
		['auctionhouse-ui-inputfield-left'] = { 8, 33 },
		['auctionhouse-ui-inputfield-middle'] = { 178, 33 },
		['auctionhouse-ui-inputfield-right'] = { 8, 33 },
		-- Controls: the search box
		['common-search-border-left'] = { 16, 40 },
		['common-search-border-middle'] = { 224, 40 },
		['common-search-border-right'] = { 16, 40 },
		['common-search-magnifyingglass'] = { 24, 24 },
		-- Controls: the up and down nudges
		['minimal-scrollbar-arrow-top'] = { 17, 11 },
		['minimal-scrollbar-arrow-top-over'] = { 17, 11 },
		['minimal-scrollbar-arrow-top-down'] = { 17, 11 },
		['minimal-scrollbar-arrow-bottom'] = { 17, 11 },
		['minimal-scrollbar-arrow-bottom-over'] = { 17, 11 },
		['minimal-scrollbar-arrow-bottom-down'] = { 17, 11 },
		-- Controls: the Settings panel's tabs
		['Options_Tab_Left'] = { 7, 23 },
		['Options_Tab_Middle'] = { 1, 23 },
		['Options_Tab_Right'] = { 7, 23 },
		['Options_Tab_Active_Left'] = { 7, 26 },
		['Options_Tab_Active_Middle'] = { 1, 26 },
		['Options_Tab_Active_Right'] = { 7, 26 },
		-- Controls: the Settings panel's category list
		['Options_List_Active'] = { 187, 21 },
		['Options_List_Hover'] = { 187, 21 },
		-- Controls: the micro buttons
		['UI-HUD-MicroMenu-ButtonBG-Down'] = { 32, 41 },
		['UI-HUD-MicroMenu-Highlightalert'] = { 32, 41 },
		-- Controls: Edit Mode's selection, both kits
		['editmode-actionbar-highlight-NineSlice-Corner'] = { 16, 16 },
		['_editmode-actionbar-highlight-NineSlice-EdgeTop'] = { 16, 16, 'h' },
		['_editmode-actionbar-highlight-NineSlice-EdgeBottom'] = { 16, 16, 'h' },
		['!editmode-actionbar-highlight-NineSlice-EdgeLeft'] = { 16, 16, 'v' },
		['!editmode-actionbar-highlight-NineSlice-EdgeRight'] = { 16, 16, 'v' },
		['editmode-actionbar-highlight-NineSlice-Center'] = { 16, 16, 'hv' },
		['editmode-actionbar-selected-NineSlice-Corner'] = { 16, 16 },
		['_editmode-actionbar-selected-NineSlice-EdgeTop'] = { 16, 16, 'h' },
		['_editmode-actionbar-selected-NineSlice-EdgeBottom'] = { 16, 16, 'h' },
		['!editmode-actionbar-selected-NineSlice-EdgeLeft'] = { 16, 16, 'v' },
		['!editmode-actionbar-selected-NineSlice-EdgeRight'] = { 16, 16, 'v' },
		['editmode-actionbar-selected-NineSlice-Center'] = { 16, 16, 'hv' },
		-- Controls: class power points
		['uf-roguecp-bg'] = { 22, 22 },
		['uf-roguecp-icon-red'] = { 14, 14 },
		['uf-roguecp-icon-blue'] = { 14, 15 },
		['UF-DruidCP-BG-Active'] = { 22, 22 },
		['UF-DruidCP-Icon'] = { 14, 14 },
		['uf-holypower-rune1'] = { 18, 18 },
		['uf-holypower-rune1-active'] = { 23, 23 },
		['uf-holypower-rune2'] = { 20, 16 },
		['uf-holypower-rune2-active'] = { 24, 22 },
		['uf-holypower-rune3'] = { 17, 15 },
		['uf-holypower-rune3-active'] = { 23, 21 },
		['uf-holypower-rune4'] = { 15, 16 },
		['uf-holypower-rune4-active'] = { 21, 22 },
		['uf-holypower-rune5'] = { 18, 16 },
		['uf-holypower-rune5-active'] = { 22, 23 },
		['UF-SoulShard-Holder'] = { 23, 30 },
		['UF-SoulShard-Icon'] = { 15, 20 },
		['uf-chi-bg'] = { 25, 25 },
		['uf-chi-icon'] = { 14, 15 },
		['UF-Arcane-BG'] = { 21, 21 },
		['UF-Arcane-Icon'] = { 19, 19 },
		['UF-Essence-BG'] = { 24, 24 },
		['UF-Essence-Icon'] = { 24, 24 },
	},
	retail = {
		-- The tooltip border (panel, bar, tooltip)
		['Tooltip-NineSlice-CornerTopLeft'] = { 7, 7 },
		['Tooltip-NineSlice-CornerTopRight'] = { 7, 7 },
		['Tooltip-NineSlice-CornerBottomLeft'] = { 7, 7 },
		['Tooltip-NineSlice-CornerBottomRight'] = { 7, 7 },
		['_Tooltip-NineSlice-EdgeTop'] = { 16, 7, 'h' },
		['_Tooltip-NineSlice-EdgeBottom'] = { 16, 7, 'h' },
		['!Tooltip-NineSlice-EdgeLeft'] = { 7, 16, 'v' },
		['!Tooltip-NineSlice-EdgeRight'] = { 7, 16, 'v' },
		-- The character frame's metal (window)
		['UI-Frame-Metal-CornerTopLeft'] = { 75, 75 },
		['UI-Frame-Metal-CornerTopRight'] = { 75, 75 },
		['UI-Frame-Metal-CornerBottomLeft'] = { 32, 32 },
		['UI-Frame-Metal-CornerBottomRight'] = { 32, 32 },
		['_UI-Frame-Metal-EdgeTop'] = { 32, 75, 'h' },
		['_UI-Frame-Metal-EdgeBottom'] = { 16, 32, 'h' },
		['!UI-Frame-Metal-EdgeLeft'] = { 75, 16, 'v' },
		['!UI-Frame-Metal-EdgeRight'] = { 75, 16, 'v' },
		-- The action button (action), its border and its states
		['UI-HUD-ActionBar-IconFrame'] = { 46, 45 },
		['UI-HUD-ActionBar-IconFrame-Background'] = { 46, 45 },
		['UI-HUD-ActionBar-IconFrame-Slot'] = { 45, 45 },
		['UI-HUD-ActionBar-IconFrame-Border'] = { 46, 45 },
		['UI-HUD-ActionBar-IconFrame-Mouseover'] = { 46, 45 },
		['UI-HUD-ActionBar-IconFrame-Down'] = { 46, 45 },
		['UI-HUD-ActionBar-IconFrame-Flash'] = { 46, 45 },
		-- The item button's empty slot (slot)
		['bags-item-slot64'] = { 32, 32, 'hv' },
		-- The close button
		['RedButton-Exit'] = { 18, 19 },
		['RedButton-exit-pressed'] = { 18, 19 },
		['RedButton-Highlight'] = { 18, 19 },
		['RedButton-Exit-Disabled'] = { 18, 19 },
		-- Controls: the check box
		['checkbox-minimal'] = { 30, 29 },
		['checkmark-minimal'] = { 30, 29 },
		['checkmark-minimal-disabled'] = { 30, 29 },
		-- Controls: the tabs of a radio group
		['uiframe-activetab-left'] = { 35, 42 },
		['_uiframe-activetab-center'] = { 1, 42, 'h' },
		['uiframe-activetab-right'] = { 37, 42 },
		['uiframe-tab-left'] = { 35, 36 },
		['_uiframe-tab-center'] = { 1, 36, 'h' },
		['uiframe-tab-right'] = { 37, 36 },
		-- Controls: the dropdown and its list
		['common-dropdown-textholder'] = { 54, 41 },
		['common-dropdown-a-button'] = { 27, 27 },
		['common-dropdown-a-button-hover'] = { 27, 27 },
		['common-dropdown-a-button-pressed'] = { 27, 27 },
		['common-dropdown-a-button-open'] = { 27, 27 },
		['common-dropdown-a-button-disabled'] = { 27, 27 },
		['common-dropdown-bg'] = { 68, 68 },
		-- Controls: the slider
		['Minimal_SliderBar_Left'] = { 11, 17 },
		['_Minimal_SliderBar_Middle'] = { 1, 17, 'h' },
		['Minimal_SliderBar_Right'] = { 11, 17 },
		['Minimal_SliderBar_Button'] = { 20, 19 },
		-- Controls: the text box
		['auctionhouse-ui-inputfield-left'] = { 8, 33 },
		['auctionhouse-ui-inputfield-middle'] = { 178, 33 },
		['auctionhouse-ui-inputfield-right'] = { 8, 33 },
		-- Controls: the search box
		['common-search-border-left'] = { 16, 40 },
		['common-search-border-middle'] = { 224, 40 },
		['common-search-border-right'] = { 16, 40 },
		['common-search-magnifyingglass'] = { 24, 24 },
		-- Controls: the up and down nudges
		['minimal-scrollbar-arrow-top'] = { 17, 11 },
		['minimal-scrollbar-arrow-top-over'] = { 17, 11 },
		['minimal-scrollbar-arrow-top-down'] = { 17, 11 },
		['minimal-scrollbar-arrow-bottom'] = { 17, 11 },
		['minimal-scrollbar-arrow-bottom-over'] = { 17, 11 },
		['minimal-scrollbar-arrow-bottom-down'] = { 17, 11 },
		-- Controls: the Settings panel's tabs
		['Options_Tab_Left'] = { 7, 23 },
		['Options_Tab_Middle'] = { 1, 23 },
		['Options_Tab_Right'] = { 7, 23 },
		['Options_Tab_Active_Left'] = { 7, 26 },
		['Options_Tab_Active_Middle'] = { 1, 26 },
		['Options_Tab_Active_Right'] = { 7, 26 },
		-- Controls: the Settings panel's category list
		['Options_List_Active'] = { 187, 21 },
		['Options_List_Hover'] = { 187, 21 },
		-- Controls: the micro buttons
		['UI-HUD-MicroMenu-ButtonBG-Down'] = { 32, 41 },
		['UI-HUD-MicroMenu-Highlightalert'] = { 32, 41 },
		-- Controls: Edit Mode's selection, both kits
		['editmode-actionbar-highlight-NineSlice-Corner'] = { 16, 16 },
		['_editmode-actionbar-highlight-NineSlice-EdgeTop'] = { 16, 16, 'h' },
		['_editmode-actionbar-highlight-NineSlice-EdgeBottom'] = { 16, 16, 'h' },
		['!editmode-actionbar-highlight-NineSlice-EdgeLeft'] = { 16, 16, 'v' },
		['!editmode-actionbar-highlight-NineSlice-EdgeRight'] = { 16, 16, 'v' },
		['editmode-actionbar-highlight-NineSlice-Center'] = { 16, 16, 'hv' },
		['editmode-actionbar-selected-NineSlice-Corner'] = { 16, 16 },
		['_editmode-actionbar-selected-NineSlice-EdgeTop'] = { 16, 16, 'h' },
		['_editmode-actionbar-selected-NineSlice-EdgeBottom'] = { 16, 16, 'h' },
		['!editmode-actionbar-selected-NineSlice-EdgeLeft'] = { 16, 16, 'v' },
		['!editmode-actionbar-selected-NineSlice-EdgeRight'] = { 16, 16, 'v' },
		['editmode-actionbar-selected-NineSlice-Center'] = { 16, 16, 'hv' },
		-- Controls: class power points
		['uf-roguecp-bg'] = { 20, 20 },
		['uf-roguecp-icon-red'] = { 14, 15 },
		['uf-roguecp-icon-blue'] = { 14, 15 },
		['UF-DruidCP-BG-Active'] = { 22, 22 },
		['UF-DruidCP-Icon'] = { 14, 14 },
		['uf-holypower-rune1'] = { 18, 18 },
		['uf-holypower-rune1-active'] = { 23, 23 },
		['uf-holypower-rune2'] = { 20, 16 },
		['uf-holypower-rune2-active'] = { 24, 22 },
		['uf-holypower-rune3'] = { 17, 15 },
		['uf-holypower-rune3-active'] = { 23, 21 },
		['uf-holypower-rune4'] = { 15, 16 },
		['uf-holypower-rune4-active'] = { 21, 22 },
		['uf-holypower-rune5'] = { 18, 16 },
		['uf-holypower-rune5-active'] = { 22, 23 },
		['UF-SoulShard-Holder'] = { 23, 30 },
		['UF-SoulShard-Icon'] = { 15, 20 },
		['uf-chi-bg'] = { 25, 25 },
		['uf-chi-icon'] = { 14, 15 },
		['UF-Arcane-BG'] = { 21, 21 },
		['UF-Arcane-Icon'] = { 19, 19 },
		['UF-Essence-BG'] = { 24, 24 },
		['UF-Essence-Icon'] = { 24, 24 },
	},
}
