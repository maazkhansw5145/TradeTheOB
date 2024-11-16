//+------------------------------------------------------------------+
//|                                                   TradeTheOB.mq5 |
//|                        Maaz Khan Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Maaz Khan Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 0
#property strict

#include <Object.mqh>
#include <Trade\Trade.mqh>

double indicatorBuffer[];

datetime lastHourCandleTime = 0;
datetime last15MinCandleTime = 0;

string lastBearishRectangleName = "";
string lastBullishRectangleName = "";

double BuySignalPrice = 0;
double SellSignalPrice = 0;
double StopLoss = 0;

int fastEMA;
int slowEMA;

double fastEMABuffer[];
double slowEMABuffer[];

string currentTrend = "";

CTrade trade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   slowEMA = iMA(_Symbol, PERIOD_H1, 100, 0, MODE_SMA, PRICE_CLOSE); // Short EMA
   fastEMA = iMA(_Symbol, PERIOD_H1, 20, 0, MODE_SMA, PRICE_CLOSE); // Long EMA
   ArraySetAsSeries(slowEMABuffer,true);
   ArraySetAsSeries(fastEMABuffer,true);
   SetIndexBuffer(0, indicatorBuffer);
   EventSetTimer(900); // 15 minutes
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
  }
//+------------------------------------------------------------------+

void updateTheBearishOB(double rectTop, double rectBottom, string rectName, datetime newCandleTime, double currentCandleHigh) {
    if (currentCandleHigh > rectTop) {
        ObjectDelete(0, rectName);
        lastBearishRectangleName = "";
        SellSignalPrice = 0;
    } else if (currentCandleHigh > rectBottom) {
        string arrowName = "LongEntryArrow_" + IntegerToString(newCandleTime);
        SellSignalPrice = rectBottom;
        StopLoss = rectTop;
        BuySignalPrice = 0;
        if (ObjectFind(0, arrowName) == -1) {    
            ObjectCreate(0, arrowName, OBJ_ARROW_DOWN, 0, newCandleTime, rectBottom);
            ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrRed);
        }
          ObjectDelete(0, rectName);
          lastBearishRectangleName = "";
    }
}

void updateTheBullishOB(double rectTop, double rectBottom, string rectName, datetime newCandleTime, double currentCandleLow) {
if (rectBottom > currentCandleLow) {
   ObjectDelete(0, rectName);
   lastBullishRectangleName = "";
   BuySignalPrice = 0;
   StopLoss = 0;
   } else if (rectTop > currentCandleLow ) {
      string arrowName = "LongEntryArrow_" + IntegerToString(newCandleTime);
      BuySignalPrice = rectTop;
      StopLoss = rectBottom;
      SellSignalPrice = 0;
      //if (ObjectFind(0, arrowName) == -1) {
      //   ObjectCreate(0, arrowName, OBJ_ARROW_UP, 0, newCandleTime, rectTop);
      //   ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrYellow);
      // }
     ObjectDelete(0, rectName);
     lastBullishRectangleName = "";
   }
}

// Function to close all short positions
void CloseAllShortTrades() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            trade.PositionClose(ticket);
        }
    }
}

// Function to close all long positions
void CloseAllLongTrades() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            trade.PositionClose(ticket);
        }
    }
}

void OpenLongTrade() {
   CloseAllShortTrades();
   double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);   
   double lotSize = CalculateLotSize(price);   
 
   if (trade.Buy(lotSize, NULL, price, StopLoss, NULL, "Long Trade")) {
      Print("Long trade opened successfully at price: ", price, " and SL: ", StopLoss);
   } else {
      Print("Error opening long trade: ", GetErrorDescription(GetLastError()));
   }
   
   SellSignalPrice = 0;
   BuySignalPrice = 0;
   StopLoss = 0; 
   
   //TODO: Remove all OBs
}

void OpenShortTrade() {
   CloseAllLongTrades();
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double takeProfit = price - (2 * (StopLoss - price));       
   double lotSize = CalculateLotSize(price);   
    
   if (trade.Sell(lotSize, _Symbol, price, StopLoss, NULL, "Short Trade")) {
      Print("Short trade opened successfully at price: ", price, " and SL: ", StopLoss);
   } else {
      Print("Error opening short trade: ", GetErrorDescription(GetLastError()));
   }
   
   SellSignalPrice = 0;
   BuySignalPrice = 0;
   StopLoss = 0; 
   
   //TODO: Remove all OBs
}

string GetErrorDescription(int errorCode) {
   switch (errorCode) {
      case 0: return "No error";
      case 1: return "No connection";
      case 2: return "Trade timeout";
      default: return "Unknown error";
   }
}

//+------------------------------------------------------------------+
//| Function to check the trend                                       |
//+------------------------------------------------------------------+

// TODO: This function does not works update it
string CheckTrend() {
  int values = CopyBuffer(slowEMA,0,0,2,slowEMABuffer);
       values = CopyBuffer(fastEMA,0,0,2,fastEMABuffer);
       
   if(fastEMABuffer[0] > slowEMABuffer[0] && fastEMABuffer[1] <= slowEMABuffer[1]){
         if(currentTrend != "Uptrend"){
            currentTrend = "Uptrennd";
            CloseAllShortTrades();
         }
         Print("Uptrend");
         return "Uptrend";
      
   } else if (fastEMABuffer[0] < slowEMABuffer[0] && fastEMABuffer[1] >= slowEMABuffer[1]) {
         if(currentTrend != "Downtrend"){
              currentTrend = "Downtrend";
              CloseAllLongTrades();
         }
         Print("Down Trend");
         return "Downtrend";
   } else {
      return "Sideways";
   }
}

double CalculateLotSize(double entryPrice) {
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskPercentage = 0.01; // 1% risk
    double riskAmount = accountBalance * riskPercentage;

    // Get the current price
    double stopLossDistance = MathAbs(entryPrice - StopLoss);

    // Calculate the value per pip
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

    // Calculate lot size
    double lotSize = riskAmount / (stopLossDistance / tickSize * tickValue);

    // Ensure the lot size is within the broker's limits
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    // Round the lot size to the nearest valid step
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;
    return lotSize;
}


//+------------------------------------------------------------------+
//| Timer event handler                                              |
//+------------------------------------------------------------------+
void OnTimer() {
   datetime currentHourCandleTime = iTime(_Symbol, PERIOD_H1, 0);
   datetime current15MinCandleTime = iTime(_Symbol, PERIOD_M15, 0);
   
   if (current15MinCandleTime != last15MinCandleTime) {
      last15MinCandleTime = current15MinCandleTime;
      double C1high = iHigh(_Symbol, PERIOD_M15, 1);
      double C1close = iClose(_Symbol, PERIOD_M15, 1);
      double C1low= iLow(_Symbol, PERIOD_M15,1);  
      if(lastBullishRectangleName != ""){
         double bullishRectTop = ObjectGetDouble(0, lastBullishRectangleName, OBJPROP_PRICE,0);
         double bullishRectBottom = ObjectGetDouble(0, lastBullishRectangleName, OBJPROP_PRICE,1);
         updateTheBullishOB(bullishRectTop, bullishRectBottom, lastBullishRectangleName,current15MinCandleTime,C1low);
      }
   
   if(lastBearishRectangleName != ""){
      double bearishRectTop = ObjectGetDouble(0, lastBearishRectangleName, OBJPROP_PRICE,0);
      double bearishRectBottom = ObjectGetDouble(0, lastBearishRectangleName, OBJPROP_PRICE,1);
      updateTheBearishOB(bearishRectTop, bearishRectBottom, lastBearishRectangleName,current15MinCandleTime,C1high);  
   }
      
      // --------- Phase 3 ------------------------
   if(BuySignalPrice != 0 && StopLoss != 0 && C1close > BuySignalPrice) {
      string trend = CheckTrend();
      if(trend != "Downtrend"){
         OpenLongTrade();
      }
   }
      
   if(SellSignalPrice != 0 && StopLoss != 0 && C1close < SellSignalPrice) {
      string trend = CheckTrend();
      if(trend != "Uptrend"){
         OpenShortTrade();
      }
   }
}

   // ----- Phase 1 ---------------------
   if (currentHourCandleTime != lastHourCandleTime) {
      lastHourCandleTime = currentHourCandleTime;
      
      double C1high = iHigh(_Symbol, PERIOD_H1, 1);
      double C1open = iOpen(_Symbol, PERIOD_H1, 1);
      double C1low= iLow(_Symbol, PERIOD_H1,1);
      double C1close = iClose(_Symbol, PERIOD_H1, 1);
          
      double C2high = iHigh(_Symbol, PERIOD_H1, 2);
      double C2low= iLow(_Symbol, PERIOD_H1,2);
      double C2open= iOpen(_Symbol, PERIOD_H1, 2);
      double C2close= iClose(_Symbol, PERIOD_H1, 2);
      
      double C2UpperWick = C2high - MathMax(C2open, C2close);
      double C2lowerWick = MathMin(C2open, C2close) - C2low;
      
      double C3high = iHigh(_Symbol, PERIOD_H1, 3);
      double C3low= iLow(_Symbol, PERIOD_H1,3);
      double C3open= iOpen(_Symbol, PERIOD_H1, 3);
      double C3close= iClose(_Symbol, PERIOD_H1, 3);

      double C3UpperWick = C3high - MathMax(C3open, C3close);
      double C3lowerWick = MathMin(C3open, C3close) - C3low;
      
      double C4high = iHigh(_Symbol, PERIOD_H1, 4);
      double C4low= iLow(_Symbol, PERIOD_H1,4);
      double C4open= iOpen(_Symbol, PERIOD_H1, 4);
      double C4close= iClose(_Symbol, PERIOD_H1, 4);
      
      double C4UpperWick = C4high - MathMax(C4open, C4close);
      double C4lowerWick = MathMin(C4open, C4close) - C4low;
      
      double C5high = iHigh(_Symbol, PERIOD_H1, 5);
      double C5low= iLow(_Symbol, PERIOD_H1,5);
      double C5close = iClose(_Symbol, PERIOD_H1, 5);
     
      double C6high = iHigh(_Symbol, PERIOD_H1, 6);
      double C6low= iLow(_Symbol, PERIOD_H1,6);
     
      if (C3lowerWick > C3UpperWick &&   
          C1low > C3low &&
          C2low > C3low &&
          C4low > C3low && 
          C5low > C3low &&
          C6low > C3low             
       ) {
       CloseAllShortTrades();
         string rectName = "Bullish_OrderBlock_" + IntegerToString(currentHourCandleTime);
         lastBullishRectangleName = rectName;
         if (ObjectFind(0, rectName) == -1) {
            ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, currentHourCandleTime - (PeriodSeconds(PERIOD_H1) * 3), C3high,  currentHourCandleTime + (3 * PeriodSeconds(PERIOD_H1)), C3low);
            ObjectSetInteger(0, rectName, OBJPROP_COLOR, clrYellow);
            ObjectSetInteger(0, rectName, OBJPROP_STYLE, STYLE_SOLID);
         }
      } else if (C3UpperWick > C3lowerWick &&   
                 C3high > C1high && 
                 C3high > C2high && 
                 C3high > C4high && 
                 C3high > C5high &&
                 C3high > C6high
         ) {
         CloseAllLongTrades();
         string rectName = "Bearish_OrderBlock_" + IntegerToString(currentHourCandleTime);
         lastBearishRectangleName = rectName;
         if (ObjectFind(0, rectName) == -1) {
            ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, currentHourCandleTime - (PeriodSeconds(PERIOD_H1) * 3), C3high,  currentHourCandleTime + (3 * PeriodSeconds(PERIOD_H1)) , C3low);
            ObjectSetInteger(0, rectName, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, rectName, OBJPROP_STYLE, STYLE_SOLID);
         }
      }
   }
}
