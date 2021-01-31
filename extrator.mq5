//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

input bool                 UseDateFrom           = true;       // SET THE START DATE
input datetime             DateFrom              = "";         // DATA/HORA INICIAL
input bool                 UseDateTo             = true;       // SET THE END DATE
input datetime             DateTo                = "";         // DATA/HORA FINAL
input string               ativo                 = "EURUSD";   // ATIVO
input ENUM_TIMEFRAMES      timeframe             = PERIOD_H1;  // TIMEFRAME
input group                "PARÂMETROS DOS INDICADORES"
input int                  periodomedia1         = 5;          // PERIODO MÉDIA 1
input int                  periodomedia2         = 9;          // PERIODO MÉDIA 2
input int                  periodomedia3         = 14;         // PERIODO MÉDIA 3
input int                  periodomedia4         = 21;         // PERIODO MÉDIA 4
input int                  periodomedia5         = 50;         // PERIODO MÉDIA 5
input int                  periodomedia6         = 100;        // PERIODO MÉDIA 6
input int                  periodorsi            = 10;         // PERÍODO RSI
input double               stepsar               = 0.2;        // STEP SAR
input double               maximumsar            = 0.02;       // MAXIMUM SAR
input int                  MAFastMACD            = 12;         // PER. MÉDIA RÁPIDA MACD
input int                  MASlowMACD            = 26;         // PER. MÉDIA LENTA MACD
input int                  SignalMACD            = 9;          // PERÍODO SINAL MACD
input int                  periodomomentum       = 12;         // PERÍODO MOMENTUM

int periodo_tempo = 1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {

//Formacao de preços
   MqlRates rates[];
   if(CopyRates(ativo,timeframe,DateFrom,DateTo,rates) == -1)
      Alert("Numero de dados copiados  = "+ArraySize(rates));
   else
      Print("Copiando dados... ativo");

///Formacao do indicador Media aritimetica de 5 periodos
   int handle_ma1 = iMA(ativo,timeframe, periodomedia1, 0, MODE_SMA, PRICE_CLOSE);
   double ma1[];
   CopyBuffer(handle_ma1,0,DateFrom,DateTo,ma1);
   if(CopyBuffer(handle_ma1,0,DateFrom,DateTo,ma1)<0)
     {
      Alert("Erro ao copiar dados de Média 1: ", GetLastError());
      return;
     }

///Formacao do indicador Media aritimetica de 9 periodos
   int handle_ma2 = iMA(ativo,timeframe, periodomedia2, 0, MODE_SMA, PRICE_CLOSE);
   double ma2[];
   CopyBuffer(handle_ma2,0,DateFrom,DateTo,ma2);
   if(CopyBuffer(handle_ma2,0,DateFrom,DateTo,ma2)<0)
     {
      Alert("Erro ao copiar dados de Média 2: ", GetLastError());
      return;
     }

///Formacao do indicador Media aritimetica de 14 periodos
   int handle_ma3 = iMA(ativo,timeframe, periodomedia3, 0, MODE_SMA, PRICE_CLOSE);
   double ma3[];
   CopyBuffer(handle_ma3,0,DateFrom,DateTo,ma3);
   if(CopyBuffer(handle_ma3,0,DateFrom,DateTo,ma3)<0)
     {
      Alert("Erro ao copiar dados de Média 3: ", GetLastError());
      return;
     }

///Formacao do indicador Media aritimetica de 21 periodos
   int handle_ma4 = iMA(ativo,timeframe, periodomedia4, 0, MODE_SMA, PRICE_CLOSE);
   double ma4[];
   CopyBuffer(handle_ma4,0,DateFrom,DateTo,ma4);
   if(CopyBuffer(handle_ma4,0,DateFrom,DateTo,ma4)<0)
     {
      Alert("Erro ao copiar dados de Média 4: ", GetLastError());
      return;
     }

///Formacao do indicador Media aritimetica de 50 periodos
   int handle_ma5 = iMA(ativo,timeframe, periodomedia5, 0, MODE_SMA, PRICE_CLOSE);
   double ma5[];
   CopyBuffer(handle_ma5,0,DateFrom,DateTo,ma5);
   if(CopyBuffer(handle_ma5,0,DateFrom,DateTo,ma5)<0)
     {
      Alert("Erro ao copiar dados de Média 5: ", GetLastError());
      return;
     }

///Formacao do indicador Media aritimetica de 100 periodos
   int handle_ma6 = iMA(ativo,timeframe, periodomedia6, 0, MODE_SMA, PRICE_CLOSE);
   double ma6[];
   CopyBuffer(handle_ma6,0,DateFrom,DateTo,ma6);
   if(CopyBuffer(handle_ma6,0,DateFrom,DateTo,ma6)<0)
     {
      Alert("Erro ao copiar dados de Média 6: ", GetLastError());
      return;
     }
     
///Formacao do indicador de índice de força relativa
   int handle_rsi = iRSI(ativo, timeframe,periodorsi,PRICE_CLOSE);
   double rsi[];
   CopyBuffer(handle_rsi,0,DateFrom,DateTo,rsi);
   if(CopyBuffer(handle_rsi,0,DateFrom,DateTo,rsi)<0)
     {
      Alert("Erro ao copiar dados de RSI: ", GetLastError());
      return;
     }

///Formacao do indicador Parabolic SAR

   int handle_sar = iSAR(ativo,timeframe,stepsar,maximumsar);
   double sar[];
   CopyBuffer(handle_sar,0,DateFrom,DateTo,sar);
   if(CopyBuffer(handle_sar,0,DateFrom,DateTo,sar)<0)
     {
      Alert("Erro ao copiar dados de SAR: ", GetLastError());
      return;
     }

///Formacao do indicador MACD
   int handle_macd = iMACD(ativo, timeframe, MAFastMACD, MASlowMACD, SignalMACD, PRICE_CLOSE);
   double macd[];
   double macds[];
   CopyBuffer(handle_macd,0,DateFrom,DateTo,macd);
   CopyBuffer(handle_macd,1,DateFrom,DateTo,macds);
   if(CopyBuffer(handle_macd,0,DateFrom,DateTo,macd)<0)
     {
      Alert("Erro ao copiar dados de MACD: ", GetLastError());
      return;
     }
   if(CopyBuffer(handle_macd,1,DateFrom,DateTo,macds)<0)
     {
      Alert("Erro ao copiar dados de SIGNAL do MACD: ", GetLastError());
      return;
     }

///Formacao do indicador de momentum
   int handle_mom = iMomentum(ativo, timeframe, periodomomentum, PRICE_CLOSE);
   double mom[];
   CopyBuffer(handle_mom,0,DateFrom,DateTo,mom);
   if(CopyBuffer(handle_mom,0,DateFrom,DateTo,mom)<0)
     {
      Alert("Erro ao copiar dados de MOMENTUM: ", GetLastError());
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
   string open_  = "open;";
   string high_  = "high;";
   string low_   = "low;";
   string close_ = "close;";
   string volume_= "volume;";
   string ticks_ = "ticks;";
   string sar_   = "sar;";
   string ma1_   = "ma"+periodomedia1+";";
   string ma2_   = "ma"+periodomedia2+";";
   string ma3_   = "ma"+periodomedia3+";";
   string ma4_   = "ma"+periodomedia4+";";
   string ma5_   = "ma"+periodomedia5+";";
   string ma6_   = "ma"+periodomedia6+";";
   string macd_  = "macd;";
   string macds_ = "macds;";
   string mom_   = "mom;";
   string rsi_   = "rsi";
   string head   = time_ + open_ + high_ + low_ + close_ + volume_ + ticks_ + sar_ + ma1_ + ma2_ + ma3_ + ma4_ + ma5_ + ma6_ + macd_ + macds_ + mom_ + rsi_;
 
   FileWrite(part2, head);

   string body = "";

   for(int i=0; i<ArraySize(rates) - periodo_tempo; i++)
     {
      time_  = rates[i].time+";";
      open_  = "";
      high_  = "";
      low_   = "";
      close_ = "";
      volume_= "";
      ticks_ = "";
      sar_   = "";
      ma1_   = "";
      ma2_   = "";
      ma3_   = "";
      ma4_   = "";
      ma5_   = "";
      ma6_   = "";
      macd_  = "";
      macds_ = "";
      mom_   = "";
      rsi_   = "";
      
      for(int j = 0; j < periodo_tempo; j++)
        {
         open_    = open_    + DoubleToString(NormalizeDouble(rates[j+i].open,5),5)+";";
         high_    = high_    + DoubleToString(NormalizeDouble(rates[j+i].high,5),5)+";";
         low_     = low_     + DoubleToString(NormalizeDouble(rates[j+i].low,5),5)+";";
         close_   = close_   + DoubleToString(NormalizeDouble(rates[j+i].close,5),5)+";";
         volume_  = volume_  + rates[j+i].real_volume+";";
         ticks_   = ticks_   + rates[j+i].tick_volume+";";
         sar_     = sar_     + DoubleToString(NormalizeDouble(sar[j+i],6),6)+";";
         ma1_     = ma1_     + DoubleToString(NormalizeDouble(ma1[j+i],6),6)+";";
         ma2_     = ma2_     + DoubleToString(NormalizeDouble(ma2[j+i],6),6)+";";
         ma3_     = ma3_     + DoubleToString(NormalizeDouble(ma3[j+i],6),6)+";";
         ma4_     = ma4_     + DoubleToString(NormalizeDouble(ma4[j+i],6),6)  + ";";
         ma5_     = ma5_     + DoubleToString(NormalizeDouble(ma5[j+i],6),6)   + ";";
         ma6_     = ma6_     + DoubleToString(NormalizeDouble(ma6[j+i],6),6)   + ";";
         macd_    = macd_    + DoubleToString(NormalizeDouble(macd[j+i],6),6)    + ";";
         macds_   = macds_   + DoubleToString(NormalizeDouble(macds[j+i],6),6)   + ";";
         mom_     = mom_     + DoubleToString(NormalizeDouble(mom[j+i],2),2)     + ";";
         rsi_     = rsi_     + DoubleToString(NormalizeDouble(rsi[j+i],2),2)     + "";
        }
      body = time_ + open_ + low_ + high_ + close_ + volume_ + ticks_ + sar_ + ma1_ + ma2_ + ma3_ + ma4_ + ma5_ + ma6_ + macd_ + macds_ + mom_ + rsi_;

      FileWrite(part2,body);

     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   FileClose(part2);
   Alert("Save complete, see the file "+FileName_part2);

  }
