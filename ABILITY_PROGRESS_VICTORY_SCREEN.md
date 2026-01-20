# Отображение прогресса изучения способностей на экране победы

## Дата
28 октября 2025

## Проблема
После победы над врагом игрок получает прогресс изучения пассивных способностей, но эта информация не отображалась в окне победы. Игрок не видел какие способности получили прогресс и сколько очков было начислено.

## Запрос пользователя
> Смотри скрин, после победы над врагом мы получаем сообщение с наградой, я хочу, чтобы в нем также было отображено сколько очков прогресса игрок получил на какие способности.
> 
> Пример:
> - Живучесть крысы - получено 100 очков прогресса изучения способности.
> - Уворот - получено 100 очков прогресса изучения способности.

## Решение

### 1. Модифицирована система изучения способностей

#### Scripts/Systems/AbilityLearningSystem.gd

**Изменения в `add_progress()`:**
```gdscript
func add_progress(enemy_type: String, enemy_rarity: String) -> Array:
    """Добавляет прогресс изучения после победы над врагом. Возвращает список полученного прогресса."""
    var enemy_key = enemy_rarity + "_" + enemy_type
    var progress_gained = []
    
    for ability_id in ability_learning_config:
        var config = ability_learning_config[ability_id]
        if enemy_key in config.sources:
            var progress_gain = config.sources[enemy_key]
            _add_ability_progress(ability_id, progress_gain)
            # Добавляем информацию о полученном прогрессе
            progress_gained.append({
                "ability_name": config.name,
                "progress": progress_gain
            })
    
    return progress_gained
```

**Изменения в `add_progress_for_ability()` (для элитных врагов):**
```gdscript
func add_progress_for_ability(ability_display_name: String, progress_gain: int) -> Dictionary:
    """Добавляет прогресс к конкретной способности (для элитных врагов). Возвращает информацию о прогрессе."""
    var ability_id = _get_ability_id_by_display_name(ability_display_name)
    if ability_id != "":
        _add_ability_progress(ability_id, progress_gain)
        return {
            "ability_name": ability_display_name,
            "progress": progress_gain
        }
    else:
        print("ОШИБКА: Не найден ID для способности: ", ability_display_name)
        return {}
```

### 2. Обновлен менеджер боя

#### Scripts/Battle/battle_manager.gd

**Изменения в `_on_enemy_died()`:**
```gdscript
# Собираем прогресс способностей
var ability_progress = []

# Проверяем, был ли враг элитным для двойного прогресса
var is_elite = enemy_node.rarity == "elite"
if is_elite:
    var elite_progress = _apply_elite_rewards()
    ability_progress.append_array(elite_progress)

# Рассчитываем и добавляем осколки душ
_calculate_and_award_soul_shards()

# Сохраняем информацию о побежденном враге и получаем прогресс способностей
var normal_progress = await _save_battle_result()
ability_progress.append_array(normal_progress)

# Показываем детальное сообщение о победе с прогрессом способностей
_show_victory_message(ability_progress)
```

**Изменения в `_save_battle_result()`:**
```gdscript
func _save_battle_result() -> Array:
    # ... код инициализации ...
    var progress_gained = []
    
    # Сохраняем данные о враге
    if enemy_node:
        battle_result.set_battle_result(enemy_node.level, enemy_node.rarity, true)
        print("Сохранен результат боя: Враг уровень ", enemy_node.level, ", Редкость ", enemy_node.rarity)
        
        # Добавляем прогресс изучения способностей и получаем результат
        progress_gained = await _add_ability_learning_progress()
    
    return progress_gained
```

**Изменения в `_add_ability_learning_progress()`:**
```gdscript
func _add_ability_learning_progress() -> Array:
    """Добавляет прогресс изучения способностей после победы над врагом. Возвращает список полученного прогресса."""
    # ... код инициализации ...
    var progress_gained = []
    
    if enemy_node:
        # ... код определения типа врага ...
        
        # Добавляем прогресс изучения и получаем список полученного прогресса
        progress_gained = ability_learning_system.add_progress(enemy_type, enemy_rarity)
    
    return progress_gained
```

**Изменения в `_apply_elite_rewards()`:**
```gdscript
func _apply_elite_rewards() -> Array:
    """Применяет двойной прогресс пассивных способностей за победу над элитным врагом. Возвращает список полученного прогресса."""
    var progress_gained = []
    
    # ... получение системы изучения и пассивок врага ...
    
    # Применяем двойной прогресс (200%) для каждой пассивной способности врага
    for passive_name in enemy_passives:
        # Элитные враги дают двойной прогресс (200 очков) вместо обычных 100 очков
        var progress_data = ability_learning_system.add_progress_for_ability(passive_name, 200)
        if not progress_data.is_empty():
            progress_gained.append(progress_data)
    
    return progress_gained
```

**Изменения в `_show_victory_message()`:**
```gdscript
func _show_victory_message(ability_progress: Array):
    """Показывает детальное сообщение о победе"""
    
    # ... код получения данных врага и наград ...
    
    # Формируем сообщение
    var message = "Победа!\n"
    message += "Враг - %s %s %d уровень\n" % [enemy_rarity, enemy_name, enemy_level]
    message += "Награда - %d опыта и %d осколков душ!" % [exp_reward, soul_shards_reward]
    
    if ability_progress.size() > 0:
        message += "\nПолучен прогресс пассивных способностей:"
        for progress_data in ability_progress:
            message += "\n- %s: +%d очков" % [progress_data.ability_name, progress_data.progress]
    
    print("Сообщение: ", message)
    
    # Показываем красивый экран победы с прогрессом способностей
    _show_victory_screen(enemy_name, enemy_level, enemy_rarity, exp_reward, soul_shards_reward, ability_progress)
```

**Изменения в `_show_victory_screen()`:**
```gdscript
func _show_victory_screen(enemy_name: String, enemy_level: int, enemy_rarity: String, exp_reward: int, soul_shards_reward: int, ability_progress: Array):
    """Показывает красивый экран победы"""
    # Загружаем сцену победы
    var victory_scene = preload("res://Scenes/UI/VictoryScreen.tscn")
    var victory_instance = victory_scene.instantiate()
    
    # Настраиваем данные с прогрессом способностей
    victory_instance.setup_victory(enemy_name, enemy_level, enemy_rarity, exp_reward, soul_shards_reward, ability_progress)
    
    # Подключаем сигнал закрытия
    victory_instance.victory_screen_closed.connect(_on_victory_screen_closed)
    
    # Добавляем в сцену
    add_child(victory_instance)
```

### 3. Обновлен экран победы

#### Scripts/UI/VictoryScreen.gd

**Изменения в `setup_victory()`:**
```gdscript
func setup_victory(enemy_name: String, enemy_level: int, enemy_rarity: String, exp_reward: int, soul_shards_reward: int, ability_progress: Array = []):
    """Настраивает экран победы с данными"""
    var enemy_name_label = $VictoryPanel/VBoxContainer/EnemyInfoContainer/EnemyNameLabel
    var exp_reward_label = $VictoryPanel/VBoxContainer/RewardsContainer/ExpRewardLabel
    var soul_shards_reward_label = $VictoryPanel/VBoxContainer/RewardsContainer/SoulShardsRewardLabel
    
    enemy_name_label.text = "%s %s %d уровень" % [enemy_rarity, enemy_name, enemy_level]
    exp_reward_label.text = "Опыт: %d" % exp_reward
    soul_shards_reward_label.text = "Осколки душ: %d" % soul_shards_reward
    
    # Если есть прогресс способностей, добавляем информацию о нем
    if ability_progress.size() > 0:
        _add_ability_progress_section(ability_progress)
```

**Новая функция `_add_ability_progress_section()`:**
```gdscript
func _add_ability_progress_section(ability_progress: Array):
    """Добавляет секцию с прогрессом изучения способностей"""
    var vbox = $VictoryPanel/VBoxContainer
    
    # Добавляем разделитель
    var separator = HSeparator.new()
    vbox.add_child(separator)
    vbox.move_child(separator, vbox.get_child_count() - 2)  # Перед кнопкой "Продолжить"
    
    # Создаем контейнер для прогресса способностей
    var progress_container = VBoxContainer.new()
    progress_container.name = "AbilityProgressContainer"
    vbox.add_child(progress_container)
    vbox.move_child(progress_container, vbox.get_child_count() - 2)  # Перед кнопкой "Продолжить"
    
    # Добавляем заголовок
    var title_label = Label.new()
    title_label.text = "Прогресс изучения способностей:"
    title_label.add_theme_font_size_override("font_size", 16)
    title_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
    progress_container.add_child(title_label)
    
    # Добавляем информацию о каждой способности
    for progress_data in ability_progress:
        var ability_label = Label.new()
        ability_label.text = "%s - получено %d очков прогресса изучения способности" % [progress_data.ability_name, progress_data.progress]
        ability_label.add_theme_font_size_override("font_size", 14)
        ability_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6, 1))  # Светло-зеленый цвет
        ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        progress_container.add_child(ability_label)
```

## Визуальный результат

### Экран победы ДО изменений:
```
┌─────────────────────────────────────┐
│            ПОБЕДА!                  │
├─────────────────────────────────────┤
│ Побежденный враг:                   │
│   uncommon Крыса 1 уровень          │
├─────────────────────────────────────┤
│ Награды:                            │
│   Опыт: 100                         │
│   Осколки душ: 20                   │
├─────────────────────────────────────┤
│        [Продолжить]                 │
└─────────────────────────────────────┘
```

### Экран победы ПОСЛЕ изменений:
```
┌─────────────────────────────────────┐
│            ПОБЕДА!                  │
├─────────────────────────────────────┤
│ Побежденный враг:                   │
│   uncommon Крыса 1 уровень          │
├─────────────────────────────────────┤
│ Награды:                            │
│   Опыт: 100                         │
│   Осколки душ: 20                   │
├─────────────────────────────────────┤
│ Прогресс изучения способностей:     │
│   Крысиная живучесть - получено     │
│     100 очков прогресса изучения    │
│     способности                     │
│   Уворот - получено 100 очков       │
│     прогресса изучения способности  │
├─────────────────────────────────────┤
│        [Продолжить]                 │
└─────────────────────────────────────┘
```

## Формат данных

### Структура данных прогресса:
```gdscript
[
    {
        "ability_name": "Крысиная живучесть",
        "progress": 100
    },
    {
        "ability_name": "Уворот",
        "progress": 100
    }
]
```

### Для обычных врагов:
- Прогресс определяется конфигурацией в `AbilityLearningSystem`
- Обычно 100 очков за способность

### Для элитных врагов:
- Двойной прогресс: 200 очков за каждую пассивную способность врага
- Прогресс суммируется с обычным прогрессом

## Особенности реализации

### 1. Асинхронность
Используется `await` для корректной работы с системой изучения способностей:
```gdscript
var ability_progress = await _save_battle_result()
```

### 2. Объединение прогресса
Прогресс от элитных врагов и обычный прогресс объединяются:
```gdscript
var ability_progress = []

if is_elite:
    var elite_progress = _apply_elite_rewards()
    ability_progress.append_array(elite_progress)

var normal_progress = await _save_battle_result()
ability_progress.append_array(normal_progress)
```

### 3. Динамическое создание UI
Секция прогресса создается программно только если есть прогресс:
```gdscript
if ability_progress.size() > 0:
    _add_ability_progress_section(ability_progress)
```

### 4. Стилизация
- Заголовок: серый цвет, размер шрифта 16
- Прогресс способностей: светло-зеленый цвет (0.6, 1.0, 0.6), размер шрифта 14
- Автоматический перенос текста для длинных названий

## Преимущества

### Информативность:
✅ Игрок видит какие способности получили прогресс
✅ Отображается точное количество очков
✅ Понятный формат сообщения

### UX:
✅ Информация показывается сразу после победы
✅ Не требует дополнительных действий от игрока
✅ Интегрировано в существующий экран победы

### Техническая реализация:
✅ Чистая архитектура с возвращением данных из функций
✅ Поддержка обычных и элитных врагов
✅ Динамическое создание UI элементов
✅ Никаких дополнительных файлов сцен

## Совместимость

### С существующими системами:
✅ Не изменяет логику начисления прогресса
✅ Совместимо со всеми типами врагов
✅ Работает с элитными врагами

### Обратная совместимость:
✅ Параметр `ability_progress` в `setup_victory()` опционален
✅ Если прогресса нет, секция не создается
✅ Старый код продолжит работать

## Результат
✅ В окне победы отображается информация о полученном прогрессе
✅ Формат: "Название способности - получено X очков прогресса изучения способности"
✅ Работает для обычных и элитных врагов
✅ Визуально приятное оформление с цветовым выделением
✅ Автоматический перенос длинных названий

