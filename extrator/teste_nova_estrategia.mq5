//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Robô Neural INC."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

input string               ativo                 = "EURUSD";   // ATIVO
input ENUM_TIMEFRAMES      timeframe             = PERIOD_M15; // TIMEFRAME P/ VALORES OHLCV

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {

   MqlTick                  tick,ticks[];

   if(!SymbolInfoTick(ativo,tick))
     {
      Alert("Erro ao obter informações de Mqlticks: ", GetLastError());
      return;
     }
   ArraySetAsSeries(ticks,true);

   /*MqlDateTime today;
   datetime current_time=TimeCurrent();
   TimeToStruct(current_time,today);
   today.hour=0;
   today.min=0;
   today.sec=0;
   datetime startday=StructToTime(today);
   datetime endday=startday+15*60;*/
   CopyTicks(ativo,ticks,COPY_TICKS_ALL/*,startday*1000,endday*1000*/);
   //ArraySetAsSeries(ticks,true);

//Criacao do arquivo parte 2
   string FileName_part2=ativo+".csv";
   int part2=FileOpen(FileName_part2,FILE_WRITE|FILE_ANSI|FILE_CSV,";");
//Tratamento de erro
   if(part2==INVALID_HANDLE)
     {
      Alert("Error opening file");
      return;
     }

   double var01 = 0.0;
   double var02 = 0.0;
   double var03 = 0.0;
   double var04 = 0.0;
   double var05 = 0.0;

   string time1_ = "time;";
   string var01_ = "var01;";
   string var02_ = "var02;";
   string var03_ = "var03;";
   string var04_ = "var04;";
   string var05_ = "var05";

   string head   = time1_ + var01_ + var02_ + var03_ + var03_ + var05_ ;

   FileWrite(part2,head);

   string body = "";
   int size = ArraySize(ticks);
   for(int i=0; i<size; i++)
     {
      time1_ = "";
      var01_ = "";
      var02_ = "";
      var03_ = "";
      var04_ = "";
      var05_ = "";

      for(int j = 0; j < 1; j++)
        {
         var01  = NormalizeDouble(((ticks[i].ask-ticks[i+1].ask)/ticks[i].ask*100),4);
         var02  = NormalizeDouble(((ticks[i].ask-ticks[i+2].ask)/ticks[i].ask*100),4);
         var03  = NormalizeDouble(((ticks[i].ask-ticks[i+3].ask)/ticks[i].ask*100),4);
         var04  = NormalizeDouble(((ticks[i].ask-ticks[i+4].ask)/ticks[i].ask*100),4);
         var05  = NormalizeDouble(((ticks[i].ask-ticks[i+5].ask)/ticks[i].ask*100),4);

         time1_ = time1_ + ticks[i].time + ";" ;
         var01_ = var01_ + DoubleToString(var01,8) + ";" ;
         var02_ = var02_ + DoubleToString(var02,8) + ";" ;
         var03_ = var03_ + DoubleToString(var03,8) + ";" ;
         var04_ = var04_ + DoubleToString(var04,8) + ";" ;
         var05_ = var05_ + DoubleToString(var05,8) ;
        }

      body = time1_ + var01_ + var02_ + var03_ + var04_ + var05_ ;

      FileWrite(part2,body);

     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   FileClose(part2);
   Alert("Save complete, see the file "+FileName_part2);

  }
//+------------------------------------------------------------------+
