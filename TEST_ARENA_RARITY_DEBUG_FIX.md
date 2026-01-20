# Исправление проблемы с редкостью врага в тестовой арене

## Проблема
В тестовой арене при выборе Крысы с редкостью "легендарный" возникает ошибка:
```
ОШИБКА: У врага Крыса нет конфигурации для редкости легендарный
```

## Анализ лога
```
Выбран враг: Крыса (common)
Выбрана редкость: легендарный
Начинаем тестовый бой с res://Scenes/Battle/Enemy_Rat.tscn (легендарный)
=== УСТАНОВКА ГЛОБАЛЬНЫХ ПЕРЕМЕННЫХ ТЕСТОВОГО РЕЖИМА ===
selected_rarity: легендарный
✅ Глобальные переменные установлены
test_enemy_rarity: легендарный
Тестовый враг создан: Крыса (легендарный)
ОШИБКА: У врага Крыса нет конфигурации для редкости легендарный
```

## Анализ проблемы
1. **Тестовый режим работает правильно** ✅ - Крыса создается с редкостью "легендарный"
2. **Проблема в конфигурации пассивных способностей** ❌ - ошибка возникает в `EnemyPassiveConfig.gd`

## Проверка конфигурации
В `EnemyPassiveConfig.gd` на строках 13-20 есть конфигурация для Крысы:
```gdscript
enemy_passives["Крыса"] = {
    "common": ["rat_vitality"] as Array[String],
    "uncommon": ["rat_vitality", "dodge"] as Array[String],
    "rare": ["rat_vitality", "dodge", "blood_flow"] as Array[String],
    "epic": ["rat_vitality", "dodge", "blood_flow", "agility"] as Array[String],
    "legendary": ["rat_vitality", "dodge", "blood_flow", "agility", "cornered"] as Array[String],
    "elite": ["rat_vitality", "dodge", "blood_flow", "agility", "cornered"] as Array[String]
}
```

**Конфигурация для редкости "legendary" ЕСТЬ** ✅

## Возможные причины
1. **Неправильное имя врага** - передается не "Крыса", а что-то другое
2. **Неправильная редкость** - передается не "legendary", а что-то другое
3. **Проблема с кодировкой** - невидимые символы в строках
4. **Проблема с регистром** - "Legendary" vs "legendary"

## Исправление
Добавлена отладка в `EnemyPassiveConfig.gd`:
```gdscript
func get_passives_for_enemy(enemy_name: String, rarity: String) -> Array[String]:
    print("=== ОТЛАДКА get_passives_for_enemy ===")
    print("enemy_name: '", enemy_name, "'")
    print("rarity: '", rarity, "'")
    print("enemy_name in enemy_passives: ", enemy_name in enemy_passives)
    if enemy_name in enemy_passives:
        print("Доступные редкости для ", enemy_name, ": ", enemy_passives[enemy_name].keys())
        print("rarity in enemy_passives[enemy_name]: ", rarity in enemy_passives[enemy_name])
    print("=====================================")
```

## Ожидаемый результат отладки
Теперь в консоли будет видно:
```
=== ОТЛАДКА get_passives_for_enemy ===
enemy_name: 'Крыса'
rarity: 'legendary'
enemy_name in enemy_passives: true
Доступные редкости для Крыса: [common, uncommon, rare, epic, legendary, elite]
rarity in enemy_passives[enemy_name]: true
=====================================
```

## Возможные проблемы
1. **Если `enemy_name` не "Крыса"** - проблема в том, как передается имя врага
2. **Если `rarity` не "legendary"** - проблема в том, как передается редкость
3. **Если `rarity in enemy_passives[enemy_name]` false** - проблема с регистром или кодировкой

## Следующие шаги
После получения отладочной информации можно будет точно определить причину и исправить проблему.

---

**Автор**: Claude AI Assistant  
**Дата**: 2024  
**Версия**: 1.0
