//+------------------------------------------------------------------+
//|                                                     beta-one.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

int OnInit(){
   return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason){
}

#include<Trade\Trade.mqh>
CTrade trade;

datetime globalbartime;
input int thisEAMagicNumber = 0x110001;
string direction = "overbought";
input int tProfit = 2; 
input int sLoss = 5;

int stoch5Min = iStochastic(_Symbol,PERIOD_M5,8,3,3,MODE_SMA,STO_LOWHIGH);
int BBands1min = iBands(_Symbol,PERIOD_M1,20,0,2,PRICE_CLOSE);

void OnTick(){
   trade.SetExpertMagicNumber(thisEAMagicNumber);   
   datetime rightbartime = iTime(_Symbol,PERIOD_CURRENT, 0);
   if(rightbartime != globalbartime){
      closeLoosingPositions();
      runLogic();
      globalbartime = rightbartime;
   }
}

void runLogic(){
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   int takeProfit = tProfit * 1000; 
   int stopLoss = sLoss * 1000; 

   double accountBal = AccountInfoDouble(ACCOUNT_BALANCE);
   double newLot = NormalizeDouble(accountBal/500, 2);
   
   if(newLot > 50){
      newLot = 50.00;
   }else if(newLot < 0.2){
      newLot = 0.20;
   }
   
   newLot = 0.20;
   
   int condition1 = redSig(stoch5Min);
   int condition2 = yellowSig(stoch5Min);
   int condition3 = greenSig(BBands1min);
   
   if(condition1 == false){ 
      if(condition2 == true){ 
         if(condition3 == true){
            Alert("Possible Buy Trade Found");
             if(PositionsTotal() < 1){
               trade.Buy(newLot, NULL, Ask, NULL, Ask+takeProfit*_Point, NULL);
             }
         } 
      }
   }
}

bool redSig (int stochDef){
   double L1[];  double L2[];
   ArraySetAsSeries(L1, true);
   ArraySetAsSeries(L2, true);
   
   CopyBuffer(stochDef,0,0,4,L1);
   CopyBuffer(stochDef,1,0,4,L2);
   
   if((( L1[0] > 70) || ( L2[0] > 70)) || (( L1[1] > 70) || ( L2[2] > 70))){
      direction = "overbought";
      return true;
   }
   return false;
}

bool yellowSig (int stochDef){
   double L1[];  double L2[];
   ArraySetAsSeries(L1, true);
   ArraySetAsSeries(L2, true);
   
   CopyBuffer(stochDef,0,0,10,L1);
   CopyBuffer(stochDef,1,0,10,L2);
   
   if(direction == "overbought"){
      if( L1[0] < 30 ){
         direction = "oversold";
         return true;
      }
   }else{
      return true;   
   }
   return false;
}

bool greenSig (int BBandsDef){
   MqlRates priceInfo[];
   CopyRates(_Symbol, PERIOD_M1, 0, 3, priceInfo);
   
   double UBand[]; double LBand[];
   ArraySetAsSeries(priceInfo, true); 
   ArraySetAsSeries(UBand, true); 
   ArraySetAsSeries(LBand, true);
   
   CopyBuffer(BBandsDef,1,0,3,UBand);
   CopyBuffer(BBandsDef,2,0,3,LBand); 
   
   if(priceInfo[1].open > priceInfo[1].close){ 
      if(priceInfo[1].close < LBand[1]) return true;
   }
   
   return false;
}

void closeLoosingPositions (){
   if(PositionsTotal() > 0){
      for(int i=PositionsTotal()-1; i>=0; i--){  
         string symbols = PositionGetSymbol(i);
         ulong posTicket = PositionGetInteger(POSITION_TICKET);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double SL = openPrice-sLoss*_Point;
         
         if(currentPrice < SL){
            trade.PositionClose(posTicket);
         }
      }
   }
}
