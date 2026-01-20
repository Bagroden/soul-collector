# Инструкция по настройке автозагрузки AbilityLearningSystem

## 🎯 Проблема
Система изучения способностей не работает, потому что `AbilityLearningSystem` не настроен как автозагрузка.

## 🔧 Решение

### **Шаг 1: Открыть Project Settings**
1. В Godot перейдите в **Project → Project Settings**
2. Выберите вкладку **Autoload**

### **Шаг 2: Добавить AbilityLearningSystem**
1. В поле **Path** введите: `res://Scripts/Systems/AbilityLearningSystem.gd`
2. В поле **Node Name** введите: `AbilityLearningSystem`
3. Нажмите кнопку **Add**

### **Шаг 3: Проверить настройки**
Убедитесь, что в списке автозагрузок есть:
- **Node Name:** AbilityLearningSystem
- **Path:** res://Scripts/Systems/AbilityLearningSystem.gd
- **Enable:** ✅ (галочка установлена)

### **Шаг 4: Сохранить проект**
1. Нажмите **Save** в Project Settings
2. Перезапустите проект

## ✅ Результат
После настройки автозагрузки система изучения способностей будет доступна глобально через `/root/AbilityLearningSystem`.

## 🚨 Альтернативное решение (если автозагрузка не работает)

Если по какой-то причине автозагрузка не работает, можно создать систему программно:

```gdscript
# В AbilityLearningWindow.gd
func _ready():
    # Создаем систему изучения способностей если её нет
    var ability_learning_system = get_node_or_null("/root/AbilityLearningSystem")
    if not ability_learning_system:
        var system_scene = preload("res://Scripts/Systems/AbilityLearningSystem.gd")
        ability_learning_system = Node.new()
        ability_learning_system.set_script(system_scene)
        ability_learning_system.name = "AbilityLearningSystem"
        get_tree().root.add_child(ability_learning_system)
        await get_tree().process_frame
    
    ability_learning_system = get_node("/root/AbilityLearningSystem")
    # ... остальной код
```

**Рекомендуется использовать автозагрузку для лучшей производительности!** 🎯✨
