--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                   Naruto TRANSFORMATION SYSTEM v2.0                     ║
║                          Ulepszona Wersja dla TFS 1.x+                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

ULEPSZENIA W TEJ WERSJI:
✓ Lepsze cache'owanie i wydajność
✓ Walidacja danych transformacji
✓ Broadcast dla epickch transformacji
✓ Konfigurowalny cooldown
✓ Lepsze wiadomości dla gracza
✓ System logowania transformacji
✓ Bezpieczniejsze zarządzanie pamięcią
✓ Opcja wymagania itemów
✓ Statystyki transformacji

AUTOR: Zoptymalizowane przez AI
DATA: 2025
LICENSE: MIT
--]]

-- ════════════════════════════════════════════════════════════════════════════
-- KONFIGURACJA GLOBALNA
-- ════════════════════════════════════════════════════════════════════════════

local CONFIG = {
    -- Cooldown na użycie transform/revert (w sekundach)
    COOLDOWN = 1,
    
    -- Minimalna mana do utrzymania transformacji
    MIN_MANA_FOR_TRANSFORM = 10,
    
    -- Czy pokazywać broadcast przy ostatniej formie
    BROADCAST_FINAL_FORM = true,
    
    -- Czy wymagać itemu do transformacji (false = wyłączone)
    REQUIRE_TRANSFORM_ITEM = false,
    TRANSFORM_ITEM_ID = 2160, -- Crystal Coin jako przykład
    
    -- Czy logować transformacje do bazy (wymaga tabeli w SQL)
    LOG_TRANSFORMS = false,
    
    -- Efekt przy automatycznym revercie
    AUTO_REVERT_EFFECT = 2,
    
    -- Storage do cooldownu
    STORAGE_COOLDOWN = 45000,
    
    -- Storage do statystyk
    STORAGE_TRANSFORM_COUNT = 45001,
    
    -- Storage do ostatniej stałej formy (permanent vocation)
    STORAGE_LAST_PERMANENT_VOC = 45002,
    
    -- Storage do zapisania aktualnej vocation (żeby zachować ją po relogu)
    STORAGE_CURRENT_VOCATION = 45003,
}

-- ════════════════════════════════════════════════════════════════════════════
-- TABELA TRANSFORMACJI - Pełna konfiguracja
-- ════════════════════════════════════════════════════════════════════════════

local SystemTransformData = {
    -- SASUKE - Vocation 1-20
    -- currentLookType = look type dla obecnej vocation (używany przy loginie)
    -- newlookType = look type następnej vocation po transformacji
    
    -- Vocation 1: Look 1876 -> Transform -> Vocation 2 (Look 1881)
    [1] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1876,
        newlookType = 1881, revertlookType = 1876,
        maxhp = 100, maxmana = 100,
        newvoc = 2, revertvoc = 1,
        constanteffect = 0,
        name = "Sasuke Pierwotna Postać",
        isPermanent = true
    },
    -- Vocation 2: Look 1881 -> Transform -> Vocation 3 (Look 1877)
    [2] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 1881,
        newlookType = 1877, revertlookType = 1876,
        maxhp = 100, maxmana = 100, 
        newvoc = 3, revertvoc = 1,
        effect = 126, constanteffect = 99,
        name = "Sasuke Dwa",
        isPermanent = false
    },
    -- Vocation 3: Look 1877 -> Transform -> Vocation 4 (Look 2524)
    [3] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1877,
        newlookType = 2524, revertlookType = 1881,
        maxhp = 100, maxmana = 100, 
        newvoc = 4, revertvoc = 2,
        effect = 127, constanteffect = 99,
        name = "Sasuke Trzy",
        isPermanent = false
    },
    -- Vocation 4: Look 2524 -> Transform -> Vocation 5 (Look 1889)
    [4] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 2524,
        newlookType = 1889, revertlookType = 1877,
        maxhp = 100, maxmana = 100, 
        newvoc = 5, revertvoc = 3,
        effect = 128, constanteffect = 99,
        name = "Sasuke Cztery",
        isPermanent = false
    },
    -- Vocation 5: Look 1889 -> Transform -> Vocation 6 (Look 1878) - PERMANENT
    [5] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 1889,
        newlookType = 1878, revertlookType = 2524,
        maxhp = 100, maxmana = 100, 
        newvoc = 6, revertvoc = 4,
        effect = 130, constanteffect = 0,
        name = "Sasuke Pięć",
        isPermanent = true
    },
    -- Vocation 6: Look 1878 -> Transform -> Vocation 7 (Look 1882) - PERMANENT (nie można cofnąć)
    [6] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 1878,
        newlookType = 1882, revertlookType = 1889,
        maxhp = 100, maxmana = 100, 
        newvoc = 7, revertvoc = 5,
        effect = 131, constanteffect = 0,
        name = "Sasuke Sześć",
        isPermanent = true
    },
    -- Vocation 7: 1882 -> Transform do voc 8 (1880)
    [7] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1882,
        newlookType = 1880, revertlookType = 1878,
        maxhp = 100, maxmana = 100, 
        newvoc = 8, revertvoc = 6,
        effect = 149, constanteffect = 99,
        name = "Sasuke Siedem",
        isPermanent = false
    },
    -- Vocation 8: 1880 -> Transform do voc 9 (1879)
    [8] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 1880,
        newlookType = 1879, revertlookType = 1882,
        maxhp = 100, maxmana = 100, 
        newvoc = 9, revertvoc = 7,
        effect = 150, constanteffect = 99,
        name = "Sasuke Osiem",
        isPermanent = false
    },
    -- Vocation 9: 1879 -> Transform do voc 10 (1885)
    [9] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1879,
        newlookType = 1885, revertlookType = 1880,
        maxhp = 100, maxmana = 100, 
        newvoc = 10, revertvoc = 8,
        effect = 152, constanteffect = 99,
        name = "Sasuke Dziewięć",
        isPermanent = false
    },
    -- Vocation 10: 1885 -> Transform do voc 11 (1884)
    [10] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 1885,
        newlookType = 1884, revertlookType = 1879,
        maxhp = 100, maxmana = 100, 
        newvoc = 11, revertvoc = 9,
        effect = 257, constanteffect = 99,
        name = "Sasuke Dziesięć",
        isPermanent = false
    },
    -- Vocation 11: 1884 -> Transform do voc 12 (1886)
    [11] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 1884,
        newlookType = 1886, revertlookType = 1885,
        maxhp = 100, maxmana = 100, 
        newvoc = 12, revertvoc = 10,
        effect = 331, constanteffect = 99,
        name = "Sasuke Jedenaście",
        isPermanent = false
    },
    -- Vocation 12: 1886 -> Transform do voc 13 (1883)
    [12] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1886,
        newlookType = 1883, revertlookType = 1884,
        maxhp = 100, maxmana = 100, 
        newvoc = 13, revertvoc = 11,
        effect = 126, constanteffect = 99,
        name = "Sasuke Dwanaście",
        isPermanent = false
    },
    -- Vocation 13: 1883 -> Transform do voc 14 (1891) - PERMANENT (nie można cofnąć)
    [13] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 1883,
        newlookType = 1891, revertlookType = 1886,
        maxhp = 100, maxmana = 100, 
        newvoc = 14, revertvoc = 12,
        effect = 127, constanteffect = 0,
        name = "Sasuke Trzynaście",
        isPermanent = true
    },
    -- Vocation 14: 1891 -> Transform do voc 15 (1890)
    [14] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 1891,
        newlookType = 1890, revertlookType = 1883,
        maxhp = 100, maxmana = 100, 
        newvoc = 15, revertvoc = 13,
        effect = 128, constanteffect = 99,
        name = "Sasuke Czternaście",
        isPermanent = false
    },
    -- Vocation 15: 1890 -> Transform do voc 16 (2407) - PERMANENT (nie można cofnąć)
    [15] = { 
        lvl = 7, manaPerSec = 0,
        currentLookType = 1890,
        newlookType = 2407, revertlookType = 1891,
        maxhp = 100, maxmana = 100, 
        newvoc = 16, revertvoc = 14,
        effect = 130, constanteffect = 0,
        name = "Sasuke Piętnaście",
        isPermanent = true
    },
    -- Vocation 16: 2407 -> Transform do voc 17 (1892)
    [16] = { 
        lvl = 8, manaPerSec = 10,
        currentLookType = 2407,
        newlookType = 1892, revertlookType = 1890,
        maxhp = 100, maxmana = 100, 
        newvoc = 17, revertvoc = 15,
        effect = 131, constanteffect = 99,
        name = "Sasuke Szesnaście",
        isPermanent = false
    },
    -- Vocation 17: 1892 -> Transform do voc 18 (1893)
    [17] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 1892,
        newlookType = 1893, revertlookType = 2407,
        maxhp = 100, maxmana = 100, 
        newvoc = 18, revertvoc = 16,
        effect = 149, constanteffect = 99,
        name = "Sasuke Siedemnaście",
        isPermanent = false
    },
    -- Vocation 18: 1893 -> Transform do voc 19 (2279)
    [18] = { 
        lvl = 7, manaPerSec = 10,
        currentLookType = 1893,
        newlookType = 2279, revertlookType = 1892,
        maxhp = 100, maxmana = 100, 
        newvoc = 19, revertvoc = 17,
        effect = 150, constanteffect = 99,
        name = "Sasuke Osiemnaście",
        isPermanent = false
    },
    -- Vocation 19: 2279 -> Transform do voc 20 (2280) - PERMANENT (nie można cofnąć)
    [19] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2279,
        newlookType = 2280, revertlookType = 1893,
        maxhp = 100, maxmana = 100, 
        newvoc = 20, revertvoc = 18,
        effect = 152, constanteffect = 0,
        name = "Sasuke Dziewiętnaście",
        isPermanent = true
    },
    -- Vocation 20: 2280 - FORMA FINALNA - PERMANENT (nie można cofnąć)
    [20] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 2280,
        newlookType = 2280, revertlookType = 2279,
        maxhp = 100, maxmana = 100, 
        newvoc = 20, revertvoc = 19,
        effect = 351, constanteffect = 0,
        name = "Sasuke Dwadzieścia - Forma Finalna",
        isPermanent = true,
        isFinalForm = true
    },

    -- ════════════════════════════════════════════════════════════════════════
    -- NARUTO TRANSFORMATION SYSTEM - Vocation 31-60
    -- ════════════════════════════════════════════════════════════════════════
    
    -- Vocation 31: Look 2240 - FORMA BAZOWA NARUTO (PERMANENT)
    [31] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2240,
        newlookType = 2241, revertlookType = 2240,
        maxhp = 100, maxmana = 100,
        newvoc = 32, revertvoc = 31,
        constanteffect = 0,
        name = "Naruto Pierwotna Postać",
        isPermanent = true
    },
    -- Vocation 32: Look 2241 -> Transform -> Vocation 33 (Look 2066)
    [32] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 2241,
        newlookType = 2066, revertlookType = 2240,
        maxhp = 100, maxmana = 100, 
        newvoc = 33, revertvoc = 31,
        effect = 126, constanteffect = 99,
        name = "Naruto Dwa",
        isPermanent = false
    },
    -- Vocation 33: Look 2066 -> Transform -> Vocation 34 (Look 2233)
    [33] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2066,
        newlookType = 2233, revertlookType = 2241,
        maxhp = 100, maxmana = 100, 
        newvoc = 34, revertvoc = 32,
        effect = 127, constanteffect = 99,
        name = "Naruto Trzy",
        isPermanent = false
    },
    -- Vocation 34: Look 2233 -> Transform -> Vocation 35 (Look 2231)
    [34] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 2233,
        newlookType = 2231, revertlookType = 2066,
        maxhp = 100, maxmana = 100, 
        newvoc = 35, revertvoc = 33,
        effect = 128, constanteffect = 99,
        name = "Naruto Cztery",
        isPermanent = false
    },
    -- Vocation 35: Look 2231 -> Transform -> Vocation 36 (Look 2228)
    [35] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2231,
        newlookType = 2228, revertlookType = 2233,
        maxhp = 100, maxmana = 100, 
        newvoc = 36, revertvoc = 34,
        effect = 130, constanteffect = 99,
        name = "Naruto Pięć",
        isPermanent = false
    },
    -- Vocation 36: Look 2228 -> Transform -> Vocation 37 (Look 2065)
    [36] = { 
        lvl = 2, manaPerSec = 10,
        currentLookType = 2228,
        newlookType = 2065, revertlookType = 2231,
        maxhp = 100, maxmana = 100, 
        newvoc = 37, revertvoc = 35,
        effect = 131, constanteffect = 99,
        name = "Naruto Sześć",
        isPermanent = false
    },
    -- Vocation 37: Look 2065 -> Transform -> Vocation 38 (Look 2067) - PERMANENT
    [37] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 2065,
        newlookType = 2067, revertlookType = 2228,
        maxhp = 100, maxmana = 100, 
        newvoc = 38, revertvoc = 36,
        effect = 149, constanteffect = 0,
        name = "Naruto Siedem",
        isPermanent = true
    },
    -- Vocation 38: Look 2067 -> Transform -> Vocation 39 (Look 2230)
    [38] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 2067,
        newlookType = 2230, revertlookType = 2065,
        maxhp = 100, maxmana = 100, 
        newvoc = 39, revertvoc = 37,
        effect = 150, constanteffect = 99,
        name = "Naruto Osiem",
        isPermanent = false
    },
    -- Vocation 39: Look 2230 -> Transform -> Vocation 40 (Look 2143)
    [39] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2230,
        newlookType = 2143, revertlookType = 2067,
        maxhp = 100, maxmana = 100, 
        newvoc = 40, revertvoc = 38,
        effect = 152, constanteffect = 99,
        name = "Naruto Dziewięć",
        isPermanent = false
    },
    -- Vocation 40: Look 2143 -> Transform -> Vocation 41 (Look 2232)
    [40] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 2143,
        newlookType = 2232, revertlookType = 2230,
        maxhp = 100, maxmana = 100, 
        newvoc = 41, revertvoc = 39,
        effect = 257, constanteffect = 99,
        name = "Naruto Dziesięć",
        isPermanent = false
    },
    -- Vocation 41: Look 2232 -> Transform -> Vocation 42 (Look 2229) - PERMANENT
    [41] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 2232,
        newlookType = 2229, revertlookType = 2143,
        maxhp = 100, maxmana = 100, 
        newvoc = 42, revertvoc = 40,
        effect = 331, constanteffect = 0,
        name = "Naruto Jedenaście",
        isPermanent = true
    },
    -- Vocation 42: Look 2229 -> Transform -> Vocation 43 (Look 2176) - PERMANENT
    [42] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 2229,
        newlookType = 2176, revertlookType = 2232,
        maxhp = 100, maxmana = 100, 
        newvoc = 43, revertvoc = 41,
        effect = 126, constanteffect = 0,
        name = "Naruto Dwanaście",
        isPermanent = true
    },
    -- Vocation 43: Look 2176 -> Transform -> Vocation 44 (Look 2521)
    [43] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2176,
        newlookType = 2521, revertlookType = 2229,
        maxhp = 100, maxmana = 100, 
        newvoc = 44, revertvoc = 42,
        effect = 127, constanteffect = 99,
        name = "Naruto Trzynaście",
        isPermanent = false
    },
    -- Vocation 44: Look 2521 -> Transform -> Vocation 45 (Look 2238)
    [44] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2521,
        newlookType = 2238, revertlookType = 2176,
        maxhp = 100, maxmana = 100, 
        newvoc = 45, revertvoc = 43,
        effect = 128, constanteffect = 99,
        name = "Naruto Czternaście",
        isPermanent = false
    },
    -- Vocation 45: Look 2238 -> Transform -> Vocation 46 (Look 2236) - PERMANENT
    [45] = { 
        lvl = 7, manaPerSec = 0,
        currentLookType = 2238,
        newlookType = 2236, revertlookType = 2521,
        maxhp = 100, maxmana = 100, 
        newvoc = 46, revertvoc = 44,
        effect = 130, constanteffect = 0,
        name = "Naruto Piętnaście",
        isPermanent = true
    },
    -- Vocation 46: Look 2236 -> Transform -> Vocation 47 (Look 2239)
    [46] = { 
        lvl = 8, manaPerSec = 10,
        currentLookType = 2236,
        newlookType = 2239, revertlookType = 2238,
        maxhp = 100, maxmana = 100, 
        newvoc = 47, revertvoc = 45,
        effect = 131, constanteffect = 99,
        name = "Naruto Szesnaście",
        isPermanent = false
    },
    -- Vocation 47: Look 2239 -> Transform -> Vocation 48 (Look 2237)
    [47] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2239,
        newlookType = 2237, revertlookType = 2236,
        maxhp = 100, maxmana = 100, 
        newvoc = 48, revertvoc = 46,
        effect = 149, constanteffect = 99,
        name = "Naruto Siedemnaście",
        isPermanent = false
    },
    -- Vocation 48: Look 2237 -> Transform -> Vocation 49 (Look 2161)
    [48] = { 
        lvl = 7, manaPerSec = 10,
        currentLookType = 2237,
        newlookType = 2161, revertlookType = 2239,
        maxhp = 100, maxmana = 100, 
        newvoc = 49, revertvoc = 47,
        effect = 150, constanteffect = 99,
        name = "Naruto Osiemnaście",
        isPermanent = false
    },
    -- Vocation 49: Look 2161 -> Transform -> Vocation 50 (Look 2235)
    [49] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 2161,
        newlookType = 2235, revertlookType = 2237,
        maxhp = 100, maxmana = 100, 
        newvoc = 50, revertvoc = 48,
        effect = 152, constanteffect = 99,
        name = "Naruto Dziewiętnaście",
        isPermanent = false
    },
    -- Vocation 50: Look 2235 -> Transform -> Vocation 51 (Look 2201)
    [50] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2235,
        newlookType = 2201, revertlookType = 2161,
        maxhp = 100, maxmana = 100, 
        newvoc = 51, revertvoc = 49,
        effect = 351, constanteffect = 99,
        name = "Naruto Dwadzieścia",
        isPermanent = false
    },
    -- Vocation 51: Look 2201 -> Transform -> Vocation 52 (Look 2072)
    [51] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2201,
        newlookType = 2072, revertlookType = 2235,
        maxhp = 100, maxmana = 100, 
        newvoc = 52, revertvoc = 50,
        effect = 126, constanteffect = 99,
        name = "Naruto Dwadzieścia Jeden",
        isPermanent = false
    },
    -- Vocation 52: Look 2072 -> Transform -> Vocation 53 (Look pusty - używamy 2072)
    [52] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2072,
        newlookType = 2072, revertlookType = 2201,
        maxhp = 100, maxmana = 100, 
        newvoc = 53, revertvoc = 51,
        effect = 127, constanteffect = 99,
        name = "Naruto Dwadzieścia Dwa",
        isPermanent = false
    },
    -- Vocation 53: Look pusty (używamy 2072) -> Transform -> Vocation 54 (Look 2049)
    [53] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2072,
        newlookType = 2049, revertlookType = 2072,
        maxhp = 100, maxmana = 100, 
        newvoc = 54, revertvoc = 52,
        effect = 128, constanteffect = 99,
        name = "Naruto Dwadzieścia Trzy",
        isPermanent = false
    },
    -- Vocation 54: Look 2049 -> Transform -> Vocation 55 (Look 1925)
    [54] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2049,
        newlookType = 1925, revertlookType = 2072,
        maxhp = 100, maxmana = 100, 
        newvoc = 55, revertvoc = 53,
        effect = 130, constanteffect = 99,
        name = "Naruto Dwadzieścia Cztery",
        isPermanent = false
    },
    -- Vocation 55: Look 1925 -> OSTATNIA FORMA (placeholder do 60)
    [55] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1925,
        newlookType = 1925, revertlookType = 2049,
        maxhp = 100, maxmana = 100, 
        newvoc = 56, revertvoc = 54,
        effect = 131, constanteffect = 99,
        name = "Naruto Dwadzieścia Pięć",
        isPermanent = false
    },
    -- Vocation 56-60: Placeholder (do uzupełnienia look types)
    [56] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1925,
        newlookType = 1925, revertlookType = 1925,
        maxhp = 100, maxmana = 100, 
        newvoc = 57, revertvoc = 55,
        effect = 149, constanteffect = 99,
        name = "Naruto Dwadzieścia Sześć",
        isPermanent = false
    },
    [57] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1925,
        newlookType = 1925, revertlookType = 1925,
        maxhp = 100, maxmana = 100, 
        newvoc = 58, revertvoc = 56,
        effect = 150, constanteffect = 99,
        name = "Naruto Dwadzieścia Siedem",
        isPermanent = false
    },
    [58] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1925,
        newlookType = 1925, revertlookType = 1925,
        maxhp = 100, maxmana = 100, 
        newvoc = 59, revertvoc = 57,
        effect = 152, constanteffect = 99,
        name = "Naruto Dwadzieścia Osiem",
        isPermanent = false
    },
    [59] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1925,
        newlookType = 1925, revertlookType = 1925,
        maxhp = 100, maxmana = 100, 
        newvoc = 60, revertvoc = 58,
        effect = 257, constanteffect = 99,
        name = "Naruto Dwadzieścia Dziewięć",
        isPermanent = false
    },
    [60] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 1925,
        newlookType = 1925, revertlookType = 1925,
        maxhp = 100, maxmana = 100, 
        newvoc = 60, revertvoc = 59,
        effect = 331, constanteffect = 0,
        name = "Naruto Trzydzieści - HOKAGE FORM",
        isPermanent = true,
        isFinalForm = true
    },

    -- ════════════════════════════════════════════════════════════════════════
    -- SAKURA TRANSFORMATION SYSTEM - Vocation 61-90
    -- ════════════════════════════════════════════════════════════════════════
    
    -- Vocation 61: Look 2258 - FORMA BAZOWA SAKURA (PERMANENT)
    [61] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2258,
        newlookType = 2255, revertlookType = 2258,
        maxhp = 100, maxmana = 100,
        newvoc = 62, revertvoc = 61,
        constanteffect = 0,
        name = "Sakura Pierwotna Postać",
        isPermanent = true
    },
    -- Vocation 62: Look 2255 -> Transform -> Vocation 63 (Look 2253)
    [62] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 2255,
        newlookType = 2253, revertlookType = 2258,
        maxhp = 100, maxmana = 100, 
        newvoc = 63, revertvoc = 61,
        effect = 126, constanteffect = 99,
        name = "Sakura Dwa",
        isPermanent = false
    },
    -- Vocation 63: Look 2253 -> Transform -> Vocation 64 (Look 2251) - PERMANENT
    [63] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 2253,
        newlookType = 2251, revertlookType = 2255,
        maxhp = 100, maxmana = 100, 
        newvoc = 64, revertvoc = 62,
        effect = 127, constanteffect = 0,
        name = "Sakura Trzy",
        isPermanent = true
    },
    -- Vocation 64: Look 2251 -> Transform -> Vocation 65 (Look 2252)
    [64] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 2251,
        newlookType = 2252, revertlookType = 2253,
        maxhp = 100, maxmana = 100, 
        newvoc = 65, revertvoc = 63,
        effect = 128, constanteffect = 99,
        name = "Sakura Cztery",
        isPermanent = false
    },
    -- Vocation 65: Look 2252 -> Transform -> Vocation 66 (Look 2257)
    [65] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2252,
        newlookType = 2257, revertlookType = 2251,
        maxhp = 100, maxmana = 100, 
        newvoc = 66, revertvoc = 64,
        effect = 130, constanteffect = 99,
        name = "Sakura Pięć",
        isPermanent = false
    },
    -- Vocation 66: Look 2257 -> Transform -> Vocation 67 (Look 2256) - PERMANENT
    [66] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2257,
        newlookType = 2256, revertlookType = 2252,
        maxhp = 100, maxmana = 100, 
        newvoc = 67, revertvoc = 65,
        effect = 131, constanteffect = 0,
        name = "Sakura Sześć",
        isPermanent = true
    },
    -- Vocation 67: Look 2256 -> Transform -> Vocation 68 (Look 2254) - PERMANENT
    [67] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 2256,
        newlookType = 2254, revertlookType = 2257,
        maxhp = 100, maxmana = 100, 
        newvoc = 68, revertvoc = 66,
        effect = 149, constanteffect = 0,
        name = "Sakura Siedem",
        isPermanent = true
    },
    -- Vocation 68: Look 2254 -> Transform -> Vocation 69 (Look 2259) - PERMANENT
    [68] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 2254,
        newlookType = 2259, revertlookType = 2256,
        maxhp = 100, maxmana = 100, 
        newvoc = 69, revertvoc = 67,
        effect = 150, constanteffect = 0,
        name = "Sakura Osiem",
        isPermanent = true
    },
    -- Vocation 69: Look 2259 -> Transform -> Vocation 70 (Look 2260) - PERMANENT
    [69] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 2259,
        newlookType = 2260, revertlookType = 2254,
        maxhp = 100, maxmana = 100, 
        newvoc = 70, revertvoc = 68,
        effect = 152, constanteffect = 0,
        name = "Sakura Dziewięć",
        isPermanent = true
    },
    -- Vocation 70: Look 2260 -> Transform -> Vocation 71 (Look 2261) - PERMANENT
    [70] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 2260,
        newlookType = 2261, revertlookType = 2259,
        maxhp = 100, maxmana = 100, 
        newvoc = 71, revertvoc = 69,
        effect = 257, constanteffect = 0,
        name = "Sakura Dziesięć",
        isPermanent = true
    },
    -- Vocation 71: Look 2261 -> Transform -> Vocation 72 (Look 2262) - PERMANENT (manaPerSec = 10!)
    [71] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 2261,
        newlookType = 2262, revertlookType = 2260,
        maxhp = 100, maxmana = 100, 
        newvoc = 72, revertvoc = 70,
        effect = 331, constanteffect = 99,
        name = "Sakura Jedenaście",
        isPermanent = true
    },
    -- Vocation 72: Look 2262 -> Transform -> Vocation 73 (Look 2410)
    [72] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2262,
        newlookType = 2410, revertlookType = 2261,
        maxhp = 100, maxmana = 100, 
        newvoc = 73, revertvoc = 71,
        effect = 126, constanteffect = 99,
        name = "Sakura Dwanaście",
        isPermanent = false
    },
    -- Vocation 73: Look 2410 -> Placeholder (do uzupełnienia)
    [73] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 2410,
        newlookType = 2410, revertlookType = 2262,
        maxhp = 100, maxmana = 100, 
        newvoc = 73, revertvoc = 72,
        effect = 127, constanteffect = 0,
        name = "Sakura Trzynaście - LEGENDARY MEDICAL NINJA",
        isPermanent = true,
        isFinalForm = true
    },

    -- ════════════════════════════════════════════════════════════════════════
    -- ITACHI TRANSFORMATION SYSTEM - Vocation 91-120
    -- ════════════════════════════════════════════════════════════════════════
    
    -- Vocation 91: Look 1894 - FORMA BAZOWA ITACHI (PERMANENT)
    [91] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1894,
        newlookType = 1895, revertlookType = 1894,
        maxhp = 100, maxmana = 100,
        newvoc = 92, revertvoc = 91,
        constanteffect = 0,
        name = "Itachi Pierwotna Postać",
        isPermanent = true
    },
    -- Vocation 92: Look 1895 -> Transform -> Vocation 93 (Look 1902)
    [92] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 1895,
        newlookType = 1902, revertlookType = 1894,
        maxhp = 100, maxmana = 100, 
        newvoc = 93, revertvoc = 91,
        effect = 126, constanteffect = 99,
        name = "Itachi Dwa",
        isPermanent = false
    },
    -- Vocation 93: Look 1902 -> Transform -> Vocation 94 (Look 1899)
    [93] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1902,
        newlookType = 1899, revertlookType = 1895,
        maxhp = 100, maxmana = 100, 
        newvoc = 94, revertvoc = 92,
        effect = 127, constanteffect = 99,
        name = "Itachi Trzy",
        isPermanent = false
    },
    -- Vocation 94: Look 1899 -> Transform -> Vocation 95 (Look 1896) - PERMANENT
    [94] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1899,
        newlookType = 1896, revertlookType = 1902,
        maxhp = 100, maxmana = 100, 
        newvoc = 95, revertvoc = 93,
        effect = 128, constanteffect = 0,
        name = "Itachi Cztery",
        isPermanent = true
    },
    -- Vocation 95: Look 1896 -> Transform -> Vocation 96 (Look 2420)
    [95] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1896,
        newlookType = 2420, revertlookType = 1899,
        maxhp = 100, maxmana = 100, 
        newvoc = 96, revertvoc = 94,
        effect = 130, constanteffect = 99,
        name = "Itachi Pięć",
        isPermanent = false
    },
    -- Vocation 96: Look 2420 -> Transform -> Vocation 97 (Look 1897) - PERMANENT
    [96] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2420,
        newlookType = 1897, revertlookType = 1896,
        maxhp = 100, maxmana = 100, 
        newvoc = 97, revertvoc = 95,
        effect = 131, constanteffect = 0,
        name = "Itachi Sześć",
        isPermanent = true
    },
    -- Vocation 97: Look 1897 -> Transform -> Vocation 98 (Look 1900)
    [97] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1897,
        newlookType = 1900, revertlookType = 2420,
        maxhp = 100, maxmana = 100, 
        newvoc = 98, revertvoc = 96,
        effect = 149, constanteffect = 99,
        name = "Itachi Siedem",
        isPermanent = false
    },
    -- Vocation 98: Look 1900 -> Transform -> Vocation 99 (Look 1901)
    [98] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 1900,
        newlookType = 1901, revertlookType = 1897,
        maxhp = 100, maxmana = 100, 
        newvoc = 99, revertvoc = 97,
        effect = 150, constanteffect = 99,
        name = "Itachi Osiem",
        isPermanent = false
    },
    -- Vocation 99: Look 1901 -> Transform -> Vocation 100 (Look 1898) - PERMANENT
    [99] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 1901,
        newlookType = 1898, revertlookType = 1900,
        maxhp = 100, maxmana = 100, 
        newvoc = 100, revertvoc = 98,
        effect = 152, constanteffect = 0,
        name = "Itachi Dziewięć",
        isPermanent = true
    },
    -- Vocation 100: Look 1898 -> Transform -> Vocation 101 (Look 1920)
    [100] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 1898,
        newlookType = 1920, revertlookType = 1901,
        maxhp = 100, maxmana = 100, 
        newvoc = 101, revertvoc = 99,
        effect = 257, constanteffect = 99,
        name = "Itachi Dziesięć",
        isPermanent = false
    },
    -- Vocation 101: Look 1920 -> Transform -> Vocation 102 (Look 1921) - PERMANENT
    [101] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 1920,
        newlookType = 1921, revertlookType = 1898,
        maxhp = 100, maxmana = 100, 
        newvoc = 102, revertvoc = 100,
        effect = 331, constanteffect = 0,
        name = "Itachi Jedenaście",
        isPermanent = true
    },
    -- Vocation 102: Look 1921 -> Transform -> Vocation 103 (Look 1922)
    [102] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1921,
        newlookType = 1922, revertlookType = 1920,
        maxhp = 100, maxmana = 100, 
        newvoc = 103, revertvoc = 101,
        effect = 126, constanteffect = 99,
        name = "Itachi Dwanaście",
        isPermanent = false
    },
    -- Vocation 103: Look 1922 -> Transform -> Vocation 104 (Look placeholder)
    [103] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1922,
        newlookType = 1922, revertlookType = 1921,
        maxhp = 100, maxmana = 100, 
        newvoc = 104, revertvoc = 102,
        effect = 127, constanteffect = 99,
        name = "Itachi Trzynaście",
        isPermanent = false
    },
    -- Vocation 104: Look placeholder -> Transform -> Vocation 105 (Look placeholder)
    [104] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 1922,
        newlookType = 1922, revertlookType = 1922,
        maxhp = 100, maxmana = 100, 
        newvoc = 105, revertvoc = 103,
        effect = 128, constanteffect = 99,
        name = "Itachi Czternaście",
        isPermanent = false
    },
    -- Vocation 105: Look placeholder -> Transform -> Vocation 106 (Look 1903)
    [105] = { 
        lvl = 7, manaPerSec = 10,
        currentLookType = 1922,
        newlookType = 1903, revertlookType = 1922,
        maxhp = 100, maxmana = 100, 
        newvoc = 106, revertvoc = 104,
        effect = 130, constanteffect = 99,
        name = "Itachi Piętnaście",
        isPermanent = false
    },
    -- Vocation 106: Look 1903 -> Transform -> Vocation 107 (Look 2159)
    [106] = { 
        lvl = 8, manaPerSec = 10,
        currentLookType = 1903,
        newlookType = 2159, revertlookType = 1922,
        maxhp = 100, maxmana = 100, 
        newvoc = 107, revertvoc = 105,
        effect = 131, constanteffect = 99,
        name = "Itachi Szesnaście",
        isPermanent = false
    },
    -- Vocation 107: Look 2159 -> Transform -> Vocation 108 (Look 1904)
    [107] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2159,
        newlookType = 1904, revertlookType = 1903,
        maxhp = 100, maxmana = 100, 
        newvoc = 108, revertvoc = 106,
        effect = 149, constanteffect = 99,
        name = "Itachi Siedemnaście",
        isPermanent = false
    },
    -- Vocation 108: Look 1904 -> Transform -> Vocation 109 (Look 2281) - PERMANENT
    [108] = { 
        lvl = 7, manaPerSec = 0,
        currentLookType = 1904,
        newlookType = 2281, revertlookType = 2159,
        maxhp = 100, maxmana = 100, 
        newvoc = 109, revertvoc = 107,
        effect = 150, constanteffect = 0,
        name = "Itachi Osiemnaście",
        isPermanent = true
    },
    -- Vocation 109: Look 2281 -> Transform -> Vocation 110 (Look 2282) - PERMANENT
    [109] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2281,
        newlookType = 2282, revertlookType = 1904,
        maxhp = 100, maxmana = 100, 
        newvoc = 110, revertvoc = 108,
        effect = 152, constanteffect = 0,
        name = "Itachi Dziewiętnaście",
        isPermanent = true
    },
    -- Vocation 110: Look 2282 -> Transform -> Vocation 111 (Look 2207)
    [110] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2282,
        newlookType = 2207, revertlookType = 2281,
        maxhp = 100, maxmana = 100, 
        newvoc = 111, revertvoc = 109,
        effect = 351, constanteffect = 99,
        name = "Itachi Dwadzieścia",
        isPermanent = false
    },
    -- Vocation 111: Look 2207 -> Transform -> Vocation 112 (Look 2285)
    [111] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2207,
        newlookType = 2285, revertlookType = 2282,
        maxhp = 100, maxmana = 100, 
        newvoc = 112, revertvoc = 110,
        effect = 126, constanteffect = 99,
        name = "Itachi Dwadzieścia Jeden",
        isPermanent = false
    },
    -- Vocation 112: Look 2285 -> Transform -> Vocation 113 (Look 2522) - PERMANENT
    [112] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 2285,
        newlookType = 2522, revertlookType = 2207,
        maxhp = 100, maxmana = 100, 
        newvoc = 113, revertvoc = 111,
        effect = 127, constanteffect = 0,
        name = "Itachi Dwadzieścia Dwa",
        isPermanent = true
    },
    -- Vocation 113: Look 2522 -> Transform -> Vocation 114 (placeholder) - ostatnia forma z danymi
    [113] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2522,
        newlookType = 2522, revertlookType = 2285,
        maxhp = 100, maxmana = 100, 
        newvoc = 114, revertvoc = 112,
        effect = 128, constanteffect = 99,
        name = "Itachi Dwadzieścia Trzy",
        isPermanent = false
    },
    
    -- ════════════════════════════════════════════════════════════════════════════
    -- SHISUI TRANSFORMATION SYSTEM (Vocation 121-150)
    -- ════════════════════════════════════════════════════════════════════════════
    
    -- Vocation 121: Look 2215 -> Transform -> Vocation 122 (Look 2216) - PERMANENT
    [121] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2215,
        newlookType = 2216, revertlookType = 2215,
        maxhp = 100, maxmana = 100, 
        newvoc = 122, revertvoc = 121,
        effect = 66, constanteffect = 0,
        name = "Shisui Pierwotna Postać",
        isPermanent = true
    },
    -- Vocation 122: Look 2216 -> Transform -> Vocation 123 (Look 2217)
    [122] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 2216,
        newlookType = 2217, revertlookType = 2215,
        maxhp = 100, maxmana = 100, 
        newvoc = 123, revertvoc = 121,
        effect = 150, constanteffect = 99,
        name = "Shisui Dwa",
        isPermanent = false
    },
    -- Vocation 123: Look 2217 -> Transform -> Vocation 124 (Look 2218) - PERMANENT
    [123] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2217,
        newlookType = 2218, revertlookType = 2216,
        maxhp = 100, maxmana = 100, 
        newvoc = 124, revertvoc = 122,
        effect = 152, constanteffect = 0,
        name = "Shisui Trzy",
        isPermanent = true
    },
    -- Vocation 124: Look 2218 -> Transform -> Vocation 125 (Look 2219)
    [124] = { 
        lvl = 2, manaPerSec = 10,
        currentLookType = 2218,
        newlookType = 2219, revertlookType = 2217,
        maxhp = 100, maxmana = 100, 
        newvoc = 125, revertvoc = 123,
        effect = 331, constanteffect = 99,
        name = "Shisui Cztery",
        isPermanent = false
    },
    -- Vocation 125: Look 2219 -> Transform -> Vocation 126 (Look 2220) - PERMANENT
    [125] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 2219,
        newlookType = 2220, revertlookType = 2218,
        maxhp = 100, maxmana = 100, 
        newvoc = 126, revertvoc = 124,
        effect = 257, constanteffect = 0,
        name = "Shisui Pięć",
        isPermanent = true
    },
    -- Vocation 126: Look 2220 -> Transform -> Vocation 127 (Look 2221)
    [126] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 2220,
        newlookType = 2221, revertlookType = 2219,
        maxhp = 100, maxmana = 100, 
        newvoc = 127, revertvoc = 125,
        effect = 126, constanteffect = 99,
        name = "Shisui Sześć",
        isPermanent = false
    },
    -- Vocation 127: Look 2221 -> Transform -> Vocation 128 (Look 2222) - PERMANENT
    [127] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 2221,
        newlookType = 2222, revertlookType = 2220,
        maxhp = 100, maxmana = 100, 
        newvoc = 128, revertvoc = 126,
        effect = 127, constanteffect = 0,
        name = "Shisui Siedem",
        isPermanent = true
    },
    -- Vocation 128: Look 2222 -> Transform -> Vocation 129 (Look 2224)
    [128] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 2222,
        newlookType = 2224, revertlookType = 2221,
        maxhp = 100, maxmana = 100, 
        newvoc = 129, revertvoc = 127,
        effect = 128, constanteffect = 99,
        name = "Shisui Osiem",
        isPermanent = false
    },
    -- Vocation 129: Look 2224 -> Transform -> Vocation 130 (Look 2223) - PERMANENT
    [129] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 2224,
        newlookType = 2223, revertlookType = 2222,
        maxhp = 100, maxmana = 100, 
        newvoc = 130, revertvoc = 128,
        effect = 130, constanteffect = 0,
        name = "Shisui Dziewięć",
        isPermanent = true
    },
    -- Vocation 130: Look 2223 -> Transform -> Vocation 131 (Look 2225)
    [130] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2223,
        newlookType = 2225, revertlookType = 2224,
        maxhp = 100, maxmana = 100, 
        newvoc = 131, revertvoc = 129,
        effect = 131, constanteffect = 99,
        name = "Shisui Dziesięć",
        isPermanent = false
    },
    -- Vocation 131: Look 2225 -> Transform -> Vocation 132 (Look 2226) - PERMANENT (z manaPerSec=10)
    [131] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2225,
        newlookType = 2226, revertlookType = 2223,
        maxhp = 100, maxmana = 100, 
        newvoc = 132, revertvoc = 130,
        effect = 149, constanteffect = 99,
        name = "Shisui Jedenaście",
        isPermanent = true
    },
    -- Vocation 132: Look 2226 -> Transform -> Vocation 133 (Look 2209)
    [132] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2226,
        newlookType = 2209, revertlookType = 2225,
        maxhp = 100, maxmana = 100, 
        newvoc = 133, revertvoc = 131,
        effect = 150, constanteffect = 99,
        name = "Shisui Dwanaście",
        isPermanent = false
    },
    -- Vocation 133: Look 2209 -> Transform -> Vocation 134 (Look 2210) - PERMANENT
    [133] = { 
        lvl = 7, manaPerSec = 0,
        currentLookType = 2209,
        newlookType = 2210, revertlookType = 2226,
        maxhp = 100, maxmana = 100, 
        newvoc = 134, revertvoc = 132,
        effect = 152, constanteffect = 0,
        name = "Shisui Trzynaście",
        isPermanent = true
    },
    -- Vocation 134: Look 2210 -> Transform -> Vocation 135 (Look 2211)
    [134] = { 
        lvl = 7, manaPerSec = 10,
        currentLookType = 2210,
        newlookType = 2211, revertlookType = 2209,
        maxhp = 100, maxmana = 100, 
        newvoc = 135, revertvoc = 133,
        effect = 351, constanteffect = 99,
        name = "Shisui Czternaście",
        isPermanent = false
    },
    -- Vocation 135: Look 2211 -> Transform -> Vocation 136 (Look 2212)
    [135] = { 
        lvl = 8, manaPerSec = 10,
        currentLookType = 2211,
        newlookType = 2212, revertlookType = 2210,
        maxhp = 100, maxmana = 100, 
        newvoc = 136, revertvoc = 134,
        effect = 357, constanteffect = 99,
        name = "Shisui Piętnaście",
        isPermanent = false
    },
    -- Vocation 136: Look 2212 -> Transform -> Vocation 137 (Look 2213) - PERMANENT
    [136] = { 
        lvl = 8, manaPerSec = 0,
        currentLookType = 2212,
        newlookType = 2213, revertlookType = 2211,
        maxhp = 100, maxmana = 100, 
        newvoc = 137, revertvoc = 135,
        effect = 358, constanteffect = 0,
        name = "Shisui Szesnaście",
        isPermanent = true
    },
    -- Vocation 137: Look 2213 -> Transform -> Vocation 138 (Look 2214)
    [137] = { 
        lvl = 9, manaPerSec = 10,
        currentLookType = 2213,
        newlookType = 2214, revertlookType = 2212,
        maxhp = 100, maxmana = 100, 
        newvoc = 138, revertvoc = 136,
        effect = 398, constanteffect = 99,
        name = "Shisui Siedemnaście",
        isPermanent = false
    },
    -- Vocation 138: Look 2214 -> Transform -> Vocation 139 (Look 2227)
    [138] = { 
        lvl = 9, manaPerSec = 10,
        currentLookType = 2214,
        newlookType = 2227, revertlookType = 2213,
        maxhp = 100, maxmana = 100, 
        newvoc = 139, revertvoc = 137,
        effect = 400, constanteffect = 99,
        name = "Shisui Osiemnaście",
        isPermanent = false
    },
    -- Vocation 139: Look 2227 -> Transform -> Vocation 140 (Look 2228) - PERMANENT 
    [139] = { 
        lvl = 10, manaPerSec = 0,
        currentLookType = 2227,
        newlookType = 2228, revertlookType = 2214,
        maxhp = 100, maxmana = 100, 
        newvoc = 140, revertvoc = 138,
        effect = 66, constanteffect = 99,
        name = "Shisui Dziewiętnaście",
        isPermanent = true
    },
    
    -- ════════════════════════════════════════════════════════════════════════════
    -- KAKASHI TRANSFORMATION SYSTEM (Vocation 151-180)
    -- ════════════════════════════════════════════════════════════════════════════
    
    -- Vocation 151: Look 1974 -> Transform -> Vocation 152 (Look 1976) - PERMANENT
    [151] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1974,
        newlookType = 1976, revertlookType = 1974,
        maxhp = 100, maxmana = 100, 
        newvoc = 152, revertvoc = 151,
        effect = 66, constanteffect = 0,
        name = "Kakashi Pierwotna Postać",
        isPermanent = true
    },
    -- Vocation 152: Look 1976 -> Transform -> Vocation 153 (Look 1977)
    [152] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 1976,
        newlookType = 1977, revertlookType = 1974,
        maxhp = 100, maxmana = 100, 
        newvoc = 153, revertvoc = 151,
        effect = 150, constanteffect = 99,
        name = "Kakashi Dwa",
        isPermanent = false
    },
    -- Vocation 153: Look 1977 -> Transform -> Vocation 154 (Look 1982) - PERMANENT
    [153] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 1977,
        newlookType = 1982, revertlookType = 1976,
        maxhp = 100, maxmana = 100, 
        newvoc = 154, revertvoc = 152,
        effect = 152, constanteffect = 0,
        name = "Kakashi Trzy",
        isPermanent = true
    },
    -- Vocation 154: Look 1982 -> Transform -> Vocation 155 (Look 1983)
    [154] = { 
        lvl = 2, manaPerSec = 10,
        currentLookType = 1982,
        newlookType = 1983, revertlookType = 1977,
        maxhp = 100, maxmana = 100, 
        newvoc = 155, revertvoc = 153,
        effect = 331, constanteffect = 99,
        name = "Kakashi Cztery",
        isPermanent = false
    },
    -- Vocation 155: Look 1983 -> Transform -> Vocation 156 (Look 1975)
    [155] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 1983,
        newlookType = 1975, revertlookType = 1982,
        maxhp = 100, maxmana = 100, 
        newvoc = 156, revertvoc = 154,
        effect = 257, constanteffect = 99,
        name = "Kakashi Pięć",
        isPermanent = false
    },
    -- Vocation 156: Look 1975 -> Transform -> Vocation 157 (Look 1981) - PERMANENT
    [156] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 1975,
        newlookType = 1981, revertlookType = 1983,
        maxhp = 100, maxmana = 100, 
        newvoc = 157, revertvoc = 155,
        effect = 126, constanteffect = 0,
        name = "Kakashi Sześć",
        isPermanent = true
    },
    -- Vocation 157: Look 1981 -> Transform -> Vocation 158 (Look 1978)
    [157] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 1981,
        newlookType = 1978, revertlookType = 1975,
        maxhp = 100, maxmana = 100, 
        newvoc = 158, revertvoc = 156,
        effect = 127, constanteffect = 99,
        name = "Kakashi Siedem",
        isPermanent = false
    },
    -- Vocation 158: Look 1978 -> Transform -> Vocation 159 (Look 1980)
    [158] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 1978,
        newlookType = 1980, revertlookType = 1981,
        maxhp = 100, maxmana = 100, 
        newvoc = 159, revertvoc = 157,
        effect = 128, constanteffect = 99,
        name = "Kakashi Osiem",
        isPermanent = false
    },
    -- Vocation 159: Look 1980 -> Transform -> Vocation 160 (Look 1979)
    [159] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1980,
        newlookType = 1979, revertlookType = 1978,
        maxhp = 100, maxmana = 100, 
        newvoc = 160, revertvoc = 158,
        effect = 130, constanteffect = 99,
        name = "Kakashi Dziewięć",
        isPermanent = false
    },
    -- Vocation 160: Look 1979 -> Transform -> Vocation 161 (Look 1994) - PERMANENT
    [160] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 1979,
        newlookType = 1994, revertlookType = 1980,
        maxhp = 100, maxmana = 100, 
        newvoc = 161, revertvoc = 159,
        effect = 131, constanteffect = 0,
        name = "Kakashi Dziesięć",
        isPermanent = true
    },
    -- Vocation 161: Look 1994 -> Transform -> Vocation 162 (Look 1985) - PERMANENT
    [161] = { 
        lvl = 6, manaPerSec = 0,
        currentLookType = 1994,
        newlookType = 1985, revertlookType = 1979,
        maxhp = 100, maxmana = 100, 
        newvoc = 162, revertvoc = 160,
        effect = 149, constanteffect = 0,
        name = "Kakashi Jedenaście",
        isPermanent = true
    },
    -- Vocation 162: Look 1985 -> Transform -> Vocation 163 (Look 1986)
    [162] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 1985,
        newlookType = 1986, revertlookType = 1994,
        maxhp = 100, maxmana = 100, 
        newvoc = 163, revertvoc = 161,
        effect = 150, constanteffect = 99,
        name = "Kakashi Dwanaście",
        isPermanent = false
    },
    -- Vocation 163: Look 1986 -> Transform -> Vocation 164 (Look 1987)
    [163] = { 
        lvl = 7, manaPerSec = 10,
        currentLookType = 1986,
        newlookType = 1987, revertlookType = 1985,
        maxhp = 100, maxmana = 100, 
        newvoc = 164, revertvoc = 162,
        effect = 152, constanteffect = 99,
        name = "Kakashi Trzynaście",
        isPermanent = false
    },
    -- Vocation 164: Look 1987 -> Transform -> Vocation 165 (Look 1988) - PERMANENT
    [164] = { 
        lvl = 7, manaPerSec = 0,
        currentLookType = 1987,
        newlookType = 1988, revertlookType = 1986,
        maxhp = 100, maxmana = 100, 
        newvoc = 165, revertvoc = 163,
        effect = 351, constanteffect = 0,
        name = "Kakashi Czternaście",
        isPermanent = true
    },
    -- Vocation 165: Look 1988 -> Transform -> Vocation 166 (Look 1989) - PERMANENT
    [165] = { 
        lvl = 8, manaPerSec = 0,
        currentLookType = 1988,
        newlookType = 1989, revertlookType = 1987,
        maxhp = 100, maxmana = 100, 
        newvoc = 166, revertvoc = 164,
        effect = 357, constanteffect = 0,
        name = "Kakashi Piętnaście",
        isPermanent = true
    },
    -- Vocation 166: Look 1989 -> Transform -> Vocation 167 (Look 2071)
    [166] = { 
        lvl = 8, manaPerSec = 10,
        currentLookType = 1989,
        newlookType = 2071, revertlookType = 1988,
        maxhp = 100, maxmana = 100, 
        newvoc = 167, revertvoc = 165,
        effect = 358, constanteffect = 99,
        name = "Kakashi Szesnaście",
        isPermanent = false
    },
    -- Vocation 167: Look 2071 -> Transform -> Vocation 168 (Look placeholder)
    [167] = { 
        lvl = 9, manaPerSec = 10,
        currentLookType = 2071,
        newlookType = 2071, revertlookType = 1989,
        maxhp = 100, maxmana = 100, 
        newvoc = 168, revertvoc = 166,
        effect = 398, constanteffect = 99,
        name = "Kakashi Siedemnaście",
        isPermanent = false
    },
    
    -- ═════════════════════════════════════════════════════════════════════
    -- HINATA TRANSFORMATION SYSTEM - Vocation 181-210
    -- ═════════════════════════════════════════════════════════════════════
    
    -- Vocation 181: Look 2417 (Base Form - PERMANENT)
    [181] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2417,
        newlookType = 1950, revertlookType = 2417,
        maxhp = 100, maxmana = 100, 
        newvoc = 182, revertvoc = 181,
        effect = 170, constanteffect = 66,
        name = "Hinata Pierwotna",
        isPermanent = true
    },
    -- Vocation 182: Look 1950 -> Transform -> Vocation 183 (TEMPORARY)
    [182] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 1950,
        newlookType = 1951, revertlookType = 2417,
        maxhp = 100, maxmana = 100, 
        newvoc = 183, revertvoc = 181,
        effect = 171, constanteffect = 66,
        name = "Hinata Dwa",
        isPermanent = false
    },
    -- Vocation 183: Look 1951 -> Transform -> Vocation 184 (PERMANENT)
    [183] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1951,
        newlookType = 2296, revertlookType = 1950,
        maxhp = 100, maxmana = 100, 
        newvoc = 184, revertvoc = 182,
        effect = 172, constanteffect = 66,
        name = "Hinata Trzy",
        isPermanent = true
    },
    -- Vocation 184: Look 2296 -> Transform -> Vocation 185 (PERMANENT)
    [184] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2296,
        newlookType = 1952, revertlookType = 1951,
        maxhp = 100, maxmana = 100, 
        newvoc = 185, revertvoc = 183,
        effect = 173, constanteffect = 66,
        name = "Hinata Cztery",
        isPermanent = true
    },
    -- Vocation 185: Look 1952 -> Transform -> Vocation 186 (PERMANENT)
    [185] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 1952,
        newlookType = 1953, revertlookType = 2296,
        maxhp = 100, maxmana = 100, 
        newvoc = 186, revertvoc = 184,
        effect = 174, constanteffect = 66,
        name = "Hinata Pięć",
        isPermanent = true
    },
    -- Vocation 186: Look 1953 -> Transform -> Vocation 187 (PERMANENT)
    [186] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 1953,
        newlookType = 1954, revertlookType = 1952,
        maxhp = 100, maxmana = 100, 
        newvoc = 187, revertvoc = 185,
        effect = 175, constanteffect = 66,
        name = "Hinata Sześć",
        isPermanent = true
    },
    -- Vocation 187: Look 1954 -> Transform -> Vocation 188 (TEMPORARY)
    [187] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 1954,
        newlookType = 1955, revertlookType = 1953,
        maxhp = 100, maxmana = 100, 
        newvoc = 188, revertvoc = 186,
        effect = 176, constanteffect = 66,
        name = "Hinata Siedem",
        isPermanent = false
    },
    -- Vocation 188: Look 1955 -> Transform -> Vocation 189 (PERMANENT)
    [188] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 1955,
        newlookType = 2267, revertlookType = 1954,
        maxhp = 100, maxmana = 100, 
        newvoc = 189, revertvoc = 187,
        effect = 177, constanteffect = 66,
        name = "Hinata Osiem",
        isPermanent = true
    },
    -- Vocation 189: Look 2267 -> Transform -> Vocation 190 (PERMANENT with mana burn)
    [189] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 2267,
        newlookType = 2297, revertlookType = 1955,
        maxhp = 100, maxmana = 100, 
        newvoc = 190, revertvoc = 188,
        effect = 178, constanteffect = 66,
        name = "Hinata Dziewięć",
        isPermanent = true
    },
    -- Vocation 190: Look 2297 -> Transform -> Vocation 191 (PERMANENT with mana burn)
    [190] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2297,
        newlookType = 2266, revertlookType = 2267,
        maxhp = 100, maxmana = 100, 
        newvoc = 191, revertvoc = 189,
        effect = 179, constanteffect = 66,
        name = "Hinata Dziesięć",
        isPermanent = true
    },
    -- Vocation 191: Look 2266 -> Transform -> Vocation 192 (PERMANENT)
    [191] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 2266,
        newlookType = 2180, revertlookType = 2297,
        maxhp = 100, maxmana = 100, 
        newvoc = 192, revertvoc = 190,
        effect = 180, constanteffect = 66,
        name = "Hinata Jedenaście",
        isPermanent = true
    },
    -- Vocation 192: Look 2180 -> Transform -> Vocation 193 (TEMPORARY)
    [192] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2180,
        newlookType = 2182, revertlookType = 2266,
        maxhp = 100, maxmana = 100, 
        newvoc = 193, revertvoc = 191,
        effect = 181, constanteffect = 66,
        name = "Hinata Dwanaście",
        isPermanent = false
    },
    -- Vocation 193: Look 2182 -> Transform -> Vocation 194 (TEMPORARY)
    [193] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2182,
        newlookType = 2182, revertlookType = 2180,
        maxhp = 100, maxmana = 100, 
        newvoc = 194, revertvoc = 192,
        effect = 182, constanteffect = 66,
        name = "Hinata Trzynaście",
        isPermanent = false
    },
    
    -- ═════════════════════════════════════════════════════════════════════
    -- KISAME TRANSFORMATION SYSTEM - Vocation 211-240
    -- ═════════════════════════════════════════════════════════════════════
    
    -- Vocation 211: Look 1907 (Base Form - PERMANENT)
    [211] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1907,
        newlookType = 1908, revertlookType = 1907,
        maxhp = 100, maxmana = 100, 
        newvoc = 212, revertvoc = 211,
        effect = 200, constanteffect = 70,
        name = "Kisame Pierwotna",
        isPermanent = true
    },
    -- Vocation 212: Look 1908 -> Transform -> Vocation 213 (PERMANENT)
    [212] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1908,
        newlookType = 1909, revertlookType = 1907,
        maxhp = 100, maxmana = 100, 
        newvoc = 213, revertvoc = 211,
        effect = 201, constanteffect = 70,
        name = "Kisame Dwa",
        isPermanent = true
    },
    -- Vocation 213: Look 1909 -> Transform -> Vocation 214 (PERMANENT)
    [213] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1909,
        newlookType = 2461, revertlookType = 1908,
        maxhp = 100, maxmana = 100, 
        newvoc = 214, revertvoc = 212,
        effect = 202, constanteffect = 70,
        name = "Kisame Trzy",
        isPermanent = true
    },
    -- Vocation 214: Look 2461 -> Transform -> Vocation 215 (PERMANENT)
    [214] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2461,
        newlookType = 2460, revertlookType = 1909,
        maxhp = 100, maxmana = 100, 
        newvoc = 215, revertvoc = 213,
        effect = 203, constanteffect = 70,
        name = "Kisame Cztery",
        isPermanent = true
    },
    -- Vocation 215: Look 2460 -> Transform -> Vocation 216 (PERMANENT)
    [215] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2460,
        newlookType = 2459, revertlookType = 2461,
        maxhp = 100, maxmana = 100, 
        newvoc = 216, revertvoc = 214,
        effect = 204, constanteffect = 70,
        name = "Kisame Pięć",
        isPermanent = true
    },
    -- Vocation 216: Look 2459 -> Transform -> Vocation 217 (PERMANENT)
    [216] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 2459,
        newlookType = 2459, revertlookType = 2460,
        maxhp = 100, maxmana = 100, 
        newvoc = 217, revertvoc = 215,
        effect = 205, constanteffect = 70,
        name = "Kisame Sześć",
        isPermanent = true
    },
    -- Vocation 217: Look 2459 -> Transform -> Vocation 218 (PERMANENT with mana burn)
    [217] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 2459,
        newlookType = 1911, revertlookType = 2459,
        maxhp = 100, maxmana = 100, 
        newvoc = 218, revertvoc = 216,
        effect = 206, constanteffect = 70,
        name = "Kisame Siedem",
        isPermanent = true
    },
    -- Vocation 218: Look 1911 -> Transform -> Vocation 219 (PERMANENT)
    [218] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 1911,
        newlookType = 1912, revertlookType = 2459,
        maxhp = 100, maxmana = 100, 
        newvoc = 219, revertvoc = 217,
        effect = 207, constanteffect = 70,
        name = "Kisame Osiem",
        isPermanent = true
    },
    -- Vocation 219: Look 1912 -> Transform -> Vocation 220 (PERMANENT)
    [219] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 1912,
        newlookType = 1913, revertlookType = 1911,
        maxhp = 100, maxmana = 100, 
        newvoc = 220, revertvoc = 218,
        effect = 208, constanteffect = 70,
        name = "Kisame Dziewięć",
        isPermanent = true
    },
    -- Vocation 220: Look 1913 -> Transform -> Vocation 221 (PERMANENT)
    [220] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 1913,
        newlookType = 1914, revertlookType = 1912,
        maxhp = 100, maxmana = 100, 
        newvoc = 221, revertvoc = 219,
        effect = 209, constanteffect = 70,
        name = "Kisame Dziesięć",
        isPermanent = true
    },
    -- Vocation 221: Look 1914 -> Transform -> Vocation 222 (PERMANENT)
    [221] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 1914,
        newlookType = 1910, revertlookType = 1913,
        maxhp = 100, maxmana = 100, 
        newvoc = 222, revertvoc = 220,
        effect = 210, constanteffect = 70,
        name = "Kisame Jedenaście",
        isPermanent = true
    },
    -- Vocation 222: Look 1910 -> Transform -> Vocation 223 (TEMPORARY)
    [222] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 1910,
        newlookType = 1916, revertlookType = 1914,
        maxhp = 100, maxmana = 100, 
        newvoc = 223, revertvoc = 221,
        effect = 211, constanteffect = 70,
        name = "Kisame Dwanaście",
        isPermanent = false
    },
    -- Vocation 223: Look 1916 -> Transform -> Vocation 224 (PERMANENT)
    [223] = { 
        lvl = 6, manaPerSec = 0,
        currentLookType = 1916,
        newlookType = 1917, revertlookType = 1910,
        maxhp = 100, maxmana = 100, 
        newvoc = 224, revertvoc = 222,
        effect = 212, constanteffect = 70,
        name = "Kisame Trzynaście",
        isPermanent = true
    },
    -- Vocation 224: Look 1917 -> Transform -> Vocation 225 (TEMPORARY)
    [224] = { 
        lvl = 7, manaPerSec = 10,
        currentLookType = 1917,
        newlookType = 1918, revertlookType = 1916,
        maxhp = 100, maxmana = 100, 
        newvoc = 225, revertvoc = 223,
        effect = 213, constanteffect = 70,
        name = "Kisame Czternaście",
        isPermanent = false
    },
    -- Vocation 225: Look 1918 -> Transform -> Vocation 226 (PERMANENT)
    [225] = { 
        lvl = 7, manaPerSec = 0,
        currentLookType = 1918,
        newlookType = 1919, revertlookType = 1917,
        maxhp = 100, maxmana = 100, 
        newvoc = 226, revertvoc = 224,
        effect = 214, constanteffect = 70,
        name = "Kisame Piętnaście",
        isPermanent = true
    },
    -- Vocation 226: Look 1919 -> Transform -> Vocation 227 (TEMPORARY)
    [226] = { 
        lvl = 7, manaPerSec = 10,
        currentLookType = 1919,
        newlookType = 1923, revertlookType = 1918,
        maxhp = 100, maxmana = 100, 
        newvoc = 227, revertvoc = 225,
        effect = 215, constanteffect = 70,
        name = "Kisame Szesnaście",
        isPermanent = false
    },
    -- Vocation 227: Look 1923 -> Transform -> Vocation 228 (TEMPORARY)
    [227] = { 
        lvl = 8, manaPerSec = 10,
        currentLookType = 1923,
        newlookType = 2459, revertlookType = 1919,
        maxhp = 100, maxmana = 100, 
        newvoc = 228, revertvoc = 226,
        effect = 216, constanteffect = 70,
        name = "Kisame Siedemnaście",
        isPermanent = false
    },
    -- Vocation 228: Look 2459 -> Transform -> Vocation 229 (PERMANENT)
    [228] = { 
        lvl = 8, manaPerSec = 0,
        currentLookType = 2459,
        newlookType = 2247, revertlookType = 1923,
        maxhp = 100, maxmana = 100, 
        newvoc = 229, revertvoc = 227,
        effect = 217, constanteffect = 70,
        name = "Kisame Osiemnaście",
        isPermanent = true
    },
    -- Vocation 229: Look 2247 -> Transform -> Vocation 230 (PERMANENT)
    [229] = { 
        lvl = 8, manaPerSec = 0,
        currentLookType = 2247,
        newlookType = 2490, revertlookType = 2459,
        maxhp = 100, maxmana = 100, 
        newvoc = 230, revertvoc = 228,
        effect = 218, constanteffect = 70,
        name = "Kisame Dziewiętnaście",
        isPermanent = true
    },
    -- Vocation 230: Look 2490 -> Transform -> Vocation 231 (TEMPORARY)
    [230] = { 
        lvl = 9, manaPerSec = 10,
        currentLookType = 2490,
        newlookType = 2490, revertlookType = 2247,
        maxhp = 100, maxmana = 100, 
        newvoc = 231, revertvoc = 229,
        effect = 219, constanteffect = 70,
        name = "Kisame Dwadzieścia",
        isPermanent = false
    },

    -- GAARA TRANSFORMATION SYSTEM - Vocation 241-270
    -- Vocation 241: Look 1994 -> Transform -> Vocation 242 (PERMANENT - Base Form)
    [241] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1994,
        newlookType = 1995, revertlookType = 1994,
        maxhp = 100, maxmana = 100, 
        newvoc = 242, revertvoc = 241,
        effect = 220, constanteffect = 70,
        name = "Gaara Base",
        isPermanent = true
    },
    -- Vocation 242: Look 1995 -> Transform -> Vocation 243 (PERMANENT)
    [242] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1995,
        newlookType = 2000, revertlookType = 1994,
        maxhp = 100, maxmana = 100, 
        newvoc = 243, revertvoc = 241,
        effect = 221, constanteffect = 70,
        name = "Gaara Dwa",
        isPermanent = true
    },
    -- Vocation 243: Look 2000 -> Transform -> Vocation 244 (TEMPORARY)
    [243] = { 
        lvl = 2, manaPerSec = 10,
        currentLookType = 2000,
        newlookType = 2001, revertlookType = 1995,
        maxhp = 100, maxmana = 100, 
        newvoc = 244, revertvoc = 242,
        effect = 222, constanteffect = 70,
        name = "Gaara Trzy",
        isPermanent = false
    },
    -- Vocation 244: Look 2001 -> Transform -> Vocation 245 (TEMPORARY)
    [244] = { 
        lvl = 2, manaPerSec = 10,
        currentLookType = 2001,
        newlookType = 1998, revertlookType = 2000,
        maxhp = 100, maxmana = 100, 
        newvoc = 245, revertvoc = 243,
        effect = 223, constanteffect = 70,
        name = "Gaara Cztery",
        isPermanent = false
    },
    -- Vocation 245: Look 1998 -> Transform -> Vocation 246 (PERMANENT)
    [245] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 1998,
        newlookType = 2070, revertlookType = 2001,
        maxhp = 100, maxmana = 100, 
        newvoc = 246, revertvoc = 244,
        effect = 224, constanteffect = 70,
        name = "Gaara Pięć",
        isPermanent = true
    },
    -- Vocation 246: Look 2070 -> Transform -> Vocation 247 (TEMPORARY)
    [246] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 2070,
        newlookType = 2003, revertlookType = 1998,
        maxhp = 100, maxmana = 100, 
        newvoc = 247, revertvoc = 245,
        effect = 225, constanteffect = 70,
        name = "Gaara Sześć",
        isPermanent = false
    },
    -- Vocation 247: Look 2003 -> Transform -> Vocation 248 (PERMANENT with mana burn)
    [247] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 2003,
        newlookType = 1997, revertlookType = 2070,
        maxhp = 100, maxmana = 100, 
        newvoc = 248, revertvoc = 246,
        effect = 226, constanteffect = 70,
        name = "Gaara Siedem",
        isPermanent = true
    },
    -- Vocation 248: Look 1997 -> Transform -> Vocation 249 (PERMANENT)
    [248] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 1997,
        newlookType = 1999, revertlookType = 2003,
        maxhp = 100, maxmana = 100, 
        newvoc = 249, revertvoc = 247,
        effect = 227, constanteffect = 70,
        name = "Gaara Osiem",
        isPermanent = true
    },
    -- Vocation 249: Look 1999 -> Transform -> Vocation 250 (PERMANENT)
    [249] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 1999,
        newlookType = 2069, revertlookType = 1997,
        maxhp = 100, maxmana = 100, 
        newvoc = 250, revertvoc = 248,
        effect = 228, constanteffect = 70,
        name = "Gaara Dziewięć",
        isPermanent = true
    },
    -- Vocation 250: Look 2069 -> Transform -> Vocation 251 (TEMPORARY)
    [250] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 2069,
        newlookType = 1996, revertlookType = 1999,
        maxhp = 100, maxmana = 100, 
        newvoc = 251, revertvoc = 249,
        effect = 229, constanteffect = 70,
        name = "Gaara Dziesięć",
        isPermanent = false
    },
    -- Vocation 251: Look 1996 -> Transform -> Vocation 252 (PERMANENT)
    [251] = { 
        lvl = 6, manaPerSec = 0,
        currentLookType = 1996,
        newlookType = 2068, revertlookType = 2069,
        maxhp = 100, maxmana = 100, 
        newvoc = 252, revertvoc = 250,
        effect = 230, constanteffect = 70,
        name = "Gaara Jedenaście",
        isPermanent = true
    },
    -- Vocation 252: Look 2068 -> Transform -> Vocation 253 (TEMPORARY)
    [252] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2068,
        newlookType = 2002, revertlookType = 1996,
        maxhp = 100, maxmana = 100, 
        newvoc = 253, revertvoc = 251,
        effect = 231, constanteffect = 70,
        name = "Gaara Dwanaście",
        isPermanent = false
    },
    -- Vocation 253: Look 2002 -> Transform -> Vocation 254 (PERMANENT)
    [253] = { 
        lvl = 7, manaPerSec = 0,
        currentLookType = 2002,
        newlookType = 2130, revertlookType = 2068,
        maxhp = 100, maxmana = 100, 
        newvoc = 254, revertvoc = 252,
        effect = 232, constanteffect = 70,
        name = "Gaara Trzynaście",
        isPermanent = true
    },
    -- Vocation 254: Look 2130 -> Transform -> Vocation 255 (TEMPORARY)
    [254] = { 
        lvl = 7, manaPerSec = 10,
        currentLookType = 2130,
        newlookType = 2447, revertlookType = 2002,
        maxhp = 100, maxmana = 100, 
        newvoc = 255, revertvoc = 253,
        effect = 233, constanteffect = 70,
        name = "Gaara Czternaście",
        isPermanent = false
    },
    -- Vocation 255: Look 2447 -> Transform -> Vocation 256 (PERMANENT)
    [255] = { 
        lvl = 8, manaPerSec = 0,
        currentLookType = 2447,
        newlookType = 2447, revertlookType = 2130,
        maxhp = 100, maxmana = 100, 
        newvoc = 256, revertvoc = 254,
        effect = 234, constanteffect = 70,
        name = "Gaara Piętnaście",
        isPermanent = true
    },

    -- HIDAN TRANSFORMATION SYSTEM - Vocation 271-300
    -- Vocation 271: Look 1941 -> Transform -> Vocation 272 (PERMANENT - Base Form)
    [271] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1941,
        newlookType = 1942, revertlookType = 1941,
        maxhp = 100, maxmana = 100, 
        newvoc = 272, revertvoc = 271,
        effect = 250, constanteffect = 70,
        name = "Hidan Base",
        isPermanent = true
    },
    -- Vocation 272: Look 1942 -> Transform -> Vocation 273 (TEMPORARY)
    [272] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 1942,
        newlookType = 2420, revertlookType = 1941,
        maxhp = 100, maxmana = 100, 
        newvoc = 273, revertvoc = 271,
        effect = 251, constanteffect = 70,
        name = "Hidan Dwa",
        isPermanent = false
    },
    -- Vocation 273: Look 2420 -> Transform -> Vocation 274 (PERMANENT)
    [273] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2420,
        newlookType = 1943, revertlookType = 1942,
        maxhp = 100, maxmana = 100, 
        newvoc = 274, revertvoc = 272,
        effect = 252, constanteffect = 70,
        name = "Hidan Trzy",
        isPermanent = true
    },
    -- Vocation 274: Look 1943 -> Transform -> Vocation 275 (TEMPORARY)
    [274] = { 
        lvl = 2, manaPerSec = 10,
        currentLookType = 1943,
        newlookType = 1946, revertlookType = 2420,
        maxhp = 100, maxmana = 100, 
        newvoc = 275, revertvoc = 273,
        effect = 253, constanteffect = 70,
        name = "Hidan Cztery",
        isPermanent = false
    },
    -- Vocation 275: Look 1946 -> Transform -> Vocation 276 (TEMPORARY)
    [275] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 1946,
        newlookType = 1949, revertlookType = 1943,
        maxhp = 100, maxmana = 100, 
        newvoc = 276, revertvoc = 274,
        effect = 254, constanteffect = 70,
        name = "Hidan Pięć",
        isPermanent = false
    },
    -- Vocation 276: Look 1949 -> Transform -> Vocation 277 (TEMPORARY)
    [276] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 1949,
        newlookType = 1948, revertlookType = 1946,
        maxhp = 100, maxmana = 100, 
        newvoc = 277, revertvoc = 275,
        effect = 255, constanteffect = 70,
        name = "Hidan Sześć",
        isPermanent = false
    },
    -- Vocation 277: Look 1948 -> Transform -> Vocation 278 (PERMANENT)
    [277] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 1948,
        newlookType = 2290, revertlookType = 1949,
        maxhp = 100, maxmana = 100, 
        newvoc = 278, revertvoc = 276,
        effect = 256, constanteffect = 70,
        name = "Hidan Siedem",
        isPermanent = true
    },
    -- Vocation 278: Look 2290 -> Transform -> Vocation 279 (TEMPORARY)
    [278] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 2290,
        newlookType = 2290, revertlookType = 1948,
        maxhp = 100, maxmana = 100, 
        newvoc = 279, revertvoc = 277,
        effect = 257, constanteffect = 70,
        name = "Hidan Osiem",
        isPermanent = false
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- TOBI TRANSFORMATION SYSTEM (Vocation 301-330)
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- Vocation 301: Look 2323 -> Transform -> Vocation 302 (PERMANENT)
    [301] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2323,
        newlookType = 1938, revertlookType = 2323,
        maxhp = 100, maxmana = 100, 
        newvoc = 302, revertvoc = 301,
        effect = 258, constanteffect = 70,
        name = "Tobi Jeden",
        isPermanent = true
    },
    -- Vocation 302: Look 1938 -> Transform -> Vocation 303 (TEMPORARY)
    [302] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 1938,
        newlookType = 1933, revertlookType = 2323,
        maxhp = 100, maxmana = 100, 
        newvoc = 303, revertvoc = 301,
        effect = 259, constanteffect = 70,
        name = "Tobi Dwa",
        isPermanent = false
    },
    -- Vocation 303: Look 1933 -> Transform -> Vocation 304 (PERMANENT)
    [303] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1933,
        newlookType = 1934, revertlookType = 1938,
        maxhp = 100, maxmana = 100, 
        newvoc = 304, revertvoc = 302,
        effect = 260, constanteffect = 70,
        name = "Tobi Trzy",
        isPermanent = true
    },
    -- Vocation 304: Look 1934 -> Transform -> Vocation 305 (PERMANENT)
    [304] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 1934,
        newlookType = 1935, revertlookType = 1933,
        maxhp = 100, maxmana = 100, 
        newvoc = 305, revertvoc = 303,
        effect = 261, constanteffect = 70,
        name = "Tobi Cztery",
        isPermanent = true
    },
    -- Vocation 305: Look 1935 -> Transform -> Vocation 306 (PERMANENT)
    [305] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 1935,
        newlookType = 1936, revertlookType = 1934,
        maxhp = 100, maxmana = 100, 
        newvoc = 306, revertvoc = 304,
        effect = 262, constanteffect = 70,
        name = "Tobi Pięć",
        isPermanent = true
    },
    -- Vocation 306: Look 1936 -> Transform -> Vocation 307 (TEMPORARY)
    [306] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 1936,
        newlookType = 1929, revertlookType = 1935,
        maxhp = 100, maxmana = 100, 
        newvoc = 307, revertvoc = 305,
        effect = 263, constanteffect = 70,
        name = "Tobi Sześć",
        isPermanent = false
    },
    -- Vocation 307: Look 1929 -> Transform -> Vocation 308 (PERMANENT)
    [307] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 1929,
        newlookType = 1930, revertlookType = 1936,
        maxhp = 100, maxmana = 100, 
        newvoc = 308, revertvoc = 306,
        effect = 264, constanteffect = 70,
        name = "Tobi Siedem",
        isPermanent = true
    },
    -- Vocation 308: Look 1930 -> Transform -> Vocation 309 (PERMANENT)
    [308] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 1930,
        newlookType = 1939, revertlookType = 1929,
        maxhp = 100, maxmana = 100, 
        newvoc = 309, revertvoc = 307,
        effect = 265, constanteffect = 70,
        name = "Tobi Osiem",
        isPermanent = true
    },
    -- Vocation 309: Look 1939 -> Transform -> Vocation 310 (PERMANENT)
    [309] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 1939,
        newlookType = 1931, revertlookType = 1930,
        maxhp = 100, maxmana = 100, 
        newvoc = 310, revertvoc = 308,
        effect = 266, constanteffect = 70,
        name = "Tobi Dziewięć",
        isPermanent = true
    },
    -- Vocation 310: Look 1931 -> Transform -> Vocation 311 (PERMANENT)
    [310] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 1931,
        newlookType = 1932, revertlookType = 1939,
        maxhp = 100, maxmana = 100, 
        newvoc = 311, revertvoc = 309,
        effect = 267, constanteffect = 70,
        name = "Tobi Dziesięć",
        isPermanent = true
    },
    -- Vocation 311: Look 1932 -> Transform -> Vocation 312 (PERMANENT)
    [311] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 1932,
        newlookType = 1928, revertlookType = 1931,
        maxhp = 100, maxmana = 100, 
        newvoc = 312, revertvoc = 310,
        effect = 268, constanteffect = 70,
        name = "Tobi Jedenaście",
        isPermanent = true
    },
    -- Vocation 312: Look 1928 -> Transform -> Vocation 313 (PERMANENT)
    [312] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 1928,
        newlookType = 2471, revertlookType = 1932,
        maxhp = 100, maxmana = 100, 
        newvoc = 313, revertvoc = 311,
        effect = 269, constanteffect = 70,
        name = "Tobi Dwanaście",
        isPermanent = true
    },
    -- Vocation 313: Look 2471 -> Transform -> Vocation 314 (PERMANENT)
    [313] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 2471,
        newlookType = 1937, revertlookType = 1928,
        maxhp = 100, maxmana = 100, 
        newvoc = 314, revertvoc = 312,
        effect = 270, constanteffect = 70,
        name = "Tobi Trzynaście",
        isPermanent = true
    },
    -- Vocation 314: Look 1937 -> Transform -> Vocation 315 (PERMANENT)
    [314] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 1937,
        newlookType = 2288, revertlookType = 2471,
        maxhp = 100, maxmana = 100, 
        newvoc = 315, revertvoc = 313,
        effect = 271, constanteffect = 70,
        name = "Tobi Czternaście",
        isPermanent = true
    },
    -- Vocation 315: Look 2288 -> Transform -> Vocation 316 (PERMANENT)
    [315] = { 
        lvl = 6, manaPerSec = 0,
        currentLookType = 2288,
        newlookType = 2289, revertlookType = 1937,
        maxhp = 100, maxmana = 100, 
        newvoc = 316, revertvoc = 314,
        effect = 272, constanteffect = 70,
        name = "Tobi Piętnaście",
        isPermanent = true
    },
    -- Vocation 316: Look 2289 -> Transform -> Vocation 317 (TEMPORARY)
    [316] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2289,
        newlookType = 2291, revertlookType = 2288,
        maxhp = 100, maxmana = 100, 
        newvoc = 317, revertvoc = 315,
        effect = 273, constanteffect = 70,
        name = "Tobi Szesnaście",
        isPermanent = false
    },
    -- Vocation 317: Look 2291 -> Transform -> Vocation 318 (PERMANENT with mana burn)
    [317] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2291,
        newlookType = 2115, revertlookType = 2289,
        maxhp = 100, maxmana = 100, 
        newvoc = 318, revertvoc = 316,
        effect = 274, constanteffect = 70,
        name = "Tobi Siedemnaście",
        isPermanent = true
    },
    -- Vocation 318: Look 2115 -> Transform -> Vocation 319 (TEMPORARY)
    [318] = { 
        lvl = 7, manaPerSec = 10,
        currentLookType = 2115,
        newlookType = 2115, revertlookType = 2291,
        maxhp = 100, maxmana = 100, 
        newvoc = 319, revertvoc = 317,
        effect = 275, constanteffect = 70,
        name = "Tobi Osiemnaście",
        isPermanent = false
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- NEJI TRANSFORMATION SYSTEM (Vocation 331-360)
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- Vocation 331: Look 2024 -> Transform -> Vocation 332 (PERMANENT with mana burn)
    [331] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 2024,
        newlookType = 2024, revertlookType = 2024,
        maxhp = 100, maxmana = 100, 
        newvoc = 332, revertvoc = 331,
        effect = 288, constanteffect = 70,
        name = "Neji Jeden",
        isPermanent = true
    },
    -- Vocation 332: Look 2024 -> Transform -> Vocation 333 (TEMPORARY)
    [332] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 2024,
        newlookType = 2026, revertlookType = 2024,
        maxhp = 100, maxmana = 100, 
        newvoc = 333, revertvoc = 331,
        effect = 289, constanteffect = 70,
        name = "Neji Dwa",
        isPermanent = false
    },
    -- Vocation 333: Look 2026 -> Transform -> Vocation 334 (TEMPORARY)
    [333] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 2026,
        newlookType = 2027, revertlookType = 2024,
        maxhp = 100, maxmana = 100, 
        newvoc = 334, revertvoc = 332,
        effect = 290, constanteffect = 70,
        name = "Neji Trzy",
        isPermanent = false
    },
    -- Vocation 334: Look 2027 -> Transform -> Vocation 335 (PERMANENT)
    [334] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2027,
        newlookType = 2028, revertlookType = 2026,
        maxhp = 100, maxmana = 100, 
        newvoc = 335, revertvoc = 333,
        effect = 291, constanteffect = 70,
        name = "Neji Cztery",
        isPermanent = true
    },
    -- Vocation 335: Look 2028 -> Transform -> Vocation 336 (TEMPORARY)
    [335] = { 
        lvl = 2, manaPerSec = 10,
        currentLookType = 2028,
        newlookType = 2029, revertlookType = 2027,
        maxhp = 100, maxmana = 100, 
        newvoc = 336, revertvoc = 334,
        effect = 292, constanteffect = 70,
        name = "Neji Pięć",
        isPermanent = false
    },
    -- Vocation 336: Look 2029 -> Transform -> Vocation 337 (TEMPORARY)
    [336] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 2029,
        newlookType = 2033, revertlookType = 2028,
        maxhp = 100, maxmana = 100, 
        newvoc = 337, revertvoc = 335,
        effect = 293, constanteffect = 70,
        name = "Neji Sześć",
        isPermanent = false
    },
    -- Vocation 337: Look 2033 -> Transform -> Vocation 338 (PERMANENT)
    [337] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 2033,
        newlookType = 2032, revertlookType = 2029,
        maxhp = 100, maxmana = 100, 
        newvoc = 338, revertvoc = 336,
        effect = 294, constanteffect = 70,
        name = "Neji Siedem",
        isPermanent = true
    },
    -- Vocation 338: Look 2032 -> Transform -> Vocation 339 (PERMANENT)
    [338] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 2032,
        newlookType = 2031, revertlookType = 2033,
        maxhp = 100, maxmana = 100, 
        newvoc = 339, revertvoc = 337,
        effect = 295, constanteffect = 70,
        name = "Neji Osiem",
        isPermanent = true
    },
    -- Vocation 339: Look 2031 -> Transform -> Vocation 340 (TEMPORARY)
    [339] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 2031,
        newlookType = 2030, revertlookType = 2032,
        maxhp = 100, maxmana = 100, 
        newvoc = 340, revertvoc = 338,
        effect = 296, constanteffect = 70,
        name = "Neji Dziewięć",
        isPermanent = false
    },
    -- Vocation 340: Look 2030 -> Transform -> Vocation 341 (PERMANENT)
    [340] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 2030,
        newlookType = 2030, revertlookType = 2031,
        maxhp = 100, maxmana = 100, 
        newvoc = 341, revertvoc = 339,
        effect = 297, constanteffect = 70,
        name = "Neji Dziesięć",
        isPermanent = true
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- KABUTO TRANSFORMATION SYSTEM - Vocation 361-390
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- Vocation 361: Look 2268 -> Transform -> Vocation 362 (PERMANENT - First form with mana burn)
    [361] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2268,
        newlookType = 2269, revertlookType = 2268,
        maxhp = 100, maxmana = 100, 
        newvoc = 362, revertvoc = 361,
        effect = 298, constanteffect = 70,
        name = "Kabuto Jeden",
        isPermanent = true
    },
    -- Vocation 362: Look 2269 -> Transform -> Vocation 363 (TEMPORARY)
    [362] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 2269,
        newlookType = 2270, revertlookType = 2268,
        maxhp = 100, maxmana = 100, 
        newvoc = 363, revertvoc = 361,
        effect = 299, constanteffect = 70,
        name = "Kabuto Dwa",
        isPermanent = false
    },
    -- Vocation 363: Look 2270 -> Transform -> Vocation 364 (PERMANENT)
    [363] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2270,
        newlookType = 2271, revertlookType = 2269,
        maxhp = 100, maxmana = 100, 
        newvoc = 364, revertvoc = 362,
        effect = 300, constanteffect = 70,
        name = "Kabuto Trzy",
        isPermanent = true
    },
    -- Vocation 364: Look 2271 -> Transform -> Vocation 365 (PERMANENT)
    [364] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2271,
        newlookType = 2272, revertlookType = 2270,
        maxhp = 100, maxmana = 100, 
        newvoc = 365, revertvoc = 363,
        effect = 301, constanteffect = 70,
        name = "Kabuto Cztery",
        isPermanent = true
    },
    -- Vocation 365: Look 2272 -> Transform -> Vocation 366 (TEMPORARY)
    [365] = { 
        lvl = 2, manaPerSec = 10,
        currentLookType = 2272,
        newlookType = 2273, revertlookType = 2271,
        maxhp = 100, maxmana = 100, 
        newvoc = 366, revertvoc = 364,
        effect = 302, constanteffect = 70,
        name = "Kabuto Pięć",
        isPermanent = false
    },
    -- Vocation 366: Look 2273 -> Transform -> Vocation 367 (TEMPORARY)
    [366] = { 
        lvl = 2, manaPerSec = 10,
        currentLookType = 2273,
        newlookType = 2274, revertlookType = 2272,
        maxhp = 100, maxmana = 100, 
        newvoc = 367, revertvoc = 365,
        effect = 303, constanteffect = 70,
        name = "Kabuto Sześć",
        isPermanent = false
    },
    -- Vocation 367: Look 2274 -> Transform -> Vocation 368 (PERMANENT)
    [367] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 2274,
        newlookType = 2275, revertlookType = 2273,
        maxhp = 100, maxmana = 100, 
        newvoc = 368, revertvoc = 366,
        effect = 304, constanteffect = 70,
        name = "Kabuto Siedem",
        isPermanent = true
    },
    -- Vocation 368: Look 2275 -> Transform -> Vocation 369 (TEMPORARY)
    [368] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 2275,
        newlookType = 2276, revertlookType = 2274,
        maxhp = 100, maxmana = 100, 
        newvoc = 369, revertvoc = 367,
        effect = 305, constanteffect = 70,
        name = "Kabuto Osiem",
        isPermanent = false
    },
    -- Vocation 369: Look 2276 -> Transform -> Vocation 370 (PERMANENT)
    [369] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 2276,
        newlookType = 2277, revertlookType = 2275,
        maxhp = 100, maxmana = 100, 
        newvoc = 370, revertvoc = 368,
        effect = 306, constanteffect = 70,
        name = "Kabuto Dziewięć",
        isPermanent = true
    },
    -- Vocation 370: Look 2277 -> Transform -> Vocation 371 (TEMPORARY)
    [370] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 2277,
        newlookType = 2165, revertlookType = 2276,
        maxhp = 100, maxmana = 100, 
        newvoc = 371, revertvoc = 369,
        effect = 307, constanteffect = 70,
        name = "Kabuto Dziesięć",
        isPermanent = false
    },
    -- Vocation 371: Look 2165 -> Transform -> Vocation 372 (TEMPORARY)
    [371] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 2165,
        newlookType = 2165, revertlookType = 2277,
        maxhp = 100, maxmana = 100, 
        newvoc = 372, revertvoc = 370,
        effect = 308, constanteffect = 70,
        name = "Kabuto Jedenaście",
        isPermanent = false
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- LEE TRANSFORMATION SYSTEM - Vocation 391-420
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- Vocation 391: Look 1956 -> Transform -> Vocation 392 (PERMANENT - First form)
    [391] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 1956,
        newlookType = 1957, revertlookType = 1956,
        maxhp = 100, maxmana = 100, 
        newvoc = 392, revertvoc = 391,
        effect = 309, constanteffect = 70,
        name = "Lee Jeden",
        isPermanent = true
    },
    -- Vocation 392: Look 1957 -> Transform -> Vocation 393 (TEMPORARY)
    [392] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 1957,
        newlookType = 1960, revertlookType = 1956,
        maxhp = 100, maxmana = 100, 
        newvoc = 393, revertvoc = 391,
        effect = 310, constanteffect = 70,
        name = "Lee Dwa",
        isPermanent = false
    },
    -- Vocation 393: Look 1960 -> Transform -> Vocation 394 (TEMPORARY)
    [393] = { 
        lvl = 1, manaPerSec = 10,
        currentLookType = 1960,
        newlookType = 1961, revertlookType = 1957,
        maxhp = 100, maxmana = 100, 
        newvoc = 394, revertvoc = 392,
        effect = 311, constanteffect = 70,
        name = "Lee Trzy",
        isPermanent = false
    },
    -- Vocation 394: Look 1961 -> Transform -> Vocation 395 (TEMPORARY)
    [394] = { 
        lvl = 2, manaPerSec = 10,
        currentLookType = 1961,
        newlookType = 1966, revertlookType = 1960,
        maxhp = 100, maxmana = 100, 
        newvoc = 395, revertvoc = 393,
        effect = 312, constanteffect = 70,
        name = "Lee Cztery",
        isPermanent = false
    },
    -- Vocation 395: Look 1966 -> Transform -> Vocation 396 (PERMANENT)
    [395] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 1966,
        newlookType = 1959, revertlookType = 1961,
        maxhp = 100, maxmana = 100, 
        newvoc = 396, revertvoc = 394,
        effect = 313, constanteffect = 70,
        name = "Lee Pięć",
        isPermanent = true
    },
    -- Vocation 396: Look 1959 -> Transform -> Vocation 397 (PERMANENT)
    [396] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 1959,
        newlookType = 1962, revertlookType = 1966,
        maxhp = 100, maxmana = 100, 
        newvoc = 397, revertvoc = 395,
        effect = 314, constanteffect = 70,
        name = "Lee Sześć",
        isPermanent = true
    },
    -- Vocation 397: Look 1962 -> Transform -> Vocation 398 (TEMPORARY)
    [397] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 1962,
        newlookType = 1963, revertlookType = 1959,
        maxhp = 100, maxmana = 100, 
        newvoc = 398, revertvoc = 396,
        effect = 315, constanteffect = 70,
        name = "Lee Siedem",
        isPermanent = false
    },
    -- Vocation 398: Look 1963 -> Transform -> Vocation 399 (TEMPORARY)
    [398] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 1963,
        newlookType = 1958, revertlookType = 1962,
        maxhp = 100, maxmana = 100, 
        newvoc = 399, revertvoc = 397,
        effect = 316, constanteffect = 70,
        name = "Lee Osiem",
        isPermanent = false
    },
    -- Vocation 399: Look 1958 -> Transform -> Vocation 400 (TEMPORARY)
    [399] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 1958,
        newlookType = 1964, revertlookType = 1963,
        maxhp = 100, maxmana = 100, 
        newvoc = 400, revertvoc = 398,
        effect = 317, constanteffect = 70,
        name = "Lee Dziewięć",
        isPermanent = false
    },
    -- Vocation 400: Look 1964 -> Transform -> Vocation 401 (TEMPORARY)
    [400] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 1964,
        newlookType = 1967, revertlookType = 1958,
        maxhp = 100, maxmana = 100, 
        newvoc = 401, revertvoc = 399,
        effect = 318, constanteffect = 70,
        name = "Lee Dziesięć",
        isPermanent = false
    },
    -- Vocation 401: Look 1967 -> Transform -> Vocation 402 (TEMPORARY)
    [401] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 1967,
        newlookType = 1965, revertlookType = 1964,
        maxhp = 100, maxmana = 100, 
        newvoc = 402, revertvoc = 400,
        effect = 319, constanteffect = 70,
        name = "Lee Jedenaście",
        isPermanent = false
    },
    -- Vocation 402: Look 1965 -> Transform -> Vocation 403 (TEMPORARY)
    [402] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 1965,
        newlookType = 1990, revertlookType = 1967,
        maxhp = 100, maxmana = 100, 
        newvoc = 403, revertvoc = 401,
        effect = 320, constanteffect = 70,
        name = "Lee Dwanaście",
        isPermanent = false
    },
    -- Vocation 403: Look 1990 -> Transform -> Vocation 404 (TEMPORARY)
    [403] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1990,
        newlookType = 1991, revertlookType = 1965,
        maxhp = 100, maxmana = 100, 
        newvoc = 404, revertvoc = 402,
        effect = 321, constanteffect = 70,
        name = "Lee Trzynaście",
        isPermanent = false
    },
    -- Vocation 404: Look 1991 -> Transform -> Vocation 405 (TEMPORARY)
    [404] = { 
        lvl = 5, manaPerSec = 10,
        currentLookType = 1991,
        newlookType = 2048, revertlookType = 1990,
        maxhp = 100, maxmana = 100, 
        newvoc = 405, revertvoc = 403,
        effect = 322, constanteffect = 70,
        name = "Lee Czternaście",
        isPermanent = false
    },
    -- Vocation 405: Look 2048 -> Transform -> Vocation 406 (PERMANENT)
    [405] = { 
        lvl = 5, manaPerSec = 0,
        currentLookType = 2048,
        newlookType = 2047, revertlookType = 1991,
        maxhp = 100, maxmana = 100, 
        newvoc = 406, revertvoc = 404,
        effect = 323, constanteffect = 70,
        name = "Lee Piętnaście",
        isPermanent = true
    },
    -- Vocation 406: Look 2047 -> Transform -> Vocation 407 (TEMPORARY)
    [406] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2047,
        newlookType = 2046, revertlookType = 2048,
        maxhp = 100, maxmana = 100, 
        newvoc = 407, revertvoc = 405,
        effect = 324, constanteffect = 70,
        name = "Lee Szesnaście",
        isPermanent = false
    },
    -- Vocation 407: Look 2046 -> Transform -> Vocation 408 (TEMPORARY)
    [407] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2046,
        newlookType = 2099, revertlookType = 2047,
        maxhp = 100, maxmana = 100, 
        newvoc = 408, revertvoc = 406,
        effect = 325, constanteffect = 70,
        name = "Lee Siedemnaście",
        isPermanent = false
    },
    -- Vocation 408: Look 2099 -> Transform -> Vocation 409 (TEMPORARY)
    [408] = { 
        lvl = 6, manaPerSec = 10,
        currentLookType = 2099,
        newlookType = 2100, revertlookType = 2046,
        maxhp = 100, maxmana = 100, 
        newvoc = 409, revertvoc = 407,
        effect = 326, constanteffect = 70,
        name = "Lee Osiemnaście",
        isPermanent = false
    },
    -- Vocation 409: Look 2100 -> Transform -> Vocation 410 (TEMPORARY)
    [409] = { 
        lvl = 7, manaPerSec = 10,
        currentLookType = 2100,
        newlookType = 2101, revertlookType = 2099,
        maxhp = 100, maxmana = 100, 
        newvoc = 410, revertvoc = 408,
        effect = 327, constanteffect = 70,
        name = "Lee Dziewiętnaście",
        isPermanent = false
    },
    -- Vocation 410: Look 2101 -> Transform -> Vocation 411 (TEMPORARY)
    [410] = { 
        lvl = 7, manaPerSec = 10,
        currentLookType = 2101,
        newlookType = 2101, revertlookType = 2100,
        maxhp = 100, maxmana = 100, 
        newvoc = 411, revertvoc = 409,
        effect = 328, constanteffect = 70,
        name = "Lee Dwadzieścia",
        isPermanent = false
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- KIBA TRANSFORMATION SYSTEM - Vocation 421-450
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- Vocation 421: Look 2527 -> Transform -> Vocation 422 (PERMANENT - First form)
    [421] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2527,
        newlookType = 2292, revertlookType = 2527,
        maxhp = 100, maxmana = 100, 
        newvoc = 422, revertvoc = 421,
        effect = 339, constanteffect = 70,
        name = "Kiba Jeden",
        isPermanent = true
    },
    -- Vocation 422: Look 2292 -> Transform -> Vocation 423 (PERMANENT)
    [422] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2292,
        newlookType = 2293, revertlookType = 2527,
        maxhp = 100, maxmana = 100, 
        newvoc = 423, revertvoc = 421,
        effect = 340, constanteffect = 70,
        name = "Kiba Dwa",
        isPermanent = true
    },
    -- Vocation 423: Look 2293 -> Transform -> Vocation 424 (PERMANENT)
    [423] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2293,
        newlookType = 2294, revertlookType = 2292,
        maxhp = 100, maxmana = 100, 
        newvoc = 424, revertvoc = 422,
        effect = 341, constanteffect = 70,
        name = "Kiba Trzy",
        isPermanent = true
    },
    -- Vocation 424: Look 2294 -> Transform -> Vocation 425 (TEMPORARY)
    [424] = { 
        lvl = 2, manaPerSec = 10,
        currentLookType = 2294,
        newlookType = 2528, revertlookType = 2293,
        maxhp = 100, maxmana = 100, 
        newvoc = 425, revertvoc = 423,
        effect = 342, constanteffect = 70,
        name = "Kiba Cztery",
        isPermanent = false
    },
    -- Vocation 425: Look 2528 -> Transform -> Vocation 426 (PERMANENT)
    [425] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2528,
        newlookType = 2138, revertlookType = 2294,
        maxhp = 100, maxmana = 100, 
        newvoc = 426, revertvoc = 424,
        effect = 343, constanteffect = 70,
        name = "Kiba Pięć",
        isPermanent = true
    },
    -- Vocation 426: Look 2138 -> Transform -> Vocation 427 (PERMANENT)
    [426] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2138,
        newlookType = 2140, revertlookType = 2528,
        maxhp = 100, maxmana = 100, 
        newvoc = 427, revertvoc = 425,
        effect = 344, constanteffect = 70,
        name = "Kiba Sześć",
        isPermanent = true
    },
    -- Vocation 427: Look 2140 -> Transform -> Vocation 428 (PERMANENT)
    [427] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 2140,
        newlookType = 2139, revertlookType = 2138,
        maxhp = 100, maxmana = 100, 
        newvoc = 428, revertvoc = 426,
        effect = 345, constanteffect = 70,
        name = "Kiba Siedem",
        isPermanent = true
    },
    -- Vocation 428: Look 2139 -> Transform -> Vocation 429 (TEMPORARY)
    [428] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 2139,
        newlookType = 2526, revertlookType = 2140,
        maxhp = 100, maxmana = 100, 
        newvoc = 429, revertvoc = 427,
        effect = 346, constanteffect = 70,
        name = "Kiba Osiem",
        isPermanent = false
    },
    -- Vocation 429: Look 2526 -> Transform -> Vocation 430 (PERMANENT)
    [429] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 2526,
        newlookType = 2526, revertlookType = 2139,
        maxhp = 100, maxmana = 100, 
        newvoc = 430, revertvoc = 428,
        effect = 347, constanteffect = 70,
        name = "Kiba Dziewięć",
        isPermanent = true
    },
    -- Vocation 430: Look 2526 -> Transform -> Vocation 431 (PERMANENT with mana burn)
    [430] = { 
        lvl = 4, manaPerSec = 10,
        currentLookType = 2526,
        newlookType = 2526, revertlookType = 2526,
        maxhp = 100, maxmana = 100, 
        newvoc = 431, revertvoc = 429,
        effect = 348, constanteffect = 70,
        name = "Kiba Dziesięć",
        isPermanent = true
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- TEN TEN TRANSFORMATION SYSTEM - Vocation 451-480
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- Vocation 451: Look 2468 -> Transform -> Vocation 452 (PERMANENT - First form)
    [451] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2468,
        newlookType = 2467, revertlookType = 2468,
        maxhp = 100, maxmana = 100, 
        newvoc = 452, revertvoc = 451,
        effect = 349, constanteffect = 70,
        name = "Ten Ten Jeden",
        isPermanent = true
    },
    -- Vocation 452: Look 2467 -> Transform -> Vocation 453 (PERMANENT)
    [452] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2467,
        newlookType = 2466, revertlookType = 2468,
        maxhp = 100, maxmana = 100, 
        newvoc = 453, revertvoc = 451,
        effect = 350, constanteffect = 70,
        name = "Ten Ten Dwa",
        isPermanent = true
    },
    -- Vocation 453: Look 2466 -> Transform -> Vocation 454 (PERMANENT)
    [453] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2466,
        newlookType = 2465, revertlookType = 2467,
        maxhp = 100, maxmana = 100, 
        newvoc = 454, revertvoc = 452,
        effect = 351, constanteffect = 70,
        name = "Ten Ten Trzy",
        isPermanent = true
    },
    -- Vocation 454: Look 2465 -> Transform -> Vocation 455 (PERMANENT)
    [454] = { 
        lvl = 1, manaPerSec = 0,
        currentLookType = 2465,
        newlookType = 2464, revertlookType = 2466,
        maxhp = 100, maxmana = 100, 
        newvoc = 455, revertvoc = 453,
        effect = 352, constanteffect = 70,
        name = "Ten Ten Cztery",
        isPermanent = true
    },
    -- Vocation 455: Look 2464 -> Transform -> Vocation 456 (PERMANENT)
    [455] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2464,
        newlookType = 2494, revertlookType = 2465,
        maxhp = 100, maxmana = 100, 
        newvoc = 456, revertvoc = 454,
        effect = 353, constanteffect = 70,
        name = "Ten Ten Pięć",
        isPermanent = true
    },
    -- Vocation 456: Look 2494 -> Transform -> Vocation 457 (PERMANENT)
    [456] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2494,
        newlookType = 2529, revertlookType = 2464,
        maxhp = 100, maxmana = 100, 
        newvoc = 457, revertvoc = 455,
        effect = 354, constanteffect = 70,
        name = "Ten Ten Sześć",
        isPermanent = true
    },
    -- Vocation 457: Look 2529 -> Transform -> Vocation 458 (PERMANENT)
    [457] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2529,
        newlookType = 2495, revertlookType = 2494,
        maxhp = 100, maxmana = 100, 
        newvoc = 458, revertvoc = 456,
        effect = 355, constanteffect = 70,
        name = "Ten Ten Siedem",
        isPermanent = true
    },
    -- Vocation 458: Look 2495 -> Transform -> Vocation 459 (PERMANENT)
    [458] = { 
        lvl = 2, manaPerSec = 0,
        currentLookType = 2495,
        newlookType = 2020, revertlookType = 2529,
        maxhp = 100, maxmana = 100, 
        newvoc = 459, revertvoc = 457,
        effect = 356, constanteffect = 70,
        name = "Ten Ten Osiem",
        isPermanent = true
    },
    -- Vocation 459: Look 2020 -> Transform -> Vocation 460 (PERMANENT)
    [459] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 2020,
        newlookType = 2021, revertlookType = 2495,
        maxhp = 100, maxmana = 100, 
        newvoc = 460, revertvoc = 458,
        effect = 357, constanteffect = 70,
        name = "Ten Ten Dziewięć",
        isPermanent = true
    },
    -- Vocation 460: Look 2021 -> Transform -> Vocation 461 (PERMANENT with mana burn)
    [460] = { 
        lvl = 3, manaPerSec = 10,
        currentLookType = 2021,
        newlookType = 2022, revertlookType = 2020,
        maxhp = 100, maxmana = 100, 
        newvoc = 461, revertvoc = 459,
        effect = 358, constanteffect = 70,
        name = "Ten Ten Dziesięć",
        isPermanent = true
    },
    -- Vocation 461: Look 2022 -> Transform -> Vocation 462 (PERMANENT)
    [461] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 2022,
        newlookType = 2023, revertlookType = 2021,
        maxhp = 100, maxmana = 100, 
        newvoc = 462, revertvoc = 460,
        effect = 359, constanteffect = 70,
        name = "Ten Ten Jedenaście",
        isPermanent = true
    },
    -- Vocation 462: Look 2023 -> Transform -> Vocation 463 (PERMANENT)
    [462] = { 
        lvl = 3, manaPerSec = 0,
        currentLookType = 2023,
        newlookType = 2463, revertlookType = 2022,
        maxhp = 100, maxmana = 100, 
        newvoc = 463, revertvoc = 461,
        effect = 360, constanteffect = 70,
        name = "Ten Ten Dwanaście",
        isPermanent = true
    },
    -- Vocation 463: Look 2463 -> Transform -> Vocation 464 (PERMANENT)
    [463] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 2463,
        newlookType = 2493, revertlookType = 2023,
        maxhp = 100, maxmana = 100, 
        newvoc = 464, revertvoc = 462,
        effect = 361, constanteffect = 70,
        name = "Ten Ten Trzynaście",
        isPermanent = true
    },
    -- Vocation 464: Look 2493 -> Transform -> Vocation 465 (PERMANENT)
    [464] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 2493,
        newlookType = 2484, revertlookType = 2463,
        maxhp = 100, maxmana = 100, 
        newvoc = 465, revertvoc = 463,
        effect = 362, constanteffect = 70,
        name = "Ten Ten Czternaście",
        isPermanent = true
    },
    -- Vocation 465: Look 2484 -> Transform -> Vocation 466 (PERMANENT)
    [465] = { 
        lvl = 4, manaPerSec = 0,
        currentLookType = 2484,
        newlookType = 2484, revertlookType = 2493,
        maxhp = 100, maxmana = 100, 
        newvoc = 466, revertvoc = 464,
        effect = 363, constanteffect = 70,
        name = "Ten Ten Piętnaście",
        isPermanent = true
    },
}

-- ════════════════════════════════════════════════════════════════════════════
-- CACHE SYSTEM - Zarządzanie pamięcią
-- ════════════════════════════════════════════════════════════════════════════

if transformCache == nil then
    transformCache = {
        effect = {},
        burnMana = {},
        stats = {} -- Statystyki transformacji
    }
end

-- Czyszczenie cache gracza przy wylogowaniu
local function cleanupPlayerCache(playerId)
    if transformCache.effect[playerId] then
        stopEvent(transformCache.effect[playerId])
        transformCache.effect[playerId] = nil
    end
    if transformCache.burnMana[playerId] then
        stopEvent(transformCache.burnMana[playerId])
        transformCache.burnMana[playerId] = nil
    end
end

-- ════════════════════════════════════════════════════════════════════════════
-- FUNKCJE POMOCNICZE
-- ════════════════════════════════════════════════════════════════════════════

-- Walidacja danych transformacji
local function validateTransformData(data)
    if not data then return false end
    if not data.newvoc or not data.revertvoc then return false end
    if not data.newlookType or not data.revertlookType then return false end
    return true
end

-- Logowanie transformacji (opcjonalne)
local function logTransform(player, fromVoc, toVoc, transformType)
    if not CONFIG.LOG_TRANSFORMS then return end
    
    -- TODO: Dodaj zapytanie SQL do logowania
    print(string.format("[TRANSFORM] %s: %d -> %d (%s)", 
        player:getName(), fromVoc, toVoc, transformType))
end

-- Aktualizacja statystyk gracza
local function updateTransformStats(player)
    local count = player:getStorageValue(CONFIG.STORAGE_TRANSFORM_COUNT)
    if count < 0 then count = 0 end
    player:setStorageValue(CONFIG.STORAGE_TRANSFORM_COUNT, count + 1)
end

-- Broadcast dla epickich transformacji
local function broadcastEpicTransform(player, transformData)
    if CONFIG.BROADCAST_FINAL_FORM and transformData.isFinalForm then
        Game.broadcastMessage(
            player:getName() .. " osiągnął " .. transformData.name .. "!",
            MESSAGE_EVENT_ADVANCE
        )
        -- Efekt na całym świecie (opcjonalnie)
        for _, p in pairs(Game.getPlayers()) do
            p:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
        end
    end
end

-- ════════════════════════════════════════════════════════════════════════════
-- FUNKCJA: Spalanie many
-- ════════════════════════════════════════════════════════════════════════════

function addTransformBurnMana(playerId, manaCount)
    local player = Player(playerId)
    if not player then
        cleanupPlayerCache(playerId)
        return
    end
    
    -- Zatrzymaj poprzedni event
    if transformCache.burnMana[playerId] then
        stopEvent(transformCache.burnMana[playerId])
        transformCache.burnMana[playerId] = nil
    end
    
    -- Jeśli nie ma spalania, zakończ
    if not manaCount or manaCount <= 0 then
        return
    end
    
    -- Sprawdź manę
    local currentMana = player:getMana()
    if currentMana < CONFIG.MIN_MANA_FOR_TRANSFORM then
        player:addMana(-currentMana)
        player:getPosition():sendMagicEffect(CONFIG.AUTO_REVERT_EFFECT)
        player:doRevert(true)
        player:sendTextMessage(MESSAGE_STATUS_SMALL, 
            "Zabrakło ci many! Transformacja została przerwana.")
        cleanupPlayerCache(playerId)
        return
    end
    
    -- Odejmij manę
    player:addMana(-manaCount)
    
    -- Zaplanuj następne spalanie
    transformCache.burnMana[playerId] = addEvent(
        addTransformBurnMana, 
        1000, 
        playerId, 
        manaCount
    )
end

-- ════════════════════════════════════════════════════════════════════════════
-- FUNKCJA: Efekty wizualne
-- ════════════════════════════════════════════════════════════════════════════

function addTransformEffect(playerId, effect)
    local player = Player(playerId)
    if not player then
        cleanupPlayerCache(playerId)
        return
    end
    
    -- Zatrzymaj poprzedni efekt
    if transformCache.effect[playerId] then
        stopEvent(transformCache.effect[playerId])
        transformCache.effect[playerId] = nil
    end
    
    if not effect or effect <= 100 then
        return
    end
    
    -- Pokaż efekt
    player:getPosition():sendMagicEffect(effect)
    
    -- Zaplanuj następny efekt
    transformCache.effect[playerId] = addEvent(
        addTransformEffect, 
        1000, 
        playerId, 
        effect
    )
end

-- ════════════════════════════════════════════════════════════════════════════
-- FUNKCJA: Revert (Cofanie transformacji)
-- ════════════════════════════════════════════════════════════════════════════

function Player.doRevert(self, force)
    if not self then return false end
   
    local vocationId = self:getVocation():getId()
    local transformData = SystemTransformData[vocationId]
    
    if not validateTransformData(transformData) then
        self:sendTextMessage(MESSAGE_STATUS_SMALL, 
            "Błąd systemu transformacji. Skontaktuj się z GM.")
        return false
    end
   
    -- Sprawdź czy to forma stała (permanent) - z niej NIE można się cofnąć
    if transformData.isPermanent then
        if not force then
            self:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
                "To jest forma stała! Nie możesz się z niej cofnąć. Użyj !transform aby iść dalej.")
        end
        return false
    end
    
    -- Sprawdź czy to pierwsza forma
    if vocationId == 1 then
        if not force then
            self:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
                "Jesteś w formie bazowej. Nie możesz się cofnąć!")
        end
        return false
    end
    
    local revertData = SystemTransformData[transformData.revertvoc]
    if not validateTransformData(revertData) then
        return false
    end
    
    local playerId = self:getId()
    
    -- Zapisz obecne proporcje HP/Many
    local currentHpPercent = self:getHealth() / self:getMaxHealth()
    local currentManaPercent = self:getMana() / self:getMaxMana()
    
    -- Zmień vocation
    self:setVocation(transformData.revertvoc)
    
    -- Zapisz aktualną vocation do storage
    self:setStorageValue(CONFIG.STORAGE_CURRENT_VOCATION, transformData.revertvoc)
    
    -- Zmień wygląd na CURRENTLOOKTYPE poprzedniej vocation (nie revertlookType!)
    self:setOutfit({lookType = revertData.currentLookType})
    
    -- Odejmij bonusy od maksymalnych wartości
    local newMaxHp = math.max(1, self:getMaxHealth() - transformData.maxhp)
    local newMaxMana = math.max(0, self:getMaxMana() - transformData.maxmana)
    self:setMaxHealth(newMaxHp)
    self:setMaxMana(newMaxMana)
    
    -- Ustaw obecne HP/Manę proporcjonalnie
    self:addHealth(math.floor(newMaxHp * currentHpPercent) - self:getHealth())
    self:addMana(math.floor(newMaxMana * currentManaPercent) - self:getMana())
    
    -- Ustaw efekty nowej formy
    addTransformEffect(playerId, revertData.constanteffect)
    addTransformBurnMana(playerId, revertData.manaPerSec)
 
    -- Log
    logTransform(self, vocationId, transformData.revertvoc, "REVERT")
    
    if not force then
        self:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
            "Powróciłeś do formy: " .. (revertData.name or "Base"))
        self:getPosition():sendMagicEffect(CONST_ME_POFF)
    end
    
    return true
end

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT: Login gracza
-- ════════════════════════════════════════════════════════════════════════════

local transformOnLogin = CreatureEvent("transformOnLogin")
function transformOnLogin.onLogin(player)
    local playerId = player:getId()
    local vocationId = player:getVocation():getId()
    
    -- NAJPIERW wyczyść stary cache (żeby nie było konfliktów)
    cleanupPlayerCache(playerId)
    
    -- Sprawdź czy gracz ma zapisaną vocation ze storage
    local savedVocation = player:getStorageValue(CONFIG.STORAGE_CURRENT_VOCATION)
    
    if savedVocation > 0 and savedVocation ~= vocationId then
        -- Gracz ma inną vocation niż zapisaną - TFS resetował do bazowej
        -- Zapisz proporcje HP/Mana PRZED zmianą
        local hpPercent = player:getHealth() / math.max(1, player:getMaxHealth())
        local manaPercent = player:getMana() / math.max(1, player:getMaxMana())
        
        -- Przywróć zapisaną vocation
        player:setVocation(savedVocation)
        vocationId = savedVocation
        
        -- Przywróć HP/Mana proporcjonalnie
        local newMaxHp = player:getMaxHealth()
        local newMaxMana = player:getMaxMana()
        player:addHealth(math.floor(newMaxHp * hpPercent) - player:getHealth())
        player:addMana(math.floor(newMaxMana * manaPercent) - player:getMana())
    end
    
    -- Pobierz dane transformacji dla obecnej vocation (TERAZ po przywróceniu vocation!)
    local transformData = SystemTransformData[vocationId]
    if not validateTransformData(transformData) then
        return true
    end
    
    -- Zapisz ostatnią permanent vocation jeśli obecna jest permanent
    if transformData.isPermanent and vocationId > 1 then
        player:setStorageValue(CONFIG.STORAGE_LAST_PERMANENT_VOC, vocationId)
    end
    
    -- Ustaw prawidłowy look type dla vocation gracza
    if transformData.currentLookType then
        player:setOutfit({lookType = transformData.currentLookType})
    end
   
    -- DEBUGOWANIE: Sprawdź czy manaPerSec > 0
    local manaPerSecValue = transformData.manaPerSec or 0
    print(string.format("[TRANSFORM DEBUG] Login voc %d: manaPerSec = %d", vocationId, manaPerSecValue))
    
    -- Inicjalizuj efekty (spalanie many dla temporary form) - TERAZ z poprawnymi danymi!
    if manaPerSecValue > 0 then
        print(string.format("[TRANSFORM DEBUG] Starting mana burn for player %s: %d/sec", player:getName(), manaPerSecValue))
        addTransformBurnMana(playerId, manaPerSecValue)
    else
        print(string.format("[TRANSFORM DEBUG] No mana burn for player %s (permanent form)", player:getName()))
    end
    
    addTransformEffect(playerId, transformData.constanteffect)
    
    return true
end
transformOnLogin:register()

-- Czyszczenie cache przy wylogowaniu
local transformOnLogout = CreatureEvent("transformOnLogout")
function transformOnLogout.onLogout(player)
    -- Zapisz aktualną vocation do storage
    local vocationId = player:getVocation():getId()
    player:setStorageValue(CONFIG.STORAGE_CURRENT_VOCATION, vocationId)
    
    cleanupPlayerCache(player:getId())
    return true
end
transformOnLogout:register()

-- ════════════════════════════════════════════════════════════════════════════
-- KOMENDA: !transform
-- ════════════════════════════════════════════════════════════════════════════

local transformTalk = TalkAction("!transform", "transform")
function transformTalk.onSay(player, words, param)
    local currentTime = os.time()
    local lastUsageTime = player:getStorageValue(CONFIG.STORAGE_COOLDOWN)
    
    -- Sprawdź cooldown
    if lastUsageTime ~= -1 and currentTime < lastUsageTime then
        local remainingCooldown = lastUsageTime - currentTime
        player:sendCancelMessage(
            "Musisz poczekać jeszcze " .. remainingCooldown .. " sekund."
        )
        return false
    end
    
    local vocationId = player:getVocation():getId()
    local transformData = SystemTransformData[vocationId]
    
    if not validateTransformData(transformData) then
        player:sendCancelMessage("Nie możesz się transformować!")
        return false
    end
    
    -- Sprawdź poziom
    if player:getLevel() < transformData.lvl then
        player:sendCancelMessage(
            "Potrzebujesz poziomu " .. transformData.lvl .. " aby się transformować!"
        )
        player:setStorageValue(CONFIG.STORAGE_COOLDOWN, currentTime + CONFIG.COOLDOWN)
        return false
    end
    
    -- Sprawdź czy to ostatnia forma
    if vocationId == transformData.newvoc then
        player:sendCancelMessage(
            "Osiągnąłeś maksymalną moc! To twoja ostatnia forma."
        )
        player:setStorageValue(CONFIG.STORAGE_COOLDOWN, currentTime + CONFIG.COOLDOWN)
        return false
    end
    
    -- Sprawdź wymagany item
    if CONFIG.REQUIRE_TRANSFORM_ITEM then
        if not player:removeItem(CONFIG.TRANSFORM_ITEM_ID, 1) then
            player:sendCancelMessage("Potrzebujesz specjalnego itemu do transformacji!")
            return false
        end
    end
    
    local nextTransformData = SystemTransformData[transformData.newvoc]
    if not validateTransformData(nextTransformData) then
        nextTransformData = transformData
    end
   
    local playerId = player:getId()
    
    -- Zmień vocation NAJPIERW
    player:setVocation(transformData.newvoc)
    
    -- Zapisz aktualną vocation do storage
    player:setStorageValue(CONFIG.STORAGE_CURRENT_VOCATION, transformData.newvoc)
    
    -- Zapisz ostatnią permanent vocation jeśli następna forma jest stała
    if nextTransformData.isPermanent then
        player:setStorageValue(CONFIG.STORAGE_LAST_PERMANENT_VOC, transformData.newvoc)
    end
    
    -- Dodaj bonusy do maksymalnych wartości
    local newMaxHp = player:getMaxHealth() + (nextTransformData.maxhp or 0)
    local newMaxMana = player:getMaxMana() + (nextTransformData.maxmana or 0)
    player:setMaxHealth(newMaxHp)
    player:setMaxMana(newMaxMana)
    
    -- Uzupełnij HP i Manę do MAKSIMUM (bonus transformacji)
    player:addHealth(newMaxHp - player:getHealth())
    player:addMana(newMaxMana - player:getMana())
    
    -- Zmień wygląd na OBECNY look type nowej vocation (nie newlookType!)
    player:setOutfit({lookType = nextTransformData.currentLookType})
    player:getPosition():sendMagicEffect(nextTransformData.effect or CONST_ME_FIREWORK_RED)
    
    -- Ustaw nowe efekty
    addTransformEffect(playerId, nextTransformData.constanteffect)
    addTransformBurnMana(playerId, nextTransformData.manaPerSec or 0)
    
    -- Wiadomość
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
        "Transformacja do: " .. (nextTransformData.name or "Unknown") .. "!")
    
    -- Broadcast dla epickich form
    broadcastEpicTransform(player, nextTransformData)
    
    -- Statystyki
    updateTransformStats(player)
    
    -- Log
    logTransform(player, vocationId, transformData.newvoc, "TRANSFORM")
    
    -- Cooldown
    player:setStorageValue(CONFIG.STORAGE_COOLDOWN, currentTime + CONFIG.COOLDOWN)
    
    return false
end
transformTalk:register()

-- ════════════════════════════════════════════════════════════════════════════
-- KOMENDA: !revert
-- ════════════════════════════════════════════════════════════════════════════

local revertTalk = TalkAction("!revert", "revert")
function revertTalk.onSay(player, words, param)
    local currentTime = os.time()
    local lastUsageTime = player:getStorageValue(CONFIG.STORAGE_COOLDOWN)
    
    -- Sprawdź cooldown
    if lastUsageTime ~= -1 and currentTime < lastUsageTime then
        local remainingCooldown = lastUsageTime - currentTime
        player:sendCancelMessage(
            "Musisz poczekać jeszcze " .. remainingCooldown .. " sekund."
        )
        return false
    end
    
    player:setStorageValue(CONFIG.STORAGE_COOLDOWN, currentTime + CONFIG.COOLDOWN)
    player:doRevert(false)
    
    return false
end
revertTalk:register()

-- ════════════════════════════════════════════════════════════════════════════
-- KOMENDA: !transforminfo (Nowa - info o transformacjach)
-- ════════════════════════════════════════════════════════════════════════════

local transformInfo = TalkAction("!transforminfo")
function transformInfo.onSay(player, words, param)
    local vocationId = player:getVocation():getId()
    local transformData = SystemTransformData[vocationId]
    
    if not validateTransformData(transformData) then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Brak dostępnych transformacji.")
        return false
    end
    
    local currentOutfit = player:getOutfit()
    local currentLook = currentOutfit.lookType
    
    local message = "╔════ DEBUG TRANSFORMACJI ════╗\n"
    message = message .. "║ OBECNA FORMA:\n"
    message = message .. "║ Nazwa: " .. (transformData.name or "Unknown") .. "\n"
    message = message .. "║ Vocation ID: " .. vocationId .. "\n"
    message = message .. "║ Look Type (obecny): " .. currentLook .. "\n"
    message = message .. "║ Look Type (oczekiwany): " .. (transformData.currentLookType or "brak") .. "\n"
    
    if currentLook ~= transformData.currentLookType then
        message = message .. "║ ⚠️ BŁĄD: Look type się nie zgadza!\n"
    else
        message = message .. "║ ✓ Look type poprawny\n"
    end
    
    if transformData.isPermanent then
        message = message .. "║ Typ: FORMA STAŁA (nie można cofnąć)\n"
    else
        message = message .. "║ Typ: Forma okresowa\n"
        message = message .. "║ Spalanie many: " .. (transformData.manaPerSec or 0) .. "/sek\n"
    end
    
    message = message .. "║\n║ TRANSFORMACJA (!transform):\n"
    local nextData = SystemTransformData[transformData.newvoc]
    if nextData and vocationId ~= transformData.newvoc then
        message = message .. "║ Następna: " .. (nextData.name or "Unknown") .. "\n"
        message = message .. "║ Vocation: " .. vocationId .. " -> " .. transformData.newvoc .. "\n"
        message = message .. "║ Look: " .. currentLook .. " -> " .. transformData.newlookType .. "\n"
        message = message .. "║ Wymagany lvl: " .. (nextData.lvl or 1) .. "\n"
        message = message .. "║ Bonus HP: +" .. (nextData.maxhp or 0) .. "\n"
        message = message .. "║ Bonus Mana: +" .. (nextData.maxmana or 0) .. "\n"
    else
        message = message .. "║ To jest OSTATNIA FORMA!\n"
    end
    
    message = message .. "║\n║ REVERT (!revert):\n"
    if transformData.isPermanent then
        message = message .. "║ ❌ NIEMOŻLIWY (forma stała)\n"
    elseif vocationId == 1 then
        message = message .. "║ ❌ NIEMOŻLIWY (forma bazowa)\n"
    else
        local prevData = SystemTransformData[transformData.revertvoc]
        if prevData then
            message = message .. "║ Poprzednia: " .. (prevData.name or "Unknown") .. "\n"
            message = message .. "║ Vocation: " .. vocationId .. " -> " .. transformData.revertvoc .. "\n"
            message = message .. "║ Look: " .. currentLook .. " -> " .. transformData.revertlookType .. "\n"
        else
            message = message .. "║ ⚠️ BŁĄD: Brak danych o poprzedniej formie!\n"
        end
    end
    
    message = message .. "║\n║ STATYSTYKI:\n"
    message = message .. "║ HP: " .. player:getHealth() .. "/" .. player:getMaxHealth() .. "\n"
    message = message .. "║ Mana: " .. player:getMana() .. "/" .. player:getMaxMana() .. "\n"
    
    local transformCount = player:getStorageValue(CONFIG.STORAGE_TRANSFORM_COUNT)
    if transformCount > 0 then
        message = message .. "║ Liczba transformacji: " .. transformCount .. "\n"
    end
    
    message = message .. "╚═════════════════════════════╝"
    
    player:showTextDialog(1950, message)
    return false
end
transformInfo:register()

print(">> Transform System v2.0 loaded successfully!")
print(">> Total vocations configured: " .. #SystemTransformData)
