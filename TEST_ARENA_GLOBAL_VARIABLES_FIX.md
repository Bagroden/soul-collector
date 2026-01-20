# Исправление проблемы тестовой арены через глобальные переменные

## Проблема
В тестовой арене при выборе конкретного врага появляется другой враг из-за того, что BattleManager выполняется в `_ready()` ДО того, как TestArena успевает установить переменные.

## Анализ лога
```
Обычный режим: спавним случайного врага...
test_mode: false          ❌ Должно быть true
test_enemy_scene:         ❌ Должно быть res://Scenes/Battle/Enemy_Rat.tscn
test_enemy_rarity: common ❌ Должно быть legendary
```

## Корневая причина
**Проблема с порядком выполнения:**
1. TestArena → создает BattleManager
2. BattleManager → `_ready()` → `test_mode = false` → обычный режим ❌
3. TestArena → `set_test_mode(true)` → **УЖЕ ПОЗДНО** ❌

## Решение через глобальные переменные

### 1. Создан TestArenaGlobals.gd
```gdscript
# res://Scripts/TestArenaGlobals.gd
extends Node

# Глобальные переменные для тестовой арены
var test_mode: bool = false
var test_enemy_scene: String = ""
var test_enemy_rarity: String = "common"

func reset():
    test_mode = false
    test_enemy_scene = ""
    test_enemy_rarity = "common"
```

### 2. Изменен TestArena.gd
```gdscript
func _on_start_battle_pressed():
    # Устанавливаем глобальные переменные тестового режима ПЕРЕД созданием BattleManager
    _set_global_test_variables()
    
    # Загружаем сцену боя
    var battle_scene = preload("res://Scenes/Battle/BattleScene.tscn")
    var battle_instance = battle_scene.instantiate()

func _set_global_test_variables():
    # Устанавливаем глобальные переменные, которые BattleManager будет читать в _ready()
    var test_globals = get_node("/root/TestArenaGlobals")
    test_globals.test_mode = true
    test_globals.test_enemy_scene = selected_enemy_scene
    test_globals.test_enemy_rarity = selected_rarity
```

### 3. Изменен BattleManager.gd
```gdscript
func _ready():
    # Проверяем глобальные переменные тестового режима
    _check_global_test_variables()
    
    # Спавним врага в зависимости от режима
    if test_mode:
        print("Тестовый режим: спавним тестового врага...")
        spawn_enemy()
    else:
        print("Обычный режим: спавним случайного врага...")
        spawn_enemy()

func _check_global_test_variables():
    var test_globals = get_node_or_null("/root/TestArenaGlobals")
    if test_globals and test_globals.test_mode:
        # Устанавливаем переменные из глобальных
        test_mode = test_globals.test_mode
        test_enemy_scene = test_globals.test_enemy_scene
        test_enemy_rarity = test_globals.test_enemy_rarity
        
        # Сбрасываем глобальные переменные после использования
        test_globals.reset()
```

## Как работает исправление

### Новый порядок выполнения:
1. **TestArena** → `_set_global_test_variables()` → устанавливает глобальные переменные ✅
2. **TestArena** → создает BattleManager ✅
3. **BattleManager** → `_ready()` → `_check_global_test_variables()` → читает глобальные переменные ✅
4. **BattleManager** → `test_mode = true` → тестовый режим ✅
5. **BattleManager** → `spawn_enemy()` → тестовый враг ✅

## Ожидаемый результат
Теперь в консоли должно быть:
```
=== УСТАНОВКА ГЛОБАЛЬНЫХ ПЕРЕМЕННЫХ ТЕСТОВОГО РЕЖИМА ===
selected_enemy_scene: res://Scenes/Battle/Enemy_Rat.tscn
selected_rarity: legendary
✅ Глобальные переменные установлены

=== НАЙДЕНЫ ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ТЕСТОВОГО РЕЖИМА ===
test_mode: true
test_enemy_scene: res://Scenes/Battle/Enemy_Rat.tscn
test_enemy_rarity: legendary
==================================================
✅ Переменные скопированы и глобальные сброшены

Тестовый режим: спавним тестового врага...
=== ОТЛАДКА SPAWN_ENEMY ===
test_mode: true
test_enemy_scene: res://Scenes/Battle/Enemy_Rat.tscn
test_enemy_rarity: legendary
==========================
Тестовый режим: спавним тестового врага
```

## Преимущества решения
1. **Порядок выполнения** - переменные устанавливаются ДО создания BattleManager
2. **Глобальность** - переменные доступны из любого места
3. **Автоочистка** - глобальные переменные сбрасываются после использования
4. **Обратная совместимость** - обычный режим работает как прежде

---

**Автор**: Claude AI Assistant  
**Дата**: 2024  
**Версия**: 1.0
