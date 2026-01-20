# Исправление редкости способности "Уворот" на Необычную

## ✅ Исправление выполнено:

### **Изменена редкость способности:**
- **"Уворот"** (`dodge`) теперь **необычная (uncommon)** способность
- **Перемещена** из папки `Common/` в папку `Uncommon/`
- **Обновлена** конфигурация загрузки в PassiveAbilityManager

## 🔧 Выполненные изменения:

### **1. Изменена редкость в файле способности:**
```gdscript
# Файл: Scripts/PassiveAbilities/Uncommon/Dodge.gd
func _init():
    id = "dodge"
    name = "Уворот"
    description = "10% шанс увернуться от атаки"
    rarity = "uncommon"  # ✅ Изменено с "common" на "uncommon"
    ability_type = AbilityType.DEFENSIVE
    trigger_type = TriggerType.ON_DAMAGE_TAKEN
    value = 10.0  # 10% шанс уворота
```

### **2. Перемещен файл:**
- **Было**: `Scripts/PassiveAbilities/Common/Dodge.gd`
- **Стало**: `Scripts/PassiveAbilities/Uncommon/Dodge.gd`

### **3. Обновлен PassiveAbilityManager:**
```gdscript
# Удалено из _load_common_abilities():
# var dodge = load("res://Scripts/PassiveAbilities/Common/Dodge.gd").new()

# Добавлено в _load_uncommon_abilities():
var dodge = load("res://Scripts/PassiveAbilities/Uncommon/Dodge.gd").new()
abilities["dodge"] = dodge
```

### **4. Конфигурация изучения осталась правильной:**
```gdscript
# Файл: Scripts/Systems/AbilityLearningSystem.gd
"dodge": {
    "name": "Уворот",
    "required_progress": 100,
    "sources": {
        "uncommon_rat": 10,   # 10% за необычную крысу
        "rare_rat": 10,        # 10% за редкую крысу
        "epic_rat": 10,        # 10% за эпическую крысу
        "legendary_rat": 10   # 10% за легендарную крысу
    }
}
```

### **5. Конфигурация врагов осталась правильной:**
```gdscript
# Файл: Scripts/PassiveAbilities/EnemyPassiveConfig.gd
"Крыса": {
    "common": ["rat_vitality"],  # ✅ dodge убрана из common
    "uncommon": ["rat_vitality", "dodge"],  # ✅ dodge доступна от uncommon+
    "rare": ["rat_vitality", "dodge", "blood_flow"],
    "epic": ["rat_vitality", "dodge", "blood_flow", "agility"],
    "legendary": ["rat_vitality", "dodge", "blood_flow", "agility", "cornered"]
}
```

## 🎯 Логика необычной редкости:

### **Почему "Уворот" должна быть необычной:**

#### **1. Мощность способности:**
- **10% шанс полного уклонения** от атаки
- **Полная защита** от урона при срабатывании
- **Базовый защитный механизм** для выживания

#### **2. Стратегическая ценность:**
- **Критически важная** способность для выживания
- **Основа защитной стратегии** персонажа
- **Высокая ценность** в сложных боях

#### **3. Баланс игры:**
- **Не должна быть слишком доступной** (common)
- **Достаточно мощная** для uncommon редкости
- **Логичная прогрессия** изучения

## 📊 Обновленная статистика по редкости:

### **🟢 ОБЫЧНЫЕ (Common) - 5 способностей:**
- `quick_strike`, `rat_bite`, `restlessness`, `bat_speed`, `rat_vitality`

### **🟡 НЕОБЫЧНЫЕ (Uncommon) - 6 способностей:**
- `dodge` ✅, `blood_flow`, `alkara_vampirism`, `curse_magic`, `mouse_nimble`, `sharp_claws`

### **🔵 РЕДКИЕ (Rare) - 10 способностей:**
- `demon_strength`, `executioner_rage`, `tharnok_shield`, `blood_sucker`, `infection`, `alkara_blood_ritual`, `curse_weakness`, `executioner_guillotine`, `tharnok_armor`, `ninja_assassinate`

### **🟣 ЭПИЧЕСКИЕ (Epic) - 11 способностей:**
- `life_steal`, `blood_bleeding`, `agility`, `ninja_shadow`, `ninja_shadow_strike`, `mouse_pack`, `echolocation`, `alkara_soul_drain`, `curse_cursed`, `executioner_judgment`, `demon_vitality`, `ninja_lethality`

### **🟠 ЛЕГЕНДАРНЫЕ (Legendary) - 9 способностей:**
- `cornered`, `mouse_king`, `silent_song`, `alkara_demon_lord`, `curse_master`, `executioner_final`, `tharnok_guardian`, `tharnok_mastery`, `ninja_master`

## 🎮 Игровой эффект:

### **Улучшенный баланс:**
- **Необычная редкость** соответствует важности способности
- **Правильная стоимость** - 300 осколков душ
- **Логичная доступность** - от необычных+ крыс

### **Прогрессия изучения крыс:**
1. **Common** → `rat_vitality`, `quick_strike`
2. **Uncommon** → `dodge` ✅ (теперь необычная)
3. **Rare** → `blood_flow`
4. **Epic** → `agility`
5. **Legendary** → `cornered`

### **Обновленная конфигурация врагов:**

#### **Крыса:**
- **Common**: `rat_vitality`
- **Uncommon**: `rat_vitality` + `dodge` ✅
- **Rare**: `rat_vitality` + `dodge` + `blood_flow`
- **Epic**: `rat_vitality` + `dodge` + `blood_flow` + `agility`
- **Legendary**: `rat_vitality` + `dodge` + `blood_flow` + `agility` + `cornered`

#### **Заглушка:**
- **Common**: `dodge` ✅ (теперь необычная)
- **Uncommon**: `dodge` + `quick_strike`
- **Rare**: `dodge` + `quick_strike` + `blood_flow`
- **Epic**: `dodge` + `quick_strike` + `blood_flow` + `agility`
- **Legendary**: `dodge` + `quick_strike` + `blood_flow` + `agility` + `cornered`

## ✅ Статус: Исправлено

Теперь "Уворот" корректно определена как необычная способность и доступна для изучения от необычных+ крыс!
