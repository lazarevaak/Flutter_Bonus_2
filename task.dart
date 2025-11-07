import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class Coin {
  final String id;
  final String name;
  final String symbol;
  final double current_price;
  final double market_cap;

  Coin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.current_price,
    required this.market_cap,
  });

  static Coin fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      current_price: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      market_cap: (json['market_cap'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() => '$name ($symbol): \$${current_price.toStringAsFixed(2)}';
}

class CoinDetails {
  final String id;
  final String name;
  final String symbol;
  final String description;
  final double market_cap_rank;
  final double price_change_24h;

  CoinDetails({
    required this.id,
    required this.name,
    required this.symbol,
    required this.description,
    required this.market_cap_rank,
    required this.price_change_24h,
  });

  static CoinDetails fromJson(Map<String, dynamic> json) {
    return CoinDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      description: json['description']?['en'] ?? '',
      market_cap_rank: (json['market_cap_rank'] as num?)?.toDouble() ?? 0.0,
      price_change_24h:
          (json['market_data']?['price_change_percentage_24h'] as num?)
                  ?.toDouble() ??
              0.0,
    );
  }
}

class CoinGeckoRepository {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  Future<List<Coin>> getTopCoins(int limit) async {
    final url = Uri.parse(
        '$_baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=$limit');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw HttpException('Ошибка при загрузке монет: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Coin.fromJson(json)).toList();
  }

  Future<CoinDetails> getCoinDetails(String coinId) async {
    final url = Uri.parse('$_baseUrl/coins/$coinId?localization=false');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw HttpException(
          'Ошибка при загрузке монеты $coinId: ${response.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return CoinDetails.fromJson(data);
  }

  Stream<Coin> getCoinsStream(List<String> coinIds) async* {
    for (final id in coinIds) {
      try {
        final details = await getCoinDetails(id);
        yield Coin(
          id: details.id,
          name: details.name,
          symbol: details.symbol,
          current_price: details.price_change_24h,
          market_cap: details.market_cap_rank,
        );
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        print('Ошибка при загрузке $id: $e');
      }
    }
  }

  Stream<List<Coin>> pollPrices(List<String> coinIds, Duration interval) async* {
    while (true) {
      try {
        final url = Uri.parse(
          '$_baseUrl/coins/markets?vs_currency=usd&ids=${coinIds.join(',')}',
        );
        final response = await http.get(url);
        if (response.statusCode != 200) {
          throw HttpException('Ошибка при загрузке нескольких монет: ${response.statusCode}');
        }

        final List<dynamic> data = jsonDecode(response.body);
        final coins = data.map((json) => Coin.fromJson(json)).toList();
        yield coins;
      } catch (e) {
        print('Ошибка при обновлении цен: $e');
      }
      await Future.delayed(interval);
    }
  }

  Stream<Coin> getFilteredCoinsStream(List<String> coinIds, double minPrice) async* {
    await for (final coin in getCoinsStream(coinIds)) {
      if (coin.current_price >= minPrice) {
        yield coin;
      }
    }
  }
}

void main() async {
  final repository = CoinGeckoRepository();

  print('Начинаем работу с CoinGecko API...\n');

  try {
    print('Топ 5 криптовалют по рыночной капитализации:');

    final topCoins = await repository.getTopCoins(5);

    for (final coin in topCoins) {
      print(coin);
    }

    print('\n' + '=' * 50 + '\n');

    print('Детальная информация о Bitcoin:');

    final btcDetails = await repository.getCoinDetails('bitcoin');

    print('Название: ${btcDetails.name}');
    print('Описание: ${btcDetails.description.substring(0, 100)}...');
    print('Изменение за 24ч: ${btcDetails.price_change_24h}%');

    print('\n' + '=' * 50 + '\n');

    print('Получение информации через стрим:');
    final coinIds = ['bitcoin', 'ethereum', 'cardano'];
    await for (final coin in repository.getCoinsStream(coinIds)) {
      print('Получена монета: ${coin.name} - \$${coin.current_price}');
    }

    print('\n' + '=' * 50 + '\n');

    print('\nПериодическое обновление цен (каждые 5 секунд):');
    final subscription = repository
        .pollPrices(['bitcoin', 'ethereum'], const Duration(seconds: 5))
        .take(3)
        .listen((coins) {
      print('\nОбновление: ${DateTime.now()}');
      for (final coin in coins) {
        print('  ${coin.name}: \$${coin.current_price}');
      }
    });
    await subscription.asFuture();

    print('\n' + '=' * 50 + '\n');

    print('Монеты с ценой > 1000:');
    await for (final coin
        in repository.getFilteredCoinsStream(['bitcoin', 'ethereum'], 1000)) {
      print('${coin.name}: \$${coin.current_price}');
    }
  } catch (e) {
    print('Ошибка: $e');
  }

  print('\nПрограмма завершена!');
}
