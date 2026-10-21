# RockESP

Независимая клиентская ESP-библиотека на базе ESP из исходного Rock Hub. Работает без RockUI и Drawing API, используя ScreenGui, Frame, TextLabel и Highlight.

**Файл:** `RockESP.lua`. **Версия:** 1.0.0.

## Подключение

В Studio: ModuleScript с содержимым файла и `require` из LocalScript. В среде с loadstring / HTTP: загрузите raw `RockESP.lua` и выполните возвращённый chunk. Результат — таблица RockESP.

`RockESP.new(options?) → esp`

### Параметры конструктора

| Параметр | Назначение |
| --- | --- |
| `Settings` | Таблица настроек из списка ниже |
| `Parent` | Родитель ScreenGui; по умолчанию PlayerGui |
| `Name` | Имя ScreenGui; по умолчанию `RockESP` |
| `DisplayOrder` | По умолчанию -2 |
| `AutoPlayers` | По умолчанию true: автоматически добавлять и удалять игроков |
| `RoleProvider` | `function(target, character) → roleStringOrNil`; не должен yield |
| `Filter` | `function(target, character) → boolean`; false скрывает цель; не должен yield |
| `OnRoleChanged` | `function(target, newRole, previousRole)` |
| `RoleRemote` | Явный RemoteFunction для получения ролей |
| `RoleRemoteName` | Альтернатива: имя RemoteFunction для рекурсивного поиска в ReplicatedStorage |

Для того же получения серверных ролей, что в исходнике, задайте `RoleRemoteName="GetPlayerData"`. Без этой настройки сетевые запросы не выполняются. Встроенный поиск Tool с именами Knife и Gun остаётся доступным.

ESP по умолчанию выключен. После создания вызовите `esp:Enable()` либо передайте `Settings={Enabled=true}`.

## Методы

- `esp:Set(key, value)` — изменить одну настройку.
- `esp:Configure(settings)` — изменить несколько; все значения проверяются до применения.
- `esp:Get(key)`, `esp:GetSettings()` — копии текущих настроек.
- `esp:SetEnabled(boolean)`, `Enable()`, `Disable()`, `Toggle()`.
- `esp:Reset()` — вернуть заводские настройки, включая выключенное состояние.
- `esp:Add(playerOrModel, targetOptions?) → entry` — вручную добавить игрока или NPC.
- `esp:Remove(target)`, `esp:Clear()` — убрать цель / все текущие цели.
- `esp:SetTargetOptions(target, patch)` — изменить индивидуальные настройки.
- `esp:SetRoles(roleMap)` — установить текущую карту ролей.
- `esp:ExportConfig() → json`.
- `esp:ImportConfig(json) → success, error?`.
- `esp:Destroy()` — остановить обновления, опрос ролей и удалить все созданные объекты.

`Clear()` не выключает AutoPlayers для будущих подключений. Для полностью ручного списка используйте AutoPlayers=false.

`RockESP.Defaults` — доступная копия заводских настроек. Не изменяйте `esp.Settings` напрямую: Set / Configure обновляют состояние GUI и проверяют значения.

## Настройки из исходного ESP

| Настройка | По умолчанию | Значения |
| --- | --- | --- |
| `Enabled` | false | boolean |
| `Roles` | true | Определение ролей и их цвета |
| `MaxDistance` | 1500 | 1–1000000 studs от камеры |
| `ColorMode` | `"White"` | White / Custom / Health / Rainbow / Team |
| `Color` | белый | Color3 для Custom |
| `Chams` | true | Подсветка модели |
| `Box` | true | Рамка |
| `BoxStyle` | `"Corners"` | Corners / Full |
| `Names` | true | Имя над рамкой |
| `Distance` | true | Расстояние под рамкой |
| `HealthBar` | true | Полоса здоровья слева |
| `Tracers` | false | Линии к целям |
| `TracerFrom` | `"Bottom"` | Bottom / Center / Top / Mouse |
| `ChamsFill` | 30 | 0–100; сила заливки, исходная формула `1 - value/100*0.85*alpha` |
| `TextSize` | 12 | 8–48 |
| `Thickness` | 1 | 1–8 |

В исходнике дистанция в studs была подписана `m`. Здесь по умолчанию используется корректная подпись `studs`; для исходной надписи задайте `DistanceSuffix="m"`.

## Цвета и роли

| Настройка | По умолчанию |
| --- | --- |
| `RoleColors` | Murderer: RGB(255,58,58); Sheriff и Hero: RGB(64,150,255) |
| `RoleLabels` | true |
| `RoleInterval` | 0.25 сек.; диапазон 0.05–60 |
| `RemoteInterval` | 1 сек.; диапазон 0.25–120 |
| `TeamColor` | false |
| `InfoColor` | RGB(188,188,188) |
| `HealthColorMode` | `"HSV"`; HSV / Lerp |
| `HealthLowColor` | Color3.fromHSV(0,0.8,1) |
| `HealthHighColor` | Color3.fromHSV(0.33,0.8,1) |
| `RainbowSpeed` | 0.15; диапазон 0–10 |
| `RainbowSaturation` | 0.55; диапазон 0–1 |
| `RainbowPerPlayer` | true |

RoleColors — таблица `roleName → Color3`; Configure заменяет её целиком. Для частичного изменения сначала получите копию через Get. HealthLowColor / HealthHighColor используются в режиме Lerp; HSV воспроизводит исходный переход красный → зелёный.

Приоритет роли: индивидуальная Role → RoleProvider → Tool Knife → Tool Gun → карта SetRoles / RemoteFunction. Приоритет цвета: индивидуальный Color → цвет роли → цвет команды → ColorMode.

SetRoles принимает карту по имени игрока или UserId. Значение — строка роли либо `{Role="Sheriff", Dead=false, Killed=false}`. Dead/Killed исключают запись. Можно задавать собственные роли; добавьте их в RoleColors. При каждом SetRoles предыдущая карта заменяется.

## Геометрия и оформление

| Настройка | По умолчанию | Диапазон / назначение |
| --- | --- | --- |
| `BoxFill` | true | Градиент внутри рамки |
| `BoxFillOpacity` | 0.18 | 0–1, максимальная непрозрачность градиента |
| `ChamsOutlineOpacity` | 0.9 | 0–1 |
| `DepthMode` | `"AlwaysOnTop"` | AlwaysOnTop / Occluded |
| `TextOutline` | true | Обводка текста |
| `TextOutlineOpacity` | 0.55 | 0–1 |
| `OutlineColor` | чёрный | Color3 |
| `TracerOpacity` | 0.75 | 0–1 |
| `TracerTarget` | `"Bottom"` | Bottom / Center / Top |
| `BoxHeight` | 6.4 | 0.1–1000 studs |
| `BoxWidthRatio` | 0.6 | 0.05–10 |
| `BoxYOffset` | -0.2 | -1000–1000 studs |
| `CornerWidth` | 0.28 | 0.01–0.5, доля ширины рамки |
| `CornerHeight` | 0.2 | 0.01–0.5, доля высоты рамки |
| `UseBoundingBox` | false | Проекция восьми углов GetBoundingBox вместо фиксированной рамки |
| `DisplayNames` | true | DisplayName вместо Name |
| `DistanceSuffix` | `" studs"` | Суффикс расстояния |
| `DistanceScale` | 1 | 0.0001–100000, множитель перед отображением |

При UseBoundingBox учитываются все части модели, включая аксессуары. Fixed-режим по умолчанию повторяет геометрию исходника: верх +3, низ -3.4 относительно root.

## Фильтры и производительность

| Настройка | По умолчанию | Назначение |
| --- | --- | --- |
| `TeamCheck` | false | Исключить игроков своей команды |
| `VisibleOnly` | false | Raycast-проверка отсутствия препятствий |
| `ShowLocalPlayer` | false | Рисовать локального игрока |
| `ShowDead` | false | Показывать Humanoid с Health <= 0 |
| `OffscreenChams` | false | Подсвечивать допустимые цели вне экрана |
| `FadeSpeed` | 10 | 0–100; 0 — мгновенно |
| `HealthSmoothing` | 8 | 0–100; 0 — мгновенно |
| `UpdateRate` | 0 | 0 — каждый кадр; иначе 1–240 обновлений/сек. |

CurrentCamera перечитывается при обновлении. Respawn поддерживается автоматически. AutoPlayers обновляется событиями Players. Нет отдельных RenderStepped-подписок для каждого игрока.

## Индивидуальные настройки цели

`targetOptions`: `Name` (строка), `Color` (Color3), `Role` (строка), `Enabled` (boolean). Для сброса переопределения Color / Role передайте false. Остальные настройки общие для экземпляра ESP.

NPC — Model с HumanoidRootPart, PrimaryPart или BasePart; Humanoid необязателен. Цель должна находиться в Workspace. Для NPC без Humanoid здоровье считается полным.

## Конфигурации и интеграция

ExportConfig / ImportConfig сохраняют все настройки, включая RoleColors и Color3. Функции, ссылки на RemoteFunction, список целей и текущая карта ролей в JSON не входят. Запись строки в файл или серверное хранилище выполняет вызывающий код.

Для связи с UI передавайте изменения переключателей в `esp:Set("Chams", value)`, цветовых picker — в `esp:Set("Color", color)`, dropdown — в соответствующий строковый ключ. `OnRoleChanged` можно связать с системой уведомлений. Библиотека не зависит от конкретного UI.

Для отдельного GitHub-репозитория достаточно `RockESP.lua` и этого документа, переименованного в README.md.
