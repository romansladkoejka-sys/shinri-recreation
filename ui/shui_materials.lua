SHUI = SHUI or {}

SHUI.Materials = SHUI.Materials or {}

SHUI.Materials.Logo = Material("shinri_ui/logo.png", "smooth")

local INVENTORY_ROOT = "dro/sprites/inventory/"

local function InventoryMaterial(path)
    return Material(INVENTORY_ROOT .. path, "smooth")
end

SHUI.Materials.Inventory = {
    Tabs = {
        Inventory = {
            Inactive = InventoryMaterial("inventory_button_0.png"),
            Active = InventoryMaterial("inventory_button_1.png")
        },
        Description = {
            Inactive = InventoryMaterial("description_button_0.png"),
            Active = InventoryMaterial("description_button_1.png")
        },
        Appearance = {
            Inactive = InventoryMaterial("appearance_button_0.png"),
            Active = InventoryMaterial("appearance_button_1.png")
        }
    },

    Header = {
        Back = InventoryMaterial("back_button.png"),
        ArrowLeft = InventoryMaterial("header_arrow_left.png"),
        ArrowRight = InventoryMaterial("header_arrow_right.png"),
        BackgroundGradient = InventoryMaterial("bg_gradient_light.png"),
        BackgroundOverlay = InventoryMaterial("bg_overlay.png"),
        TitleFrame = InventoryMaterial("title_frame.png"),
        TitleFrameActive = InventoryMaterial("title_frame_active.png"),
        RarityFrame = InventoryMaterial("rarity_frame.png"),
        Repair = InventoryMaterial("repair.png"),
        Unique = InventoryMaterial("unique_icon.png")
    },

    Character = {
        Background = InventoryMaterial("char/char_bg.png"),
        Head = InventoryMaterial("char/head_frame.png"),
        Body = InventoryMaterial("char/body_frame.png"),
        Hands = InventoryMaterial("char/hands_frame.png"),
        Feet = InventoryMaterial("char/feet_frame.png"),
        Back = InventoryMaterial("char/back_frame.png"),
        WeaponLeft = InventoryMaterial("char/left_weapon_frame.png"),
        WeaponRight = InventoryMaterial("char/right_weapon_frame.png"),
        ArrowLeft = InventoryMaterial("char/left_arrow.png"),
        ArrowRight = InventoryMaterial("char/right_arrow.png"),
        Eye = InventoryMaterial("char/eye.png")
    },

    Inventory = {
        Slot = InventoryMaterial("inv/inventory_box.png"),
        Organize = InventoryMaterial("inv/organize_button.png"),
        Backpack = InventoryMaterial("inv/backpack_icon.png"),
        Bag = InventoryMaterial("inv/bag_icon.png"),
        Statistic = InventoryMaterial("inv/statistic_icon.png"),
        Character = InventoryMaterial("inv/character_icon.png"),
        Brush = InventoryMaterial("inv/brush_icon.png"),
        Chest = InventoryMaterial("inv/chest_icon.png"),
        Craft = InventoryMaterial("inv/craft_icon.png"),
        Equip = InventoryMaterial("inv/equip_icon.png"),
        Flag = InventoryMaterial("inv/flag_icon.png"),
        Food = InventoryMaterial("inv/food_icon.png"),
        Ingredient = InventoryMaterial("inv/ingr_icon.png"),
        Medical = InventoryMaterial("inv/med_icon.png"),
        Other = InventoryMaterial("inv/other_icon.png"),
        Pin = InventoryMaterial("inv/pin_icon.png"),
        Weapon = InventoryMaterial("inv/weapon_icon.png"),

        Item = {
            Ammo = InventoryMaterial("item/icon_ammo.png"),
            Durability = InventoryMaterial("item/icon_durability.png"),
            Energy = InventoryMaterial("item/icon_energy.png")
        },

        Crafting = {
            BackgroundOverlay = InventoryMaterial("craft/bg_overlay.png"),
            AllWorkshops = InventoryMaterial("craft/craft_all_workshops_icon.png"),
            ChemicalLaboratory = InventoryMaterial("craft/craft_chemical_laboratory_icon.png"),
            Stove = InventoryMaterial("craft/craft_stove_icon.png"),
            WeaponWorkbench = InventoryMaterial("craft/craft_weapon_workbench_icon.png"),
            Workbench = InventoryMaterial("craft/craft_workbench_icon.png"),
            PinInactive = InventoryMaterial("craft/pin_button_0.png"),
            PinActive = InventoryMaterial("craft/pin_button_1.png"),
            Pin = InventoryMaterial("craft/pin_icon.png"),
            RecipeBackground = InventoryMaterial("craft/recipe_bg_gradient.png"),
            RecipeSelected = InventoryMaterial("craft/recipe_select_bg_gradient.png")
        }
    },

    Status = {
        BarBackground = InventoryMaterial("status/bar_bg.png"),
        BarForeground = InventoryMaterial("status/bar_fg.png"),
        BarTicks = InventoryMaterial("status/bar_ticks.png"),
        BarStartTick = InventoryMaterial("status/bar_start_tick.png"),
        TemperatureBar = InventoryMaterial("status/bar_temperature.png"),
        BarPosition = InventoryMaterial("status/icon_bar_pos.png"),

        Health = InventoryMaterial("status/icon_health.png"),
        HealthSimple = InventoryMaterial("status/icon_health2.png"),
        HealthRound = InventoryMaterial("status/icon_health_round.png"),
        Stamina = InventoryMaterial("status/icon_stamina.png"),
        StaminaSimple = InventoryMaterial("status/icon_stamina2.png"),
        StaminaRound = InventoryMaterial("status/icon_stamina_round.png"),
        Hunger = InventoryMaterial("status/icon_hunger.png"),
        HungerSimple = InventoryMaterial("status/icon_hunger2.png"),
        HungerRound = InventoryMaterial("status/icon_hunger_round.png"),
        Sleepiness = InventoryMaterial("status/icon_sleepiness.png"),
        SleepinessSimple = InventoryMaterial("status/icon_sleepiness2.png"),
        SleepinessRound = InventoryMaterial("status/icon_sleepiness_round.png"),
        TemperatureSimple = InventoryMaterial("status/icon_temperature2.png"),

        BuffBackground = InventoryMaterial("status/buff_bg.png"),
        Buff = InventoryMaterial("status/buff_icon.png"),
        DebuffBackground = InventoryMaterial("status/debuff_bg.png"),
        Debuff = InventoryMaterial("status/debuff_icon.png")
    },

    Description = {
        Glow = InventoryMaterial("desc/ellipse_blur.png"),
        Frame = InventoryMaterial("desc/stat_frame.png"),
        Fingerprint = InventoryMaterial("desc/icon_fingerprint.png"),
        Footprint = InventoryMaterial("desc/icon_footprint.png"),
        Hunger = InventoryMaterial("desc/icon_hunger.png"),
        Sleepiness = InventoryMaterial("desc/icon_sleepiness.png"),
        Speed = InventoryMaterial("desc/icon_speed.png"),
        Stamina = InventoryMaterial("desc/icon_stamina.png"),
        Vision = InventoryMaterial("desc/icon_vision.png")
    }
}
