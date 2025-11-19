# CryptoLab
### Задание по асинхронному программированию на Dart с CoinGecko API

- Работа с `Future` и `async/await`
- Создание и использование `Stream`
- HTTP-запросы с помощью пакета `http`
- Десериализация JSON в Dart-объекты
- Реализация паттерна Repository
- Обработка ошибок в асинхронном коде
---
#### Задачи:

1. **Создание моделей данных**
   - `Coin` - базовая информация о криптовалюте
   - `CoinDetails` - детальная информация

2. **Реализация Repository**
   - `getTopCoins(int limit)` - получение топ криптовалют
   - `getCoinDetails(String coinId)` - детальная информация о монете
   - `getCoinsStream(List<String> coinIds)` - стрим с монетами

3. **CLI-интерфейс**
   - Вывод отформатированной информации в консоль

4. Использовать json_serializable (можно с freezed) для создания моделей

5. **Периодическое обновление**
   - `pollPrices()` - стрим с периодическим обновлением цен

6. **Трансформации стримов**
   - Фильтрация по цене
   - Извлечение только названий

---
  
#### Запуск:

```bash
dart pub get
dart run task.dart
```
#### Вывод:
<img width="814" height="337" alt="Снимок экрана 2025-11-08 в 02 39 58" src="https://github.com/user-attachments/assets/e0c7c9f4-afe9-4127-ae59-c8a3e79d4c4a" />
<img width="814" height="638" alt="Снимок экрана 2025-11-08 в 02 40 33" src="https://github.com/user-attachments/assets/cacc3609-400c-4154-bdf8-059fee0f3553" />
