# Перенос "Проклятие слабости" в обычные способности с изменением механики

## ✅ Изменения выполнены:

### **1. Изменена редкость:**
- **"Проклятие слабости"** (`curse_weakness`) перенесена из **редких (rare)** в **обычные (common)** способности
- **Перемещена** из папки `Rare/` в папку `Common/`

### **2. Изменена механика:**
- **Было**: "Снижает защиту врага на 50% на 3 хода"
- **Стало**: "Снижение силы врага на 30%"

## 🔧 Выполненные изменения:

### **1. Обновлен файл способности:**
```gdscript
# Файл: Scripts/PassiveAbilities/Common/CurseWeakness.gd
var weakness_duration: float = 3.0
var strength_reduction: float = 0.3  # ✅ 30% снижение силы (было 0.5 для защиты)

func _init():
    id = "curse_weakness"
    name = "Проклятие слабости"
    description = "Снижение силы врага на 30%"  # ✅ Новая механика
    rarity = "common"  # ✅ Изменено с "rare" на "common"
    ability_type = AbilityType.OFFENSIVE
    trigger_type = TriggerType.ON_ATTACK
    value = 25.0  # 25% шанс
```

### **2. Обновлена логика выполнения:**
```gdscript
func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
    # Проверяем шанс проклятия
    if randf() < (value / 100.0):
        # ✅ Снижаем силу врага на 30%
        var original_strength = target.strength
        var reduced_strength = int(original_strength * (1.0 - strength_reduction))
        target.strength = reduced_strength
        
        # Накладываем эффект слабости для отслеживания
        if target.has_method("add_effect"):
            target.add_effect("weakness", weakness_duration, 1, {
                "strength_reduction": strength_reduction, 
                "original_strength": original_strength
            })
        
        return {
            "success": true,
            "message": owner.display_name + " проклинает " + target.display_name + " слабостью! Сила снижена на 30%",
            "effect": "weakness",
            "duration": weakness_duration,
            "strength_reduction": strength_reduction,
            "original_strength": original_strength,
            "new_strength": reduced_strength
        }
```

### **3. Перемещен файл:**
- **Было**: `Scripts/PassiveAbilities/Rare/CurseWeakness.gd`
- **Стало**: `Scripts/PassiveAbilities/Common/CurseWeakness.gd`

### **4. Обновлен PassiveAbilityManager:**
```gdscript
# Удалено из _load_rare_abilities():
# var curse_weakness = load("res://Scripts/PassiveAbilities/Rare/CurseWeakness.gd").new()

# Добавлено в _load_common_abilities():
var curse_weakness = load("res://Scripts/PassiveAbilities/Common/CurseWeakness.gd").new()
abilities["curse_weakness"] = curse_weakness
```

### **5. Обновлена конфигурация изучения:**
```gdscript
# Файл: Scripts/Systems/AbilityLearningSystem.gd
"curse_weakness": {
    "name": "Проклятие слабости",
    "required_progress": 100,
    "sources": {
        "common_rat": 10,      # ✅ Доступна от обычных крыс
        "uncommon_rat": 10,    # 10% за необычную крысу
        "rare_rat": 10,        # 10% за редкую крысу
        "epic_rat": 10,        # 10% за эпическую крысу
        "legendary_rat": 10   # 10% за легендарную крысу
    }
}
```

### **6. Обновлена конфигурация врагов:**

#### **Крыса:**
```gdscript
"Крыса": {
    "common": ["rat_vitality", "curse_weakness"],  # ✅ Добавлена в common
    "uncommon": ["rat_vitality", "curse_weakness", "dodge"],
    "rare": ["rat_vitality", "curse_weakness", "dodge", "blood_flow"],
    "epic": ["rat_vitality", "curse_weakness", "dodge", "blood_flow", "agility"],
    "legendary": ["rat_vitality", "curse_weakness", "dodge", "blood_flow", "agility", "cornered"]
}
```

#### **Демон Проклятия:**
```gdscript
"CurseDemon": {
    "common": ["curse_magic", "curse_weakness"],  # ✅ Добавлена в common
    "uncommon": ["curse_magic", "curse_weakness", "demon_strength"],
    "rare": ["curse_magic", "curse_weakness", "demon_strength"],  # ✅ Убрана из rare
    "epic": ["curse_magic", "curse_weakness", "demon_strength", "curse_cursed"],
    "legendary": ["curse_magic", "curse_weakness", "demon_strength", "curse_cursed", "curse_master"]
}
```

## 🎯 Логика изменений:

### **Почему "Проклятие слабости" стала обычной:**

#### **1. Упрощенная механика:**
- **Прямое снижение силы** вместо сложного эффекта защиты
- **Простое понимание** - враг становится слабее
- **Немедленный эффект** без сложных расчетов

#### **2. Баланс игры:**
- **30% снижение силы** - умеренный эффект
- **25% шанс срабатывания** - не слишком часто
- **Доступность с начала** - базовая способность ослабления

#### **3. Игровой опыт:**
- **Ранняя доступность** - можно изучать от обычных крыс
- **Низкая стоимость** - 100 осколков душ
- **Полезность на всех уровнях** - ослабление врагов всегда актуально

## 📊 Обновленная статистика по редкости:

### **🟢 ОБЫЧНЫЕ (Common) - 6 способностей:**
- `quick_strike`, `rat_bite`, `restlessness`, `bat_speed`, `rat_vitality`, **`curse_weakness`** ✅

### **🟡 НЕОБЫЧНЫЕ (Uncommon) - 6 способностей:**
- `dodge`, `blood_flow`, `alkara_vampirism`, `curse_magic`, `mouse_nimble`, `sharp_claws`

### **🔵 РЕДКИЕ (Rare) - 9 способностей:**
- `demon_strength`, `executioner_rage`, `tharnok_shield`, `blood_sucker`, `infection`, `alkara_blood_ritual`, `executioner_guillotine`, `tharnok_armor`, `ninja_assassinate`

### **🟣 ЭПИЧЕСКИЕ (Epic) - 11 способностей:**
- `life_steal`, `blood_bleeding`, `agility`, `ninja_shadow`, `ninja_shadow_strike`, `mouse_pack`, `echolocation`, `alkara_soul_drain`, `curse_cursed`, `executioner_judgment`, `demon_vitality`, `ninja_lethality`

### **🟠 ЛЕГЕНДАРНЫЕ (Legendary) - 9 способностей:**
- `cornered`, `mouse_king`, `silent_song`, `alkara_demon_lord`, `curse_master`, `executioner_final`, `tharnok_guardian`, `tharnok_mastery`, `ninja_master`

## 🎮 Игровой эффект:

### **Улучшенная доступность:**
- **Обычная редкость** - доступна с самого начала
- **Низкая стоимость** - 100 осколков душ
- **Быстрое изучение** - от обычных крыс

### **Новая механика:**
- **Снижение силы врага** на 30%
- **Немедленный эффект** - враг становится слабее
- **Простое понимание** - понятно, что происходит

### **Прогрессия изучения крыс:**
1. **Common** → `rat_vitality`, `quick_strike`, **`curse_weakness`** ✅
2. **Uncommon** → `dodge`
3. **Rare** → `blood_flow`
4. **Epic** → `agility`
5. **Legendary** → `cornered`

## ✅ Статус: Изменено

Теперь "Проклятие слабости" является обычной способностью с новой механикой снижения силы врага на 30%!
