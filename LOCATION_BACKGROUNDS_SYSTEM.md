# Система фонов для локаций

## Описание

Реализована система динамической смены фонов в бою в зависимости от текущей локации. Теперь каждая локация имеет свой уникальный фон, что улучшает визуальное восприятие и погружение в игру.

## Доступные фоны

### Текущие фоны

| Локация | ID | Файл фона |
|---------|-----|-----------|
| Подземелье под городом | `dungeon` | `Dungeon_under_town.png` |
| Тёмный лес | `forest` | `Dark_forest.png` |
| Заброшенное кладбище | `cemetery` | `Old_cemetery.jpg` |
| Заброшенное кладбище (2) | `abandoned_cemetery` | `Old_cemetery.jpg` |
| Тестовая арена | `test_arena` | `Dungeon_under_town.png` |

### Расположение файлов

Все фоны находятся в папке:
```
Assets/Backgrounds/
├── Dungeon_under_town.png
├── Dark_forest.png
└── Old_cemetery.jpg
```

---

## Техническая реализация

### 1. Scripts/Battle/background.gd

**Что изменено:**

1. **Добавлен маппинг локаций к фонам:**
```gdscript
var location_backgrounds: Dictionary = {
    "dungeon": "res://Assets/Backgrounds/Dungeon_under_town.png",
    "forest": "res://Assets/Backgrounds/Dark_forest.png",
    "cemetery": "res://Assets/Backgrounds/Old_cemetery.jpg",
    "abandoned_cemetery": "res://Assets/Backgrounds/Old_cemetery.jpg",
    "test_arena": "res://Assets/Backgrounds/Dungeon_under_town.png"
}
```

2. **Добавлена функция выбора фона по локации:**
```gdscript
func _load_texture_by_location() -> void:
    """Загружает текстуру фона в зависимости от текущей локации"""
    # Получаем LocationManager
    var location_manager = get_node_or_null("/root/LocationManager")
    if location_manager:
        var current_location_id = location_manager.get_current_location_id()
        
        # Выбираем фон для локации
        if current_location_id in location_backgrounds:
            texture_path = location_backgrounds[current_location_id]
        else:
            # Используем фон подземелья по умолчанию
            texture_path = location_backgrounds["dungeon"]
    else:
        # Если LocationManager не найден, используем фон по умолчанию
        texture_path = location_backgrounds["dungeon"]
    
    # Загружаем выбранную текстуру
    _load_texture()
```

3. **Изменен `_ready()`:**
```gdscript
func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _load_texture_by_location()  # Вместо _load_texture()
    if is_instance_valid(get_viewport()):
        get_viewport().connect("size_changed", Callable(self, "_update_scale"))
    # принудительно обновляем масштаб после загрузки
    await get_tree().process_frame
    _update_scale()
```

---

## Как работает система

### Последовательность загрузки фона:

1. **Инициализация сцены боя**
   - Создается узел `Background` (Sprite2D) с прикрепленным скриптом `background.gd`

2. **Вызов `_ready()`**
   - Запускается функция `_load_texture_by_location()`

3. **Получение текущей локации**
   - Обращение к `LocationManager` (автолоад)
   - Вызов `get_current_location_id()` для получения ID локации

4. **Выбор фона**
   - Поиск ID локации в словаре `location_backgrounds`
   - Если найдено - используется соответствующий фон
   - Если не найдено - используется фон подземелья по умолчанию

5. **Загрузка текстуры**
   - Вызов `_load_texture()` с выбранным путем
   - Если файл не найден - создается плейсхолдер

6. **Масштабирование**
   - Фон растягивается на весь экран
   - Сохраняются пропорции изображения

---

## Добавление новых фонов

### Шаг 1: Добавить файл фона

Поместите файл изображения в папку:
```
Assets/Backgrounds/your_background.png
```

**Рекомендации:**
- Формат: PNG или JPG
- Размер: желательно Full HD (1920x1080) или выше
- Соотношение сторон: 16:9 (оптимально)

### Шаг 2: Добавить в маппинг

Откройте `Scripts/Battle/background.gd` и добавьте запись в словарь:

```gdscript
var location_backgrounds: Dictionary = {
    "dungeon": "res://Assets/Backgrounds/Dungeon_under_town.png",
    "forest": "res://Assets/Backgrounds/Dark_forest.png",
    "cemetery": "res://Assets/Backgrounds/Old_cemetery.jpg",
    "abandoned_cemetery": "res://Assets/Backgrounds/Old_cemetery.jpg",
    "test_arena": "res://Assets/Backgrounds/Dungeon_under_town.png",
    
    # Новая локация
    "new_location_id": "res://Assets/Backgrounds/your_background.png"
}
```

**Важно:** `"new_location_id"` должен совпадать с `location_id` в `LocationManagerAutoload.gd`!

### Шаг 3: Проверка

1. Запустите игру
2. Выберите новую локацию
3. Начните бой
4. Убедитесь, что отображается правильный фон

---

## Fallback система

### Что происходит при ошибках:

1. **LocationManager не найден:**
   - Используется фон подземелья (`dungeon`)

2. **location_id не найден в маппинге:**
   - Используется фон подземелья (`dungeon`)

3. **Файл фона не существует:**
   - Генерируется плейсхолдер (градиент неба + шахматная земля)
   - В консоли выводится предупреждение

---

## Примеры использования

### Пример 1: Тёмный лес

```gdscript
# В LocationManagerAutoload.gd
var forest = LocationData.new()
forest.location_id = "forest"  # <-- Этот ID используется для выбора фона
forest.location_name = "Тёмный лес"

# В background.gd автоматически выберется:
# "forest" -> "res://Assets/Backgrounds/Dark_forest.png"
```

### Пример 2: Добавление новой локации "Вулкан"

**1. Добавляем фон:**
```
Assets/Backgrounds/Volcanic_valley.png
```

**2. Обновляем маппинг в background.gd:**
```gdscript
var location_backgrounds: Dictionary = {
    "dungeon": "res://Assets/Backgrounds/Dungeon_under_town.png",
    "forest": "res://Assets/Backgrounds/Dark_forest.png",
    "cemetery": "res://Assets/Backgrounds/Old_cemetery.jpg",
    "volcanic_valley": "res://Assets/Backgrounds/Volcanic_valley.png"  # Новая локация
}
```

**3. Создаем локацию в LocationManagerAutoload.gd:**
```gdscript
var volcano = LocationData.new()
volcano.location_id = "volcanic_valley"  # Совпадает с ключом в маппинге
volcano.location_name = "Вулканическая долина"
# ... остальные настройки ...
```

---

## Оптимизация и производительность

### Загрузка текстур

- ✅ **Текстуры загружаются один раз** при создании сцены боя
- ✅ **Используется `load()`** вместо `preload()` для динамической загрузки
- ✅ **Кеширование**: Godot автоматически кеширует загруженные ресурсы

### Память

- Размер одного Full HD фона: ~2-5 МБ (в зависимости от сжатия)
- В памяти одновременно находится только текущий фон
- При смене локации старая текстура выгружается автоматически

---

## Визуальные настройки

### Масштабирование фона

Фон автоматически растягивается на весь экран с сохранением пропорций:

```gdscript
func _update_scale() -> void:
    if texture == null:
        return
    var vp_size: Vector2i = get_viewport_rect().size
    var tex_size: Vector2i = texture.get_size()
    if tex_size.x == 0 or tex_size.y == 0:
        return
    
    # Растягиваем фон на весь экран
    var scale_x: float = float(vp_size.x) / float(tex_size.x)
    var scale_y: float = float(vp_size.y) / float(tex_size.y)
    scale = Vector2(scale_x, scale_y)
    
    # Позиционируем в центре экрана
    position = Vector2(
        vp_size.x * 0.5,  # половина экрана вправо
        vp_size.y * 0.5   # половина экрана вниз
    )
```

### Фильтрация текстур

- Используется `TEXTURE_FILTER_NEAREST` для пиксель-арт стиля
- Можно изменить на `TEXTURE_FILTER_LINEAR` для сглаживания

---

## Troubleshooting (Решение проблем)

### Проблема: Фон не меняется при смене локации

**Причина:** LocationManager не обновляет `current_location`

**Решение:**
1. Проверьте, что `LocationManager.set_current_location(location_id)` вызывается при выборе локации
2. Убедитесь, что `location_id` совпадает с ключом в `location_backgrounds`

### Проблема: Отображается плейсхолдер вместо фона

**Причина:** Файл фона не найден

**Решение:**
1. Проверьте путь к файлу в `location_backgrounds`
2. Убедитесь, что файл существует в папке `Assets/Backgrounds/`
3. Проверьте расширение файла (.png, .jpg)

### Проблема: Фон растянут неправильно

**Причина:** Неподходящее соотношение сторон изображения

**Решение:**
1. Используйте изображения с соотношением сторон 16:9
2. Или измените логику масштабирования в `_update_scale()`

---

## Планы на будущее

### Возможные улучшения:

1. **Анимированные фоны**
   - Добавление параллакс-эффекта
   - Частицы (дождь, снег, пепел)
   - Анимированные элементы (огонь, вода)

2. **Вариативность фонов**
   - Несколько вариантов фонов для одной локации
   - Случайный выбор при входе в бой
   - День/ночь варианты

3. **Плавные переходы**
   - Fade-in при загрузке фона
   - Переход между фонами при смене локации

4. **Погодные эффекты**
   - Наложение погодных эффектов поверх фона
   - Зависимость от времени суток или сюжетных событий

5. **Динамическое освещение**
   - Световые эффекты в зависимости от способностей
   - Изменение тона фона в критические моменты боя

---

## Связанные файлы

- `Scripts/Battle/background.gd` - Основная логика фонов
- `Scripts/LocationManagerAutoload.gd` - Управление локациями
- `Assets/Backgrounds/` - Папка с файлами фонов
- `Scenes/Battle/BattleScene.tscn` - Сцена боя (содержит узел Background)

---

**Дата создания:** 31 октября 2025  
**Версия:** 1.0  
**Статус:** Реализовано ✅

