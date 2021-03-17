//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Robô Neural INC."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

input bool                 UseDateFrom           = true;       // SET THE START DATE
input datetime             DateFrom              = "";         // DATA/HORA INICIAL
input bool                 UseDateTo             = true;       // SET THE END DATE
input datetime             DateTo                = "";         // DATA/HORA FINAL
input string               ativo                 = "EURUSD";   // ATIVO
input ENUM_TIMEFRAMES      timeframe             = PERIOD_H1;  // TIMEFRAME PRINCIPAL
input ENUM_TIMEFRAMES      timeframe2            = PERIOD_M15; // TIMEFRAME SECUNDÁRIO
input group                "PARÂMETROS DOS INDICADORES"
input int                  periodorsi            = 10;         // PERÍODO RSI

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {

//Formacao de preços timeframe principal
   MqlRates rates[];
   if(CopyRates(ativo,timeframe,DateFrom,DateTo,rates) == -1)
      Alert("Numero de dados copiados do timeframe principal = "+ArraySize(rates));
   else
      Print("Copiando dados... ativo");

//Formacao de preços timeframe secundário
   MqlRates rates2[];
   if(CopyRates(ativo,timeframe2,DateFrom,DateTo,rates2) == -1)
      Alert("Numero de dados copiados do timeframe secundário = "+ArraySize(rates2));
   else
      Print("Copiando dados... ativo");

///Formacao do indicador de índice de força relativa
   int handle_rsi = iRSI(ativo, timeframe,periodorsi,PRICE_CLOSE);
   double rsi[];
   CopyBuffer(handle_rsi,0,DateFrom,DateTo,rsi);
   if(CopyBuffer(handle_rsi,0,DateFrom,DateTo,rsi)<0)
     {
      Alert("Erro ao copiar dados de RSI: ", GetLastError());
      return;
     }

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

   string time_  = "time;";
   string open1_  = "open1;";
   string max1_   = "max1;";
   string min1_   = "min1;";
   string open2_  = "open2;";
   string max2_   = "max2;";
   string min2_   = "min2;";
   string open3_  = "open3;";
   string max3_   = "max3;";
   string min3_   = "min3;";
   string open4_  = "open4;";
   string max4_   = "max4;";
   string min4_   = "min4;";
   string close4_ = "close4;";
   string ticks_ = "ticks;";
   string rsi_   = "rsi";
   string head   = time_ + open1_ + max1_ + min1_ + open2_ + max2_ + min2_ + open3_  + max3_ + min3_ + open4_ + max4_ + min4_ + close4_ + ticks_ + rsi_;

   FileWrite(part2, head);

   string body = "";

   for(int i=0; i<ArraySize(rates) - 1; i++)
     {
      time_  = rates[i].time+";";
      open1_  = "";
      max1_   = "";
      min1_   = "";
      open2_  = "";
      max2_   = "";
      min2_   = "";
      open3_  = "";
      max3_   = "";
      min3_   = "";
      open4_  = "";
      max4_   = "";
      min4_   = "";
      close4_ = "";
      ticks_  = "";
      rsi_    = "";

      for(int j = 0; j < 1; j++)
        {
         open1_   = open1_    + DoubleToString(NormalizeDouble(rates2[j+i].open,5),5)+";";
         max1_    = max1_     + DoubleToString(NormalizeDouble(rates2[j+i].high,5),5)+";";
         min1_    = min1_     + DoubleToString(NormalizeDouble(rates2[j+i].low,5),5)+";";
         open2_   = open2_    + DoubleToString(NormalizeDouble(rates2[j+i+1].open,5),5)+";";
         max2_    = max2_     + DoubleToString(NormalizeDouble(rates2[j+i+1].high,5),5)+";";
         min2_    = min2_     + DoubleToString(NormalizeDouble(rates2[j+i+1].low,5),5)+";";
         open3_   = open3_    + DoubleToString(NormalizeDouble(rates2[j+i+2].open,5),5)+";";
         max3_    = max3_     + DoubleToString(NormalizeDouble(rates2[j+i+2].high,5),5)+";";
         min3_    = min3_     + DoubleToString(NormalizeDouble(rates2[j+i+2].low,5),5)+";";
         open4_   = open4_    + DoubleToString(NormalizeDouble(rates2[j+i+3].open,5),5)+";";
         max4_    = max4_     + DoubleToString(NormalizeDouble(rates2[j+i+3].high,5),5)+";";
         min4_    = min4_     + DoubleToString(NormalizeDouble(rates2[j+i+3].low,5),5)+";";
         close4_  = close4_   + DoubleToString(NormalizeDouble(rates2[j+i+3].close,5),5)+";";
         ticks_   = ticks_    + rates[j+i].tick_volume+";";
         rsi_     = rsi_      + DoubleToString(NormalizeDouble(rsi[j+i],2),2) + "";
        }
      body = time_ + open1_ + max1_ + min1_ + open2_ + max2_ + min2_ + open3_ + max3_ + min3_ + open4_ + max4_ + min4_ + close4_ + ticks_ + rsi_ ;

      FileWrite(part2,body);

     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   FileClose(part2);
   Alert("Save complete, see the file "+FileName_part2);

  }
//+------------------------------------------------------------------+
