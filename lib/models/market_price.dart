// Compatibility re-export.
// Some parts of the project (or older branches) may import `market_price.dart`.
// Keep a single source of truth for MarketPrice/Candle in `market_model.dart`.

export 'market_model.dart' show MarketPrice, Candle;
