# RockUI

Самостоятельная UI-библиотека для Roblox / Luau, оформленная по интерфейсу Rock Hub: почти чёрный фон, скруглённые панели, белый акцент, компактные переключатели, вкладки-пилюли и сетки карточек с изображениями.

**Версия:** 1.1.0. **Файл библиотеки:** `RockUI.lua`.

**Репозиторий:** [rockscripter/sklad](https://github.com/rockscripter/sklad). **Ветка:** `main`.

Watermark исходного Rock Hub **уже встроена в RockUI.lua**: появляется автоматически при создании окна, показывает FPS / ping / время и открывает либо закрывает это окно. Отдельно подключать её не нужно.

В этом репозитории:

- [RockUI.lua](RockUI.lua) — UI со встроенной watermark; документация в этом README.
- [RockESP.lua](RockESP.lua) — независимая ESP-библиотека; документация: [ESP.md](ESP.md).
- [logo.png](logo.png) — оригинальный логотип watermark.

Каждая Lua-библиотека возвращает таблицу API. Игровой скрипт и базы скинов для работы UI не нужны.

## Подключение

В Studio поместите содержимое `RockUI.lua` в ModuleScript и подключите его через `require` из LocalScript. Библиотека работает на клиенте; стандартный родитель — `Players.LocalPlayer.PlayerGui`.

В среде с поддержкой `loadstring` и HTTP можно загрузить raw-файл:

```lua
local RockUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/rockscripter/sklad/main/RockUI.lua"))()
```

Ссылка ведёт на `RockUI.lua` из ветки `main` репозитория `rockscripter/sklad`. Это способ подключения; полноценный демонстрационный скрипт в поставку не включён.

## Окно

`RockUI:CreateWindow(options) → window`

| Поле | По умолчанию | Назначение |
| --- | --- | --- |
| `Title` | `"Rock UI"` | Заголовок |
| `Subtitle` | `""` | Подзаголовок |
| `Name` | `"RockUI"` | Имя ScreenGui |
| `Size` | `Vector2.new(760, 530)` | Размер в логических пикселях |
| `MinSize` | `Vector2.new(480, 350)` | Минимальный размер |
| `Scale` | `1` | Масштаб; дополнительно ограничивается размером экрана |
| `Radius` | `8` | Скругление новых элементов |
| `Theme` | `"Dark"` | `"Dark"`, `"Light"` или таблица цветовых токенов |
| `ToggleKey` | `Enum.KeyCode.RightShift` | Скрытие и открытие меню |
| `Visible` | `true` | Начальная видимость |
| `Resizable` | `true` | Изменение размера за правый нижний угол |
| `AnimationSpeed` | `0.2` | Длительность анимаций в секундах |
| `ReducedMotion` | `false` | Мгновенное применение вместо tween-анимаций |
| `Parent` | `PlayerGui` | Родитель ScreenGui |
| `DisplayOrder` | `50` | Порядок отображения |
| `Storage` | `nil` | Адаптер именованных конфигураций |
| `OnDestroy` | `nil` | Callback после уничтожения |
| `Watermark` | `true` | Встроенная watermark: true, false или таблица её настроек |

Перетаскивание — за заголовок. Поддерживаются мышь и touch. Окно автоматически вписывается в экран.

### Методы окна

- `window:AddTab({Name, Description?, Icon?}) → tab`; также принимает имя строкой.
- `window:AddSeparator(text?)` — разделитель в боковой панели.
- `window:SetTitle(text)`.
- `window:SetVisible(boolean)`, `window:Toggle()`.
- `window:SetToggleKey(Enum.KeyCode | string)`.
- `window:SetSize(Vector2)`, `window:SetScale(number)`.
- `window:SetTheme(name | table)`, `window:GetTheme() → table`.
- `window:SetWatermarkVisible(boolean)` — показать / скрыть watermark; при необходимости создаёт её.
- `window:Destroy()` — удаляет UI, popups и обработчики событий библиотеки.

`window.Visible` хранит состояние меню. `window.Flags[flag]` — актуальные значения контролов; изменяйте значения через методы контролов, а не прямой записью в Flags.

## Встроенная watermark

`CreateWindow` создаёт watermark в том же ScreenGui, отдельно от скрываемой панели меню. Поэтому после закрытия окна watermark остаётся доступной и позволяет открыть меню, включая touch-устройства. Клик по watermark, крестик окна, ToggleKey и `window:SetVisible()` автоматически синхронизируют состояние `menu` / `close`. Уничтожение окна удаляет watermark и её обработчики.

По умолчанию включена. Чтобы отключить создание, передайте `Watermark=false`. Для настройки передайте `Watermark={...}` в options окна. Ссылка на созданный объект доступна как **`window.Watermark`**.

| Настройка `Watermark` | По умолчанию | Назначение |
| --- | --- | --- |
| `Brand` | `"rock hub"` | Текст бренда |
| `LogoText` | `"rh"` | Резервный текст логотипа |
| `LogoImage` | nil | Roblox asset ID / URI картинки |
| `LogoUrl` | Оригинальный URL PNG | Загрузка логотипа через файловую среду; false отключает её |
| `LogoPath` | `"rockhub_logo.png"` | Файл-кэш логотипа |
| `Position` | `UDim2.fromOffset(12,62)` | Начальная позиция |
| `Scale` | `1` | Дополнительный масштаб, >0 и <=5 |
| `AutoScale` | `true` | Исходное адаптивное масштабирование для touch |
| `Visible` | `true` | Видимость watermark независимо от видимости меню |
| `Used` | `false` | Признак первого использования, отключает начальную пульсацию |
| `Draggable` | `true` | Перетаскивание с порогом 6 px |
| `Tooltip` | `true` | Подсказка открытия / закрытия меню |
| `Shimmer` / `ShimmerSpeed` | `true` / `0.35` | Исходный движущийся градиент |
| `Pulse` | `true` | Пульсация до первого клика |
| `ReducedMotion` | Настройка окна | Отключение длительных tween-переходов |
| `ClockFormat` | `"%H:%M"` | Формат часов |
| `UpdateInterval` | `0.5` | Обновление FPS / ping, секунды |
| `PingProvider` | nil | `function() → milliseconds`, необязательный источник ping |
| `MenuText` / `CloseText` | `"menu"` / `"close"` | Подписи кнопки |
| `OpenHint` / `CloseHint` | `"click to open the menu"` / `"click to close the menu"` | Подсказки |
| `DragHint` / `KeyHint` | `"drag to move"` / `"or press"` | Текст подсказки перемещения и клавиши |
| `OnToggle` | nil | `function(open, watermark)` после переключения меню через watermark |
| `OnPositionChanged` | nil | `function(position, watermark)` после drag или SetPosition |
| `OnUsed` | nil | `function(true, watermark)` при первом клике |

Методы `window.Watermark`:

- `Show()`, `Hide()`, `Toggle()`, `SetVisible(boolean)` — видимость полосы.
- `SetMenuOpen(boolean, silent?)` — управление связанным окном; silent=true синхронизирует только индикатор и не вызывает callback.
- `SetBrand(text)`, `SetLogo(assetIdOrUri)`.
- `SetPosition(UDim2, silent?)`, `GetPosition()`, `SetScale(number)`, `SetUsed(boolean)`.
- `ShowTip(boolean, hideAfterSeconds?)`, `GetStats() → {FPS, Ping, Time}`.
- `SetTheme(...)`, `GetTheme()` — общая тема окна; `SetToggleKey(...)` — общая клавиша окна.
- `ExportConfig()`, `ImportConfig(json) → success, error?` — только состояние watermark.
- `Destroy()` — удалить watermark; `window:SetWatermarkVisible(true)` создаст её снова.

Цвета и ToggleKey наследуются от окна автоматически. Собственная обработка клавиши и ручной BindWindow не нужны. Если передано Watermark=false, поле window.Watermark отсутствует до первого SetWatermarkVisible(true).

`window:ExportConfig()` также сохраняет позицию, масштаб, видимость, признак Used и Brand watermark. `window:ImportConfig(json, {Watermark=false})` позволяет пропустить эту часть. Конфигурации UI версии 1.0 без watermark по-прежнему загружаются. ResetConfig сбрасывает значения контролов, сохраняя положение и оформление watermark.

Для картинки 1в1 используйте [logo.png](logo.png). Raw-ссылка логотипа в этом репозитории:

`https://raw.githubusercontent.com/rockscripter/sklad/main/logo.png`

Чтобы watermark загружала PNG именно из `sklad`, передайте в настройках окна:

```lua
Watermark = {
    LogoUrl = "https://raw.githubusercontent.com/rockscripter/sklad/main/logo.png",
    LogoPath = "sklad_logo.png",
}
```

Это поля таблицы options для CreateWindow. В файловой среде используется загрузка PNG через writefile и getcustomasset / getsynasset. Без явного LogoUrl библиотека использует исходный URL Rock Hub. В Studio загрузите PNG как Roblox asset и задайте LogoImage. При отсутствии картинки используется `rh`.

## Вкладки и секции

- `tab:Select()` — активировать вкладку.
- `tab:AddSubTab({Name}) → subtab`; также принимает строку.
- `tab:AddSection({Name, Collapsible?, Collapsed?}) → section`; также принимает строку.
- `subtab:AddSection(...)` — секция во вложенной вкладке.
- `section:SetCollapsed(boolean)` — свернуть / развернуть секцию.
- `container:SetVisible(boolean)`, `container:Destroy()`.
- `container:Search(query)` — фильтр по названиям и описаниям непосредственных контролов и секций.

Подвкладки добавляются **до** контента обычной вкладки. Если у вкладки есть подвкладки, добавляйте контролы и секции в них. Вкладки, подвкладки и секции поддерживают перечисленные ниже методы `Add…`.

## Общие настройки контролов

| Поле | Назначение |
| --- | --- |
| `Name` | Название |
| `Description` | Дополнительный текст строки |
| `Flag` | Уникальный ключ в `window.Controls` и `window.Flags` |
| `Default` | Начальное значение |
| `Callback` | `function(value, control)` после изменения значения |
| `Visible` | Начальная видимость; по умолчанию true |
| `Disabled` | Запрет пользовательского изменения; по умолчанию false |
| `Tooltip` | Текст всплывающей подсказки |
| `Save` | Если false, исключает контрол из сохранения и сброса конфигурации |

Начальная установка значения выполняется без callback. Callbacks запускаются отдельными задачами с перехватом ошибок. `Disabled` блокирует пользовательское управление; программный `Set` остаётся доступен.

### Общие методы

- `control:Get()` — текущее значение; таблицы возвращаются копией.
- `control:Set(value, silent?)` — установить значение; `silent=true` отключает callback и слушатели.
- `control:Reset(silent?)` — вернуть начальное значение.
- `control:OnChanged(function(value, control)) → disconnectFunction`.
- `control:SetVisible(boolean)`, `control:SetDisabled(boolean)`.
- `control:SetName(text)`, `control:SetDescription(text)`, `control:SetTooltip(text)`.
- `control:Destroy()`.

`SetDescription` обновляет существующее описание; создавайте строку с `Description`, если планируете менять его позже. Общие методы значений относятся к контролам с состоянием. Button, Label, Paragraph, Divider и Viewport имеют специализированный API ниже.

## Контролы

### Toggle

`container:AddToggle({Name, Default=false, Callback, ...}) → control`

Значение: boolean. Компактный анимированный переключатель.

### Button

`container:AddButton({Name, Text="Run", Callback, ...}) → control`

Callback кнопки имеет сигнатуру `function(control)`. `control:Press()` — программное нажатие. Кнопка не имеет сохраняемого значения.

### Slider

`container:AddSlider({Name, Min=0, Max=100, Step=1, Default, Suffix?, ...})`

Значение: конечное число. Значения округляются относительно Min с указанным шагом и ограничиваются диапазоном. Доступны перетаскивание и ручной числовой ввод. `Max > Min`, `Step > 0`.

### Input

`container:AddInput({Name, Default="", Placeholder?, MaxLength?, Numeric=false, Live=false, ...})`

Значение: строка. `MaxLength` учитывает UTF-8 символы. `Numeric=true` допускает только строки, преобразуемые в число. `Live=true` отправляет изменения во время ввода; иначе — после потери фокуса. Неверный ввод возвращает предыдущее значение.

### Dropdown с preview

`container:AddDropdown({Name, Options, Default?, Multi=false, AllowNone=true, Placeholder?, PopupWidth=330, PopupHeight=310, SearchPlaceholder?, EmptyText?, ...})`

Поиск встроен. Варианты могут быть строками либо объектами:

```lua
{ Id = "item-id", Name = "Название", Image = "rbxassetid://123", Description = "Описание", Disabled = false }
```

`Id` — уникальная строка или число. Если Id отсутствует, используются Value или Name. `Image` принимает числовой asset ID или Roblox URI, включая `rbxthumb://...`. `Preview` — альтернативное имя поля Image. Обычная внешняя HTTPS-картинка не является ImageLabel asset URI: сначала загрузите изображение в Roblox либо передайте URI локального asset вашей среды.

Для 3D-preview вместо Image передайте `Model = modelInstance` или BasePart. Объект клонируется в WorldModel внутри ViewportFrame; оригинал не изменяется. `Archivable` должен быть true. `CameraCFrame` позволяет заменить автоматическое кадрирование.

Single-select хранит Id или nil. Multi-select хранит массив Id, а не таблицы вариантов. Повторный выбор снимает выделение; `AllowNone=false` запрещает снятие одиночного выбора нажатием.

Методы селекторов:

- `control:Choose(id)` — пользовательская логика выбора, учитывает Disabled варианта и контрола.
- `control:Clear(silent?)` — очистить выбор.
- `control:IsSelected(id) → boolean`.
- `control:GetSelectedOptions() → array` — копии выбранных объектов.
- `control:SetOptions(array, silent?)` — заменить варианты; отсутствующие Id удаляются из текущего выбора.
- `control:Open()` — открыть dropdown.

`Set` и `Default` принимают Id / массив Id. После замены Options следите, чтобы первоначальный Default оставался действительным перед вызовом Reset.

### Segmented / Select

`container:AddSegmented({Name, Options, Default?, AllowNone?, ...})`

`AddSelect` — псевдоним AddSegmented. Горизонтальные кнопки одиночного выбора; формат Options и методы выбора совпадают с Dropdown. Предназначен для небольшого количества коротких вариантов. Multi не поддерживается.

### ImageSelector — сетка как на изображении

`container:AddImageSelector(options) → control`

Карточки с preview, отдельным тёмным footer, названием, редкостью, обводкой и badge выбранного элемента. Поддерживаются изображения и ViewportFrame-модели. Порционная отрисовка по мере прокрутки, поиск, категории, одиночный и множественный выбор.

Использует формат Options из Dropdown с дополнительными полями:

```lua
{ Id = "batwing", Name = "Batwing", Image = "rbxthumb://type=Asset&id=123&w=150&h=150", Category = "Knife", Rarity = "Ancient", RarityColor = Color3.fromRGB(255,198,62) }
```

| Настройка | По умолчанию |
| --- | --- |
| `Height` | `390` |
| `CardHeight` | `150` |
| `Columns` | Автоматически по ширине |
| `MinCardWidth` | `108` |
| `PageSize` | `32` |
| `Categories` | Вычисляются из Options; массив строк или `{Id, Name}` |
| `DefaultCategory` | nil — все |
| `ShowAll` | true |
| `AllText` | `"All"` |
| `Toggle` | false — дополнительный верхний переключатель |
| `ToggleText` | `"Skins"` |
| `Enabled` | true — состояние верхнего переключателя |
| `OnEnabled` | `function(enabled, control)` |
| `OnCategory` | `function(category, control)` |
| `RarityColors` | Таблица `rarity → Color3` |
| `SelectedText` | `"SELECTED"` |
| `NoneText` | `"default"` |
| `SearchPlaceholder` | `"Search..."` |
| `EmptyText` | `"Nothing found"` |

Дополнительно: `control:SetCategory(idOrNil)`, `control:SetSearch(text)`; при `Toggle=true` — `control:SetEnabled(boolean, silent?)`.

Верхний переключатель является отдельным состоянием интерфейса: он вызывает OnEnabled и не блокирует выбор карточек. В конфигурацию контрола входит выбор Id; состояние верхнего переключателя, категория и поисковая строка не сохраняются. Списки предметов и действия при выборе предоставляет вызывающий код.

### ColorPicker

`container:AddColorPicker({Name, Default=Color3.new(1,1,1), ...})`

Значение: Color3. HSV-поле, hue-полоса, ручной HEX `#RRGGBB`, три RGB-поля. Изменения отправляются в реальном времени. `control:Open()` — открыть picker.

### Keybind

`container:AddKeybind({Name, Default=Enum.KeyCode.Unknown, Mode="Press", OnTriggered?, ...})`

- `Mode="Press"`: один вызов `OnTriggered(true, control)` при нажатии.
- `Mode="Toggle"`: последовательное переключение true / false.
- `Mode="Hold"`: true при нажатии, false при отпускании.

Callback / OnChanged сообщают об изменении самой привязки. OnTriggered сообщает о нажатии. Клик по полю начинает захват клавиши; Escape отменяет, Backspace очищает. Состояние привязки — Enum.KeyCode. При вводе в TextBox привязки не срабатывают.

### Текст и медиа

- `AddLabel({Name, Height=34})` или `AddLabel(text)`; `label:Set(text)` меняет текст.
- `AddParagraph({Name, Description, Height=86})` — заголовок и многострочное описание.
- `AddDivider(text?)` — текстовый или линейный разделитель.
- `AddImage({Name, Image, Height=180, ScaleType=Enum.ScaleType.Fit, ...})`; `Set(assetIdOrUri)` меняет картинку.
- `AddViewport({Name, Model, Height=220, CameraCFrame?})`; `control.Preview` — созданный ViewportFrame.

## Темы

`window:SetTheme("Dark")` / `window:SetTheme("Light")` заменяют палитру. Таблица в SetTheme изменяет только перечисленные цвета, например `{Accent=Color3.fromRGB(170,120,255)}`. Существующие элементы и открытые dropdown обновляются автоматически.

| Токен | Dark RGB |
| --- | --- |
| `Background` | 14, 14, 14 |
| `Panel` | 20, 20, 20 |
| `Element` | 27, 27, 27 |
| `Hover` | 36, 36, 36 |
| `Stroke` | 42, 42, 42 |
| `Text` | 230, 230, 230 |
| `Dim` | 120, 120, 120 |
| `Muted` | 85, 85, 85 |
| `Accent` | 255, 255, 255 |
| `Card` | 35, 35, 35 |
| `Footer` | 16, 16, 16 |
| `Success` | 105, 208, 145 |
| `Warning` | 255, 198, 62 |
| `Danger` | 240, 94, 110 |

Значения токенов — только Color3. `RockUI.Themes` содержит встроенные палитры. Собственные RarityColor и цвета изображений не заменяются темой.

## Конфигурации

- `window:ExportConfig() → jsonString` — значения контролов с Flag, текущая палитра и состояние встроенной watermark.
- `window:ImportConfig(json, {Silent?, Theme?, Watermark?}) → success, error?`.
- `window:ResetConfig(silent?)` — начальные значения сохраняемых контролов; палитру не сбрасывает.

ImportConfig сначала проверяет все применимые значения; ошибочная конфигурация отклоняется до применения. Неизвестные Flags пропускаются. `Theme=false` сохраняет текущие цвета. `Silent=true` отключает callbacks. При обычном импорте callbacks видят уже применённые значения остальных контролов. JSON не содержит функции и Instance; Color3 и KeyCode сериализуются специальными записями.

Именованное хранение подключается через `Storage` в CreateWindow:

| Функция адаптера | Контракт |
| --- | --- |
| `Write(name, json)` | Сохранить строку; ошибка через error при неудаче |
| `Read(name)` | Вернуть сохранённую JSON-строку |
| `Delete(name)` | Удалить запись |
| `List()` | Вернуть массив имён |

Адаптер вызывается через точку, без self. Он может использовать файловую систему вашей среды либо вашу серверную систему сохранения. Библиотека сама не создаёт файлы и папки.

`window:SaveConfig(name)`, `LoadConfig(name, options?)`, `DeleteConfig(name)` возвращают `success, error?`. `ListConfigs()` возвращает `names, error?`. Имя: 1–64 ASCII буквы, цифры, `_`, `-`.

## Уведомления и подтверждение

- `window:Notify({Title, Content?, Type?, Duration=4}) → handle`. Type: `"Success"`, `"Error"` или обычное оформление. `Duration=0` отключает автоматическое закрытие. `handle:Close()` удаляет уведомление.
- `window:Confirm({Title, Content?, ConfirmText?, CancelText?, Callback}) → handle`. Callback: `function(confirmed)`. Нажатие вне окна закрывает его без callback; кнопки передают true / false. `handle:Close()` — закрытие программно.

Одновременно открывается один popup; новый dropdown, picker или Confirm закрывает предыдущий. Закрытие меню также закрывает popup.

## Публикация

Файлы размещаются в корне ветки `main` репозитория [rockscripter/sklad](https://github.com/rockscripter/sklad):

```text
RockUI.lua
RockESP.lua
README.md
ESP.md
logo.png
```

Встроенная watermark входит в `RockUI.lua` и не требует отдельного модуля. При обновлении документации замените README.md и ESP.md в корне репозитория.
