## MiningAndDrovaIO

Обеспечиваем бесперебойную поочередную работу стриминга игр в [Drova.io](https://drova.io/stations/9bcf8d1b-85bb-4f5e-bcce-61e0ddd6e5e6 "Drova.io") и майнинга ETH с таблеткой в периоды неактивности.
Актуально для видеокарт с памятью **GDDR5X**: GTX 1060, 1070, 1080 и 1080 Ti.

------------

Разработал методику разгона: **mineshanya**#1525 (Discord)
Помогли с идеей скрипта и настройкой планировщика: **dmf**#5859 (Discord), **gloomakaemphatic**#5245 (Discord)

## Как настроить данный набор скриптов

У вас на пк должны иметься:
- MSI Afterburner
- OhGodAnETHlargementPill-r2
- NiceHashMiner с плагином t-rex
- В настройках драйвера видеокарты параметр "CUDA Force P2 State" должен быть в положении "Off"

Последнее можно сделать через **NiceHashMiner** или **nvidiaProfileInspector**.
Этот параметр не позволяет снижать частоту видеопамяти под нагрузкой, а также резко возвращать высокую частоту видеопамяти сразу после окончания нагрузки, положительно влияет на стабильность разгона.

------------

Добавляем в планировщик 2 задачи - одна триггерится запуском ese.exe, вторая при простое.
К каждой задаче прилагается по PowerShell скрипту, разместите их в любом удобном месте вашего пк и **пропишите этот путь** в задачах.

**НЕ ЗАБУДЬТЕ ТАКЖЕ ПРОПИСАТЬ СВОИ ПУТИ И ПАРАМЕТРЫ В СКРИПТЕ Mining_Start.ps1**

Вот так можно настроить отслеживание запуска программ:
https://winitpro.ru/index.php/2021/05/13/vypolnit-dejstvie-pri-zapuske-zavershenii-programmy-v-windows/

## Как подобрать разгон для майнинга на примере GTX 1080 (актуально для всех карт, поддерживающих таблетку)
При разгоне видеокарты можно заметить, что при пошаговом увеличении частоты видеопамяти, на некоторых шагах производительность резко подскакивает относительно соседних (примерно на 1 MH/s).

> Например, 5692 MHz <-> 26.67 MH/s, 5760 MHz <-> 27.28 MH/s, 5764 MHz <-> 26.24 MH/s.
Здесь частота 5760 MHz - "локальный максимум". Именно в таких точках запуск таблетки будет успешным, а во всех остальных полетят артефакты и выбьет синий экран.
В моём случае, "локальные максимумы" шли через один до частоты 5579 MHz, а затем примерно через 2-4 ступени вплоть до 5840 MHz.

Очень **важный** момент! После перезагрузки пк эта таблица периодически смещается на 1 шаг туда-сюда (5760 MHz -> 5764 MHz или 5764 MHz -> 5760 MHz).

### Как составить табличку "локальных максимумумов"

1. **Выделяем свободный день** (процесс довольно долгий и медитативный)
	1.1. **Закрываем всё лишнее** - программы, браузеры, плееры и т.п.
2. **Фиксируем частоту ядра** на некотором произвольном значении и напряжении (ближе к максимальному стабильному, чтобы нагляднее видеть всплески производительности, например 1987 MHz при 1.080v)
3. **Следим за стабильностью температур** (можно, например, зафиксировать обороты кулера) (10-я серия снижает кривую частоту ядра на 1 шаг примерно каждые 10 градусов, это будет мешать отслеживать всплески)
4. **Запускаем майнер**
5. **Устанавливаем начальную частоту** видеопамяти ~5500 MHz
6. **Ждём устоявшегося хешрейта**, к пк в этот момент **не прикасаемся** и **не двигаем** мышкой (да, это влияет, проверьте сами)
7. **Записываем** частоту видеопамяти и хешрейт куда-нибудь в табличку (столбцы: частота памяти, MH/s, удачность запуска таблетки (последний заполняем на 10 шаге))
8. **Переходим на ступень выше** по частоте видеопамяти и повторяем шаги 6-7 до достижения частоты ~5800 MHz
9. Теперь **анализируем табличку**, отмечаем "локальные максимумы", далее работаем **только** с ними!
10. **Перебираем по очереди** "локальные максимумы" и вносим в табличку удачность запуска таблетки (не забываем, что после перезагрузки пк они могут сдвинуться, не забывайте это проверять!)

Теперь, когда вы нашли локальные максимумы, запишите в MSI Afterburner 2 профиля - один с локальным максимумом, второй с его соседним положением (в какую сторону - выясняете экспериментально)
В моем случае, это профиль 4 (5760 MHz) и профиль 5 (5764 MHz).

------------

Ну вот и всё! Теперь остается только запустить сам майнинг по следующей логике:
1. Убеждаемся, что в MSI Afterburner активирован один из майнинговых профилей
2. Запускаем майнер, например, NiceHashMiner с плагином t-rex
3. Дожидаемя генерации DAG-файла и старта работы
4. По MH/s определяем, попали ли мы на "локальный максимум"
	4.1. Если это не "локальный максимум", меняем профиль в MSI Afterburner на соседний
	4.2. Если это "локальный максимум", то переходим к следующему шагу
5. Запускаем таблетку и любуемся высоким хешрейтом

------------

> Помимо MH/s, "локальные максимумы" можно отслеживать и по FB Usage (Frame Buffer), именно через него у меня написан скрипт.
Из преимуществ, "локальный максимум" видно сразу же после начала майнинга, не нужно дожидаться устоявшегося хешрейта.
Из недостатков, визуально не всегда очевидно, что это именно он, особенно когда плохо представляешь, чего ожидать.