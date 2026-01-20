# Реализация системы покупки способностей развития души

## Дата
28 октября 2025

## Проблема
Пользователь сообщил о трех проблемах:
1. Не происходит списание валюты при изучении способностей развития души
2. Нет индикации того, какие способности уже изучены
3. Непонятно, что способность изучена

## Решение

### 1. Система валют
Добавлена полноценная система проверки и списания 4 типов валют:
- **Осколки душ (ОД)** - для всех способностей
- **Сильные души** - для rare/epic способностей
- **Великие души** - для legendary способностей
- **Божественные души** - для mythic способностей

### 2. Таблица стоимости
| Редкость | Стоимость |
|----------|-----------|
| Common | 50 ОД |
| Uncommon | 100 ОД |
| Rare | 150 ОД + 1 сильная душа |
| Epic | 200 ОД + 2 сильные души |
| Legendary | 300 ОД + 4 великие души |
| Mythic | 500 ОД + 8 божественных душ |

### 3. Визуальная индикация

#### Изученные способности
- ✅ Зеленый фон панели (`Color(0.2, 0.4, 0.2, 0.3)`)
- ✅ Зеленая граница (2px, `Color(0.3, 0.6, 0.3, 0.8)`)
- ✅ Текст "✅ Изучено" вместо информации о прогрессе
- ✅ Кнопка "Изучено" (заблокирована)

#### Неизученные способности
- Если достаточно валюты:
  - Кнопка "Изучить ([стоимость])"
  - Активна для нажатия
- Если недостаточно валюты:
  - Кнопка "Недостаточно валюты"
  - Заблокирована

### 4. Процесс изучения
1. Нажатие кнопки "Изучить"
2. Проверка, не изучена ли способность (`current_level >= 1`)
3. Проверка наличия валюты через `_check_soul_ability_cost()`
4. Списание валюты через `_spend_soul_ability_cost()`
5. Установка уровня в `AbilityLearningSystem` через `set_ability_learned()`
6. Добавление в `player_data.learned_passives`
7. Применение бонуса через `ability.execute_ability()`
8. Сохранение прогресса
9. Обновление UI
10. Показ сообщения об успехе

## Изменения в файлах

### Scripts/UI/AbilityLearningScreen.gd
**Новые функции:**
- `_check_soul_ability_cost(rarity: String) -> bool` - проверка валюты
- `_spend_soul_ability_cost(rarity: String) -> bool` - списание валюты
- `_learn_soul_development_ability(ability_id: String, ability: PassiveAbility)` - изучение способности души
- `_learn_normal_ability(ability_id: String, ability: PassiveAbility)` - изучение обычной способности
- `_show_message_dialog(title: String, message: String)` - диалог с сообщением

**Измененные функции:**
- `_create_ability_card()` - добавлена визуальная индикация изученных способностей
- `_on_learn_ability()` - разделена логика для обычных способностей и способностей души
- Кнопка "Изучить" теперь проверяет наличие валюты и блокируется при недостатке

### Scripts/Systems/AbilityLearningSystem.gd
**Новые функции:**
- `set_ability_learned(ability_id: String)` - устанавливает способность как изученную
  - Устанавливает `current_level = 1`
  - Устанавливает `is_learned = true`
  - Сохраняет время изучения
  - Отправляет сигнал `ability_learned`
  - Сохраняет прогресс в файл

### Scripts/Currency/
**Тестовые значения для отладки:**
- `StrongSoulsManager.gd`: `strong_souls = 100`
- `GreatSoulsManager.gd`: `great_souls = 50`
- `DivineSoulsManager.gd`: `divine_souls = 20`
- `SoulShardManager.gd`: уже имеет `soul_shards = 500000`

## Технические детали

### Проверка валюты
```gdscript
func _check_soul_ability_cost(rarity: String) -> bool:
    # Получаем менеджеры валют
    var soul_shard_manager = get_node_or_null("/root/SoulShardManager")
    var strong_souls_manager = get_node_or_null("/root/StrongSoulsManager")
    var great_souls_manager = get_node_or_null("/root/GreatSoulsManager")
    var divine_souls_manager = get_node_or_null("/root/DivineSoulsManager")
    
    # Проверяем наличие валюты в зависимости от редкости
    match rarity:
        "common": return soul_shard_manager.get_soul_shards() >= 50
        "uncommon": return soul_shard_manager.get_soul_shards() >= 100
        "rare": return shards >= 150 and strong >= 1
        # и т.д.
```

### Списание валюты
```gdscript
func _spend_soul_ability_cost(rarity: String) -> bool:
    # Для каждой редкости списываем соответствующую валюту
    # Возвращает true если успешно, false если ошибка
    match rarity:
        "rare":
            if soul_shard_manager.spend_soul_shards(150) and 
               strong_souls_manager.spend_strong_souls(1):
                return true
            return false
        # и т.д.
```

### Установка изученной способности
```gdscript
func set_ability_learned(ability_id: String):
    if not ability_id in learning_progress:
        learning_progress[ability_id] = {
            "current_progress": 0,
            "current_level": 0,
            "is_learned": false,
            "learned_at": null,
            "sources": {}
        }
    
    var progress = learning_progress[ability_id]
    progress.current_level = 1
    progress.is_learned = true
    progress.learned_at = Time.get_datetime_string_from_system()
    
    _save_progress()
    ability_learned.emit(ability_id, 0)
```

## Сообщения пользователю

### Успех
```
Заголовок: Способность изучена!
Текст: Способность '[название]' успешно изучена!

Бонус применен.
```

### Недостаточно валюты
```
Заголовок: Недостаточно валюты
Текст: Недостаточно валюты для изучения этой способности.

Требуется: [стоимость]
```

### Уже изучено
```
Заголовок: Уже изучено
Текст: Эта способность уже изучена!
```

## Совместимость
- ✅ Полная совместимость с обычными пассивными способностями
- ✅ Сохранение и загрузка изученных способностей
- ✅ Миграция старых сохранений через `_migrate_old_saves()`
- ✅ Синхронизация с `PlayerData.learned_passives`

## Тестирование

### Для тестирования доступны:
1. **Осколки душ**: 500,000 ОД
2. **Сильные души**: 100 шт
3. **Великие души**: 50 шт
4. **Божественные души**: 20 шт

### Тестовые сценарии:
1. ✅ Покупка способности Common (50 ОД)
2. ✅ Покупка способности Uncommon (100 ОД)
3. ✅ Покупка способности Rare (150 ОД + 1 душа)
4. ✅ Покупка способности Epic (200 ОД + 2 души)
5. ✅ Покупка способности Legendary (300 ОД + 4 души)
6. ✅ Покупка способности Mythic (500 ОД + 8 душ)
7. ✅ Попытка купить без достаточной валюты
8. ✅ Попытка купить уже изученную способность
9. ✅ Визуальная индикация изученных способностей
10. ✅ Сохранение и загрузка изученных способностей

## Результат
Все три проблемы решены:
1. ✅ Валюта корректно списывается при изучении
2. ✅ Изученные способности визуально отличаются (зеленый фон, текст "✅ Изучено")
3. ✅ Понятна индикация изученных способностей (заблокированная кнопка, зеленый фон)

## Дополнительная документация
- `SOUL_DEVELOPMENT_SYSTEM.md` - общая информация о системе развития души
- `SOUL_DEVELOPMENT_UI_INTEGRATION.md` - интеграция UI
- `SOUL_DEVELOPMENT_UI_FIXES.md` - исправления UI
- `SOUL_DEVELOPMENT_CURRENCY_SYSTEM.md` - подробности системы валют

