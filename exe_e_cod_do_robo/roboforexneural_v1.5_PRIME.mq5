//+------------------------------------------------------------------+
//|                                            ROBÔ FOREX NEURAL.mq5 |
//|                                            gibranvalle@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Gibran, Borges e James"
#property link      "gibranvalle@gmail.com"
#property version   "1.5"
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Bibliotecas utilizadas
#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/HistoryOrderInfo.mqh>
#include <IsNewBar.mqh>

enum ENUM_VOL_INIT
  {
   vollv_full,   // [1]AGRESSIVO
   vollv_easy,   // [2]CONSERVADOR
  };

enum ENUM_TP_MART
  {
   mart1,        // [1]VOLUME FIBONACCI
   mart2,        // [2]05 FIBO + 04 2x ANT
   mart3,        // [3]2x VOL ANTERIOR
   mart4,        // [4]2x VOL ACUMULADO
  };

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input ulong              magicrobo           = 941;        // MAGIC NUMBER DO ROBÔ
input group              "REDE NEURAL"
input bool               ativaenvioneural    = false;      // ATIVA ENVIO DE DADOS P/ REDE
input string             endereco            = "localhost";// IP/SITE DA REDE NEURAL
input int                porta               = 8083;       // PORTA DA REDE NEURAL
//input bool               ExtTLS              = false;      // ATIVA ENVIO POR HTTPS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "ABERTURA DE POSIÇÕES"
input bool               ativaentradaea      = true;       // ATIVA ABERTURA
input double             loteinicial         = 0.01;       // TAM DO LOTE P/ CADA $50,00 DE CAPITAL
input ENUM_VOL_INIT      nivellote           = vollv_easy; // PERFIL DE AJUSTE DOS LOTES
input group              "MARTINGALE"
input ENUM_TP_MART       tipomartingale      = mart1;      // TIPO DE VOLUME MARTINGALE
input int                multiplicador       = 2;          // MULTIPLICADOR P/ MARTINGALE
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "BREAKEVEN/TRAILING STOP"
input bool               ativbreak           = false;      // ATIVA BREAKEVEN/TRAILING STOP
input double             pontosbreak         = 5;          // PTOS PROX AO TP PARA ATIV BREAKEVEN
input double             pontosbreak2        = 5;          // PTOS P/ MOVER TP PARA FRENTE BREAKEVEN
input double             pontosbesl          = 10;         // PTOS A MENOS PARA SL NOVO
input double             pontosts            = 5;          // PTOS DO SL NOVO PARA ATIV TS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "GERENCIAMENTO DE RISCO - FECHA AS POSIÇÕES NO PREJU"
input bool               ativastop           = false;      // ATIVA STOP FORÇADO
input double             stoppercent         = 10.00;     // % DO CAPITAL LIQUIDO PARA "STOPAR"
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "GERENCIAMENTO DE RISCO - NÃO ABRE NOVAS POSIÇÕES"
input double             prctniveloper       = 3000;       // MARGEM MINIMA P/ ABRIR POSIÇÕES
input double             volumeinicial       = 0.5;        // VOL MÁX P/ CADA $50,00 DE CAPITAL
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
string                   shortname;

//--- Variáveis temporárias e de carater geral
double                   stopcompra          = 0.0;
double                   stopvenda           = 0.0;
double                   takecompra          = 0.0;
double                   takevenda           = 0.0;

double                   percent_margem, saldo, capital, lucro_prejuizo, volumemaximo, volumeoper, slcomprapadrao, slvendapadrao, previsao_temp, previsao;

//--- Variáveis p/ envio de dados à rede neural
int                      socketneural        = SocketCreate();//quando chamado, cria o soquete para conexão ao servidor de previsões
string                   recebido            = "";//string para receber a previsão do servidor
string                   open1               = "";
string                   open2               = "";
string                   open3               = "";
string                   open4               = "";
string                   open5               = "";
string                   close1              = "";
string                   close2              = "";
string                   close3              = "";
string                   close4              = "";
string                   close5              = "";
string                   low1                = "";
string                   low2                = "";
string                   low3                = "";
string                   low4                = "";
string                   low5                = "";
string                   high1               = "";
string                   high2               = "";
string                   high3               = "";
string                   high4               = "";
string                   high5               = "";
string                   envioneural         = "";//string contendo os dados a serem enviados para o servidor
bool                     enviado;

//--- Definição das variáveis dos volumes para compra e venda quando utilizar martingale
double                   volnv2,volnv3,volnv4,volnv5,volnv6,volnv7,volnv8,volnv9;
double                   volnv_2,volnv_3,volnv_4,volnv_5,volnv_6,volnv_7,volnv_8,volnv_9;

//--- Variáveis p/ ticks e candles
MqlTick                  tick;
MqlRates                 candle[];

//--- Usa a classe responsável pela execução das ordens - Ctrade
CTrade                   trade;

//+--------------------------------+
//| Expert initialization function |
//+--------------------------------+
int OnInit()
  {

//--- Seta o magic number do robô
   trade.SetExpertMagicNumber(magicrobo);

   ArraySetAsSeries(candle,true);

   if(socketneural!=INVALID_HANDLE)
      Print("Confirmação de soquete criado, este é o número dele: ",socketneural);

   SocketConnect(socketneural,endereco,porta,1000);

//--- Definição dos preços de stoploss padrão para as diversas moedas
   if(Symbol()=="EURUSD")
     {
      slcomprapadrao=0.50000;
      slvendapadrao=1.63000;
     }
   if(Symbol()=="EURCAD")
     {
      slcomprapadrao=1.10000;
      slvendapadrao=2.00000;
     }
   if(Symbol()=="EURGBP")
     {
      slcomprapadrao=0.50000;
      slvendapadrao=1.50000;
     }
   if(Symbol()=="EURAUD")
     {
      slcomprapadrao=1.10000;
      slvendapadrao=2.50000;
     }
   if(Symbol()=="GBPUSD")
     {
      slcomprapadrao=1.02000;
      slvendapadrao=2.50000;
     }
   if(Symbol()=="USDJPY")
     {
      slcomprapadrao=50.000;
      slvendapadrao=330.000;
     }
   if(Symbol()=="XAUUSD")
     {
      slcomprapadrao=200.000;
      slvendapadrao=3000.000;
     }

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------------------------------+
//+----------------------------------+
//| Expert deinitialization function |
//+----------------------------------+
void OnDeinit(const int reason)
  {
//---
   ChartIndicatorDelete(0,1,shortname);

// Motivo da desinicialização do EA
   printf("Deinit reason: %d", reason);

   SocketClose(socketneural);
  }

//+------------------------------------------------------------------------------------------+
///////////////////////////////
//| INÍCIO DA FUNÇÃO ONTICK |//
///////////////////////////////
void OnTick()
  {
   if(!SymbolInfoTick(_Symbol,tick))
     {
      Alert("Erro ao obter informações de Mqlticks: ", GetLastError());
      return;
     }
   CopyRates(_Symbol,_Period,0,6,candle);
   if(CopyRates(_Symbol,_Period,0,6,candle)<0)
     {
      Alert("Erro ao obter informações de Mqlrates: ", GetLastError());
      return;
     }

   static CIsNewBar NB1,NB2,NB3/*,NB4,NB5,NB6,NB7,NB8,NB9,NB10,NB11,NB12,NB13,NB14,NB15,NB16,NB17,NB18,NB19,NB20,NB21,NB22*/;

   saldo = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
   lucro_prejuizo = NormalizeDouble(AccountInfoDouble(ACCOUNT_PROFIT),2);
   capital = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY),2);
//   double margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN),2);
//   double margem_livre = NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN),2);
   percent_margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),2);

   if(NB1.IsNewBar(_Symbol,_Period)) //VERIFICA SE É UM NOVO CANDLE
     {

      if(nivellote==vollv_easy)
        {
         if(capital>=95 && capital<500)
           {
            volumeoper=loteinicial;
            volumemaximo=volumeinicial;
           }
         if(capital>=500 && capital<1000)
           {
            volumeoper=loteinicial*2;
            volumemaximo=volumeinicial*2;
           }
         if(capital>=1000 && capital<1500)
           {
            volumeoper=loteinicial*3;
            volumemaximo=volumeinicial*3;
           }
         if(capital>=1500 && capital<2000)
           {
            volumeoper=loteinicial*4;
            volumemaximo=volumeinicial*4;
           }
         if(capital>=2000 && capital<2500)
           {
            volumeoper=loteinicial*5;
            volumemaximo=volumeinicial*5;
           }
         if(capital>=2500 && capital<3000)
           {
            volumeoper=loteinicial*6;
            volumemaximo=volumeinicial*6;
           }
         if(capital>=3000 && capital<3500)
           {
            volumeoper=loteinicial*7;
            volumemaximo=volumeinicial*7;
           }
         if(capital>=3500 && capital<4000)
           {
            volumeoper=loteinicial*8;
            volumemaximo=volumeinicial*8;
           }
         if(capital>=4000 && capital<4500)
           {
            volumeoper=loteinicial*9;
            volumemaximo=volumeinicial*9;
           }
         if(capital>=4500 && capital<5000)
           {
            volumeoper=loteinicial*10;
            volumemaximo=volumeinicial*10;
           }
         if(capital>=5000 && capital<5500)
           {
            volumeoper=loteinicial*11;
            volumemaximo=volumeinicial*11;
           }
         if(capital>=5500 && capital<6000)
           {
            volumeoper=loteinicial*12;
            volumemaximo=volumeinicial*12;
           }
         if(capital>=6000 && capital<6500)
           {
            volumeoper=loteinicial*13;
            volumemaximo=volumeinicial*13;
           }
         if(capital>=6500 && capital<7000)
           {
            volumeoper=loteinicial*14;
            volumemaximo=volumeinicial*14;
           }
         if(capital>=7000 && capital<7500)
           {
            volumeoper=loteinicial*15;
            volumemaximo=volumeinicial*15;
           }
         if(capital>=7500 && capital<8000)
           {
            volumeoper=loteinicial*16;
            volumemaximo=volumeinicial*16;
           }
         if(capital>=8000 && capital<8500)
           {
            volumeoper=loteinicial*17;
            volumemaximo=volumeinicial*17;
           }
         if(capital>=8500 && capital<9000)
           {
            volumeoper=loteinicial*18;
            volumemaximo=volumeinicial*18;
           }
         if(capital>=9000 && capital<9500)
           {
            volumeoper=loteinicial*19;
            volumemaximo=volumeinicial*19;
           }
         if(capital>=9500 && capital<10000)
           {
            volumeoper=loteinicial*20;
            volumemaximo=volumeinicial*20;
           }

         if(capital>=10000 && capital<10500)
           {
            volumeoper=loteinicial*21;
            volumemaximo=volumeinicial*21;
           }
         if(capital>=10500 && capital<11000)
           {
            volumeoper=loteinicial*22;
            volumemaximo=volumeinicial*22;
           }
         if(capital>=11000 && capital<11500)
           {
            volumeoper=loteinicial*23;
            volumemaximo=volumeinicial*23;
           }
         if(capital>=11500 && capital<12000)
           {
            volumeoper=loteinicial*24;
            volumemaximo=volumeinicial*24;
           }
         if(capital>=12000 && capital<12500)
           {
            volumeoper=loteinicial*25;
            volumemaximo=volumeinicial*25;
           }
         if(capital>=12500 && capital<13000)
           {
            volumeoper=loteinicial*26;
            volumemaximo=volumeinicial*26;
           }
         if(capital>=13000 && capital<13500)
           {
            volumeoper=loteinicial*27;
            volumemaximo=volumeinicial*27;
           }
         if(capital>=13500 && capital<14000)
           {
            volumeoper=loteinicial*28;
            volumemaximo=volumeinicial*28;
           }
         if(capital>=14000 && capital<14500)
           {
            volumeoper=loteinicial*29;
            volumemaximo=volumeinicial*29;
           }
         if(capital>=14500 && capital<15000)
           {
            volumeoper=loteinicial*30;
            volumemaximo=volumeinicial*30;
           }
         if(capital>=15000 && capital<15500)
           {
            volumeoper=loteinicial*31;
            volumemaximo=volumeinicial*31;
           }
         if(capital>=15500 && capital<16000)
           {
            volumeoper=loteinicial*32;
            volumemaximo=volumeinicial*32;
           }
         if(capital>=16000 && capital<16500)
           {
            volumeoper=loteinicial*33;
            volumemaximo=volumeinicial*33;
           }
         if(capital>=16500 && capital<17000)
           {
            volumeoper=loteinicial*34;
            volumemaximo=volumeinicial*34;
           }
         if(capital>=17000 && capital<17500)
           {
            volumeoper=loteinicial*35;
            volumemaximo=volumeinicial*35;
           }
         if(capital>=17500 && capital<18000)
           {
            volumeoper=loteinicial*36;
            volumemaximo=volumeinicial*36;
           }
         if(capital>=18000 && capital<18500)
           {
            volumeoper=loteinicial*37;
            volumemaximo=volumeinicial*37;
           }
         if(capital>=18500 && capital<19000)
           {
            volumeoper=loteinicial*38;
            volumemaximo=volumeinicial*38;
           }
         if(capital>=19000 && capital<19500)
           {
            volumeoper=loteinicial*39;
            volumemaximo=volumeinicial*39;
           }
         if(capital>=19500 && capital<20000)
           {
            volumeoper=loteinicial*40;
            volumemaximo=volumeinicial*40;
           }

         if(capital>=20000 && capital<20500)
           {
            volumeoper=loteinicial*41;
            volumemaximo=volumeinicial*41;
           }
         if(capital>=20500 && capital<21000)
           {
            volumeoper=loteinicial*42;
            volumemaximo=volumeinicial*42;
           }
         if(capital>=21000 && capital<21500)
           {
            volumeoper=loteinicial*43;
            volumemaximo=volumeinicial*43;
           }
         if(capital>=21500 && capital<22000)
           {
            volumeoper=loteinicial*44;
            volumemaximo=volumeinicial*44;
           }
         if(capital>=22000 && capital<22500)
           {
            volumeoper=loteinicial*45;
            volumemaximo=volumeinicial*45;
           }
         if(capital>=22500 && capital<23000)
           {
            volumeoper=loteinicial*46;
            volumemaximo=volumeinicial*46;
           }
         if(capital>=23000 && capital<23500)
           {
            volumeoper=loteinicial*47;
            volumemaximo=volumeinicial*47;
           }
         if(capital>=23500 && capital<24000)
           {
            volumeoper=loteinicial*48;
            volumemaximo=volumeinicial*48;
           }
         if(capital>=24000 && capital<24500)
           {
            volumeoper=loteinicial*49;
            volumemaximo=volumeinicial*49;
           }
         if(capital>=24500 && capital<25000)
           {
            volumeoper=loteinicial*50;
            volumemaximo=volumeinicial*50;
           }
         if(capital>=25000 && capital<25500)
           {
            volumeoper=loteinicial*51;
            volumemaximo=volumeinicial*51;
           }
         if(capital>=25500 && capital<26000)
           {
            volumeoper=loteinicial*52;
            volumemaximo=volumeinicial*52;
           }
         if(capital>=26000 && capital<26500)
           {
            volumeoper=loteinicial*53;
            volumemaximo=volumeinicial*53;
           }
         if(capital>=26500 && capital<27000)
           {
            volumeoper=loteinicial*54;
            volumemaximo=volumeinicial*54;
           }
         if(capital>=27000 && capital<27500)
           {
            volumeoper=loteinicial*55;
            volumemaximo=volumeinicial*55;
           }
         if(capital>=27500 && capital<28000)
           {
            volumeoper=loteinicial*56;
            volumemaximo=volumeinicial*56;
           }
         if(capital>=28000 && capital<28500)
           {
            volumeoper=loteinicial*57;
            volumemaximo=volumeinicial*57;
           }
         if(capital>=28500 && capital<29000)
           {
            volumeoper=loteinicial*58;
            volumemaximo=volumeinicial*58;
           }
         if(capital>=29000 && capital<29500)
           {
            volumeoper=loteinicial*59;
            volumemaximo=volumeinicial*59;
           }
         if(capital>=29500 && capital<30000)
           {
            volumeoper=loteinicial*60;
            volumemaximo=volumeinicial*60;
           }

         if(capital>=30000 && capital<30500)
           {
            volumeoper=loteinicial*61;
            volumemaximo=volumeinicial*61;
           }
         if(capital>=30500 && capital<31000)
           {
            volumeoper=loteinicial*62;
            volumemaximo=volumeinicial*62;
           }
         if(capital>=31000 && capital<31500)
           {
            volumeoper=loteinicial*63;
            volumemaximo=volumeinicial*63;
           }
         if(capital>=31500 && capital<32000)
           {
            volumeoper=loteinicial*64;
            volumemaximo=volumeinicial*64;
           }
         if(capital>=32000 && capital<32500)
           {
            volumeoper=loteinicial*65;
            volumemaximo=volumeinicial*65;
           }
         if(capital>=32500 && capital<33000)
           {
            volumeoper=loteinicial*66;
            volumemaximo=volumeinicial*66;
           }
         if(capital>=33000 && capital<33500)
           {
            volumeoper=loteinicial*67;
            volumemaximo=volumeinicial*67;
           }
         if(capital>=33500 && capital<34000)
           {
            volumeoper=loteinicial*68;
            volumemaximo=volumeinicial*68;
           }
         if(capital>=34000 && capital<34500)
           {
            volumeoper=loteinicial*69;
            volumemaximo=volumeinicial*69;
           }
         if(capital>=34500 && capital<35000)
           {
            volumeoper=loteinicial*70;
            volumemaximo=volumeinicial*70;
           }
         if(capital>=35000 && capital<35500)
           {
            volumeoper=loteinicial*71;
            volumemaximo=volumeinicial*71;
           }
         if(capital>=35500 && capital<36000)
           {
            volumeoper=loteinicial*72;
            volumemaximo=volumeinicial*72;
           }
         if(capital>=36000 && capital<36500)
           {
            volumeoper=loteinicial*73;
            volumemaximo=volumeinicial*73;
           }
         if(capital>=36500 && capital<37000)
           {
            volumeoper=loteinicial*74;
            volumemaximo=volumeinicial*74;
           }
         if(capital>=37000 && capital<37500)
           {
            volumeoper=loteinicial*75;
            volumemaximo=volumeinicial*75;
           }
         if(capital>=37500 && capital<38000)
           {
            volumeoper=loteinicial*76;
            volumemaximo=volumeinicial*76;
           }
         if(capital>=38000 && capital<38500)
           {
            volumeoper=loteinicial*77;
            volumemaximo=volumeinicial*77;
           }
         if(capital>=38500 && capital<39000)
           {
            volumeoper=loteinicial*78;
            volumemaximo=volumeinicial*78;
           }
         if(capital>=39000 && capital<39500)
           {
            volumeoper=loteinicial*79;
            volumemaximo=volumeinicial*79;
           }
         if(capital>=39500 && capital<40000)
           {
            volumeoper=loteinicial*80;
            volumemaximo=volumeinicial*80;
           }

         if(capital>=40000 && capital<40500)
           {
            volumeoper=loteinicial*81;
            volumemaximo=volumeinicial*81;
           }
         if(capital>=40500 && capital<41000)
           {
            volumeoper=loteinicial*82;
            volumemaximo=volumeinicial*82;
           }
         if(capital>=41000 && capital<41500)
           {
            volumeoper=loteinicial*83;
            volumemaximo=volumeinicial*83;
           }
         if(capital>=41500 && capital<42000)
           {
            volumeoper=loteinicial*84;
            volumemaximo=volumeinicial*84;
           }
         if(capital>=42000 && capital<42500)
           {
            volumeoper=loteinicial*85;
            volumemaximo=volumeinicial*85;
           }
         if(capital>=42500 && capital<43000)
           {
            volumeoper=loteinicial*86;
            volumemaximo=volumeinicial*86;
           }
         if(capital>=43000 && capital<43500)
           {
            volumeoper=loteinicial*87;
            volumemaximo=volumeinicial*87;
           }
         if(capital>=43500 && capital<44000)
           {
            volumeoper=loteinicial*88;
            volumemaximo=volumeinicial*88;
           }
         if(capital>=44000 && capital<44500)
           {
            volumeoper=loteinicial*89;
            volumemaximo=volumeinicial*89;
           }
         if(capital>=44500 && capital<45000)
           {
            volumeoper=loteinicial*90;
            volumemaximo=volumeinicial*90;
           }
         if(capital>=45000 && capital<45500)
           {
            volumeoper=loteinicial*91;
            volumemaximo=volumeinicial*91;
           }
         if(capital>=45500 && capital<46000)
           {
            volumeoper=loteinicial*92;
            volumemaximo=volumeinicial*92;
           }
         if(capital>=46000 && capital<46500)
           {
            volumeoper=loteinicial*93;
            volumemaximo=volumeinicial*93;
           }
         if(capital>=46500 && capital<47000)
           {
            volumeoper=loteinicial*94;
            volumemaximo=volumeinicial*94;
           }
         if(capital>=47000 && capital<47500)
           {
            volumeoper=loteinicial*95;
            volumemaximo=volumeinicial*95;
           }
         if(capital>=47500 && capital<48000)
           {
            volumeoper=loteinicial*96;
            volumemaximo=volumeinicial*96;
           }
         if(capital>=48000 && capital<48500)
           {
            volumeoper=loteinicial*97;
            volumemaximo=volumeinicial*97;
           }
         if(capital>=48500 && capital<49000)
           {
            volumeoper=loteinicial*98;
            volumemaximo=volumeinicial*98;
           }
         if(capital>=49000 && capital<49500)
           {
            volumeoper=loteinicial*99;
            volumemaximo=volumeinicial*99;
           }
         if(capital>=49500 && capital<50000)
           {
            volumeoper=loteinicial*100;
            volumemaximo=volumeinicial*100;
           }
        }

      if(nivellote==vollv_full)
        {
         if(capital>=0 && capital<10000000)
           {
            volumeoper=loteinicial;
            volumemaximo=volumeinicial;
           }
        }

      //--- Definição dos volumes de compra e venda quando utilizar martingale
      if(tipomartingale==mart1)//sequência de fibonacci p/ volume
        {
         volnv2             = 2*volumeoper;//2
         volnv3             = 3*volumeoper;//3
         volnv4             = 5*volumeoper;//5
         volnv5             = 8*volumeoper;//8
         volnv6             = 13*volumeoper;//13
         volnv7             = 21*volumeoper;//21
         volnv8             = 34*volumeoper;//34
         volnv9             = 55*volumeoper;//55
        }
      if(tipomartingale==mart2)//mix - fibo ate a 5 ordem e o dobro do anterior nas proximas ordens
        {
         volnv2             = 2*volumeoper;//2
         volnv3             = 3*volumeoper;//3
         volnv4             = 5*volumeoper;//5
         volnv5             = 8*volumeoper;//8
         volnv6             = volnv5*multiplicador;//16
         volnv7             = volnv6*multiplicador;//32
         volnv8             = volnv7*multiplicador;//64
         volnv9             = volnv8*multiplicador;//128
        }
      if(tipomartingale==mart3)//dobro do volume anterior
        {
         volnv2             = volumeoper*multiplicador;//2
         volnv3             = volnv2*multiplicador;//4
         volnv4             = volnv3*multiplicador;//8
         volnv5             = volnv4*multiplicador;//16
         volnv6             = volnv5*multiplicador;//32
         volnv7             = volnv6*multiplicador;//64
         volnv8             = volnv7*multiplicador;//128
         volnv9             = volnv8*multiplicador;//256
        }
      if(tipomartingale==mart4)//dobro do volume acumulado
        {
         volnv2             = volumeoper*multiplicador;//2
         volnv3             = (volumeoper+volnv2)*multiplicador;//6
         volnv4             = (volumeoper+volnv2+volnv3)*multiplicador;//18
         volnv5             = (volumeoper+volnv2+volnv3+volnv4)*multiplicador;//54
         volnv6             = (volumeoper+volnv2+volnv3+volnv4+volnv5)*multiplicador;//162
         volnv7             = (volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6)*multiplicador;//486
         volnv8             = (volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7)*multiplicador;//1458
         volnv9             = (volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7+volnv8)*multiplicador;//4374
        }
      if(volnv2>220.0)
         volnv2=0;
      if(volnv3>220.0)
         volnv3=0;
      if(volnv4>220.0)
         volnv4=0;
      if(volnv5>220.0)
         volnv5=0;
      if(volnv6>220.0)
         volnv6=0;
      if(volnv7>220.0)
         volnv7=0;
      if(volnv8>220.0)
         volnv8=0;
     }

//+------------------------------------------------------------------+
//| ENVIO DE SINAIS P/ REDE NEURAL                                   |
//+------------------------------------------------------------------+
//Comentar esse bloco caso for utilizar para teste de estratégia a partir de um arquivo

   if(ativaenvioneural==true)
     {
      if(NB2.IsNewBar(_Symbol,_Period)) //VERIFICA SE É UM NOVO CANDLE
        {
         open1  = DoubleToString(candle[4].open,5);
         open2  = DoubleToString(candle[3].open,5);
         open3  = DoubleToString(candle[2].open,5);
         open4  = DoubleToString(candle[1].open,5);
         low1   = DoubleToString(candle[4].low,5);
         low2   = DoubleToString(candle[3].low,5);
         low3   = DoubleToString(candle[2].low,5);
         low4   = DoubleToString(candle[1].low,5);
         high1  = DoubleToString(candle[4].high,5);
         high2  = DoubleToString(candle[3].high,5);
         high3  = DoubleToString(candle[2].high,5);
         high4  = DoubleToString(candle[1].high,5);
         close1 = DoubleToString(candle[4].close,5);
         close2 = DoubleToString(candle[3].close,5);
         close3 = DoubleToString(candle[2].close,5);
         close4 = DoubleToString(candle[1].close,5);

         envioneural = open1+","+high1+","+low1+","+open2+","+high2+","+low2+","+open3+","+high3+","+low3+","+open4+","+high4+","+low4+","+close4;

         if(SocketIsConnected(socketneural))
            enviado = socksend(socketneural,envioneural);
         else
            Print("Falhou conexão a ",endereco,":",porta,", erro ",GetLastError());

         Sleep(300);

         if(SocketIsConnected(socketneural))
           {
            recebido = socketreceive(socketneural,1600);
            Print("Previsão recebida: ",recebido);
           }
         else
           {
            Print("soquete para recebimento não conectado!");
           }

         previsao=NormalizeDouble(StringToDouble(recebido),5);

         Print("Valor da Previsão: ",previsao);

        }
     }

//+------------------------------------------------------------------+
//| APÓS PREVISÃO RECEBIDA EFETUAR AS OPERAÇÕES DENTRO DA ESTRATÉGIA |
//+------------------------------------------------------------------+
//previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);//ATIVAR ESSA LINHA CASO FOR USAR O TESTE DE ESTRATÉGIA A PARTIR DO ARQUIVO DE PREVISÕES
   double Ask = NormalizeDouble(tick.ask,5);
   double Bid = NormalizeDouble(tick.bid,5);
   int Spread = SymbolInfoInteger(Symbol(),SYMBOL_SPREAD);
//Print(TimeCurrent()+ " " + previsao);
   Comment(StringFormat("Previsao = %G\nAsk = %G\nBid = %G\nSpread = %d",previsao,Ask,Bid,Spread));

   if(ativaentradaea==true &&  !PossuiPosAbertaOutroAtivo())
     {
      if(NB3.IsNewBar(_Symbol,_Period)) //VERIFICA SE É UM NOVO CANDLE
        {
         if(previsao > Ask /*+ 40*_Point*/ && previsao!=0.0 && (percent_margem>prctniveloper||VolumePos()<volumemaximo))
           {
            if(PossuiPosVenda())
              {
               if(PossuiPosVendaComentada("V1"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv2,_Symbol,tick.ask,slcomprapadrao,previsao,"C2");
                  return;
                 }
               if(PossuiPosVendaComentada("V2"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv3,_Symbol,tick.ask,slcomprapadrao,previsao,"C3");
                  return;
                 }
               if(PossuiPosVendaComentada("V3"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv4,_Symbol,tick.ask,slcomprapadrao,previsao,"C4");
                  return;
                 }
               if(PossuiPosVendaComentada("V4"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv5,_Symbol,tick.ask,slcomprapadrao,previsao,"C5");
                  return;
                 }
               if(PossuiPosVendaComentada("V5"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv6,_Symbol,tick.ask,slcomprapadrao,previsao,"C6");
                  return;
                 }
               if(PossuiPosVendaComentada("V6"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv7,_Symbol,tick.ask,slcomprapadrao,previsao,"C7");
                  return;
                 }
               if(PossuiPosVendaComentada("V7"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv8,_Symbol,tick.ask,slcomprapadrao,previsao,"C8");
                  return;
                 }
              }
            else
              {
               if(PositionsTotal()==0)
                 {
                  trade.Buy(volumeoper,_Symbol,tick.ask,slcomprapadrao,previsao,"C1");
                  return;
                 }
               if(PossuiPosCompraComentada("C1") && !PossuiPosCompraComentada("C2") && Ask<PrecoAberturaPosCompra() && VolumePos()<=500 && volnv2!=0)
                 {
                  trade.Buy(volnv2,_Symbol,tick.ask,slcomprapadrao,previsao,"C2");
                  return;
                 }
               if(PossuiPosCompraComentada("C2") && !PossuiPosCompraComentada("C3") && Ask<PrecoAberturaPosCompra() && VolumePos()<=500 && volnv3!=0)
                 {
                  trade.Buy(volnv3,_Symbol,tick.ask,slcomprapadrao,previsao,"C3");
                  return;
                 }
               if(PossuiPosCompraComentada("C3") && !PossuiPosCompraComentada("C4") && Ask<PrecoAberturaPosCompra() && VolumePos()<=500 && volnv4!=0)
                 {
                  trade.Buy(volnv4,_Symbol,tick.ask,slcomprapadrao,previsao,"C4");
                  return;
                 }
               if(PossuiPosCompraComentada("C4") && !PossuiPosCompraComentada("C5") && Ask<PrecoAberturaPosCompra() && VolumePos()<=500 && volnv5!=0)
                 {
                  trade.Buy(volnv5,_Symbol,tick.ask,slcomprapadrao,previsao,"C5");
                  return;
                 }
               if(PossuiPosCompraComentada("C5") && !PossuiPosCompraComentada("C6") && Ask<PrecoAberturaPosCompra() && VolumePos()<=500 && volnv6!=0)
                 {
                  trade.Buy(volnv6,_Symbol,tick.ask,slcomprapadrao,previsao,"C6");
                  return;
                 }
               if(PossuiPosCompraComentada("C6") && !PossuiPosCompraComentada("C7") && Ask<PrecoAberturaPosCompra() && VolumePos()<=500 && volnv7!=0)
                 {
                  trade.Buy(volnv7,_Symbol,tick.ask,slcomprapadrao,previsao,"C7");
                  return;
                 }
               if(PossuiPosCompraComentada("C7") && !PossuiPosCompraComentada("C8") && Ask<PrecoAberturaPosCompra() && VolumePos()<=500 && volnv8!=0)
                 {
                  trade.Buy(volnv8,_Symbol,tick.ask,slcomprapadrao,previsao,"C8");
                  return;
                 }
              }
           }

         if(previsao < Bid /*- 40*_Point*/ && previsao!=0.0 && (percent_margem>prctniveloper||VolumePos()<volumemaximo))
           {
            if(PossuiPosCompra())
              {
               if(PossuiPosCompraComentada("C1"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv2,_Symbol,tick.bid,slvendapadrao,previsao,"V2");
                  return;
                 }
               if(PossuiPosCompraComentada("C2"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv3,_Symbol,tick.bid,slvendapadrao,previsao,"V3");
                  return;
                 }
               if(PossuiPosCompraComentada("C3"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv4,_Symbol,tick.bid,slvendapadrao,previsao,"V4");
                  return;
                 }
               if(PossuiPosCompraComentada("C4"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv5,_Symbol,tick.bid,slvendapadrao,previsao,"V5");
                  return;
                 }
               if(PossuiPosCompraComentada("C5"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv6,_Symbol,tick.bid,slvendapadrao,previsao,"V6");
                  return;
                 }
               if(PossuiPosCompraComentada("C6"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv7,_Symbol,tick.bid,slvendapadrao,previsao,"V7");
                  return;
                 }
               if(PossuiPosCompraComentada("C7"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv8,_Symbol,tick.bid,slvendapadrao,previsao,"V8");
                  return;
                 }
              }
            else
              {
               if(PositionsTotal()==0)
                 {
                  trade.Sell(volumeoper,_Symbol,tick.bid,slvendapadrao,previsao,"V1");
                  return;
                 }
               if(PossuiPosVendaComentada("V1") && !PossuiPosVendaComentada("V2") && Bid>PrecoAberturaPosVenda() && VolumePos()<=500 && volnv2!=0)
                 {
                  trade.Sell(volnv2,_Symbol,tick.bid,slvendapadrao,previsao,"V2");
                  return;
                 }
               if(PossuiPosVendaComentada("V2") && !PossuiPosVendaComentada("V3") && Bid>PrecoAberturaPosVenda() && VolumePos()<=500 && volnv3!=0)
                 {
                  trade.Sell(volnv3,_Symbol,tick.bid,slvendapadrao,previsao,"V3");
                  return;
                 }
               if(PossuiPosVendaComentada("V3") && !PossuiPosVendaComentada("V4") && Bid>PrecoAberturaPosVenda() && VolumePos()<=500 && volnv4!=0)
                 {
                  trade.Sell(volnv4,_Symbol,tick.bid,slvendapadrao,previsao,"V4");
                  return;
                 }
               if(PossuiPosVendaComentada("V4") && !PossuiPosVendaComentada("V5") && Bid>PrecoAberturaPosVenda() && VolumePos()<=500 && volnv5!=0)
                 {
                  trade.Sell(volnv5,_Symbol,tick.bid,slvendapadrao,previsao,"V5");
                  return;
                 }
               if(PossuiPosVendaComentada("V5") && !PossuiPosVendaComentada("V6") && Bid>PrecoAberturaPosVenda() && VolumePos()<=500 && volnv6!=0)
                 {
                  trade.Sell(volnv6,_Symbol,tick.bid,slvendapadrao,previsao,"V6");
                  return;
                 }
               if(PossuiPosVendaComentada("V6") && !PossuiPosVendaComentada("V7") && Bid>PrecoAberturaPosVenda() && VolumePos()<=500 && volnv7!=0)
                 {
                  trade.Sell(volnv7,_Symbol,tick.bid,slvendapadrao,previsao,"V7");
                  return;
                 }
               if(PossuiPosVendaComentada("V7") && !PossuiPosVendaComentada("V8") && Bid>PrecoAberturaPosVenda() && VolumePos()<=500 && volnv8!=0)
                 {
                  trade.Sell(volnv8,_Symbol,tick.bid,slvendapadrao,previsao,"V8");
                  return;
                 }
              }
           }

         //////////////////////////
         //---|AJUSTE DE TAKE|---//
         //////////////////////////
         Sleep(300);
         if(TPUltimaPosAberta() != previsao && (StopUltimaPosAberta()==slcomprapadrao||StopUltimaPosAberta()==slvendapadrao) && ((PossuiPosCompra() && previsao > PrecoPosCompra())||(PossuiPosVenda() && previsao < PrecoPosCompra())))
           {
            if(PossuiPosCompra())
               trade.PositionModify(_Symbol,slcomprapadrao,previsao);
            if(PossuiPosVenda())
               trade.PositionModify(_Symbol,slvendapadrao,previsao);
            return;
           }
        }
     }

//////////////////////////
//---|STOP FORÇADO |----//
//////////////////////////
   if(ativastop==true)
      if(MathAbs((LucroPrejuizoPosAberta()/capital)*100)>=stoppercent && saldo!=capital)
        {
         FechaTodasPosicoesAbertas();
         Sleep(200);
        }
        
////////////////////////////
//---|BREAKEVEN E TS |----//
////////////////////////////
   if(ativbreak==true)
     {

      if(PossuiPosCompra() && tick.bid>PrecoPosCompra() && StopUltimaPosAberta()==slcomprapadrao && tick.ask>TPUltimaPosAberta()-pontosbreak*_Point)
        {
         trade.PositionModify(_Symbol,tick.bid-pontosbesl*_Point,TPUltimaPosAberta()+pontosbreak2*_Point);
         Sleep(200);
        }
      if(PossuiPosCompra() && tick.bid>TPUltimaPosAberta()+pontosts*_Point && StopUltimaPosAberta()!=slcomprapadrao)
        {
         trade.PositionModify(_Symbol,TPUltimaPosAberta()+pontosts*_Point,TPUltimaPosAberta()+pontosts*_Point);
         Sleep(200);
        }

      if(PossuiPosVenda() && tick.ask<PrecoPosCompra() && StopUltimaPosAberta()==slvendapadrao && tick.bid<TPUltimaPosAberta()+pontosbreak*_Point)
        {
         trade.PositionModify(_Symbol,tick.ask+pontosbesl*_Point,TPUltimaPosAberta()-pontosbreak2*_Point);
         Sleep(200);
        }
      if(PossuiPosVenda() && tick.ask<TPUltimaPosAberta()-pontosts*_Point && StopUltimaPosAberta()!=slvendapadrao)
        {
         trade.PositionModify(_Symbol,TPUltimaPosAberta()-pontosts*_Point,TPUltimaPosAberta()-pontosts*_Point);
         Sleep(200);
        }

     }

  }

//+------------------------------------------------------------------------------------------+
////////////////////////////
//| FIM DA FUNÇÃO ONTICK |//
////////////////////////////
/////////////////////////////////////
//| INÍCIO DAS FUNÇÕES AUXILIARES |//
/////////////////////////////////////
//+------------------------------------------------------------------+
//| ENVIA OS DADOS PARA O SERVIDOR DE PREVISÕES                      |
//+------------------------------------------------------------------+
bool socksend(int socket,string request)
  {
   char req[];
   int  len=StringToCharArray(request,req)-1;
   if(len<0)
      return(false);
//--- se for usada uma conexão TLS segura pela porta 443
//   if(ExtTLS)
//      return(SocketTlsSend(socket,req,len)==len);
//--- se for usada uma conexão TCP normal
   return(SocketSend(socket,req,len)==len);
  }
//+------------------------------------------------------------------+
//| RECEBE AS PREVISÕES DO SERVIDOR                                  |
//+------------------------------------------------------------------+
string socketreceive(int socket,uint timeout)
  {
   char   rsp[];
   string result;
   uint   timeout_check=GetTickCount()+timeout;
//--- lê dados do soquete enquanto eles existem, mas não mais tempo do que o timeout
   do
     {
      uint len=SocketIsReadable(socket);
      if(len)
        {
         int rsp_len;
         //--- diferentes comandos de leitura dependendo de se a conexão é segura ou não
         //if(ExtTLS)
         //   rsp_len=SocketTlsRead(socket,rsp,len);
         //else
         rsp_len=SocketRead(socket,rsp,len,timeout);
         //--- analisa a resposta
         if(rsp_len>0)
            result+=CharArrayToString(rsp,0,rsp_len,CP_UTF8);
        }
     }
   while(GetTickCount()<timeout_check && !IsStopped());
   return(result);
  }
//+------------------------------------------------------------------------------------------+
//+-------------------------------------------------------------------------+
//| VERIFICA SE HÁ PELO MENOS UMA POSIÇÃO DE COMPRA ABERTA NO ATIVO CORRENTE|
//+-------------------------------------------------------------------------+
bool PossuiPosCompra()
  {
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(TipoPosicao==POSITION_TYPE_BUY && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return true;
         break;
        }
     }
   return false;
  }
//+------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------------+
//| VERIFICA SE HÁ PELO MENOS UMA POSIÇÃO DE VENDA ABERTA NO ATIVO CORRENTE|
//+------------------------------------------------------------------------+
bool PossuiPosVenda()
  {
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(TipoPosicao==POSITION_TYPE_SELL && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return true;
         break;
        }
     }
   return false;
  }
//+----------------------------------------------------------------------------------------------+
//+-------------------------------------------------------------+
//| VERIFICA SE HÁ PELO MENOS UMA POSIÇÃO ABERTA EM OUTRO ATIVO |
//+-------------------------------------------------------------+
bool PossuiPosAbertaOutroAtivo()
  {
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if((TipoPosicao==POSITION_TYPE_BUY||TipoPosicao==POSITION_TYPE_SELL) && position_symbol!=_Symbol /*&& magic == magicrobo*/)
        {
         return true;
         break;
        }
     }
   return false;
  }
//+------------------------------------------------------------------------------------------+
//+----------------------------------------------+
//| RETORNA O VOLUME DA POSIÇÃO DE COMPRA ABERTA |
//+----------------------------------------------+
double VolumePosCompra()
  {
   int posabertas = PositionsTotal();
   for(int i = posabertas-1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double volume = PositionGetDouble(POSITION_VOLUME);
      ENUM_POSITION_TYPE tipo =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(tipo == POSITION_TYPE_BUY && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return volume;
         break;
        }
     }
   return -1;
  }
//+------------------------------------------------------------------------------------------+
//+---------------------------------------------+
//| RETORNA O VOLUME DA POSIÇÃO DE VENDA ABERTA |
//+---------------------------------------------+
double VolumePosVenda()
  {
   int posabertas = PositionsTotal();
   for(int i = posabertas-1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double volume = PositionGetDouble(POSITION_VOLUME);
      ENUM_POSITION_TYPE tipo =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(tipo == POSITION_TYPE_SELL && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return volume;
         break;
        }
     }
   return -1;
  }
//+------------------------------------------------------------------------------------------+
//+----------------------------------------------+
//| RETORNA O VOLUME DA POSIÇÃO ABERTA |
//+----------------------------------------------+
double VolumePos()
  {
   int posabertas = PositionsTotal();
   for(int i = posabertas-1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double volume = PositionGetDouble(POSITION_VOLUME);
      ENUM_POSITION_TYPE tipo =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if((tipo == POSITION_TYPE_BUY||tipo == POSITION_TYPE_SELL) && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return volume;
         break;
        }
     }
   return -1;
  }
//+------------------------------------------------------------------------------------------+
//+---------------------------------+
//| FECHA TODAS AS POSIÇÕES ABERTAS |
//+---------------------------------+
void FechaTodasPosicoesAbertas()
  {
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if((TipoPosicao==POSITION_TYPE_SELL||TipoPosicao==POSITION_TYPE_BUY) && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         //--- everyrging is ready, trying to modify a buy position
         if(!trade.PositionClose(ticket))
           {
            //--- failure message
            Print("PositionClose() method failed. Return code=",trade.ResultRetcode(),
                  ". Descrição do código: ",trade.ResultRetcodeDescription());
           }
         else
           {
            Print("PositionClose() method executed successfully. Return code=",trade.ResultRetcode(),
                  " (",trade.ResultRetcodeDescription(),")");
           }
        }
     }
  }
//+------------------------------------------------------------------------------------------+
//+--------------------------------------------------+
//| VERIFICA SE EXISTE PELO MENOS UMA ORDEM PENDENTE |
//+--------------------------------------------------+
bool PossuiOrdemPendente()
  {
   int total = OrdersTotal();
   for(int i = total-1; i >= 0; i--)
     {
      ulong  order_ticket = OrderGetTicket(i);
      string order_symbol = OrderGetString(ORDER_SYMBOL);
      //ulong  magic = OrderGetInteger(ORDER_MAGIC);
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(order_symbol==_Symbol /*&& magic == magicrobo*/ && (type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_SELL_LIMIT || type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_SELL_STOP))
        {
         return true;
         break;
        }
     }
   return false;
  }
//+------------------------------------------------------------------------------------------
//+-------------------------------------------+
//| EXCLUI TODOS OS TIPOS DE ORDENS PENDENTES |
//+-------------------------------------------+
void ExcluiOrdensPendentes()
  {
   int total = OrdersTotal(); // número de ordens pendentes
   for(int i = total-1; i >= 0; i--)
     {
      //--- aquisição dos parâmetros da posição para posterior composição da ordem de fechamento
      ulong  order_ticket = OrderGetTicket(i);
      string order_symbol = OrderGetString(ORDER_SYMBOL);
      //ulong  magic = OrderGetInteger(ORDER_MAGIC);
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(order_symbol==_Symbol /*&& magic == magicrobo*/ && (type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_SELL_LIMIT || type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_SELL_STOP))
        {
         //--- everyrging is ready, trying to modify a buy position
         if(!trade.OrderDelete(order_ticket))
           {
            //--- failure message
            Print("OrderDelete() method failed. Return code=",trade.ResultRetcode(),
                  ". Descrição do código: ",trade.ResultRetcodeDescription());
           }
         else
           {
            Print("OrderDelete() method executed successfully. Return code=",trade.ResultRetcode(),
                  " (",trade.ResultRetcodeDescription(),")");
           }
        }
     }
  }
//+------------------------------------------------------------------------------------------+
//+---------------------------------------------------------------------+
//| VERIFICA SE HÁ POSIÇÃO DE COMPRA ABERTA COM COMENTÁRIO PRÉ DEFINIDO |
//+---------------------------------------------------------------------+
bool PossuiPosCompraComentada(string comentario)
  {
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      string coment = PositionGetString(POSITION_COMMENT);
      if(TipoPosicao==POSITION_TYPE_BUY && position_symbol==_Symbol /*&& magic == magicrobo*/ && coment==comentario)
        {
         return true;
         break;
        }
     }
   return false;
  }
//+------------------------------------------------------------------------------------------+
//+--------------------------------------------------------------------+
//| VERIFICA SE HÁ POSIÇÃO DE VENDA ABERTA  COM COMENTÁRIO PRÉ DEFINIDO|
//+--------------------------------------------------------------------+
bool PossuiPosVendaComentada(string comentario)
  {
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      string coment = PositionGetString(POSITION_COMMENT);
      if(TipoPosicao==POSITION_TYPE_SELL && position_symbol==_Symbol /*&& magic == magicrobo*/ && coment==comentario)
        {
         return true;
         break;
        }
     }
   return false;
  }
//+------------------------------------------------------------------------------------------+
//+--------------------------------------------------------+
//| VERIFICA PREÇO DE ABERTURA DA ULTIMA POSIÇÃO DE COMPRA |
//+--------------------------------------------------------+
double PrecoAberturaPosCompra()
  {
   HistorySelect(0,TimeCurrent());
   string   name;
   ulong    ticket=0;
   double   price;
   double   profit;
   datetime time;
   string   symbol;
   long     type;
   long     entry;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      //--- tentar obter ticket negócios
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- obter as propriedades negócios
         price =HistoryDealGetDouble(ticket,DEAL_PRICE);
         time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         //--- apenas para o símbolo atual
         if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
           {
            return price;
            break;
           }
        }
     }
   return 0;
  }
//+------------------------------------------------------------------------------------------+
//+-------------------------------------------------------+
//| VERIFICA PREÇO DE ABERTURA DA ULTIMA POSIÇÃO DE VENDA |
//+-------------------------------------------------------+
double PrecoAberturaPosVenda()
  {
   HistorySelect(0,TimeCurrent());
   string   name;
   ulong    ticket=0;
   double   price;
   double   profit;
   datetime time;
   string   symbol;
   long     type;
   long     entry;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      //--- tentar obter ticket negócios
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- obter as propriedades negócios
         price =HistoryDealGetDouble(ticket,DEAL_PRICE);
         time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         //--- apenas para o símbolo atual
         if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
           {
            return price;
            break;
           }
        }
     }
   return 0;
  }
//+------------------------------------------------------------------------------------------+
//+-----------------------------------+
//| RETORNA O PREÇO DA POSIÇÃO ABERTA |
//+-----------------------------------+
double PrecoPosCompra()
  {
   int posabertas = PositionsTotal();
   for(int i = posabertas-1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double preco = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE tipo =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if((tipo == POSITION_TYPE_BUY||tipo == POSITION_TYPE_SELL) && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return preco;
         break;
        }
     }
   return -1;
  }
//+------------------------------------------------------------------------------------------+
//+---------------------------------------------+
//| RETORNA O STOPLOSS DA ÚLTIMA POSIÇÃO ABERTA |
//+---------------------------------------------+
double StopUltimaPosAberta()
  {
   int posabertas = PositionsTotal();
   for(int i = posabertas-1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double sl = PositionGetDouble(POSITION_SL);
      ENUM_POSITION_TYPE tipo =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if((tipo == POSITION_TYPE_BUY || tipo == POSITION_TYPE_SELL) && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return sl;
         break;
        }
     }
   return 0;
  }
//+------------------------------------------------------------------------------------------+
//+------------------------------------------------+
//| RETORNA O TAKE PROFIT DA ÚLTIMA POSIÇÃO ABERTA |
//+------------------------------------------------+
double TPUltimaPosAberta()
  {
   int posabertas = PositionsTotal();
   for(int i = posabertas-1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double tp = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE tipo =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if((tipo == POSITION_TYPE_BUY || tipo == POSITION_TYPE_SELL) && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return tp;
         break;
        }
     }
   return 0;
  }
//+------------------------------------------------------------------------------------------+
//+-------------------------------------------------------------+
//| VERIFICA O LUCRO/PREJUIZO DA POSIÇÃO DE COMPRA/VENDA ABERTA |
//+-------------------------------------------------------------+
double LucroPrejuizoPosAberta()
  {
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double LucroPrejuizo = PositionGetDouble(POSITION_PROFIT);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if((TipoPosicao==POSITION_TYPE_BUY||TipoPosicao==POSITION_TYPE_SELL) && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return LucroPrejuizo;
         break;
        }
     }
   return 0;
  }
//+------------------------------------------------------------------------------------------+
/*
PM1 = ((tick.ask*volumeoper+prcnvl_2*volnv2)/(volumeoper+volnv2))+pontostp*_Point;
PM2 = ((tick.ask*volumeoper+prcnvl_2*volnv2+prcnvl_3*volnv3)/(volumeoper+volnv2+volnv3))+pontostp*_Point;
PM3 = ((tick.ask*volumeoper+prcnvl_2*volnv2+prcnvl_3*volnv3+prcnvl_4*volnv4)/(volumeoper+volnv2+volnv3+volnv4))+pontostp*_Point;
PM4 = ((tick.ask*volumeoper+prcnvl_2*volnv2+prcnvl_3*volnv3+prcnvl_4*volnv4+prcnvl_5*volnv5)/(volumeoper+volnv2+volnv3+volnv4+volnv5))+pontostp*_Point;
PM5 = ((tick.ask*volumeoper+prcnvl_2*volnv2+prcnvl_3*volnv3+prcnvl_4*volnv4+prcnvl_5*volnv5+prcnvl_6*volnv6)/(volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6))+pontostp*_Point;
PM6 = ((tick.ask*volumeoper+prcnvl_2*volnv2+prcnvl_3*volnv3+prcnvl_4*volnv4+prcnvl_5*volnv5+prcnvl_6*volnv6+prcnvl_7*volnv7)/(volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7))+pontostp*_Point;
*/
/*PMV1 = ((tick.bid*volumeoper+prcnvl2*volnv2)/(volumeoper+volnv2))-pontostp*_Point;
PMV2 = ((tick.bid*volumeoper+prcnvl2*volnv2+prcnvl3*volnv3)/(volumeoper+volnv2+volnv3))-pontostp*_Point;
PMV3 = ((tick.bid*volumeoper+prcnvl2*volnv2+prcnvl3*volnv3+prcnvl4*volnv4)/(volumeoper+volnv2+volnv3+volnv4))-pontostp*_Point;
PMV4 = ((tick.bid*volumeoper+prcnvl2*volnv2+prcnvl3*volnv3+prcnvl4*volnv4+prcnvl5*volnv5)/(volumeoper+volnv2+volnv3+volnv4+volnv5))-pontostp*_Point;
PMV5 = ((tick.bid*volumeoper+prcnvl2*volnv2+prcnvl3*volnv3+prcnvl4*volnv4+prcnvl5*volnv5+prcnvl6*volnv6)/(volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6))-pontostp*_Point;
PMV6 = ((tick.bid*volumeoper+prcnvl2*volnv2+prcnvl3*volnv3+prcnvl4*volnv4+prcnvl5*volnv5+prcnvl6*volnv6+prcnvl7*volnv7)/(volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7))-pontostp*_Point;
*/
