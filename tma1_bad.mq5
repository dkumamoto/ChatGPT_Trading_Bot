//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input double StopLossTicks = 10;         // Stop Loss in ticks
input double TakeProfitMultiplier = 2;   // Take Profit multiplier (2x SL)
input double LotSize = 0.1;              // Lot size
input int StartHour = 8;                 // Trading start time (hour)
input int EndHour = 13;                  // Trading end time (hour)
input int EMAPeriod = 10;                // EMA period

int OnInit() {
   // Initialization code
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   // Cleanup code
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   // Check if current time is within the trading hours
   datetime currentTime = TimeCurrent();
   int currentHour = TimeHour(currentTime);
   if (currentHour < StartHour || currentHour >= EndHour) return;

   // Define the candles
   double open1 = iOpen(_Symbol, PERIOD_M5, 2);
   double close1 = iClose(_Symbol, PERIOD_M5, 2);
   double high1 = iHigh(_Symbol, PERIOD_M5, 2);
   double low1 = iLow(_Symbol, PERIOD_M5, 2);

   double open2 = iOpen(_Symbol, PERIOD_M5, 1);
   double close2 = iClose(_Symbol, PERIOD_M5, 1);
   double high2 = iHigh(_Symbol, PERIOD_M5, 1);
   double low2 = iLow(_Symbol, PERIOD_M5, 1);

   double open3 = iOpen(_Symbol, PERIOD_M5, 0);
   double close3 = iClose(_Symbol, PERIOD_M5, 0);
   double high3 = iHigh(_Symbol, PERIOD_M5, 0);
   double low3 = iLow(_Symbol, PERIOD_M5, 0);

   // Calculate EMA
   double ema = iMA(_Symbol, PERIOD_M5, EMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);

   // Check for Buy Condition
   if (close1 < open1 && close2 < open2 && close3 > open3 && close3 > MathMax(high1, high2) && close3 > ema) {
      double sl = low3 - StopLossTicks * _Point; // Stop Loss 1 tick below low of entry candle
      double tp = close3 + (close3 - sl) * TakeProfitMultiplier; // Take Profit 2x the SL distance
      // Open Buy order
      MqlTradeRequest request;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(result);
      request.action = TRADE_ACTION_DEAL;
      request.symbol = _Symbol;
      request.volume = LotSize;
      request.type = ORDER_TYPE_BUY;
      request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      request.sl = sl;
      request.tp = tp;
      request.deviation = 2;
      request.magic = 0;
      request.comment = "Buy Trade";
      if(!OrderSend(request, result)) {
         Print("Error opening Buy Order: ", result.retcode);
      }
   }

   // Check for Sell Condition
   if (close1 > open1 && close2 > open2 && close3 < open3 && close3 < MathMin(low1, low2) && close3 < ema) {
      double sl = high3 + StopLossTicks * _Point; // Stop Loss 1 tick above high of entry candle
      double tp = close3 - (sl - close3) * TakeProfitMultiplier; // Take Profit 2x the SL distance
      // Open Sell order
      MqlTradeRequest request;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(result);
      request.action = TRADE_ACTION_DEAL;
      request.symbol = _Symbol;
      request.volume = LotSize;
      request.type = ORDER_TYPE_SELL;
      request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      request.sl = sl;
      request.tp = tp;
      request.deviation = 2;
      request.magic = 0;
      request.comment = "Sell Trade";
      if(!OrderSend(request, result)) {
         Print("Error opening Sell Order: ", result.retcode);
      }
   }
}
