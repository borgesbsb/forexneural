#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs
input bool     UseDateFrom =true; // Set the start date
input datetime DateFrom=""; // Start date
input bool     UseDateTo=true; // Set the end date
input datetime DateTo=""; // End date
string papel = "EURUSD"; // Papel estudado
input ENUM_TIMEFRAMES timeframe  = PERIOD_H1;
int periodo_tempo = 1;

void OnStart()
{

//Variaveis de intervalo para o dataset
   datetime from,to;

//Configuracao para insercao de dados pelo forulario da plataforma
   if(UseDateFrom)
   {
      from=DateFrom;
      Alert("Dados do From =  "+from);
   }
   else
   {
      int bars=Bars("EURUSD",Period());
      if(bars>0)
        {
         datetime tm[];
         if(CopyTime(papel,Period(),bars-1,1,tm)==-1)
           {
            Alert("Error defining data start, please try again later");
            return;
           }
         else
           {
            from=tm[0];
           }
        }
      else
        {
         Alert("Timeframe is under construction, please try again later");
         return;
        }
   }
   if(UseDateTo)
   {
      to=DateTo;
       Alert("Dados do TO =  "+to);
   }
   else
   {
      to=TimeCurrent();
   }
/////////////FIM - Configuracao para insercao de dados pelo forulario da plataforma

    
//Formacao de preços com períodos de 10 min.
   MqlRates rates[];
   if(CopyRates(papel,timeframe,from,to,rates) == -1)
     {
         Alert("Numero de dados copiados  = "+ArraySize(rates));
      
     }else{
         Print("Copiando dados... papel");
     }

///Formacao do indicador Parabolic SAR

   int handle_sar = iSAR(papel,timeframe,0.2,0.02);
   double sar[];
   CopyBuffer(handle_sar,0,from,to,sar);
//ArraySetAsSeries(sar,true);

///Formacao do indicador Media aritimetica de 5 periodos

   int handle_ma5 = iMA(papel,timeframe, 5, 0, MODE_SMA, PRICE_CLOSE);
   double ma5[];
   CopyBuffer(handle_ma5,0,from,to,ma5);

///Formacao do indicador Media aritimetica de 9 periodos
   int handle_ma9 = iMA(papel,timeframe, 9, 0, MODE_SMA, PRICE_CLOSE);
   double ma9[];
   CopyBuffer(handle_ma9,0,from,to,ma9);

///Formacao do indicador Media aritimetica de 21 periodos
   int handle_ma21 = iMA(papel,timeframe, 21, 0, MODE_SMA, PRICE_CLOSE);
   double ma21[];
   CopyBuffer(handle_ma21,0,from,to,ma21);

///Formacao do indicador Media aritimetica de 50 periodos
   int handle_ma50 = iMA(papel,timeframe, 50, 0, MODE_SMA, PRICE_CLOSE);
   double ma50[];
   CopyBuffer(handle_ma50,0,from,to,ma50);


///Formacao do indicador Media aritimetica de 100 periodos
   int handle_ma100 = iMA(papel,timeframe, 100, 0, MODE_SMA, PRICE_CLOSE);
   double ma100[];
   CopyBuffer(handle_ma100,0,from,to,ma100);


///Formacao do indicador MACD
   int handle_macd = iMACD(papel, timeframe, 12, 26, 9, PRICE_CLOSE);
   double macd[];
   double macds[];
   CopyBuffer(handle_macd,0,from,to,macd);
   CopyBuffer(handle_macd,1,from,to,macds);

///Formacao do indicador de momentum
   int handle_mom = iMomentum(papel, timeframe, 12, PRICE_CLOSE);
   double mom[];
   CopyBuffer(handle_mom,0,from,to,mom);

///Formacao do indicador de índice de força relativa
   int handle_rsi = iRSI(papel, timeframe,14,PRICE_CLOSE );
   double rsi[];
   CopyBuffer(handle_rsi,0,from,to,rsi);


//////////////////////////////////////////////////////////////////
//Criacao do arquivo parte 1
  // string FileName_part1=papel+" "+IntegerToString(PeriodSeconds()/60)+"part1"+".csv";
   //int part1=FileOpen(FileName_part1,FILE_WRITE|FILE_ANSI|FILE_CSV,";");
//Tratamento de erro
   //if(part1==INVALID_HANDLE)
    // {
    //  Alert("Error opening file");
    //  return;
    // }

//Criacao o arquivo parte 2
   string FileName_part2=papel+".csv";
   int part2=FileOpen(FileName_part2,FILE_WRITE|FILE_ANSI|FILE_CSV,";");
//Tratamento de erro
   if(part2==INVALID_HANDLE)
     {
      Alert("Error opening file");
      return;
     }

   string time_  = "time;";
   string open_  = "";
   string high_  = "";
   string low_   = "";
   string close_ = "";
   string volume_= "";
   string ticks_ = "";
   string sar_   = "";
   string ma5_   = "";
   string ma9_   = "";
   string ma21_  = "";
   string ma50_  = "";
   string ma100_ = "";
   string macd_  = "";
   string macds_ = "";
   string mom_   = "";
   string rsi_   = "";

   for(int i=1; i <= periodo_tempo ; i++)
   {
      open_  =   open_    + "open"+i+";";
      high_  =   high_    + "high"+i+";";
      low_   =   low_     + "low"+i+";";
      close_ =   close_   + "close"+i+";";
      volume_=   volume_  + "volume"+i+";";
      ticks_ =   ticks_   + "ticks"+i+";";
      sar_   =   sar_     + "sar"+i+";";
      ma5_   =   ma5_     + "ma5"+i+";";
      ma9_   =   ma9_     + "ma9"+i+";";
      ma21_  =   ma21_    + "ma21"+i+";";
      ma50_  =   ma50_    + "ma50"+i+";";
      ma100_ =   ma100_   + "ma100"+i+";";
      macd_  =   macd_    + "macd"+i+";";
      macds_ =   macds_   + "macds"+i+";";
      mom_   =   mom_     + "mom"+i+";";
      rsi_   =   rsi_     + "rsi"+i+"";
      
   }

   string head  = time_   + 
                  open_   + 
                  high_   + 
                  low_    + 
                  close_  + 
                  volume_ + 
                  ticks_  + 
                  sar_    + 
                  ma5_    + 
                  ma9_    +  
                  ma21_   + 
                  ma50_   + 
                  ma100_  + 
                  macd_   + 
                  macds_  + 
                  mom_    +
                  rsi_    ; 
   FileWrite(part2, head);

   
      
       string body = "";
       
       for(int i=0;i<ArraySize(rates) - periodo_tempo;i++){
           
            time_  = rates[i].time+";";
            open_  = "";  
            high_  = ""; 
            low_   = "";  
            close_ = "";  
            volume_= "";  
            ticks_ = "";  
            sar_   = "";  
            ma5_   = "";  
            ma9_   = "";  
            ma21_  = "";
            ma50_  = "";
            ma100_ = "";
            macd_  = "";
            macds_ = "";
            mom_   = "";
            rsi_   = "";
            
            for(int j = 0; j < periodo_tempo; j++){
              
              
                 open_   = open_    + DoubleToString(NormalizeDouble(rates[j+i].open,  5),5)+";";
                 high_   = high_    + DoubleToString(NormalizeDouble(rates[j+i].high,5),5)+";";
                 low_    = low_     + DoubleToString(NormalizeDouble(rates[j+i].low,5),5)+";";
                 close_  = close_   + DoubleToString(NormalizeDouble(rates[j+i].close,5),5)+";";
                 volume_ = volume_  + rates[j+i].real_volume+";";
                 ticks_  = ticks_   + rates[j+i].tick_volume+";";  
                 sar_    = sar_     + DoubleToString(NormalizeDouble(sar[j+i],6),6)+";";
                 ma5_    = ma5_     + DoubleToString(NormalizeDouble(ma5[j+i],6),6)+";";
                 ma9_    = ma9_     + DoubleToString(NormalizeDouble(ma9[j+i],6),6)+";";
                 ma21_    = ma21_   + DoubleToString( NormalizeDouble(ma21[j+i],6),6 )  + ";";
                 ma50_    = ma50_   + DoubleToString( NormalizeDouble(ma50[j+i],6),6)   + ";";
                 ma100_   = ma100_  + DoubleToString(NormalizeDouble(ma100[j+i],6),6)   + ";";
                 macd_    = macd_   + DoubleToString(NormalizeDouble(macd[j+i],6),6)    + ";";
                 macds_   = macds_  + DoubleToString(NormalizeDouble(macds[j+i],6),6)   + ";";
                 mom_     = mom_    + DoubleToString(NormalizeDouble(mom[j+i],2),2)     + ";";
                 rsi_     = rsi_    + DoubleToString(NormalizeDouble(rsi[j+i],2),2)     + "";
            }
           body = time_ + open_ + low_ + high_ + close_ + volume_ + ticks_ + sar_ + ma5_ + ma9_ + ma21_ + ma50_ + ma100_ + macd_ + macds_ + mom_ + rsi_;
              
            FileWrite(part2,body);   
         
       }
       
   FileClose(part2);
   Alert("Save complete, see the file "+FileName_part2);

}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
