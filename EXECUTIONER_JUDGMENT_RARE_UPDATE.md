# Перенос "Суд палача" в редкие способности

## ✅ Изменения выполнены:

### **Изменена редкость способности:**
- **"Суд палача"** (`executioner_judgment`) перенесена из **эпических (epic)** в **редкие (rare)** способности
- **Перемещена** из папки `Epic/` в папку `Rare/`

## 🔧 Выполненные изменения:

### **1. Изменена редкость в файле способности:**
```gdscript
# Файл: Scripts/PassiveAbilities/Rare/ExecutionerJudgment.gd
func _init():
    id = "executioner_judgment"
    name = "Суд палача"
    description = "30% шанс наложить метку суда, которая взрывается через 2 хода, снимая 20% от максимального здоровья врага и оглушая на один ход"
    rarity = "rare"  # ✅ Изменено с "epic" на "rare"
    ability_type = AbilityType.OFFENSIVE
    trigger_type = TriggerType.ON_ATTACK
    value = 30.0  # 30% шанс
```

### **2. Перемещен файл:**
- **Было**: `Scripts/PassiveAbilities/Epic/ExecutionerJudgment.gd`
- **Стало**: `Scripts/PassiveAbilities/Rare/ExecutionerJudgment.gd`

### **3. Обновлен комментарий:**
```gdscript
# Было:
# res://Scripts/PassiveAbilities/Epic/ExecutionerJudgment.gd

# Стало:
# res://Scripts/PassiveAbilities/Rare/ExecutionerJudgment.gd  ✅
```

### **4. Обновлен PassiveAbilityManager:**
```gdscript
# Удалено из _load_epic_abilities():
# var executioner_judgment = load("res://Scripts/PassiveAbilities/Epic/ExecutionerJudgment.gd").new()

# Добавлено в _load_rare_abilities():
var executioner_judgment = load("res://Scripts/PassiveAbilities/Rare/ExecutionerJudgment.gd").new()
abilities["executioner_judgment"] = executioner_judgment
```

### **5. Обновлена конфигурация врагов:**
```gdscript
# Файл: Scripts/PassiveAbilities/EnemyPassiveConfig.gd
"ExecutionerDemon": {
    "common": ["executioner_rage"],
    "uncommon": ["executioner_rage", "demon_strength"],
    "rare": ["executioner_rage", "demon_strength", "executioner_judgment"],  # ✅ Добавлена в rare
    "epic": ["executioner_rage", "demon_strength", "executioner_guillotine", "executioner_judgment"],  # ✅ Остается в epic
    "legendary": ["executioner_rage", "demon_strength", "executioner_guillotine", "executioner_judgment", "executioner_final"]
}
```

### **6. Добавлена конфигурация изучения:**
```gdscript
# Файл: Scripts/Systems/AbilityLearningSystem.gd
"executioner_judgment": {
    "name": "Суд палача",
    "required_progress": 100,
    "sources": {
        "rare_ExecutionerDemon": 10,        # ✅ 10% за редкого демона палача
        "epic_ExecutionerDemon": 10,        # ✅ 10% за эпического демона палача
        "legendary_ExecutionerDemon": 10   # ✅ 10% за легендарного демона палача
    }
}
```

## 🎯 Логика редкой редкости:

### **Почему "Суд палача" должна быть редкой:**

#### **1. Баланс способности:**
- **30% шанс** - не слишком высокий, но и не слишком низкий
- **Отложенный эффект** - взрывается через 2 хода
- **Мощный, но не критический** эффект

#### **2. Стратегическая ценность:**
- **Полезная способность** для контроля боя
- **Не критически важная** для всех сборок
- **Хорошая** для редкой редкости

#### **3. Прогрессия изучения:**
- **Доступна раньше** - от rare Executioner Demon
- **Логичная прогрессия** - сначала суд, потом гильотина
- **Сбалансированная** доступность

## 📊 Обновленная статистика по редкости:

### **🔵 РЕДКИЕ (Rare) - 9 способностей:**
- `demon_strength` (Демон колдун), `executioner_rage`, `tharnok_shield`, `blood_sucker`, `infection`, `alkara_blood_ritual`, `tharnok_armor`, `ninja_assassinate`, **`executioner_judgment`** ✅

### **🟣 ЭПИЧЕСКИЕ (Epic) - 11 способностей:**
- `life_steal`, `blood_bleeding`, `agility`, `ninja_shadow`, `ninja_shadow_strike`, `mouse_pack`, `echolocation`, `alkara_soul_drain`, `curse_cursed`, `executioner_guillotine`, `demon_vitality`, `ninja_lethality`

## 🎮 Игровой эффект:

### **Улучшенная прогрессия Executioner Demon:**
- **Common** → `executioner_rage` - Ярость палача
- **Uncommon** → `executioner_rage` + `demon_strength` - + Демоническая сила
- **Rare** → `executioner_rage` + `demon_strength` + **`executioner_judgment`** - + Суд палача
- **Epic** → `executioner_rage` + `demon_strength` + `executioner_guillotine` + `executioner_judgment` - + Гильотина палача
- **Legendary** → `executioner_rage` + `demon_strength` + `executioner_guillotine` + `executioner_judgment` + `executioner_final` - + Финальный палач

### **Обновленная конфигурация врагов:**

#### **Демон Палач (Executioner Demon):**
- **Common**: `executioner_rage`
- **Uncommon**: `executioner_rage` + `demon_strength`
- **Rare**: `executioner_rage` + `demon_strength` + **`executioner_judgment`** ✅
- **Epic**: `executioner_rage` + `demon_strength` + `executioner_guillotine` + `executioner_judgment`
- **Legendary**: `executioner_rage` + `demon_strength` + `executioner_guillotine` + `executioner_judgment` + `executioner_final`

### **Стоимость изучения:**
- **Суд палача** - 500 осколков душ (Rare)
- **Доступность** - от редких+ Executioner Demon

## 🎯 Механика способности:

### **"Суд палача" (executioner_judgment):**
- **Триггер**: При атаке (30% шанс)
- **Эффект**: Накладывает метку суда на врага
- **Взрыв**: Через 2 хода
- **Урон**: 20% от максимального HP врага
- **Дополнительно**: Оглушение на 1 ход

### **Стратегическое значение:**
- **Контроль боя** - отложенный урон и оглушение
- **Планирование** - нужно учитывать время взрыва
- **Мощность** - 20% от максимального HP - значительный урон
- **Утилита** - оглушение дает преимущество

## ✅ Статус: Обновлено

Теперь "Суд палача" корректно определена как редкая способность и доступна для изучения от редких+ Executioner Demon!
