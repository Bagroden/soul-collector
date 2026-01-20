# Перенос "Гильотина палача" в эпические способности

## ✅ Изменения выполнены:

### **Изменена редкость способности:**
- **"Гильотина палача"** (`executioner_guillotine`) перенесена из **редких (rare)** в **эпические (epic)** способности
- **Перемещена** из папки `Rare/` в папку `Epic/`

## 🔧 Выполненные изменения:

### **1. Изменена редкость в файле способности:**
```gdscript
# Файл: Scripts/PassiveAbilities/Epic/ExecutionerGuillotine.gd
func _init():
    id = "executioner_guillotine"
    name = "Гильотина палача"
    description = "Увеличивает критический урон в 3 раза"
    rarity = "epic"  # ✅ Изменено с "rare" на "epic"
    ability_type = AbilityType.OFFENSIVE
    trigger_type = TriggerType.PASSIVE  # Постоянная способность
    value = 3.0  # Множитель критического урона
```

### **2. Перемещен файл:**
- **Было**: `Scripts/PassiveAbilities/Rare/ExecutionerGuillotine.gd`
- **Стало**: `Scripts/PassiveAbilities/Epic/ExecutionerGuillotine.gd`

### **3. Обновлен комментарий:**
```gdscript
# Было:
# res://Scripts/PassiveAbilities/Rare/ExecutionerGuillotine.gd

# Стало:
# res://Scripts/PassiveAbilities/Epic/ExecutionerGuillotine.gd  ✅
```

### **4. Обновлен PassiveAbilityManager:**
```gdscript
# Удалено из _load_rare_abilities():
# var executioner_guillotine = load("res://Scripts/PassiveAbilities/Rare/ExecutionerGuillotine.gd").new()

# Добавлено в _load_epic_abilities():
var executioner_guillotine = load("res://Scripts/PassiveAbilities/Epic/ExecutionerGuillotine.gd").new()
abilities["executioner_guillotine"] = executioner_guillotine
```

### **5. Обновлена конфигурация врагов:**
```gdscript
# Файл: Scripts/PassiveAbilities/EnemyPassiveConfig.gd
"ExecutionerDemon": {
    "common": ["executioner_rage"],
    "uncommon": ["executioner_rage", "demon_strength"],
    "rare": ["executioner_rage", "demon_strength"],  # ✅ Убрана executioner_guillotine
    "epic": ["executioner_rage", "demon_strength", "executioner_guillotine", "executioner_judgment"],  # ✅ Добавлена в epic
    "legendary": ["executioner_rage", "demon_strength", "executioner_guillotine", "executioner_judgment", "executioner_final"]
}
```

### **6. Добавлена конфигурация изучения:**
```gdscript
# Файл: Scripts/Systems/AbilityLearningSystem.gd
"executioner_guillotine": {
    "name": "Гильотина палача",
    "required_progress": 100,
    "sources": {
        "epic_ExecutionerDemon": 10,        # ✅ 10% за эпического демона палача
        "legendary_ExecutionerDemon": 10   # ✅ 10% за легендарного демона палача
    }
}
```

## 🎯 Логика эпической редкости:

### **Почему "Гильотина палача" должна быть эпической:**

#### **1. Мощность способности:**
- **Увеличивает критический урон в 3 раза** - очень мощный эффект
- **Постоянная способность** - работает всегда
- **Значительное усиление** боевой эффективности

#### **2. Стратегическая ценность:**
- **Критически важная** для боевых сборок
- **Высокая ценность** в сложных боях
- **Мощное усиление** атакующих способностей

#### **3. Баланс игры:**
- **Не должна быть слишком доступной** (rare)
- **Достаточно мощная** для epic редкости
- **Логичная прогрессия** изучения

## 📊 Обновленная статистика по редкости:

### **🔵 РЕДКИЕ (Rare) - 8 способностей:**
- `demon_strength` (Демон колдун), `executioner_rage`, `tharnok_shield`, `blood_sucker`, `infection`, `alkara_blood_ritual`, `tharnok_armor`, `ninja_assassinate`

### **🟣 ЭПИЧЕСКИЕ (Epic) - 12 способностей:**
- `life_steal`, `blood_bleeding`, `agility`, `ninja_shadow`, `ninja_shadow_strike`, `mouse_pack`, `echolocation`, `alkara_soul_drain`, `curse_cursed`, `executioner_guillotine` ✅, `executioner_judgment`, `demon_vitality`, `ninja_lethality`

## 🎮 Игровой эффект:

### **Улучшенная прогрессия Executioner Demon:**
- **Common** → `executioner_rage` - Ярость палача
- **Uncommon** → `executioner_rage` + `demon_strength` - + Демоническая сила
- **Rare** → `executioner_rage` + `demon_strength` - Базовые способности
- **Epic** → `executioner_rage` + `demon_strength` + **`executioner_guillotine`** + `executioner_judgment` - + Гильотина палача + Суд палача
- **Legendary** → `executioner_rage` + `demon_strength` + `executioner_guillotine` + `executioner_judgment` + `executioner_final` - + Финальный палач

### **Обновленная конфигурация врагов:**

#### **Демон Палач (Executioner Demon):**
- **Common**: `executioner_rage`
- **Uncommon**: `executioner_rage` + `demon_strength`
- **Rare**: `executioner_rage` + `demon_strength`
- **Epic**: `executioner_rage` + `demon_strength` + **`executioner_guillotine`** + `executioner_judgment` ✅
- **Legendary**: `executioner_rage` + `demon_strength` + `executioner_guillotine` + `executioner_judgment` + `executioner_final`

### **Стоимость изучения:**
- **Гильотина палача** - 700 осколков душ (Epic)
- **Доступность** - только от эпических+ Executioner Demon

## ✅ Статус: Обновлено

Теперь "Гильотина палача" корректно определена как эпическая способность и доступна для изучения от эпических+ Executioner Demon!
