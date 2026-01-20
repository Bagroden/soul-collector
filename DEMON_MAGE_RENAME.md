# Переименование способности "Демон колдун"

## ✅ Изменения выполнены:

### **Переименована способность с `curse_demon_mage` на `demon_mage`**

## 🔧 Выполненные изменения:

### **1. Переименован файл:**
- **Было**: `Scripts/PassiveAbilities/Uncommon/CurseDemonMage.gd`
- **Стало**: `Scripts/PassiveAbilities/Uncommon/DemonMage.gd` ✅

### **2. Обновлен ID способности:**
- **Было**: `id = "curse_demon_mage"`
- **Стало**: `id = "demon_mage"` ✅

### **3. Обновлен комментарий:**
- **Было**: `# res://Scripts/PassiveAbilities/Uncommon/CurseDemonMage.gd`
- **Стало**: `# res://Scripts/PassiveAbilities/Uncommon/DemonMage.gd` ✅

### **4. Обновлен PassiveAbilityManager:**
```gdscript
# Было:
var curse_demon_mage = load("res://Scripts/PassiveAbilities/Uncommon/CurseDemonMage.gd").new()
abilities["curse_demon_mage"] = curse_demon_mage

# Стало:
var demon_mage = load("res://Scripts/PassiveAbilities/Uncommon/DemonMage.gd").new()
abilities["demon_mage"] = demon_mage
```

### **5. Обновлена конфигурация врагов:**
```gdscript
# Было:
"rare": ["curse_weakness", "curse_magic", "curse_demon_mage"]

# Стало:
"rare": ["curse_weakness", "curse_magic", "demon_mage"]
```

### **6. Обновлена конфигурация изучения:**
```gdscript
# Было:
"curse_demon_mage": {
    "name": "Демон колдун",
    "required_progress": 100,
    "sources": {
        "rare_CurseDemon": 10,
        "epic_CurseDemon": 10,
        "legendary_CurseDemon": 10
    }
}

# Стало:
"demon_mage": {
    "name": "Демон колдун",
    "required_progress": 100,
    "sources": {
        "rare_CurseDemon": 10,
        "epic_CurseDemon": 10,
        "legendary_CurseDemon": 10
    }
}
```

## 📁 Финальное состояние:

### **🟢 UNCOMMON (Необычные):**
- `Scripts/PassiveAbilities/Uncommon/DemonMage.gd` ✅
  - **ID**: `demon_mage`
  - **Название**: "Демон колдун"
  - **Описание**: "Увеличение мудрости и интеллекта на 15"
  - **Принадлежность**: Curse Demon

## 🎮 Игровой эффект:

### **Демон Проклятия (Curse Demon):**
- **Common**: `curse_weakness` (Проклятие слабости)
- **Uncommon**: `curse_weakness` + `curse_magic` (Проклятая магия)
- **Rare**: `curse_weakness` + `curse_magic` + **`demon_mage`** (Демон колдун) ✅
- **Epic**: `curse_weakness` + `curse_magic` + `demon_mage` + `curse_cursed` (Проклятый)
- **Legendary**: `curse_weakness` + `curse_magic` + `demon_mage` + `curse_cursed` + `curse_master` (Мастер проклятий)

### **Стоимость изучения:**
- **demon_mage** - 300 осколков душ (Uncommon)
- **Доступность** - от редких+ Curse Demon

## ✅ Статус: Переименовано

Способность успешно переименована с `curse_demon_mage` на `demon_mage`!
