# Руководство по созданию монстра в игре

## Обзор процесса
Создание нового монстра включает 6 основных шапов:
1. Создание сцены врага
2. Создание пассивных способностей
3. Добавление способностей в PassiveAbilityManager
4. Конфигурация в EnemyPassiveConfig
5. Добавление в систему изучения способностей
6. Назначение боссом локации (если нужно)

---

## Шаг 1: Создание сцены врага

### Файл: `Scenes/Battle/Enemy_[ИмяВрага].tscn`

**Структура файла:**
```gdscript
[gd_scene load_steps=29 format=3 uid="uid://[уникальный_uid]"]

[ext_resource type="Script" uid="uid://b4131gr6a6ssw" path="res://Scripts/Battle/body.gd" id="1_body"]
[ext_resource type="Texture2D" uid="uid://[текстура_uid]" path="res://Assets/Sprites/[текстура].png" id="2_cidh2"]
[ext_resource type="Script" uid="uid://baajjson61nik" path="res://Scripts/Battle/character_visual.gd" id="2_visual"]

# Анимации (копируются из существующего врага)
[sub_resource type="AtlasTexture" id="AtlasTexture_[id]"]
atlas = ExtResource("2_cidh2")
region = Rect2([x], [y], 64, 64)

# ... остальные анимации ...

[sub_resource type="SpriteFrames" id="SpriteFrames_1"]
animations = [
    # idle, attack, hurt, death, special, [уникальные_анимации]
]

[node name="[ИмяВрага]" type="Node2D"]
script = ExtResource("1_body")
display_name = "[Отображаемое имя]"
max_hp = [HP]
hp = [HP]
attack_power = [Атака]
rarity = "[редкость]"  # common, uncommon, rare, epic, legendary, mythic, boss
strength = [Сила]
agility = [Ловкость]
vitality = [Живучесть]
endurance = [Выносливость]
intelligence = [Интеллект]
wisdom = [Мудрость]
level = [Уровень]

[node name="Visual" type="AnimatedSprite2D" parent="."]
script = ExtResource("2_visual")
sprite_frames = SubResource("SpriteFrames_1")
animation = "idle"
position = Vector2(0, [Y_позиция])
scale = Vector2([X_масштаб], [Y_масштаб])
```

**Параметры по типам врагов:**
- **Обычный враг:** HP=50-100, Атака=10-20, уровень=1-3
- **Редкий враг:** HP=80-150, Атака=15-25, уровень=2-4
- **Эпический враг:** HP=120-200, Атака=20-30, уровень=3-5
- **Легендарный враг:** HP=150-250, Атака=25-35, уровень=4-6
- **Элитный враг:** HP=200-300, Атака=30-40, уровень=5-7
- **Босс:** HP=180-400, Атака=25-50, уровень=6-10

---

## Шаг 2: Создание пассивных способностей

### Файлы: `Scripts/PassiveAbilities/[Редкость]/[ИмяСпособности].gd`

**Базовая структура:**
```gdscript
# res://Scripts/PassiveAbilities/[Редкость]/[ИмяСпособности].gd
extends PassiveAbility

func _init():
    id = "[id_способности]"                    # ⚠️ ВАЖНО: Уникальный ID
    name = "[Отображаемое имя]"                # ⚠️ ВАЖНО: Отображаемое имя
    description = "[Описание способности]"
    rarity = "[редкость]"                      # ⚠️ ВАЖНО: Редкость способности
    ability_type = AbilityType.[ТИП]           # ⚠️ ВАЖНО: Тип способности
    trigger_type = TriggerType.[ТРИГГЕР]      # ⚠️ ВАЖНО: Когда срабатывает
    # Значения для каждого уровня
    level_values = [значение1, значение2, значение3]
    value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
    # Получаем текущий уровень способности
    var current_level = _context.get("ability_level", _context.get("level", 1))
    var current_value = get_value_for_level(current_level)
    
    # Логика способности
    # ...
    
    return {"success": true/false, "message": "[сообщение]"}
```

**Типы способностей:**
- `AbilityType.DEFENSIVE` - Защитные (уворот, блок, регенерация)
- `AbilityType.OFFENSIVE` - Атакующие (кровотечение, крит, урон)
- `AbilityType.UTILITY` - Утилитарные (скорость, мана, опыт)
- `AbilityType.SPECIAL` - Особые (магические, трансформации)

**Триггеры:**
- `TriggerType.ON_ATTACK` - При атаке
- `TriggerType.ON_DAMAGE_TAKEN` - При получении урона
- `TriggerType.ON_TURN_START` - В начале хода
- `TriggerType.ON_TURN_END` - В конце хода
- `TriggerType.ON_DEATH` - При смерти
- `TriggerType.PASSIVE` - Постоянно активная
- `TriggerType.ON_CRIT` - При критическом ударе
- `TriggerType.ON_HEAL` - При лечении
- `TriggerType.ON_DODGE` - При уклонении

**Типы урона:**
- `"physical"` - Физический (по умолчанию)
- `"magic"` - Магический
- `"shadow"` - Теневой
- `"fire"` - Огненный
- `"ice"` - Ледяной
- `"poison"` - Ядовитый

---

## Шаг 3: Добавление способностей в PassiveAbilityManager

### Файл: `Scripts/PassiveAbilities/PassiveAbilityManager.gd`

**В методе `_load_[редкость]_abilities()`:**
```gdscript
func _load_[редкость]_abilities():
    # [Описание способностей]
    var [имя_переменной] = load("res://Scripts/PassiveAbilities/[Редкость]/[ИмяСпособности].gd").new()
    abilities["[id_способности]"] = [имя_переменной]
```

**Примеры:**
```gdscript
func _load_boss_abilities():
    # Гнилой слизень
    var rotten_aura = load("res://Scripts/PassiveAbilities/Boss/RottenAura.gd").new()
    abilities["rotten_aura"] = rotten_aura
    
    # Тёмный шатун
    var shadow_strike = load("res://Scripts/PassiveAbilities/Boss/ShadowStrike.gd").new()
    abilities["shadow_strike"] = shadow_strike
```

---

## Шаг 4: Конфигурация в EnemyPassiveConfig

### Файл: `Scripts/PassiveAbilities/EnemyPassiveConfig.gd`

**Добавить в метод `_init()`:**
```gdscript
enemy_passives["[Имя врага]"] = {
    "common": ["[способность1]"] as Array[String],
    "uncommon": ["[способность1]", "[способность2]"] as Array[String],
    "rare": ["[способность1]", "[способность2]", "[способность3]"] as Array[String],
    "epic": ["[способность1]", "[способность2]", "[способность3]", "[способность4]"] as Array[String],
    "legendary": ["[способность1]", "[способность2]", "[способность3]", "[способность4]", "[способность5]"] as Array[String],
    "elite": ["[способность1]", "[способность2]", "[способность3]", "[способность4]", "[способность5]", "[уникальная_способность]"] as Array[String],
    "boss": ["[способность1]", "[способность2]", "[способность3]", "[способность4]", "[способность5]", "[уникальная_способность]"] as Array[String]
}
```

**Пример:**
```gdscript
enemy_passives["Тёмный шатун"] = {
    "common": ["shadow_strike"] as Array[String],
    "uncommon": ["shadow_strike", "stealth"] as Array[String],
    "rare": ["shadow_strike", "stealth", "shadow_aura"] as Array[String],
    "epic": ["shadow_strike", "stealth", "shadow_aura", "agility"] as Array[String],
    "legendary": ["shadow_strike", "stealth", "shadow_aura", "agility", "dodge"] as Array[String],
    "elite": ["shadow_strike", "stealth", "shadow_aura", "agility", "dodge", "sharp_claws"] as Array[String],
    "boss": ["shadow_strike", "stealth", "shadow_aura", "agility", "dodge", "sharp_claws"] as Array[String]
}
```

---

## Шаг 5: Добавление в систему изучения способностей

### Файл: `Scripts/Systems/AbilityLearningSystem.gd`

**В методе `_init()` в секции `ability_learning_config`:**
```gdscript
"[id_способности]": {
    "name": "[Отображаемое имя]",
    "description": "[Описание способности]",
    "required_progress": [100, 500, 1000],  # Прогресс для каждого уровня
    "required_soul_shards": [100, 1000, 10000],  # Осколки душ для каждого уровня
    "level_values": [значение1, значение2, значение3],  # Значения для каждого уровня
    "sources": {
        "[редкость]_[имя_врага]": 100    # 100 очков за врага
    }
}
```

**Пример:**
```gdscript
"shadow_strike": {
    "name": "Теневой удар",
    "description": "При атаке имеет шанс нанести дополнительный теневой урон, который игнорирует броню",
    "required_progress": [100, 500, 1000],
    "required_soul_shards": [100, 1000, 10000],
    "level_values": [15.0, 20.0, 25.0],
    "sources": {
        "boss_тёмный_шатун": 100
    }
}
```

---

## Шаг 6: Назначение боссом локации (если нужно)

### Файлы: `Scripts/LocationManager.gd` и `Scripts/LocationManagerAutoload.gd`

**Изменить босса локации:**
```gdscript
# В методе _init() для нужной локации
[локация].boss_enemy = "[ИмяВрага]"
```

**Пример:**
```gdscript
forest.boss_enemy = "DarkStalker"
```

---

## Чек-лист создания монстра

### ✅ Обязательные шаги:
1. **Сцена врага** - создан файл `Scenes/Battle/Enemy_[Имя].tscn`
2. **Пассивные способности** - созданы файлы способностей
3. **PassiveAbilityManager** - добавлены способности в загрузку
4. **EnemyPassiveConfig** - добавлена конфигурация врага
5. **AbilityLearningSystem** - добавлены способности в систему изучения
6. **LocationManager** - назначен боссом (если нужно)

### ✅ Проверки:
- [ ] Все файлы созданы без ошибок
- [ ] ID способностей уникальны
- [ ] Имена врагов совпадают в конфигурации
- [ ] Редкости указаны правильно
- [ ] Триггеры способностей корректны
- [ ] Типы урона указаны правильно
- [ ] Линтер не показывает ошибок

### ✅ Тестирование:
- [ ] Враг появляется в игре
- [ ] Пассивные способности загружаются
- [ ] Способности срабатывают в бою
- [ ] Урон наносится правильно
- [ ] Сообщения в логе корректны

---

## Примеры успешных реализаций

### "Гнилой слизень" (босс)
- **Сцена:** `Enemy_RottenSlime.tscn`
- **Способности:** `RottenAura.gd`
- **Локация:** Подземелье под городом

### "Тёмный шатун" (босс)
- **Сцена:** `Enemy_DarkStalker.tscn`
- **Способности:** `ShadowStrike.gd`, `ShadowAura.gd`, `Stealth.gd`
- **Локация:** Тёмный лес

---

## Важные замечания

1. **Уникальность ID** - каждый ID способности должен быть уникальным
2. **Совпадение имён** - имена врагов должны совпадать во всех конфигурациях
3. **Правильные пути** - пути к файлам должны быть корректными
4. **Тестирование** - всегда тестируйте нового врага в игре
5. **Баланс** - учитывайте баланс характеристик и способностей
6. **Документация** - обновляйте `ALL_PASSIVE_ABILITIES.md` при добавлении новых способностей

---

*Это руководство основано на успешном создании "Тёмного шатуна" и может использоваться для создания любых новых монстров в игре.*