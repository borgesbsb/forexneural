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
input ENUM_TIMEFRAMES      timeframe             = PERIOD_H1;  // TIMEFRAME P/ VALORES OHLCV
input ENUM_TIMEFRAMES      timeframe2            = PERIOD_H1;  // TIMEFRAME BASE P/ MÉDIAS(IGUAL AO OHLCV)
input group                "PARÂMETROS DOS INDICADORES"
input int                  periodorsi            = 10;         // PERÍODO RSI
input int                  periodobb             = 20;         // PERIODO BOLINGER
input double               desviobb              = 2.0;        // DESVIO BOLINGER
input int                  periodoenv            = 20;         // PERIODO ENVELOPE
input int                  pontosenv             = 200;        // PONTOS ENVELOPE

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

//Formacao de médias a partir do timeframe base
   int   periodo = 0;
   switch(timeframe2)
     {
      case  PERIOD_M1:
         periodo = 1440;
         break;
      case  PERIOD_M5:
         periodo = 288;
         break;
      case  PERIOD_M15:
         periodo = 96;
         break;
      case  PERIOD_M30:
         periodo = 48;
         break;
      case  PERIOD_H1:
         periodo = 24;
         break;
      case  PERIOD_H4:
         periodo = 6;
         break;
      default:
         break;
     }
   int      handleMM = iMA(ativo,timeframe2,periodo,0,MODE_SMA,PRICE_CLOSE);
   double   mm[],mm3[],mm5[],mm7[],mm10[],mm15[],mm30[];
   CopyBuffer(handleMM,0,DateFrom,DateTo,mm);
   if(CopyBuffer(handleMM,0,DateFrom,DateTo,mm)<0)
      Alert("Erro ao baixar dados das Médias");
   else
      Print("Copiando dados para array das medias... aguarde");
   for(int i=0; i<ArraySize(mm); i++)
     {
      if(i==2)
         mm3[0] = (mm[0]+mm[1]+mm[2])/3;
      if(i==4)
         mm5[0] = (mm[0]+mm[1]+mm[2]+mm[3]+mm[4])/5;
      if(i==6)
         mm7[0] = (mm[0]+mm[1]+mm[2]+mm[3]+mm[4]+mm[5]+mm[6])/7;
      if(i==9)
         mm10[0] = (mm[0]+mm[1]+mm[2]+mm[3]+mm[4]+mm[5]+mm[6]+mm[7]+mm[8]+mm[9])/10;
      if(i==14)
         mm15[0] = (mm[0]+mm[1]+mm[2]+mm[3]+mm[4]+mm[5]+mm[6]+mm[7]+mm[8]+mm[9]+mm[10]+ //
                    mm[11]+mm[12]+mm[13]+mm[14])/15;
      if(i==29)
         mm30[0] = (mm[0]+mm[1]+mm[2]+mm[3]+mm[4]+mm[5]+mm[6]+mm[7]+mm[8]+mm[9]+mm[10]+ //
                    mm[11]+mm[12]+mm[13]+mm[14]+mm[15]+mm[16]+mm[17]+mm[18]+mm[19]+mm[20]+ //
                    mm[21]+mm[22]+mm[23]+mm[24]+mm[25]+mm[26]+mm[27]+mm[28]+mm[29])/30;

      if((i+1) % 3 == 0 && (i+1) % 5 > 0 && (i+1) % 7 > 0 && (i+1) % 10 > 0 && (i+1) % 15 > 0 && (i+1) % 30 > 0)
         mm3[((ArraySize(mm))/(i+1))-1] = (mm[ArraySize(mm)-(i+1)-1] + mm[ArraySize(mm)-(i+1)-2] + //
                                           mm[ArraySize(mm)-(i+1)-3])/3;

      if((i+1) % 3 > 0 && (i+1) % 5 == 0 && (i+1) % 7 > 0 && (i+1) % 10 > 0 && (i+1) % 15 > 0 && (i+1) % 30 > 0)
         mm5[((ArraySize(mm))/(i+1))-1] = (mm[ArraySize(mm)-(i+1)-1] + mm[ArraySize(mm)-(i+1)-2] + //
                                           mm[ArraySize(mm)-(i+1)-3] + mm[ArraySize(mm)-(i+1)-4] + //
                                           mm[ArraySize(mm)-(i+1)-5])/5;

      if((i+1) % 3 > 0 && (i+1) % 5 > 0 && (i+1) % 7 == 0 && (i+1) % 10 > 0 && (i+1) % 15 > 0 && (i+1) % 30 > 0)
         mm7[((ArraySize(mm))/(i+1))-1] = (mm[ArraySize(mm)-(i+1)-1] + mm[ArraySize(mm)-(i+1)-2] + //
                                           mm[ArraySize(mm)-(i+1)-3] + mm[ArraySize(mm)-(i+1)-4] + //
                                           mm[ArraySize(mm)-(i+1)-5] + mm[ArraySize(mm)-(i+1)-6] + //
                                           mm[ArraySize(mm)-(i+1)-7])/7;

      if((i+1) % 3 > 0 && (i+1) % 5 > 0 && (i+1) % 7 > 0 && (i+1) % 10 == 0 && (i+1) % 15 > 0 && (i+1) % 30 > 0)
         mm10[((ArraySize(mm))/(i+1))-1] = (mm[ArraySize(mm)-(i+1)-1] + mm[ArraySize(mm)-(i+1)-2] + //
                                            mm[ArraySize(mm)-(i+1)-3] + mm[ArraySize(mm)-(i+1)-4] + //
                                            mm[ArraySize(mm)-(i+1)-5] + mm[ArraySize(mm)-(i+1)-6] + //
                                            mm[ArraySize(mm)-(i+1)-7] + mm[ArraySize(mm)-(i+1)-8] + //
                                            mm[ArraySize(mm)-(i+1)-9] + mm[ArraySize(mm)-(i+1)-10])/10;

      if((i+1) % 3 > 0 && (i+1) % 5 > 0 && (i+1) % 7 > 0 && (i+1) % 10 > 0 && (i+1) % 15 == 0 && (i+1) % 30 > 0)
         mm15[((ArraySize(mm))/(i+1))-1] = (mm[ArraySize(mm)-(i+1)-1] + mm[ArraySize(mm)-(i+1)-2] + //
                                            mm[ArraySize(mm)-(i+1)-3] + mm[ArraySize(mm)-(i+1)-4] + //
                                            mm[ArraySize(mm)-(i+1)-5] + mm[ArraySize(mm)-(i+1)-6] + //
                                            mm[ArraySize(mm)-(i+1)-7] + mm[ArraySize(mm)-(i+1)-8] + //
                                            mm[ArraySize(mm)-(i+1)-9] + mm[ArraySize(mm)-(i+1)-10] + //
                                            mm[ArraySize(mm)-(i+1)-11] + mm[ArraySize(mm)-(i+1)-12] + //
                                            mm[ArraySize(mm)-(i+1)-13] + mm[ArraySize(mm)-(i+1)-14] + //
                                            mm[ArraySize(mm)-(i+1)-15])/15;

      if((i+1) % 3 > 0 && (i+1) % 5 > 0 && (i+1) % 7 > 0 && (i+1) % 10 > 0 && (i+1) % 15 > 0 && (i+1) % 30 == 0)
         mm30[((ArraySize(mm))/(i+1))-1] = (mm[ArraySize(mm)-(i+1)-1] + mm[ArraySize(mm)-(i+1)-2] + //
                                            mm[ArraySize(mm)-(i+1)-3] + mm[ArraySize(mm)-(i+1)-4] + //
                                            mm[ArraySize(mm)-(i+1)-5] + mm[ArraySize(mm)-(i+1)-6] + //
                                            mm[ArraySize(mm)-(i+1)-7] + mm[ArraySize(mm)-(i+1)-8] + //
                                            mm[ArraySize(mm)-(i+1)-9] + mm[ArraySize(mm)-(i+1)-10] + //
                                            mm[ArraySize(mm)-(i+1)-11] + mm[ArraySize(mm)-(i+1)-12] + //
                                            mm[ArraySize(mm)-(i+1)-13] + mm[ArraySize(mm)-(i+1)-14] + //
                                            mm[ArraySize(mm)-(i+1)-15] + mm[ArraySize(mm)-(i+1)-16] + //
                                            mm[ArraySize(mm)-(i+1)-17] + mm[ArraySize(mm)-(i+1)-18] + //
                                            mm[ArraySize(mm)-(i+1)-19] + mm[ArraySize(mm)-(i+1)-20] + //
                                            mm[ArraySize(mm)-(i+1)-21] + mm[ArraySize(mm)-(i+1)-22] + //
                                            mm[ArraySize(mm)-(i+1)-23] + mm[ArraySize(mm)-(i+1)-24] + //
                                            mm[ArraySize(mm)-(i+1)-25] + mm[ArraySize(mm)-(i+1)-26] + //
                                            mm[ArraySize(mm)-(i+1)-27] + mm[ArraySize(mm)-(i+1)-28] + //
                                            mm[ArraySize(mm)-(i+1)-29] + mm[ArraySize(mm)-(i+1)-30])/30;
     }

///Formacao do indicador RSI
   int      handle_rsi = iRSI(ativo, timeframe,periodorsi,PRICE_CLOSE);
   double   rsi[];
   CopyBuffer(handle_rsi,0,DateFrom,DateTo,rsi);
   if(CopyBuffer(handle_rsi,0,DateFrom,DateTo,rsi)<0)
      Alert("Erro ao copiar dados de RSI: ", GetLastError());
   else
      Print("Copiando dados para array do RSI... aguarde");

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
///Formacao do indicador ENVELOPE
   int      handleENV   =  iMA(ativo,timeframe,periodoenv,0,MODE_SMA,PRICE_CLOSE);
   double   mediaENV[],ENVU[],ENVD[];
   CopyBuffer(handleENV,0,DateFrom,DateTo,mediaENV);
   if(CopyBuffer(handleMM,0,DateFrom,DateTo,mediaENV)<0)
      Alert("Erro ao baixar dados do Envelope");
   else
      Print("Copiando dados para array do Envelope... aguarde");
   for(int i=0; i<ArraySize(mediaENV); i++)
     {
      ENVU[i]=mediaENV[i]+pontosenv*_Point;
      ENVD[i]=mediaENV[i]-pontosenv*_Point;
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
         open1_   = open1_    + DoubleToString(NormalizeDouble(rates2[4*i].open,5),5)+";";
         max1_    = max1_     + DoubleToString(NormalizeDouble(rates2[4*i].high,5),5)+";";
         min1_    = min1_     + DoubleToString(NormalizeDouble(rates2[4*i].low,5),5)+";";
         open2_   = open2_    + DoubleToString(NormalizeDouble(rates2[4*i+1].open,5),5)+";";
         max2_    = max2_     + DoubleToString(NormalizeDouble(rates2[4*i+1].high,5),5)+";";
         min2_    = min2_     + DoubleToString(NormalizeDouble(rates2[4*i+1].low,5),5)+";";
         open3_   = open3_    + DoubleToString(NormalizeDouble(rates2[4*i+2].open,5),5)+";";
         max3_    = max3_     + DoubleToString(NormalizeDouble(rates2[4*i+2].high,5),5)+";";
         min3_    = min3_     + DoubleToString(NormalizeDouble(rates2[4*i+2].low,5),5)+";";
         open4_   = open4_    + DoubleToString(NormalizeDouble(rates2[4*i+3].open,5),5)+";";
         max4_    = max4_     + DoubleToString(NormalizeDouble(rates2[4*i+3].high,5),5)+";";
         min4_    = min4_     + DoubleToString(NormalizeDouble(rates2[4*i+3].low,5),5)+";";
         close4_  = close4_   + DoubleToString(NormalizeDouble(rates2[4*i+3].close,5),5)+";";
         ticks_   = ticks_    + rates[i].tick_volume+";";
         rsi_     = rsi_      + DoubleToString(NormalizeDouble(rsi[i],2),2) + "";
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
