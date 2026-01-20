# Исправление распределения способностей Executioner Demon по папкам

## ✅ Изменения выполнены:

### **Исправлено распределение всех способностей Executioner Demon по папкам согласно их редкости:**

## 🔧 Выполненные изменения:

### **1. executioner_rage (Ярость палача):**
- **Было**: `Scripts/PassiveAbilities/Rare/ExecutionerRage.gd` (rare)
- **Стало**: `Scripts/PassiveAbilities/Common/ExecutionerRage.gd` (common) ✅
- **Редкость**: изменена с `"rare"` на `"common"`
- **Перемещена** из `_load_rare_abilities()` в `_load_common_abilities()`

### **2. demon_strength (Демон колдун):**
- **Было**: `Scripts/PassiveAbilities/Rare/DemonStrength.gd` (rare)
- **Стало**: `Scripts/PassiveAbilities/Uncommon/DemonStrength.gd` (uncommon) ✅
- **Редкость**: изменена с `"rare"` на `"uncommon"`
- **Перемещена** из `_load_rare_abilities()` в `_load_uncommon_abilities()`

### **3. executioner_judgment (Суд палача):**
- **Было**: `Scripts/PassiveAbilities/Epic/ExecutionerJudgment.gd` (epic)
- **Стало**: `Scripts/PassiveAbilities/Rare/ExecutionerJudgment.gd` (rare) ✅
- **Редкость**: изменена с `"epic"` на `"rare"`
- **Перемещена** из `_load_epic_abilities()` в `_load_rare_abilities()`

### **4. executioner_guillotine (Гильотина палача):**
- **Было**: `Scripts/PassiveAbilities/Rare/ExecutionerGuillotine.gd` (rare)
- **Стало**: `Scripts/PassiveAbilities/Epic/ExecutionerGuillotine.gd` (epic) ✅
- **Редкость**: изменена с `"rare"` на `"epic"`
- **Перемещена** из `_load_rare_abilities()` в `_load_epic_abilities()`

### **5. executioner_final (Последний приговор):**
- **Остается**: `Scripts/PassiveAbilities/Legendary/ExecutionerFinal.gd` (legendary) ✅
- **Редкость**: `"legendary"` (правильно)
- **Остается** в `_load_legendary_abilities()`

## 📁 Правильное распределение по папкам:

### **🔵 COMMON (Обычные):**
- `Scripts/PassiveAbilities/Common/ExecutionerRage.gd` ✅

### **🟢 UNCOMMON (Необычные):**
- `Scripts/PassiveAbilities/Uncommon/DemonStrength.gd` ✅

### **🔵 RARE (Редкие):**
- `Scripts/PassiveAbilities/Rare/ExecutionerJudgment.gd` ✅

### **🟣 EPIC (Эпические):**
- `Scripts/PassiveAbilities/Epic/ExecutionerGuillotine.gd` ✅

### **🟠 LEGENDARY (Легендарные):**
- `Scripts/PassiveAbilities/Legendary/ExecutionerFinal.gd` ✅

## 🎮 Правильная прогрессия Executioner Demon:

### **Common** → `executioner_rage` (Ярость палача)
- **Механика**: Урон увеличивается на 50% при низком HP владельца (меньше 20%)
- **Тип**: Атакующая способность
- **Стоимость**: 100 осколков душ

### **Uncommon** → `executioner_rage` + `demon_strength` (Демон колдун)
- **Механика**: Увеличение мудрости и интеллекта на 15
- **Тип**: Утилитарная способность
- **Стоимость**: 300 осколков душ

### **Rare** → `executioner_rage` + `demon_strength` + `executioner_judgment` (Суд палача)
- **Механика**: 30% шанс наложить метку суда, которая взрывается через 2 хода, снимая 20% от максимального HP врага и оглушая на 1 ход
- **Тип**: Атакующая способность с отложенным эффектом
- **Стоимость**: 500 осколков душ

### **Epic** → `executioner_rage` + `demon_strength` + `executioner_guillotine` (Гильотина палача) + `executioner_judgment`
- **Механика**: Увеличивает критический урон в 3 раза
- **Тип**: Постоянная способность
- **Стоимость**: 700 осколков душ

### **Legendary** → `executioner_rage` + `demon_strength` + `executioner_guillotine` + `executioner_judgment` + `executioner_final` (Последний приговор)
- **Механика**: При получении смертельного урона не умирает, вместо этого HP снижается до 1 и проводит контратаку с усилением в 300% к урону
- **Тип**: Защитная способность
- **Стоимость**: 1000 осколков душ

## 🔧 Обновленные файлы:

### **1. PassiveAbilityManager.gd:**
```gdscript
# _load_common_abilities():
var executioner_rage = load("res://Scripts/PassiveAbilities/Common/ExecutionerRage.gd").new()
abilities["executioner_rage"] = executioner_rage

# _load_uncommon_abilities():
var demon_strength = load("res://Scripts/PassiveAbilities/Uncommon/DemonStrength.gd").new()
abilities["demon_strength"] = demon_strength

# _load_rare_abilities():
var executioner_judgment = load("res://Scripts/PassiveAbilities/Rare/ExecutionerJudgment.gd").new()
abilities["executioner_judgment"] = executioner_judgment

# _load_epic_abilities():
var executioner_guillotine = load("res://Scripts/PassiveAbilities/Epic/ExecutionerGuillotine.gd").new()
abilities["executioner_guillotine"] = executioner_guillotine

# _load_legendary_abilities():
var executioner_final = load("res://Scripts/PassiveAbilities/Legendary/ExecutionerFinal.gd").new()
abilities["executioner_final"] = executioner_final
```

### **2. EnemyPassiveConfig.gd:**
```gdscript
"ExecutionerDemon": {
    "common": ["executioner_rage"],
    "uncommon": ["executioner_rage", "demon_strength"],
    "rare": ["executioner_rage", "demon_strength", "executioner_judgment"],
    "epic": ["executioner_rage", "demon_strength", "executioner_guillotine", "executioner_judgment"],
    "legendary": ["executioner_rage", "demon_strength", "executioner_guillotine", "executioner_judgment", "executioner_final"]
}
```

### **3. AbilityLearningSystem.gd:**
```gdscript
"executioner_rage": {
    "name": "Ярость палача",
    "required_progress": 100,
    "sources": {
        "common_ExecutionerDemon": 10,      # 10% за обычного демона палача
        "uncommon_ExecutionerDemon": 10,    # 10% за необычного демона палача
        "rare_ExecutionerDemon": 10,        # 10% за редкого демона палача
        "epic_ExecutionerDemon": 10,        # 10% за эпического демона палача
        "legendary_ExecutionerDemon": 10   # 10% за легендарного демона палача
    }
},
"demon_strength": {
    "name": "Демон колдун",
    "required_progress": 100,
    "sources": {
        "uncommon_ExecutionerDemon": 10,    # 10% за необычного демона палача
        "rare_ExecutionerDemon": 10,        # 10% за редкого демона палача
        "epic_ExecutionerDemon": 10,        # 10% за эпического демона палача
        "legendary_ExecutionerDemon": 10   # 10% за легендарного демона палача
    }
},
"executioner_judgment": {
    "name": "Суд палача",
    "required_progress": 100,
    "sources": {
        "rare_ExecutionerDemon": 10,        # 10% за редкого демона палача
        "epic_ExecutionerDemon": 10,        # 10% за эпического демона палача
        "legendary_ExecutionerDemon": 10   # 10% за легендарного демона палача
    }
},
"executioner_guillotine": {
    "name": "Гильотина палача",
    "required_progress": 100,
    "sources": {
        "epic_ExecutionerDemon": 10,        # 10% за эпического демона палача
        "legendary_ExecutionerDemon": 10   # 10% за легендарного демона палача
    }
}
```

## ✅ Статус: Все исправлено

Теперь все способности Executioner Demon правильно распределены по папкам согласно их редкости и корректно загружаются в PassiveAbilityManager!
