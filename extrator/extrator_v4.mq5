//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Robô Neural INC."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

input datetime             DateFrom              = "";         // DATA/HORA INICIAL
input datetime             DateTo                = "";         // DATA/HORA FINAL
input string               ativo                 = "EURUSD";   // ATIVO
input ENUM_TIMEFRAMES      timeframe             = PERIOD_M15; // TIMEFRAME PRINCIPAL
int                  periodorsi            = 14;         // PERÍODO RSI
int                  periodobb             = 21;         // PERIODO BOLINGER
double               desviobb              = 2.0;        // DESVIO BOLINGER
double               stepsar               = 0.02;       // STEP SAR
double               maximumsar            = 0.23;       // MAXIMUM SAR

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {
//Formacao de preços timeframe olhcv
   MqlRates rates[];
   if(CopyRates(ativo,timeframe,DateFrom,DateTo,rates) == -1)
      Alert("Erro ao baixar dados OHLCV");
   else
      Print("Copiando dados para array ohlc... aguarde");

//ArraySetAsSeries(rates,true);

///Formacao do indicador RSI
   int      handle_rsi = iRSI(ativo, timeframe,periodorsi,PRICE_CLOSE);
   double   rsi[];
   CopyBuffer(handle_rsi,0,DateFrom,DateTo,rsi);
   if(CopyBuffer(handle_rsi,0,DateFrom,DateTo,rsi)<0)
      Alert("Erro ao copiar dados de RSI: ", GetLastError());
   else
      Print("Copiando dados para array do RSI... aguarde");
//ArraySetAsSeries(rsi,true);

///Formacao do indicador BOLINGER
   int      handleBB   =  iBands(ativo,timeframe,periodobb,0,desviobb,PRICE_CLOSE);
   double   bbu[],bbd[];
   CopyBuffer(handleBB,1,DateFrom,DateTo,bbu);
   if(CopyBuffer(handleBB,1,DateFrom,DateTo,bbu)<0)
      Alert("Erro ao copiar dados de Bolinger Superior: ", GetLastError());
   else
      Print("Copiando dados para array do Bolinger Superior... aguarde");
   CopyBuffer(handleBB,2,DateFrom,DateTo,bbd);
   if(CopyBuffer(handleBB,2,DateFrom,DateTo,bbd)<0)
      Alert("Erro ao copiar dados de Bolinger Inferior: ", GetLastError());
   else
      Print("Copiando dados para array do Bolinger Inferior... aguarde");
//ArraySetAsSeries(bbu,true);
//ArraySetAsSeries(bbd,true);

///Formacao do indicador SAR
   int      handle_sar = iSAR(ativo,timeframe,stepsar,maximumsar);
   double   sar[];
   CopyBuffer(handle_sar,0,DateFrom,DateTo,sar);
   if(CopyBuffer(handle_sar,0,DateFrom,DateTo,sar)<0)
      Alert("Erro ao copiar dados de SAR: ", GetLastError());
   else
      Print("Copiando dados para array do SAR... aguarde");
//ArraySetAsSeries(sar,true);

//////////////////////////////////////////////////////////////////
//Criacao do arquivo parte 1
// string FileName_part1=ativo+" "+IntegerToString(PeriodSeconds()/60)+"part1"+".csv";
//int part1=FileOpen(FileName_part1,FILE_WRITE|FILE_ANSI|FILE_CSV,";");
//Tratamento de erro
//if(part1==INVALID_HANDLE)
// {
//  Alert("Error opening file");
//  return;
// }

//Criacao do arquivo parte 2
   string FileName_part2=ativo+".csv";
   int part2=FileOpen(FileName_part2,FILE_WRITE|FILE_ANSI|FILE_CSV,";");
//Tratamento de erro
   if(part2==INVALID_HANDLE)
     {
      Alert("Error opening file");
      return;
     }

   string time_    = "time;";
   string open1_   = "open1;";
   string max1_    = "max1;";
   string min1_    = "min1;";
   string close1_  = "close1;";
   string volume1_ = "volume1;";
   string rsi1_    = "rsi1;";
   string bolu1_   = "bolingerU1;";
   string bold1_   = "bolingerD1;";
   string sar1_    = "sar1;";
   string open2_   = "open2;";
   string max2_    = "max2;";
   string min2_    = "min2;";
   string close2_  = "close2;";
   string volume2_ = "volume2;";
   string rsi2_    = "rsi2;";
   string bolu2_   = "bolingerU2;";
   string bold2_   = "bolingerD2;";
   string sar2_    = "sar2;";
   string open3_   = "open3;";
   string max3_    = "max3;";
   string min3_    = "min3;";
   string close3_  = "close3;";
   string volume3_ = "volume3;";
   string rsi3_    = "rsi3;";
   string bolu3_   = "bolingerU3;";
   string bold3_   = "bolingerD3;";
   string sar3_    = "sar3;";
   string open4_   = "open4;";
   string max4_    = "max4;";
   string min4_    = "min4;";
   string close4_  = "close4;";
   string volume4_ = "volume4;";
   string rsi4_    = "rsi4;";
   string bolu4_   = "bolingerU4;";
   string bold4_   = "bolingerD4;";
   string sar4_    = "sar4;";
   string open1h4_ = "open1h4;";
   string max1h4_  = "max1h4;";
   string min1h4_  = "min1h4;";
   string close1h4_= "close1h4;";
   string open1d1_ = "open1d1;";
   string max1d1_  = "max1d1;";
   string min1d1_  = "min1d1;";
   string close1d1_= "close1d1;";
   string head   = time_    + open1_  + max1_   + min1_     + close1_  + volume1_ + rsi1_   + bolu1_  + bold1_ + sar1_ +//
                   open2_   + max2_   + min2_   + close2_   + volume2_ + rsi2_    + bolu2_  + bold2_  + sar2_ +//
                   open3_   + max3_   + min3_   + close3_   + volume3_ + rsi3_    + bolu3_  + bold3_  + sar3_ +//
                   open4_   + max4_   + min4_   + close4_   + volume4_ + rsi4_    + bolu4_  + bold4_  + sar4_ +//
                   open1h4_ + max1h4_ + min1h4_ + close1h4_ + open1d1_ + max1d1_  + min1d1_ + close1d1_ ;

   FileWrite(part2,head);

   string body = "";
   int size = ArraySize(rates);
   int i = 0;
   int j = 0;
   int k = 0;
   for(i=0; i<size; i++)
     {
      time_  = rates[i].time+";";
      open1_   = "";
      max1_    = "";
      min1_    = "";
      close1_  = "";
      volume1_ = "";
      rsi1_    = "";
      bolu1_   = "";
      bold1_   = "";
      sar1_    = "";
      open2_   = "";
      max2_    = "";
      min2_    = "";
      close2_  = "";
      volume2_ = "";
      rsi2_    = "";
      bolu2_   = "";
      bold2_   = "";
      sar2_    = "";
      open3_   = "";
      max3_    = "";
      min3_    = "";
      close3_  = "";
      volume3_ = "";
      rsi3_    = "";
      bolu3_   = "";
      bold3_   = "";
      sar3_    = "";
      open4_   = "";
      max4_    = "";
      min4_    = "";
      close4_  = "";
      volume4_ = "";
      rsi4_    = "";
      bolu4_   = "";
      bold4_   = "";
      sar4_    = "";
      open1h4_ = "";
      max1h4_  = "";
      min1h4_  = "";
      close1h4_= "";
      open1d1_ = "";
      max1d1_  = "";
      min1d1_  = "";
      close1d1_= "";

      for(int l = 0; l < 1; l++)
        {
         open1_    = open1_      + DoubleToString(NormalizeDouble(rates[i].open,5),5)     +";";
         max1_     = max1_       + DoubleToString(NormalizeDouble(rates[i].high,5),5)     +";";
         min1_     = min1_       + DoubleToString(NormalizeDouble(rates[i].low,5),5)      +";";
         close1_   = close1_     + DoubleToString(NormalizeDouble(rates[i].close,5),5)    +";";
         volume1_  = volume1_    + rates[i].tick_volume                                   +";";
         rsi1_     = rsi1_       + DoubleToString(NormalizeDouble(rsi[i],2),2)            +";";
         bolu1_    = bolu1_      + DoubleToString(NormalizeDouble(bbu[i],5),5)            +";";
         bold1_    = bold1_      + DoubleToString(NormalizeDouble(bbd[i],5),5)            +";";
         sar1_     = sar1_       + DoubleToString(NormalizeDouble(sar[i],5),5)            +";";
         open2_    = open2_      + DoubleToString(NormalizeDouble(rates[i+1].open,5),5)   +";";
         max2_     = max2_       + DoubleToString(NormalizeDouble(rates[i+1].high,5),5)   +";";
         min2_     = min2_       + DoubleToString(NormalizeDouble(rates[i+1].low,5),5)    +";";
         close2_   = close2_     + DoubleToString(NormalizeDouble(rates[i+1].close,5),5)  +";";
         volume2_  = volume2_    + rates[i+1].tick_volume                                 +";";
         rsi2_     = rsi2_       + DoubleToString(NormalizeDouble(rsi[i+1],2),2)          +";";
         bolu2_    = bolu2_      + DoubleToString(NormalizeDouble(bbu[i+1],5),5)          +";";
         bold2_    = bold2_      + DoubleToString(NormalizeDouble(bbd[i+1],5),5)          +";";
         sar2_     = sar2_       + DoubleToString(NormalizeDouble(sar[i+1],5),5)          +";";
         open3_    = open3_      + DoubleToString(NormalizeDouble(rates[i+2].open,5),5)   +";";
         max3_     = max3_       + DoubleToString(NormalizeDouble(rates[i+2].high,5),5)   +";";
         min3_     = min3_       + DoubleToString(NormalizeDouble(rates[i+2].low,5),5)    +";";
         close3_   = close3_     + DoubleToString(NormalizeDouble(rates[i+2].close,5),5)  +";";
         volume3_  = volume3_    + rates[i+2].tick_volume                                 +";";
         rsi3_     = rsi3_       + DoubleToString(NormalizeDouble(rsi[i+2],2),2)          +";";
         bolu3_    = bolu3_      + DoubleToString(NormalizeDouble(bbu[i+2],5),5)          +";";
         bold3_    = bold3_      + DoubleToString(NormalizeDouble(bbd[i+2],5),5)          +";";
         sar3_     = sar3_       + DoubleToString(NormalizeDouble(sar[i+2],5),5)          +";";
         open4_    = open4_      + DoubleToString(NormalizeDouble(rates[i+3].open,5),5)   +";";
         max4_     = max4_       + DoubleToString(NormalizeDouble(rates[i+3].high,5),5)   +";";
         min4_     = min4_       + DoubleToString(NormalizeDouble(rates[i+3].low,5),5)    +";";
         close4_   = close4_     + DoubleToString(NormalizeDouble(rates[i+3].close,5),5)  +";";
         volume4_  = volume4_    + rates[i+3].tick_volume                                 +";";
         rsi4_     = rsi4_       + DoubleToString(NormalizeDouble(rsi[i+3],2),2)          +";";
         bolu4_    = bolu4_      + DoubleToString(NormalizeDouble(bbu[i+3],5),5)          +";";
         bold4_    = bold4_      + DoubleToString(NormalizeDouble(bbd[i+3],5),5)          +";";
         sar4_     = sar4_       + DoubleToString(NormalizeDouble(sar[i+3],5),5)          +";";
         if(i>=15)
           {
            double maximoh4=0;
            double minimoh4=10000000;
            for(int m=i-15; m<i; m++)
              {
               if(rates[m].high>maximoh4)
                  maximoh4=rates[m].high;
               if(rates[m].low<minimoh4)
                  minimoh4=rates[m].low;
              }
            open1h4_  = open1h4_    + DoubleToString(NormalizeDouble(rates[i-15].open,5),5)    +";";
            max1h4_   = max1h4_     + DoubleToString(NormalizeDouble(maximoh4,5),5)            +";";
            min1h4_   = min1h4_     + DoubleToString(NormalizeDouble(minimoh4,5),5)            +";";
            close1h4_ = close1h4_   + DoubleToString(NormalizeDouble(rates[i].close,5),5)      +";";
           }
         if(i>=95)
           {
            double maximod1=0;
            double minimod1=10000000;
            for(int m=i-95; m<i; m++)
              {
               if(rates[m].high>maximod1)
                  maximod1=rates[m].high;
               if(rates[m].low<minimod1)
                  minimod1=rates[m].low;
              }
            open1d1_  = open1d1_    + DoubleToString(NormalizeDouble(rates[i-95].open,5),5)    +";";
            max1d1_   = max1d1_     + DoubleToString(NormalizeDouble(maximod1,5),5)            +";";
            min1d1_   = min1d1_     + DoubleToString(NormalizeDouble(minimod1,5),5)            +";";
            close1d1_ = close1d1_   + DoubleToString(NormalizeDouble(rates[i].close,5),5)        ;
           }
        }
      body = time_ + open1_ + max1_ + min1_ + close1_ + volume1_ + rsi1_ + bolu1_ + bold1_ + sar1_ +//
             open2_ + max2_ + min2_ + close2_ + volume2_ + rsi2_ + bolu2_ + bold2_ + sar2_ +//
             open3_ + max3_ + min3_ + close3_ + volume3_ + rsi3_ + bolu3_ + bold3_ + sar3_ +//
             open4_ + max4_ + min4_ + close4_ + volume4_ + rsi4_ + bolu4_ + bold4_ + sar4_ +//
             open1h4_+max1h4_+min1h4_+close1h4_+open1d1_+max1d1_ + min1d1_ + close1d1_ ;

      FileWrite(part2,body);

     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   FileClose(part2);
   Alert("Save complete, see the file "+FileName_part2);

  }
//+------------------------------------------------------------------+
