# Исправление принадлежности способности "Демон колдун"

## ✅ Изменения выполнены:

### **Исправлена принадлежность способности "Демон колдун" - теперь это способность Curse Demon, а не Executioner Demon**

## 🔧 Выполненные изменения:

### **1. Переименована способность:**
- **Было**: `demon_strength` (Демон колдун) - принадлежала Executioner Demon
- **Стало**: `curse_demon_mage` (Демон колдун) - принадлежит Curse Demon ✅
- **Файл**: `Scripts/PassiveAbilities/Uncommon/CurseDemonMage.gd`

### **2. Создана новая способность для Executioner Demon:**
- **Новая способность**: `demon_power` (Демоническая сила) ✅
- **Файл**: `Scripts/PassiveAbilities/Uncommon/DemonPower.gd`
- **Механика**: Увеличение силы и выносливости на 10

## 📁 Обновленное распределение способностей:

### **🟢 UNCOMMON (Необычные):**

#### **Curse Demon:**
- `Scripts/PassiveAbilities/Uncommon/CurseDemonMage.gd` ✅
  - **ID**: `curse_demon_mage`
  - **Название**: "Демон колдун"
  - **Описание**: "Увеличение мудрости и интеллекта на 15"

#### **Executioner Demon:**
- `Scripts/PassiveAbilities/Uncommon/DemonPower.gd` ✅
  - **ID**: `demon_power`
  - **Название**: "Демоническая сила"
  - **Описание**: "Увеличение силы и выносливости на 10"

## 🎮 Обновленная прогрессия врагов:

### **Демон Проклятия (Curse Demon):**
- **Common**: `curse_weakness` (Проклятие слабости)
- **Uncommon**: `curse_weakness` + `curse_magic` (Проклятая магия)
- **Rare**: `curse_weakness` + `curse_magic` + **`curse_demon_mage`** (Демон колдун) ✅
- **Epic**: `curse_weakness` + `curse_magic` + `curse_demon_mage` + `curse_cursed` (Проклятый)
- **Legendary**: `curse_weakness` + `curse_magic` + `curse_demon_mage` + `curse_cursed` + `curse_master` (Мастер проклятий)

### **Демон Палач (Executioner Demon):**
- **Common**: `executioner_rage` (Ярость палача)
- **Uncommon**: `executioner_rage` + **`demon_power`** (Демоническая сила) ✅
- **Rare**: `executioner_rage` + `demon_power` + `executioner_judgment` (Суд палача)
- **Epic**: `executioner_rage` + `demon_power` + `executioner_guillotine` (Гильотина палача) + `executioner_judgment`
- **Legendary**: `executioner_rage` + `demon_power` + `executioner_guillotine` + `executioner_judgment` + `executioner_final` (Последний приговор)

## 🔧 Обновленные файлы:

### **1. CurseDemonMage.gd:**
```gdscript
# res://Scripts/PassiveAbilities/Uncommon/CurseDemonMage.gd
extends PassiveAbility

func _init():
    id = "curse_demon_mage"
    name = "Демон колдун"
    description = "Увеличение мудрости и интеллекта на 15"
    rarity = "uncommon"
    ability_type = AbilityType.UTILITY
    trigger_type = TriggerType.PASSIVE
    value = 15.0  # +15 к мудрости и интеллекту
```

### **2. DemonPower.gd:**
```gdscript
# res://Scripts/PassiveAbilities/Uncommon/DemonPower.gd
extends PassiveAbility

func _init():
    id = "demon_power"
    name = "Демоническая сила"
    description = "Увеличение силы и выносливости на 10"
    rarity = "uncommon"
    ability_type = AbilityType.UTILITY
    trigger_type = TriggerType.PASSIVE
    value = 10.0  # +10 к силе и выносливости
```

### **3. PassiveAbilityManager.gd:**
```gdscript
# _load_uncommon_abilities():
# CurseDemon
var curse_demon_mage = load("res://Scripts/PassiveAbilities/Uncommon/CurseDemonMage.gd").new()
abilities["curse_demon_mage"] = curse_demon_mage

# ExecutionerDemon
var demon_power = load("res://Scripts/PassiveAbilities/Uncommon/DemonPower.gd").new()
abilities["demon_power"] = demon_power
```

### **4. EnemyPassiveConfig.gd:**
```gdscript
# ДЕМОН ПРОКЛЯТИЯ
"CurseDemon": {
    "common": ["curse_weakness"],
    "uncommon": ["curse_weakness", "curse_magic"],
    "rare": ["curse_weakness", "curse_magic", "curse_demon_mage"],  # ✅ Обновлено
    "epic": ["curse_weakness", "curse_magic", "curse_demon_mage", "curse_cursed"],
    "legendary": ["curse_weakness", "curse_magic", "curse_demon_mage", "curse_cursed", "curse_master"]
}

# ДЕМОН ПАЛАЧ
"ExecutionerDemon": {
    "common": ["executioner_rage"],
    "uncommon": ["executioner_rage", "demon_power"],  # ✅ Обновлено
    "rare": ["executioner_rage", "demon_power", "executioner_judgment"],
    "epic": ["executioner_rage", "demon_power", "executioner_guillotine", "executioner_judgment"],
    "legendary": ["executioner_rage", "demon_power", "executioner_guillotine", "executioner_judgment", "executioner_final"]
}
```

### **5. AbilityLearningSystem.gd:**
```gdscript
"curse_demon_mage": {
    "name": "Демон колдун",
    "required_progress": 100,
    "sources": {
        "rare_CurseDemon": 10,        # 10% за редкого демона проклятия
        "epic_CurseDemon": 10,        # 10% за эпического демона проклятия
        "legendary_CurseDemon": 10   # 10% за легендарного демона проклятия
    }
},
"demon_power": {
    "name": "Демоническая сила",
    "required_progress": 100,
    "sources": {
        "uncommon_ExecutionerDemon": 10,    # 10% за необычного демона палача
        "rare_ExecutionerDemon": 10,        # 10% за редкого демона палача
        "epic_ExecutionerDemon": 10,        # 10% за эпического демона палача
        "legendary_ExecutionerDemon": 10   # 10% за легендарного демона палача
    }
}
```

## 🎯 Логика изменений:

### **Почему "Демон колдун" должен принадлежать Curse Demon:**
- **Тематика**: Curse Demon связан с магией и проклятиями
- **Мудрость и интеллект**: подходят для магических способностей
- **Логика**: колдун = магия = проклятия

### **Почему "Демоническая сила" подходит для Executioner Demon:**
- **Тематика**: Executioner Demon - боевой демон
- **Сила и выносливость**: подходят для физических способностей
- **Логика**: палач = сила = физическая мощь

## 📊 Стоимость изучения:

### **curse_demon_mage (Демон колдун):**
- **Стоимость**: 300 осколков душ (Uncommon)
- **Доступность**: от редких+ Curse Demon

### **demon_power (Демоническая сила):**
- **Стоимость**: 300 осколков душ (Uncommon)
- **Доступность**: от необычных+ Executioner Demon

## ✅ Статус: Исправлено

Теперь способности правильно распределены между врагами согласно их тематике и логике!
