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
double                   prejuizo;

//--- Variáveis p/ ticks e candles
MqlTick                  tick;
MqlRates                 candle[];

// Cria estruturas de tempo para manipulação de horários
MqlDateTime horario_inicio, horario_termino,/* horario_fechamento,*/ //
            horario_atual, horario_inicio_pausa1, horario_termino_pausa1, //
            horario_inicio_pausa2, horario_termino_pausa2, horario_posicao;

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
         if(capital>=50 && capital<98)
           {
            volumeoper=loteinicial;
            volumemaximo=volumeinicial;
           }
         if(capital>=98 && capital<200)
           {
            volumeoper=loteinicial*2;
            volumemaximo=volumeinicial*2;
           }
         if(capital>=200 && capital<300)
           {
            volumeoper=loteinicial*3;
            volumemaximo=volumeinicial*3;
           }
         if(capital>=300 && capital<400)
           {
            volumeoper=loteinicial*4;
            volumemaximo=volumeinicial*4;
           }
         if(capital>=400 && capital<500)
           {
            volumeoper=loteinicial*5;
            volumemaximo=volumeinicial*5;
           }
         if(capital>=500 && capital<600)
           {
            volumeoper=loteinicial*6;
            volumemaximo=volumeinicial*6;
           }
         if(capital>=600 && capital<700)
           {
            volumeoper=loteinicial*7;
            volumemaximo=volumeinicial*7;
           }
         if(capital>=700 && capital<800)
           {
            volumeoper=loteinicial*8;
            volumemaximo=volumeinicial*8;
           }
         if(capital>=800 && capital<900)
           {
            volumeoper=loteinicial*9;
            volumemaximo=volumeinicial*9;
           }
         if(capital>=900 && capital<1000)
           {
            volumeoper=loteinicial*10;
            volumemaximo=volumeinicial*10;
           }
         if(capital>=1000 && capital<1100)
           {
            volumeoper=loteinicial*11;
            volumemaximo=volumeinicial*11;
           }
         if(capital>=1100 && capital<1200)
           {
            volumeoper=loteinicial*12;
            volumemaximo=volumeinicial*12;
           }
         if(capital>=1200 && capital<1300)
           {
            volumeoper=loteinicial*13;
            volumemaximo=volumeinicial*13;
           }
         if(capital>=1300 && capital<1400)
           {
            volumeoper=loteinicial*14;
            volumemaximo=volumeinicial*14;
           }
         if(capital>=1400 && capital<1500)
           {
            volumeoper=loteinicial*15;
            volumemaximo=volumeinicial*15;
           }
         if(capital>=1500 && capital<1600)
           {
            volumeoper=loteinicial*16;
            volumemaximo=volumeinicial*16;
           }
         if(capital>=1600 && capital<1700)
           {
            volumeoper=loteinicial*17;
            volumemaximo=volumeinicial*17;
           }
         if(capital>=1700 && capital<1800)
           {
            volumeoper=loteinicial*18;
            volumemaximo=volumeinicial*18;
           }
         if(capital>=1800 && capital<1900)
           {
            volumeoper=loteinicial*19;
            volumemaximo=volumeinicial*19;
           }
         if(capital>=1900 && capital<2000)
           {
            volumeoper=loteinicial*20;
            volumemaximo=volumeinicial*20;
           }
         if(capital>=2000 && capital<2100)
           {
            volumeoper=loteinicial*21;
            volumemaximo=volumeinicial*21;
           }
         if(capital>=2100 && capital<2200)
           {
            volumeoper=loteinicial*22;
            volumemaximo=volumeinicial*22;
           }
         if(capital>=2200 && capital<2300)
           {
            volumeoper=loteinicial*23;
            volumemaximo=volumeinicial*23;
           }
         if(capital>=2300 && capital<2400)
           {
            volumeoper=loteinicial*24;
            volumemaximo=volumeinicial*24;
           }
         if(capital>=2400 && capital<2500)
           {
            volumeoper=loteinicial*25;
            volumemaximo=volumeinicial*25;
           }
         if(capital>=2500 && capital<2600)
           {
            volumeoper=loteinicial*26;
            volumemaximo=volumeinicial*26;
           }
         if(capital>=2600 && capital<2700)
           {
            volumeoper=loteinicial*27;
            volumemaximo=volumeinicial*27;
           }
         if(capital>=2700 && capital<2800)
           {
            volumeoper=loteinicial*28;
            volumemaximo=volumeinicial*28;
           }
         if(capital>=2800 && capital<2900)
           {
            volumeoper=loteinicial*29;
            volumemaximo=volumeinicial*29;
           }
         if(capital>=2900 && capital<3000)
           {
            volumeoper=loteinicial*30;
            volumemaximo=volumeinicial*30;
           }
         if(capital>=3000 && capital<3100)
           {
            volumeoper=loteinicial*31;
            volumemaximo=volumeinicial*31;
           }
         if(capital>=3100 && capital<3200)
           {
            volumeoper=loteinicial*32;
            volumemaximo=volumeinicial*32;
           }
         if(capital>=3200 && capital<3300)
           {
            volumeoper=loteinicial*33;
            volumemaximo=volumeinicial*33;
           }
         if(capital>=3300 && capital<3400)
           {
            volumeoper=loteinicial*34;
            volumemaximo=volumeinicial*34;
           }
         if(capital>=3400 && capital<3500)
           {
            volumeoper=loteinicial*35;
            volumemaximo=volumeinicial*35;
           }
         if(capital>=3500 && capital<3600)
           {
            volumeoper=loteinicial*36;
            volumemaximo=volumeinicial*36;
           }
         if(capital>=3600 && capital<3700)
           {
            volumeoper=loteinicial*37;
            volumemaximo=volumeinicial*37;
           }
         if(capital>=3700 && capital<3800)
           {
            volumeoper=loteinicial*38;
            volumemaximo=volumeinicial*38;
           }
         if(capital>=3800 && capital<3900)
           {
            volumeoper=loteinicial*39;
            volumemaximo=volumeinicial*39;
           }
         if(capital>=3900 && capital<4000)
           {
            volumeoper=loteinicial*40;
            volumemaximo=volumeinicial*40;
           }
         if(capital>=4000 && capital<4100)
           {
            volumeoper=loteinicial*41;
            volumemaximo=volumeinicial*41;
           }
         if(capital>=4100 && capital<4200)
           {
            volumeoper=loteinicial*42;
            volumemaximo=volumeinicial*42;
           }
         if(capital>=4200 && capital<4300)
           {
            volumeoper=loteinicial*43;
            volumemaximo=volumeinicial*43;
           }
         if(capital>=4300 && capital<4400)
           {
            volumeoper=loteinicial*44;
            volumemaximo=volumeinicial*44;
           }
         if(capital>=4400 && capital<4500)
           {
            volumeoper=loteinicial*45;
            volumemaximo=volumeinicial*45;
           }
         if(capital>=4500 && capital<4600)
           {
            volumeoper=loteinicial*46;
            volumemaximo=volumeinicial*46;
           }
         if(capital>=4600 && capital<4700)
           {
            volumeoper=loteinicial*47;
            volumemaximo=volumeinicial*47;
           }
         if(capital>=4700 && capital<4800)
           {
            volumeoper=loteinicial*48;
            volumemaximo=volumeinicial*48;
           }
         if(capital>=4800 && capital<4900)
           {
            volumeoper=loteinicial*49;
            volumemaximo=volumeinicial*49;
           }
         if(capital>=4900 && capital<5000)
           {
            volumeoper=loteinicial*50;
            volumemaximo=volumeinicial*50;
           }
         if(capital>=5000 && capital<5100)
           {
            volumeoper=loteinicial*51;
            volumemaximo=volumeinicial*51;
           }
         if(capital>=5100 && capital<5200)
           {
            volumeoper=loteinicial*52;
            volumemaximo=volumeinicial*52;
           }
         if(capital>=5200 && capital<5300)
           {
            volumeoper=loteinicial*53;
            volumemaximo=volumeinicial*53;
           }
         if(capital>=5300 && capital<5400)
           {
            volumeoper=loteinicial*54;
            volumemaximo=volumeinicial*54;
           }
         if(capital>=5400 && capital<5500)
           {
            volumeoper=loteinicial*55;
            volumemaximo=volumeinicial*55;
           }
         if(capital>=5500 && capital<5600)
           {
            volumeoper=loteinicial*56;
            volumemaximo=volumeinicial*56;
           }
         if(capital>=5600 && capital<5700)
           {
            volumeoper=loteinicial*57;
            volumemaximo=volumeinicial*57;
           }
         if(capital>=5700 && capital<5800)
           {
            volumeoper=loteinicial*58;
            volumemaximo=volumeinicial*58;
           }
         if(capital>=5800 && capital<5900)
           {
            volumeoper=loteinicial*59;
            volumemaximo=volumeinicial*59;
           }
         if(capital>=5900 && capital<6000)
           {
            volumeoper=loteinicial*60;
            volumemaximo=volumeinicial*60;
           }
         if(capital>=6000 && capital<6100)
           {
            volumeoper=loteinicial*61;
            volumemaximo=volumeinicial*61;
           }
         if(capital>=6100 && capital<6200)
           {
            volumeoper=loteinicial*62;
            volumemaximo=volumeinicial*62;
           }
         if(capital>=6200 && capital<6300)
           {
            volumeoper=loteinicial*63;
            volumemaximo=volumeinicial*63;
           }
         if(capital>=6300 && capital<6400)
           {
            volumeoper=loteinicial*64;
            volumemaximo=volumeinicial*64;
           }
         if(capital>=6400 && capital<6500)
           {
            volumeoper=loteinicial*65;
            volumemaximo=volumeinicial*65;
           }
         if(capital>=6500 && capital<6600)
           {
            volumeoper=loteinicial*66;
            volumemaximo=volumeinicial*66;
           }
         if(capital>=6600 && capital<6700)
           {
            volumeoper=loteinicial*67;
            volumemaximo=volumeinicial*67;
           }
         if(capital>=6700 && capital<6800)
           {
            volumeoper=loteinicial*68;
            volumemaximo=volumeinicial*68;
           }
         if(capital>=6800 && capital<6900)
           {
            volumeoper=loteinicial*69;
            volumemaximo=volumeinicial*69;
           }
         if(capital>=6900 && capital<7000)
           {
            volumeoper=loteinicial*70;
            volumemaximo=volumeinicial*70;
           }
         if(capital>=7000 && capital<7100)
           {
            volumeoper=loteinicial*71;
            volumemaximo=volumeinicial*71;
           }
         if(capital>=7100 && capital<7200)
           {
            volumeoper=loteinicial*72;
            volumemaximo=volumeinicial*72;
           }
         if(capital>=7200 && capital<7300)
           {
            volumeoper=loteinicial*73;
            volumemaximo=volumeinicial*73;
           }
         if(capital>=7300 && capital<7400)
           {
            volumeoper=loteinicial*74;
            volumemaximo=volumeinicial*74;
           }
         if(capital>=7400 && capital<7500)
           {
            volumeoper=loteinicial*75;
            volumemaximo=volumeinicial*75;
           }
         if(capital>=7500 && capital<7600)
           {
            volumeoper=loteinicial*76;
            volumemaximo=volumeinicial*76;
           }
         if(capital>=7600 && capital<7700)
           {
            volumeoper=loteinicial*77;
            volumemaximo=volumeinicial*77;
           }
         if(capital>=7700 && capital<7800)
           {
            volumeoper=loteinicial*78;
            volumemaximo=volumeinicial*78;
           }
         if(capital>=7800 && capital<7900)
           {
            volumeoper=loteinicial*79;
            volumemaximo=volumeinicial*79;
           }
         if(capital>=7900 && capital<8000)
           {
            volumeoper=loteinicial*80;
            volumemaximo=volumeinicial*80;
           }
         if(capital>=8000 && capital<8100)
           {
            volumeoper=loteinicial*81;
            volumemaximo=volumeinicial*81;
           }
         if(capital>=8100 && capital<8200)
           {
            volumeoper=loteinicial*82;
            volumemaximo=volumeinicial*82;
           }
         if(capital>=8200 && capital<8300)
           {
            volumeoper=loteinicial*83;
            volumemaximo=volumeinicial*83;
           }
         if(capital>=8300 && capital<8400)
           {
            volumeoper=loteinicial*84;
            volumemaximo=volumeinicial*84;
           }
         if(capital>=8400 && capital<8500)
           {
            volumeoper=loteinicial*85;
            volumemaximo=volumeinicial*85;
           }
         if(capital>=8500 && capital<8600)
           {
            volumeoper=loteinicial*86;
            volumemaximo=volumeinicial*86;
           }
         if(capital>=8600 && capital<8700)
           {
            volumeoper=loteinicial*87;
            volumemaximo=volumeinicial*87;
           }
         if(capital>=8700 && capital<8800)
           {
            volumeoper=loteinicial*88;
            volumemaximo=volumeinicial*88;
           }
         if(capital>=8800 && capital<8900)
           {
            volumeoper=loteinicial*89;
            volumemaximo=volumeinicial*89;
           }
         if(capital>=8900 && capital<9000)
           {
            volumeoper=loteinicial*90;
            volumemaximo=volumeinicial*90;
           }
         if(capital>=9000 && capital<9100)
           {
            volumeoper=loteinicial*91;
            volumemaximo=volumeinicial*91;
           }
         if(capital>=9100 && capital<9200)
           {
            volumeoper=loteinicial*92;
            volumemaximo=volumeinicial*92;
           }
         if(capital>=9200 && capital<9300)
           {
            volumeoper=loteinicial*93;
            volumemaximo=volumeinicial*93;
           }
         if(capital>=9300 && capital<9400)
           {
            volumeoper=loteinicial*94;
            volumemaximo=volumeinicial*94;
           }
         if(capital>=9400 && capital<9500)
           {
            volumeoper=loteinicial*95;
            volumemaximo=volumeinicial*95;
           }
         if(capital>=9500 && capital<9600)
           {
            volumeoper=loteinicial*96;
            volumemaximo=volumeinicial*96;
           }
         if(capital>=9600 && capital<9700)
           {
            volumeoper=loteinicial*97;
            volumemaximo=volumeinicial*97;
           }
         if(capital>=9700 && capital<9800)
           {
            volumeoper=loteinicial*98;
            volumemaximo=volumeinicial*98;
           }
         if(capital>=9800 && capital<9900)
           {
            volumeoper=loteinicial*99;
            volumemaximo=volumeinicial*99;
           }
         if(capital>=9900 && capital<10000)
           {
            volumeoper=loteinicial*100;
            volumemaximo=volumeinicial*100;
           }
         if(capital>=10000 && capital<10100)
           {
            volumeoper=loteinicial*101;
            volumemaximo=volumeinicial*101;
           }
         if(capital>=10100 && capital<10200)
           {
            volumeoper=loteinicial*102;
            volumemaximo=volumeinicial*102;
           }
         if(capital>=10200 && capital<10300)
           {
            volumeoper=loteinicial*103;
            volumemaximo=volumeinicial*103;
           }
         if(capital>=10300 && capital<10400)
           {
            volumeoper=loteinicial*104;
            volumemaximo=volumeinicial*206;
           }
         if(capital>=10400 && capital<10500)
           {
            volumeoper=loteinicial*105;
            volumemaximo=volumeinicial*208;
           }
         if(capital>=10500 && capital<10600)
           {
            volumeoper=loteinicial*106;
            volumemaximo=volumeinicial*210;
           }
         if(capital>=10600 && capital<10700)
           {
            volumeoper=loteinicial*107;
            volumemaximo=volumeinicial*212;
           }
         if(capital>=10700 && capital<10800)
           {
            volumeoper=loteinicial*108;
            volumemaximo=volumeinicial*214;
           }
         if(capital>=10800 && capital<10900)
           {
            volumeoper=loteinicial*109;
            volumemaximo=volumeinicial*216;
           }
         if(capital>=10900 && capital<11000)
           {
            volumeoper=loteinicial*110;
            volumemaximo=volumeinicial*218;
           }
         if(capital>=11000 && capital<11100)
           {
            volumeoper=loteinicial*111;
            volumemaximo=volumeinicial*220;
           }
         if(capital>=11100 && capital<11200)
           {
            volumeoper=loteinicial*112;
            volumemaximo=volumeinicial*222;
           }
         if(capital>=11200 && capital<11300)
           {
            volumeoper=loteinicial*113;
            volumemaximo=volumeinicial*224;
           }
         if(capital>=11300 && capital<11400)
           {
            volumeoper=loteinicial*114;
            volumemaximo=volumeinicial*226;
           }
         if(capital>=11400 && capital<11500)
           {
            volumeoper=loteinicial*115;
            volumemaximo=volumeinicial*228;
           }
         if(capital>=11500 && capital<11600)
           {
            volumeoper=loteinicial*116;
            volumemaximo=volumeinicial*230;
           }
         if(capital>=11600 && capital<11700)
           {
            volumeoper=loteinicial*117;
            volumemaximo=volumeinicial*232;
           }
         if(capital>=11700 && capital<11800)
           {
            volumeoper=loteinicial*118;
            volumemaximo=volumeinicial*234;
           }
         if(capital>=11800 && capital<11900)
           {
            volumeoper=loteinicial*119;
            volumemaximo=volumeinicial*236;
           }
         if(capital>=11900 && capital<12000)
           {
            volumeoper=loteinicial*120;
            volumemaximo=volumeinicial*238;
           }
         if(capital>=12000 && capital<12100)
           {
            volumeoper=loteinicial*121;
            volumemaximo=volumeinicial*240;
           }
         if(capital>=12100 && capital<12200)
           {
            volumeoper=loteinicial*122;
            volumemaximo=volumeinicial*242;
           }
         if(capital>=12200 && capital<12300)
           {
            volumeoper=loteinicial*123;
            volumemaximo=volumeinicial*244;
           }
         if(capital>=12300 && capital<12400)
           {
            volumeoper=loteinicial*124;
            volumemaximo=volumeinicial*246;
           }
         if(capital>=12400 && capital<12500)
           {
            volumeoper=loteinicial*125;
            volumemaximo=volumeinicial*248;
           }
         if(capital>=12500 && capital<12600)
           {
            volumeoper=loteinicial*126;
            volumemaximo=volumeinicial*250;
           }
         if(capital>=12600 && capital<12700)
           {
            volumeoper=loteinicial*127;
            volumemaximo=volumeinicial*252;
           }
         if(capital>=12700 && capital<12800)
           {
            volumeoper=loteinicial*128;
            volumemaximo=volumeinicial*254;
           }
         if(capital>=12800 && capital<12900)
           {
            volumeoper=loteinicial*129;
            volumemaximo=volumeinicial*256;
           }
         if(capital>=12900 && capital<13000)
           {
            volumeoper=loteinicial*130;
            volumemaximo=volumeinicial*258;
           }
         if(capital>=13000 && capital<13100)
           {
            volumeoper=loteinicial*131;
            volumemaximo=volumeinicial*260;
           }
         if(capital>=13100 && capital<13200)
           {
            volumeoper=loteinicial*132;
            volumemaximo=volumeinicial*262;
           }
         if(capital>=13200 && capital<13300)
           {
            volumeoper=loteinicial*133;
            volumemaximo=volumeinicial*264;
           }
         if(capital>=13300 && capital<13400)
           {
            volumeoper=loteinicial*134;
            volumemaximo=volumeinicial*266;
           }
         if(capital>=13400 && capital<13500)
           {
            volumeoper=loteinicial*135;
            volumemaximo=volumeinicial*268;
           }
         if(capital>=13500 && capital<13600)
           {
            volumeoper=loteinicial*136;
            volumemaximo=volumeinicial*270;
           }
         if(capital>=13600 && capital<13700)
           {
            volumeoper=loteinicial*137;
            volumemaximo=volumeinicial*272;
           }
         if(capital>=13700 && capital<13800)
           {
            volumeoper=loteinicial*138;
            volumemaximo=volumeinicial*274;
           }
         if(capital>=13800 && capital<13900)
           {
            volumeoper=loteinicial*139;
            volumemaximo=volumeinicial*276;
           }
         if(capital>=13900 && capital<14000)
           {
            volumeoper=loteinicial*140;
            volumemaximo=volumeinicial*278;
           }
         if(capital>=14000 && capital<14100)
           {
            volumeoper=loteinicial*141;
            volumemaximo=volumeinicial*280;
           }
         if(capital>=14100 && capital<14200)
           {
            volumeoper=loteinicial*142;
            volumemaximo=volumeinicial*282;
           }
         if(capital>=14200 && capital<14300)
           {
            volumeoper=loteinicial*143;
            volumemaximo=volumeinicial*284;
           }
         if(capital>=14300 && capital<14400)
           {
            volumeoper=loteinicial*144;
            volumemaximo=volumeinicial*286;
           }
         if(capital>=14400 && capital<14500)
           {
            volumeoper=loteinicial*145;
            volumemaximo=volumeinicial*288;
           }
         if(capital>=14500 && capital<14600)
           {
            volumeoper=loteinicial*146;
            volumemaximo=volumeinicial*290;
           }
         if(capital>=14600 && capital<14700)
           {
            volumeoper=loteinicial*147;
            volumemaximo=volumeinicial*292;
           }
         if(capital>=14700 && capital<14800)
           {
            volumeoper=loteinicial*148;
            volumemaximo=volumeinicial*294;
           }
         if(capital>=14800 && capital<14900)
           {
            volumeoper=loteinicial*149;
            volumemaximo=volumeinicial*296;
           }
         if(capital>=14900 && capital<15000)
           {
            volumeoper=loteinicial*150;
            volumemaximo=volumeinicial*298;
           }
         if(capital>=15000 && capital<15100)
           {
            volumeoper=loteinicial*151;
            volumemaximo=volumeinicial*300;
           }
         if(capital>=15100 && capital<15200)
           {
            volumeoper=loteinicial*152;
            volumemaximo=volumeinicial*302;
           }
         if(capital>=15200 && capital<15300)
           {
            volumeoper=loteinicial*153;
            volumemaximo=volumeinicial*304;
           }
         if(capital>=15300 && capital<15400)
           {
            volumeoper=loteinicial*154;
            volumemaximo=volumeinicial*306;
           }
         if(capital>=15400 && capital<15500)
           {
            volumeoper=loteinicial*155;
            volumemaximo=volumeinicial*308;
           }
         if(capital>=15500 && capital<15600)
           {
            volumeoper=loteinicial*156;
            volumemaximo=volumeinicial*310;
           }
         if(capital>=15600 && capital<15700)
           {
            volumeoper=loteinicial*157;
            volumemaximo=volumeinicial*312;
           }
         if(capital>=15700 && capital<15800)
           {
            volumeoper=loteinicial*158;
            volumemaximo=volumeinicial*314;
           }
         if(capital>=15800 && capital<15900)
           {
            volumeoper=loteinicial*159;
            volumemaximo=volumeinicial*316;
           }
         if(capital>=15900 && capital<16000)
           {
            volumeoper=loteinicial*160;
            volumemaximo=volumeinicial*318;
           }
         if(capital>=16000 && capital<16100)
           {
            volumeoper=loteinicial*161;
            volumemaximo=volumeinicial*320;
           }
         if(capital>=16100 && capital<16200)
           {
            volumeoper=loteinicial*162;
            volumemaximo=volumeinicial*322;
           }
         if(capital>=16200 && capital<16300)
           {
            volumeoper=loteinicial*163;
            volumemaximo=volumeinicial*324;
           }
         if(capital>=16300 && capital<16400)
           {
            volumeoper=loteinicial*164;
            volumemaximo=volumeinicial*326;
           }
         if(capital>=16400 && capital<16500)
           {
            volumeoper=loteinicial*165;
            volumemaximo=volumeinicial*328;
           }
         if(capital>=16500 && capital<16600)
           {
            volumeoper=loteinicial*166;
            volumemaximo=volumeinicial*330;
           }
         if(capital>=16600 && capital<16700)
           {
            volumeoper=loteinicial*167;
            volumemaximo=volumeinicial*332;
           }
         if(capital>=16700 && capital<16800)
           {
            volumeoper=loteinicial*168;
            volumemaximo=volumeinicial*334;
           }
         if(capital>=16800 && capital<16900)
           {
            volumeoper=loteinicial*169;
            volumemaximo=volumeinicial*336;
           }
         if(capital>=16900 && capital<17000)
           {
            volumeoper=loteinicial*170;
            volumemaximo=volumeinicial*338;
           }
         if(capital>=17000 && capital<17100)
           {
            volumeoper=loteinicial*171;
            volumemaximo=volumeinicial*340;
           }
         if(capital>=17100 && capital<17200)
           {
            volumeoper=loteinicial*172;
            volumemaximo=volumeinicial*342;
           }
         if(capital>=17200 && capital<17300)
           {
            volumeoper=loteinicial*173;
            volumemaximo=volumeinicial*344;
           }
         if(capital>=17300 && capital<17400)
           {
            volumeoper=loteinicial*174;
            volumemaximo=volumeinicial*346;
           }
         if(capital>=17400 && capital<17500)
           {
            volumeoper=loteinicial*175;
            volumemaximo=volumeinicial*348;
           }
         if(capital>=17500 && capital<17600)
           {
            volumeoper=loteinicial*176;
            volumemaximo=volumeinicial*350;
           }
         if(capital>=17600 && capital<17700)
           {
            volumeoper=loteinicial*177;
            volumemaximo=volumeinicial*352;
           }
         if(capital>=17700 && capital<17800)
           {
            volumeoper=loteinicial*178;
            volumemaximo=volumeinicial*354;
           }
         if(capital>=17800 && capital<17900)
           {
            volumeoper=loteinicial*179;
            volumemaximo=volumeinicial*356;
           }
         if(capital>=17900 && capital<18000)
           {
            volumeoper=loteinicial*180;
            volumemaximo=volumeinicial*358;
           }
         if(capital>=18000 && capital<18100)
           {
            volumeoper=loteinicial*181;
            volumemaximo=volumeinicial*360;
           }
         if(capital>=18100 && capital<18200)
           {
            volumeoper=loteinicial*182;
            volumemaximo=volumeinicial*362;
           }
         if(capital>=18200 && capital<18300)
           {
            volumeoper=loteinicial*183;
            volumemaximo=volumeinicial*364;
           }
         if(capital>=18300 && capital<18400)
           {
            volumeoper=loteinicial*184;
            volumemaximo=volumeinicial*366;
           }
         if(capital>=18400 && capital<18500)
           {
            volumeoper=loteinicial*185;
            volumemaximo=volumeinicial*368;
           }
         if(capital>=18500 && capital<18600)
           {
            volumeoper=loteinicial*186;
            volumemaximo=volumeinicial*370;
           }
         if(capital>=18600 && capital<18700)
           {
            volumeoper=loteinicial*187;
            volumemaximo=volumeinicial*372;
           }
         if(capital>=18700 && capital<18800)
           {
            volumeoper=loteinicial*188;
            volumemaximo=volumeinicial*374;
           }
         if(capital>=18800 && capital<18900)
           {
            volumeoper=loteinicial*189;
            volumemaximo=volumeinicial*376;
           }
         if(capital>=18900 && capital<19000)
           {
            volumeoper=loteinicial*190;
            volumemaximo=volumeinicial*378;
           }
         if(capital>=19000 && capital<19100)
           {
            volumeoper=loteinicial*191;
            volumemaximo=volumeinicial*80;
           }
         if(capital>=19100 && capital<19200)
           {
            volumeoper=loteinicial*192;
            volumemaximo=volumeinicial*382;
           }
         if(capital>=19200 && capital<19300)
           {
            volumeoper=loteinicial*193;
            volumemaximo=volumeinicial*384;
           }
         if(capital>=19300 && capital<19400)
           {
            volumeoper=loteinicial*194;
            volumemaximo=volumeinicial*386;
           }
         if(capital>=19400 && capital<19500)
           {
            volumeoper=loteinicial*195;
            volumemaximo=volumeinicial*388;
           }
         if(capital>=19500 && capital<19600)
           {
            volumeoper=loteinicial*196;
            volumemaximo=volumeinicial*390;
           }
         if(capital>=19600 && capital<19700)
           {
            volumeoper=loteinicial*197;
            volumemaximo=volumeinicial*392;
           }
         if(capital>=19700 && capital<19800)
           {
            volumeoper=loteinicial*198;
            volumemaximo=volumeinicial*394;
           }
         if(capital>=19800 && capital<19900)
           {
            volumeoper=loteinicial*199;
            volumemaximo=volumeinicial*396;
           }
         if(capital>=19900 && capital<20000)
           {
            volumeoper=loteinicial*200;
            volumemaximo=volumeinicial*398;
           }
         if(capital>=20000 && capital<20100)
           {
            volumeoper=loteinicial*201;
            volumemaximo=volumeinicial*400;
           }
         if(capital>=20100 && capital<20200)
           {
            volumeoper=loteinicial*202;
            volumemaximo=volumeinicial*402;
           }
         if(capital>=20200 && capital<20300)
           {
            volumeoper=loteinicial*203;
            volumemaximo=volumeinicial*404;
           }
         if(capital>=20300 && capital<20400)
           {
            volumeoper=loteinicial*204;
            volumemaximo=volumeinicial*406;
           }
         if(capital>=20400 && capital<20500)
           {
            volumeoper=loteinicial*205;
            volumemaximo=volumeinicial*408;
           }
         if(capital>=20500 && capital<20600)
           {
            volumeoper=loteinicial*206;
            volumemaximo=volumeinicial*410;
           }
         if(capital>=20600 && capital<20700)
           {
            volumeoper=loteinicial*207;
            volumemaximo=volumeinicial*412;
           }
         if(capital>=20700 && capital<20800)
           {
            volumeoper=loteinicial*208;
            volumemaximo=volumeinicial*414;
           }
         if(capital>=20800 && capital<20900)
           {
            volumeoper=loteinicial*209;
            volumemaximo=volumeinicial*416;
           }
         if(capital>=20900 && capital<21000)
           {
            volumeoper=loteinicial*210;
            volumemaximo=volumeinicial*418;
           }
         if(capital>=21000 && capital<21100)
           {
            volumeoper=loteinicial*211;
            volumemaximo=volumeinicial*420;
           }
         if(capital>=21100 && capital<21200)
           {
            volumeoper=loteinicial*212;
            volumemaximo=volumeinicial*422;
           }
         if(capital>=21200 && capital<21300)
           {
            volumeoper=loteinicial*213;
            volumemaximo=volumeinicial*424;
           }
         if(capital>=21300 && capital<21400)
           {
            volumeoper=loteinicial*214;
            volumemaximo=volumeinicial*426;
           }
         if(capital>=21400 && capital<21500)
           {
            volumeoper=loteinicial*215;
            volumemaximo=volumeinicial*428;
           }
         if(capital>=21500 && capital<21600)
           {
            volumeoper=loteinicial*216;
            volumemaximo=volumeinicial*430;
           }
         if(capital>=21600 && capital<21700)
           {
            volumeoper=loteinicial*217;
            volumemaximo=volumeinicial*432;
           }
         if(capital>=21700 && capital<21800)
           {
            volumeoper=loteinicial*218;
            volumemaximo=volumeinicial*434;
           }
         if(capital>=21800 && capital<21900)
           {
            volumeoper=loteinicial*219;
            volumemaximo=volumeinicial*436;
           }
         if(capital>=21900 && capital<22000)
           {
            volumeoper=loteinicial*220;
            volumemaximo=volumeinicial*438;
           }
         if(capital>=22000 && capital<22100)
           {
            volumeoper=loteinicial*221;
            volumemaximo=volumeinicial*440;
           }
         if(capital>=22100 && capital<22200)
           {
            volumeoper=loteinicial*222;
            volumemaximo=volumeinicial*442;
           }
         if(capital>=22200 && capital<22300)
           {
            volumeoper=loteinicial*223;
            volumemaximo=volumeinicial*444;
           }
         if(capital>=22300 && capital<22400)
           {
            volumeoper=loteinicial*224;
            volumemaximo=volumeinicial*446;
           }
         if(capital>=22400 && capital<22500)
           {
            volumeoper=loteinicial*225;
            volumemaximo=volumeinicial*448;
           }
         if(capital>=22500 && capital<22600)
           {
            volumeoper=loteinicial*226;
            volumemaximo=volumeinicial*450;
           }
         if(capital>=22600 && capital<22700)
           {
            volumeoper=loteinicial*227;
            volumemaximo=volumeinicial*452;
           }
         if(capital>=22700 && capital<22800)
           {
            volumeoper=loteinicial*228;
            volumemaximo=volumeinicial*454;
           }
         if(capital>=22800 && capital<22900)
           {
            volumeoper=loteinicial*229;
            volumemaximo=volumeinicial*456;
           }
         if(capital>=22900 && capital<23000)
           {
            volumeoper=loteinicial*230;
            volumemaximo=volumeinicial*458;
           }
         if(capital>=23000 && capital<23100)
           {
            volumeoper=loteinicial*231;
            volumemaximo=volumeinicial*460;
           }
         if(capital>=23100 && capital<23200)
           {
            volumeoper=loteinicial*232;
            volumemaximo=volumeinicial*462;
           }
         if(capital>=23200 && capital<23300)
           {
            volumeoper=loteinicial*233;
            volumemaximo=volumeinicial*464;
           }
         if(capital>=23300 && capital<23400)
           {
            volumeoper=loteinicial*234;
            volumemaximo=volumeinicial*466;
           }
         if(capital>=23400 && capital<23500)
           {
            volumeoper=loteinicial*235;
            volumemaximo=volumeinicial*468;
           }
         if(capital>=23500 && capital<23600)
           {
            volumeoper=loteinicial*236;
            volumemaximo=volumeinicial*470;
           }
         if(capital>=23600 && capital<23700)
           {
            volumeoper=loteinicial*237;
            volumemaximo=volumeinicial*472;
           }
         if(capital>=23700 && capital<23800)
           {
            volumeoper=loteinicial*238;
            volumemaximo=volumeinicial*474;
           }
         if(capital>=23800 && capital<23900)
           {
            volumeoper=loteinicial*239;
            volumemaximo=volumeinicial*476;
           }
         if(capital>=23900 && capital<24000)
           {
            volumeoper=loteinicial*240;
            volumemaximo=volumeinicial*478;
           }
         if(capital>=24000 && capital<24100)
           {
            volumeoper=loteinicial*241;
            volumemaximo=volumeinicial*480;
           }
         if(capital>=24100 && capital<24200)
           {
            volumeoper=loteinicial*242;
            volumemaximo=volumeinicial*482;
           }
         if(capital>=24200 && capital<24300)
           {
            volumeoper=loteinicial*243;
            volumemaximo=volumeinicial*484;
           }
         if(capital>=24300 && capital<24400)
           {
            volumeoper=loteinicial*244;
            volumemaximo=volumeinicial*486;
           }
         if(capital>=24400 && capital<24500)
           {
            volumeoper=loteinicial*245;
            volumemaximo=volumeinicial*488;
           }
         if(capital>=24500 && capital<24600)
           {
            volumeoper=loteinicial*246;
            volumemaximo=volumeinicial*490;
           }
         if(capital>=24600 && capital<24700)
           {
            volumeoper=loteinicial*247;
            volumemaximo=volumeinicial*492;
           }
         if(capital>=24700 && capital<24800)
           {
            volumeoper=loteinicial*248;
            volumemaximo=volumeinicial*494;
           }
         if(capital>=24800 && capital<24900)
           {
            volumeoper=loteinicial*249;
            volumemaximo=volumeinicial*496;
           }
         if(capital>=24900 && capital<25000)
           {
            volumeoper=loteinicial*250;
            volumemaximo=volumeinicial*498;
           }
         if(capital>=25000 && capital<25100)
           {
            volumeoper=loteinicial*251;
            volumemaximo=volumeinicial*500;
           }
         if(capital>=25100 && capital<25200)
           {
            volumeoper=loteinicial*252;
            volumemaximo=volumeinicial*502;
           }
         if(capital>=25200 && capital<25300)
           {
            volumeoper=loteinicial*253;
            volumemaximo=volumeinicial*504;
           }
         if(capital>=25300 && capital<25400)
           {
            volumeoper=loteinicial*254;
            volumemaximo=volumeinicial*506;
           }
         if(capital>=25400 && capital<25500)
           {
            volumeoper=loteinicial*255;
            volumemaximo=volumeinicial*508;
           }
         if(capital>=25500 && capital<25600)
           {
            volumeoper=loteinicial*256;
            volumemaximo=volumeinicial*510;
           }
         if(capital>=25600 && capital<25700)
           {
            volumeoper=loteinicial*257;
            volumemaximo=volumeinicial*512;
           }
         if(capital>=25700 && capital<25800)
           {
            volumeoper=loteinicial*258;
            volumemaximo=volumeinicial*514;
           }
         if(capital>=25800 && capital<25900)
           {
            volumeoper=loteinicial*259;
            volumemaximo=volumeinicial*516;
           }
         if(capital>=25900 && capital<26000)
           {
            volumeoper=loteinicial*260;
            volumemaximo=volumeinicial*518;
           }
         if(capital>=26000 && capital<26100)
           {
            volumeoper=loteinicial*261;
            volumemaximo=volumeinicial*520;
           }
         if(capital>=26100 && capital<26200)
           {
            volumeoper=loteinicial*262;
            volumemaximo=volumeinicial*522;
           }
         if(capital>=26200 && capital<26300)
           {
            volumeoper=loteinicial*263;
            volumemaximo=volumeinicial*524;
           }
         if(capital>=26300 && capital<26400)
           {
            volumeoper=loteinicial*264;
            volumemaximo=volumeinicial*526;
           }
         if(capital>=26400 && capital<26500)
           {
            volumeoper=loteinicial*265;
            volumemaximo=volumeinicial*528;
           }
         if(capital>=26500 && capital<26600)
           {
            volumeoper=loteinicial*266;
            volumemaximo=volumeinicial*530;
           }
         if(capital>=26600 && capital<26700)
           {
            volumeoper=loteinicial*267;
            volumemaximo=volumeinicial*532;
           }
         if(capital>=26700 && capital<26800)
           {
            volumeoper=loteinicial*268;
            volumemaximo=volumeinicial*534;
           }
         if(capital>=26800 && capital<26900)
           {
            volumeoper=loteinicial*269;
            volumemaximo=volumeinicial*536;
           }
         if(capital>=26900 && capital<27000)
           {
            volumeoper=loteinicial*270;
            volumemaximo=volumeinicial*538;
           }
         if(capital>=27000 && capital<27100)
           {
            volumeoper=loteinicial*271;
            volumemaximo=volumeinicial*540;
           }
         if(capital>=27100 && capital<27200)
           {
            volumeoper=loteinicial*272;
            volumemaximo=volumeinicial*542;
           }
         if(capital>=27200 && capital<27300)
           {
            volumeoper=loteinicial*273;
            volumemaximo=volumeinicial*544;
           }
         if(capital>=27300 && capital<27400)
           {
            volumeoper=loteinicial*274;
            volumemaximo=volumeinicial*546;
           }
         if(capital>=27400 && capital<27500)
           {
            volumeoper=loteinicial*275;
            volumemaximo=volumeinicial*548;
           }
         if(capital>=27500 && capital<27600)
           {
            volumeoper=loteinicial*276;
            volumemaximo=volumeinicial*550;
           }
         if(capital>=27600 && capital<27700)
           {
            volumeoper=loteinicial*277;
            volumemaximo=volumeinicial*552;
           }
         if(capital>=27700 && capital<27800)
           {
            volumeoper=loteinicial*278;
            volumemaximo=volumeinicial*554;
           }
         if(capital>=27800 && capital<27900)
           {
            volumeoper=loteinicial*279;
            volumemaximo=volumeinicial*556;
           }
         if(capital>=27900 && capital<28000)
           {
            volumeoper=loteinicial*280;
            volumemaximo=volumeinicial*558;
           }
         if(capital>=28000 && capital<28100)
           {
            volumeoper=loteinicial*281;
            volumemaximo=volumeinicial*560;
           }
         if(capital>=28100 && capital<28200)
           {
            volumeoper=loteinicial*282;
            volumemaximo=volumeinicial*562;
           }
         if(capital>=28200 && capital<28300)
           {
            volumeoper=loteinicial*283;
            volumemaximo=volumeinicial*564;
           }
         if(capital>=28300 && capital<28400)
           {
            volumeoper=loteinicial*284;
            volumemaximo=volumeinicial*566;
           }
         if(capital>=28400 && capital<28500)
           {
            volumeoper=loteinicial*285;
            volumemaximo=volumeinicial*568;
           }
         if(capital>=28500 && capital<28600)
           {
            volumeoper=loteinicial*286;
            volumemaximo=volumeinicial*570;
           }
         if(capital>=28600 && capital<28700)
           {
            volumeoper=loteinicial*287;
            volumemaximo=volumeinicial*572;
           }
         if(capital>=28700 && capital<28800)
           {
            volumeoper=loteinicial*288;
            volumemaximo=volumeinicial*574;
           }
         if(capital>=28800 && capital<28900)
           {
            volumeoper=loteinicial*289;
            volumemaximo=volumeinicial*576;
           }
         if(capital>=28900 && capital<29000)
           {
            volumeoper=loteinicial*290;
            volumemaximo=volumeinicial*578;
           }
         if(capital>=29000 && capital<29100)
           {
            volumeoper=loteinicial*291;
            volumemaximo=volumeinicial*80;
           }
         if(capital>=29100 && capital<29200)
           {
            volumeoper=loteinicial*292;
            volumemaximo=volumeinicial*582;
           }
         if(capital>=29200 && capital<29300)
           {
            volumeoper=loteinicial*293;
            volumemaximo=volumeinicial*584;
           }
         if(capital>=29300 && capital<29400)
           {
            volumeoper=loteinicial*294;
            volumemaximo=volumeinicial*586;
           }
         if(capital>=29400 && capital<29500)
           {
            volumeoper=loteinicial*295;
            volumemaximo=volumeinicial*588;
           }
         if(capital>=29500 && capital<29600)
           {
            volumeoper=loteinicial*296;
            volumemaximo=volumeinicial*590;
           }
         if(capital>=29600 && capital<29700)
           {
            volumeoper=loteinicial*297;
            volumemaximo=volumeinicial*592;
           }
         if(capital>=29700 && capital<29800)
           {
            volumeoper=loteinicial*298;
            volumemaximo=volumeinicial*594;
           }
         if(capital>=29800 && capital<29900)
           {
            volumeoper=loteinicial*299;
            volumemaximo=volumeinicial*596;
           }
         if(capital>=29900 && capital<30000)
           {
            volumeoper=loteinicial*300;
            volumemaximo=volumeinicial*598;
           }
        }

      if(nivellote==vollv_full)
        {
         if(capital>=50 && capital<98)
           {
            volumeoper=loteinicial;
            volumemaximo=volumeinicial;
           }
         if(capital>=98 && capital<200)
           {
            volumeoper=loteinicial*2;
            volumemaximo=volumeinicial*2;
           }
         if(capital>=200 && capital<300)
           {
            volumeoper=loteinicial*4;
            volumemaximo=volumeinicial*4;
           }
         if(capital>=300 && capital<400)
           {
            volumeoper=loteinicial*6;
            volumemaximo=volumeinicial*6;
           }
         if(capital>=400 && capital<500)
           {
            volumeoper=loteinicial*8;
            volumemaximo=volumeinicial*8;
           }
         if(capital>=500 && capital<600)
           {
            volumeoper=loteinicial*10;
            volumemaximo=volumeinicial*10;
           }
         if(capital>=600 && capital<700)
           {
            volumeoper=loteinicial*12;
            volumemaximo=volumeinicial*12;
           }
         if(capital>=700 && capital<800)
           {
            volumeoper=loteinicial*14;
            volumemaximo=volumeinicial*14;
           }
         if(capital>=800 && capital<900)
           {
            volumeoper=loteinicial*16;
            volumemaximo=volumeinicial*16;
           }
         if(capital>=900 && capital<1000)
           {
            volumeoper=loteinicial*18;
            volumemaximo=volumeinicial*18;
           }
         if(capital>=1000 && capital<1100)
           {
            volumeoper=loteinicial*20;
            volumemaximo=volumeinicial*20;
           }
         if(capital>=1100 && capital<1200)
           {
            volumeoper=loteinicial*22;
            volumemaximo=volumeinicial*22;
           }
         if(capital>=1200 && capital<1300)
           {
            volumeoper=loteinicial*24;
            volumemaximo=volumeinicial*24;
           }
         if(capital>=1300 && capital<1400)
           {
            volumeoper=loteinicial*26;
            volumemaximo=volumeinicial*26;
           }
         if(capital>=1400 && capital<1500)
           {
            volumeoper=loteinicial*28;
            volumemaximo=volumeinicial*28;
           }
         if(capital>=1500 && capital<1600)
           {
            volumeoper=loteinicial*30;
            volumemaximo=volumeinicial*30;
           }
         if(capital>=1600 && capital<1700)
           {
            volumeoper=loteinicial*32;
            volumemaximo=volumeinicial*32;
           }
         if(capital>=1700 && capital<1800)
           {
            volumeoper=loteinicial*34;
            volumemaximo=volumeinicial*34;
           }
         if(capital>=1800 && capital<1900)
           {
            volumeoper=loteinicial*36;
            volumemaximo=volumeinicial*36;
           }
         if(capital>=1900 && capital<2000)
           {
            volumeoper=loteinicial*38;
            volumemaximo=volumeinicial*38;
           }
         if(capital>=2000 && capital<2100)
           {
            volumeoper=loteinicial*40;
            volumemaximo=volumeinicial*40;
           }
         if(capital>=2100 && capital<2200)
           {
            volumeoper=loteinicial*42;
            volumemaximo=volumeinicial*42;
           }
         if(capital>=2200 && capital<2300)
           {
            volumeoper=loteinicial*44;
            volumemaximo=volumeinicial*44;
           }
         if(capital>=2300 && capital<2400)
           {
            volumeoper=loteinicial*46;
            volumemaximo=volumeinicial*46;
           }
         if(capital>=2400 && capital<2500)
           {
            volumeoper=loteinicial*48;
            volumemaximo=volumeinicial*48;
           }
         if(capital>=2500 && capital<2600)
           {
            volumeoper=loteinicial*50;
            volumemaximo=volumeinicial*50;
           }
         if(capital>=2600 && capital<2700)
           {
            volumeoper=loteinicial*52;
            volumemaximo=volumeinicial*52;
           }
         if(capital>=2700 && capital<2800)
           {
            volumeoper=loteinicial*54;
            volumemaximo=volumeinicial*54;
           }
         if(capital>=2800 && capital<2900)
           {
            volumeoper=loteinicial*56;
            volumemaximo=volumeinicial*56;
           }
         if(capital>=2900 && capital<3000)
           {
            volumeoper=loteinicial*58;
            volumemaximo=volumeinicial*58;
           }
         if(capital>=3000 && capital<3100)
           {
            volumeoper=loteinicial*60;
            volumemaximo=volumeinicial*60;
           }
         if(capital>=3100 && capital<3200)
           {
            volumeoper=loteinicial*62;
            volumemaximo=volumeinicial*62;
           }
         if(capital>=3200 && capital<3300)
           {
            volumeoper=loteinicial*64;
            volumemaximo=volumeinicial*64;
           }
         if(capital>=3300 && capital<3400)
           {
            volumeoper=loteinicial*66;
            volumemaximo=volumeinicial*66;
           }
         if(capital>=3400 && capital<3500)
           {
            volumeoper=loteinicial*68;
            volumemaximo=volumeinicial*68;
           }
         if(capital>=3500 && capital<3600)
           {
            volumeoper=loteinicial*70;
            volumemaximo=volumeinicial*70;
           }
         if(capital>=3600 && capital<3700)
           {
            volumeoper=loteinicial*72;
            volumemaximo=volumeinicial*72;
           }
         if(capital>=3700 && capital<3800)
           {
            volumeoper=loteinicial*74;
            volumemaximo=volumeinicial*74;
           }
         if(capital>=3800 && capital<3900)
           {
            volumeoper=loteinicial*76;
            volumemaximo=volumeinicial*76;
           }
         if(capital>=3900 && capital<4000)
           {
            volumeoper=loteinicial*78;
            volumemaximo=volumeinicial*78;
           }
         if(capital>=4000 && capital<4100)
           {
            volumeoper=loteinicial*80;
            volumemaximo=volumeinicial*80;
           }
         if(capital>=4100 && capital<4200)
           {
            volumeoper=loteinicial*82;
            volumemaximo=volumeinicial*82;
           }
         if(capital>=4200 && capital<4300)
           {
            volumeoper=loteinicial*84;
            volumemaximo=volumeinicial*84;
           }
         if(capital>=4300 && capital<4400)
           {
            volumeoper=loteinicial*86;
            volumemaximo=volumeinicial*86;
           }
         if(capital>=4400 && capital<4500)
           {
            volumeoper=loteinicial*88;
            volumemaximo=volumeinicial*88;
           }
         if(capital>=4500 && capital<4600)
           {
            volumeoper=loteinicial*90;
            volumemaximo=volumeinicial*90;
           }
         if(capital>=4600 && capital<4700)
           {
            volumeoper=loteinicial*92;
            volumemaximo=volumeinicial*92;
           }
         if(capital>=4700 && capital<4800)
           {
            volumeoper=loteinicial*94;
            volumemaximo=volumeinicial*94;
           }
         if(capital>=4800 && capital<4900)
           {
            volumeoper=loteinicial*96;
            volumemaximo=volumeinicial*96;
           }
         if(capital>=4900 && capital<5000)
           {
            volumeoper=loteinicial*98;
            volumemaximo=volumeinicial*98;
           }
         if(capital>=5000 && capital<5100)
           {
            volumeoper=loteinicial*100;
            volumemaximo=volumeinicial*100;
           }
         if(capital>=5100 && capital<5200)
           {
            volumeoper=loteinicial*102;
            volumemaximo=volumeinicial*102;
           }
         if(capital>=5200 && capital<5300)
           {
            volumeoper=loteinicial*104;
            volumemaximo=volumeinicial*104;
           }
         if(capital>=5300 && capital<5400)
           {
            volumeoper=loteinicial*106;
            volumemaximo=volumeinicial*106;
           }
         if(capital>=5400 && capital<5500)
           {
            volumeoper=loteinicial*108;
            volumemaximo=volumeinicial*108;
           }
         if(capital>=5500 && capital<5600)
           {
            volumeoper=loteinicial*110;
            volumemaximo=volumeinicial*110;
           }
         if(capital>=5600 && capital<5700)
           {
            volumeoper=loteinicial*112;
            volumemaximo=volumeinicial*112;
           }
         if(capital>=5700 && capital<5800)
           {
            volumeoper=loteinicial*114;
            volumemaximo=volumeinicial*114;
           }
         if(capital>=5800 && capital<5900)
           {
            volumeoper=loteinicial*116;
            volumemaximo=volumeinicial*116;
           }
         if(capital>=5900 && capital<6000)
           {
            volumeoper=loteinicial*118;
            volumemaximo=volumeinicial*118;
           }
         if(capital>=6000 && capital<6100)
           {
            volumeoper=loteinicial*120;
            volumemaximo=volumeinicial*120;
           }
         if(capital>=6100 && capital<6200)
           {
            volumeoper=loteinicial*122;
            volumemaximo=volumeinicial*122;
           }
         if(capital>=6200 && capital<6300)
           {
            volumeoper=loteinicial*124;
            volumemaximo=volumeinicial*124;
           }
         if(capital>=6300 && capital<6400)
           {
            volumeoper=loteinicial*126;
            volumemaximo=volumeinicial*126;
           }
         if(capital>=6400 && capital<6500)
           {
            volumeoper=loteinicial*128;
            volumemaximo=volumeinicial*128;
           }
         if(capital>=6500 && capital<6600)
           {
            volumeoper=loteinicial*130;
            volumemaximo=volumeinicial*130;
           }
         if(capital>=6600 && capital<6700)
           {
            volumeoper=loteinicial*132;
            volumemaximo=volumeinicial*132;
           }
         if(capital>=6700 && capital<6800)
           {
            volumeoper=loteinicial*134;
            volumemaximo=volumeinicial*134;
           }
         if(capital>=6800 && capital<6900)
           {
            volumeoper=loteinicial*136;
            volumemaximo=volumeinicial*136;
           }
         if(capital>=6900 && capital<7000)
           {
            volumeoper=loteinicial*138;
            volumemaximo=volumeinicial*138;
           }
         if(capital>=7000 && capital<7100)
           {
            volumeoper=loteinicial*140;
            volumemaximo=volumeinicial*140;
           }
         if(capital>=7100 && capital<7200)
           {
            volumeoper=loteinicial*142;
            volumemaximo=volumeinicial*142;
           }
         if(capital>=7200 && capital<7300)
           {
            volumeoper=loteinicial*144;
            volumemaximo=volumeinicial*144;
           }
         if(capital>=7300 && capital<7400)
           {
            volumeoper=loteinicial*146;
            volumemaximo=volumeinicial*146;
           }
         if(capital>=7400 && capital<7500)
           {
            volumeoper=loteinicial*148;
            volumemaximo=volumeinicial*148;
           }
         if(capital>=7500 && capital<7600)
           {
            volumeoper=loteinicial*150;
            volumemaximo=volumeinicial*150;
           }
         if(capital>=7600 && capital<7700)
           {
            volumeoper=loteinicial*152;
            volumemaximo=volumeinicial*152;
           }
         if(capital>=7700 && capital<7800)
           {
            volumeoper=loteinicial*154;
            volumemaximo=volumeinicial*154;
           }
         if(capital>=7800 && capital<7900)
           {
            volumeoper=loteinicial*156;
            volumemaximo=volumeinicial*156;
           }
         if(capital>=7900 && capital<8000)
           {
            volumeoper=loteinicial*158;
            volumemaximo=volumeinicial*158;
           }
         if(capital>=8000 && capital<8100)
           {
            volumeoper=loteinicial*160;
            volumemaximo=volumeinicial*160;
           }
         if(capital>=8100 && capital<8200)
           {
            volumeoper=loteinicial*162;
            volumemaximo=volumeinicial*162;
           }
         if(capital>=8200 && capital<8300)
           {
            volumeoper=loteinicial*164;
            volumemaximo=volumeinicial*164;
           }
         if(capital>=8300 && capital<8400)
           {
            volumeoper=loteinicial*166;
            volumemaximo=volumeinicial*166;
           }
         if(capital>=8400 && capital<8500)
           {
            volumeoper=loteinicial*168;
            volumemaximo=volumeinicial*168;
           }
         if(capital>=8500 && capital<8600)
           {
            volumeoper=loteinicial*170;
            volumemaximo=volumeinicial*170;
           }
         if(capital>=8600 && capital<8700)
           {
            volumeoper=loteinicial*172;
            volumemaximo=volumeinicial*172;
           }
         if(capital>=8700 && capital<8800)
           {
            volumeoper=loteinicial*174;
            volumemaximo=volumeinicial*174;
           }
         if(capital>=8800 && capital<8900)
           {
            volumeoper=loteinicial*176;
            volumemaximo=volumeinicial*176;
           }
         if(capital>=8900 && capital<9000)
           {
            volumeoper=loteinicial*178;
            volumemaximo=volumeinicial*178;
           }
         if(capital>=9000 && capital<9100)
           {
            volumeoper=loteinicial*180;
            volumemaximo=volumeinicial*80;
           }
         if(capital>=9100 && capital<9200)
           {
            volumeoper=loteinicial*182;
            volumemaximo=volumeinicial*182;
           }
         if(capital>=9200 && capital<9300)
           {
            volumeoper=loteinicial*184;
            volumemaximo=volumeinicial*184;
           }
         if(capital>=9300 && capital<9400)
           {
            volumeoper=loteinicial*186;
            volumemaximo=volumeinicial*186;
           }
         if(capital>=9400 && capital<9500)
           {
            volumeoper=loteinicial*188;
            volumemaximo=volumeinicial*188;
           }
         if(capital>=9500 && capital<9600)
           {
            volumeoper=loteinicial*190;
            volumemaximo=volumeinicial*190;
           }
         if(capital>=9600 && capital<9700)
           {
            volumeoper=loteinicial*192;
            volumemaximo=volumeinicial*192;
           }
         if(capital>=9700 && capital<9800)
           {
            volumeoper=loteinicial*194;
            volumemaximo=volumeinicial*194;
           }
         if(capital>=9800 && capital<9900)
           {
            volumeoper=loteinicial*196;
            volumemaximo=volumeinicial*196;
           }
         if(capital>=9900 && capital<10000)
           {
            volumeoper=loteinicial*198;
            volumemaximo=volumeinicial*198;
           }
         if(capital>=10000 && capital<10100)
           {
            volumeoper=loteinicial*200;
            volumemaximo=volumeinicial*200;
           }
         if(capital>=10100 && capital<10200)
           {
            volumeoper=loteinicial*202;
            volumemaximo=volumeinicial*202;
           }
         if(capital>=10200 && capital<10300)
           {
            volumeoper=loteinicial*204;
            volumemaximo=volumeinicial*204;
           }
         if(capital>=10300 && capital<10400)
           {
            volumeoper=loteinicial*206;
            volumemaximo=volumeinicial*206;
           }
         if(capital>=10400 && capital<10500)
           {
            volumeoper=loteinicial*208;
            volumemaximo=volumeinicial*208;
           }
         if(capital>=10500 && capital<10600)
           {
            volumeoper=loteinicial*210;
            volumemaximo=volumeinicial*210;
           }
         if(capital>=10600 && capital<10700)
           {
            volumeoper=loteinicial*212;
            volumemaximo=volumeinicial*212;
           }
         if(capital>=10700 && capital<10800)
           {
            volumeoper=loteinicial*214;
            volumemaximo=volumeinicial*214;
           }
         if(capital>=10800 && capital<10900)
           {
            volumeoper=loteinicial*216;
            volumemaximo=volumeinicial*216;
           }
         if(capital>=10900 && capital<11000)
           {
            volumeoper=loteinicial*218;
            volumemaximo=volumeinicial*218;
           }
         if(capital>=11000 && capital<11100)
           {
            volumeoper=loteinicial*220;
            volumemaximo=volumeinicial*220;
           }
         if(capital>=11100 && capital<11200)
           {
            volumeoper=loteinicial*222;
            volumemaximo=volumeinicial*222;
           }
         if(capital>=11200 && capital<11300)
           {
            volumeoper=loteinicial*224;
            volumemaximo=volumeinicial*224;
           }
         if(capital>=11300 && capital<11400)
           {
            volumeoper=loteinicial*226;
            volumemaximo=volumeinicial*226;
           }
         if(capital>=11400 && capital<11500)
           {
            volumeoper=loteinicial*228;
            volumemaximo=volumeinicial*228;
           }
         if(capital>=11500 && capital<11600)
           {
            volumeoper=loteinicial*230;
            volumemaximo=volumeinicial*230;
           }
         if(capital>=11600 && capital<11700)
           {
            volumeoper=loteinicial*232;
            volumemaximo=volumeinicial*232;
           }
         if(capital>=11700 && capital<11800)
           {
            volumeoper=loteinicial*234;
            volumemaximo=volumeinicial*234;
           }
         if(capital>=11800 && capital<11900)
           {
            volumeoper=loteinicial*236;
            volumemaximo=volumeinicial*236;
           }
         if(capital>=11900 && capital<12000)
           {
            volumeoper=loteinicial*238;
            volumemaximo=volumeinicial*238;
           }
         if(capital>=12000 && capital<12100)
           {
            volumeoper=loteinicial*240;
            volumemaximo=volumeinicial*240;
           }
         if(capital>=12100 && capital<12200)
           {
            volumeoper=loteinicial*242;
            volumemaximo=volumeinicial*242;
           }
         if(capital>=12200 && capital<12300)
           {
            volumeoper=loteinicial*244;
            volumemaximo=volumeinicial*244;
           }
         if(capital>=12300 && capital<12400)
           {
            volumeoper=loteinicial*246;
            volumemaximo=volumeinicial*246;
           }
         if(capital>=12400 && capital<12500)
           {
            volumeoper=loteinicial*248;
            volumemaximo=volumeinicial*248;
           }
         if(capital>=12500 && capital<12600)
           {
            volumeoper=loteinicial*250;
            volumemaximo=volumeinicial*250;
           }
         if(capital>=12600 && capital<12700)
           {
            volumeoper=loteinicial*252;
            volumemaximo=volumeinicial*252;
           }
         if(capital>=12700 && capital<12800)
           {
            volumeoper=loteinicial*254;
            volumemaximo=volumeinicial*254;
           }
         if(capital>=12800 && capital<12900)
           {
            volumeoper=loteinicial*256;
            volumemaximo=volumeinicial*256;
           }
         if(capital>=12900 && capital<13000)
           {
            volumeoper=loteinicial*258;
            volumemaximo=volumeinicial*258;
           }
         if(capital>=13000 && capital<13100)
           {
            volumeoper=loteinicial*260;
            volumemaximo=volumeinicial*260;
           }
         if(capital>=13100 && capital<13200)
           {
            volumeoper=loteinicial*262;
            volumemaximo=volumeinicial*262;
           }
         if(capital>=13200 && capital<13300)
           {
            volumeoper=loteinicial*264;
            volumemaximo=volumeinicial*264;
           }
         if(capital>=13300 && capital<13400)
           {
            volumeoper=loteinicial*266;
            volumemaximo=volumeinicial*266;
           }
         if(capital>=13400 && capital<13500)
           {
            volumeoper=loteinicial*268;
            volumemaximo=volumeinicial*268;
           }
         if(capital>=13500 && capital<13600)
           {
            volumeoper=loteinicial*270;
            volumemaximo=volumeinicial*270;
           }
         if(capital>=13600 && capital<13700)
           {
            volumeoper=loteinicial*272;
            volumemaximo=volumeinicial*272;
           }
         if(capital>=13700 && capital<13800)
           {
            volumeoper=loteinicial*274;
            volumemaximo=volumeinicial*274;
           }
         if(capital>=13800 && capital<13900)
           {
            volumeoper=loteinicial*276;
            volumemaximo=volumeinicial*276;
           }
         if(capital>=13900 && capital<14000)
           {
            volumeoper=loteinicial*278;
            volumemaximo=volumeinicial*278;
           }
         if(capital>=14000 && capital<14100)
           {
            volumeoper=loteinicial*280;
            volumemaximo=volumeinicial*280;
           }
         if(capital>=14100 && capital<14200)
           {
            volumeoper=loteinicial*282;
            volumemaximo=volumeinicial*282;
           }
         if(capital>=14200 && capital<14300)
           {
            volumeoper=loteinicial*284;
            volumemaximo=volumeinicial*284;
           }
         if(capital>=14300 && capital<14400)
           {
            volumeoper=loteinicial*286;
            volumemaximo=volumeinicial*286;
           }
         if(capital>=14400 && capital<14500)
           {
            volumeoper=loteinicial*288;
            volumemaximo=volumeinicial*288;
           }
         if(capital>=14500 && capital<14600)
           {
            volumeoper=loteinicial*290;
            volumemaximo=volumeinicial*290;
           }
         if(capital>=14600 && capital<14700)
           {
            volumeoper=loteinicial*292;
            volumemaximo=volumeinicial*292;
           }
         if(capital>=14700 && capital<14800)
           {
            volumeoper=loteinicial*294;
            volumemaximo=volumeinicial*294;
           }
         if(capital>=14800 && capital<14900)
           {
            volumeoper=loteinicial*296;
            volumemaximo=volumeinicial*296;
           }
         if(capital>=14900 && capital<15000)
           {
            volumeoper=loteinicial*298;
            volumemaximo=volumeinicial*298;
           }
         if(capital>=15000 && capital<15100)
           {
            volumeoper=loteinicial*300;
            volumemaximo=volumeinicial*300;
           }
         if(capital>=15100 && capital<15200)
           {
            volumeoper=loteinicial*302;
            volumemaximo=volumeinicial*302;
           }
         if(capital>=15200 && capital<15300)
           {
            volumeoper=loteinicial*304;
            volumemaximo=volumeinicial*304;
           }
         if(capital>=15300 && capital<15400)
           {
            volumeoper=loteinicial*306;
            volumemaximo=volumeinicial*306;
           }
         if(capital>=15400 && capital<15500)
           {
            volumeoper=loteinicial*308;
            volumemaximo=volumeinicial*308;
           }
         if(capital>=15500 && capital<15600)
           {
            volumeoper=loteinicial*310;
            volumemaximo=volumeinicial*310;
           }
         if(capital>=15600 && capital<15700)
           {
            volumeoper=loteinicial*312;
            volumemaximo=volumeinicial*312;
           }
         if(capital>=15700 && capital<15800)
           {
            volumeoper=loteinicial*314;
            volumemaximo=volumeinicial*314;
           }
         if(capital>=15800 && capital<15900)
           {
            volumeoper=loteinicial*316;
            volumemaximo=volumeinicial*316;
           }
         if(capital>=15900 && capital<16000)
           {
            volumeoper=loteinicial*318;
            volumemaximo=volumeinicial*318;
           }
         if(capital>=16000 && capital<16100)
           {
            volumeoper=loteinicial*320;
            volumemaximo=volumeinicial*320;
           }
         if(capital>=16100 && capital<16200)
           {
            volumeoper=loteinicial*322;
            volumemaximo=volumeinicial*322;
           }
         if(capital>=16200 && capital<16300)
           {
            volumeoper=loteinicial*324;
            volumemaximo=volumeinicial*324;
           }
         if(capital>=16300 && capital<16400)
           {
            volumeoper=loteinicial*326;
            volumemaximo=volumeinicial*326;
           }
         if(capital>=16400 && capital<16500)
           {
            volumeoper=loteinicial*328;
            volumemaximo=volumeinicial*328;
           }
         if(capital>=16500 && capital<16600)
           {
            volumeoper=loteinicial*330;
            volumemaximo=volumeinicial*330;
           }
         if(capital>=16600 && capital<16700)
           {
            volumeoper=loteinicial*332;
            volumemaximo=volumeinicial*332;
           }
         if(capital>=16700 && capital<16800)
           {
            volumeoper=loteinicial*334;
            volumemaximo=volumeinicial*334;
           }
         if(capital>=16800 && capital<16900)
           {
            volumeoper=loteinicial*336;
            volumemaximo=volumeinicial*336;
           }
         if(capital>=16900 && capital<17000)
           {
            volumeoper=loteinicial*338;
            volumemaximo=volumeinicial*338;
           }
         if(capital>=17000 && capital<17100)
           {
            volumeoper=loteinicial*340;
            volumemaximo=volumeinicial*340;
           }
         if(capital>=17100 && capital<17200)
           {
            volumeoper=loteinicial*342;
            volumemaximo=volumeinicial*342;
           }
         if(capital>=17200 && capital<17300)
           {
            volumeoper=loteinicial*344;
            volumemaximo=volumeinicial*344;
           }
         if(capital>=17300 && capital<17400)
           {
            volumeoper=loteinicial*346;
            volumemaximo=volumeinicial*346;
           }
         if(capital>=17400 && capital<17500)
           {
            volumeoper=loteinicial*348;
            volumemaximo=volumeinicial*348;
           }
         if(capital>=17500 && capital<17600)
           {
            volumeoper=loteinicial*350;
            volumemaximo=volumeinicial*350;
           }
         if(capital>=17600 && capital<17700)
           {
            volumeoper=loteinicial*352;
            volumemaximo=volumeinicial*352;
           }
         if(capital>=17700 && capital<17800)
           {
            volumeoper=loteinicial*354;
            volumemaximo=volumeinicial*354;
           }
         if(capital>=17800 && capital<17900)
           {
            volumeoper=loteinicial*356;
            volumemaximo=volumeinicial*356;
           }
         if(capital>=17900 && capital<18000)
           {
            volumeoper=loteinicial*358;
            volumemaximo=volumeinicial*358;
           }
         if(capital>=18000 && capital<18100)
           {
            volumeoper=loteinicial*360;
            volumemaximo=volumeinicial*360;
           }
         if(capital>=18100 && capital<18200)
           {
            volumeoper=loteinicial*362;
            volumemaximo=volumeinicial*362;
           }
         if(capital>=18200 && capital<18300)
           {
            volumeoper=loteinicial*364;
            volumemaximo=volumeinicial*364;
           }
         if(capital>=18300 && capital<18400)
           {
            volumeoper=loteinicial*366;
            volumemaximo=volumeinicial*366;
           }
         if(capital>=18400 && capital<18500)
           {
            volumeoper=loteinicial*368;
            volumemaximo=volumeinicial*368;
           }
         if(capital>=18500 && capital<18600)
           {
            volumeoper=loteinicial*370;
            volumemaximo=volumeinicial*370;
           }
         if(capital>=18600 && capital<18700)
           {
            volumeoper=loteinicial*372;
            volumemaximo=volumeinicial*372;
           }
         if(capital>=18700 && capital<18800)
           {
            volumeoper=loteinicial*374;
            volumemaximo=volumeinicial*374;
           }
         if(capital>=18800 && capital<18900)
           {
            volumeoper=loteinicial*376;
            volumemaximo=volumeinicial*376;
           }
         if(capital>=18900 && capital<19000)
           {
            volumeoper=loteinicial*378;
            volumemaximo=volumeinicial*378;
           }
         if(capital>=19000 && capital<19100)
           {
            volumeoper=loteinicial*380;
            volumemaximo=volumeinicial*80;
           }
         if(capital>=19100 && capital<19200)
           {
            volumeoper=loteinicial*382;
            volumemaximo=volumeinicial*382;
           }
         if(capital>=19200 && capital<19300)
           {
            volumeoper=loteinicial*384;
            volumemaximo=volumeinicial*384;
           }
         if(capital>=19300 && capital<19400)
           {
            volumeoper=loteinicial*386;
            volumemaximo=volumeinicial*386;
           }
         if(capital>=19400 && capital<19500)
           {
            volumeoper=loteinicial*388;
            volumemaximo=volumeinicial*388;
           }
         if(capital>=19500 && capital<19600)
           {
            volumeoper=loteinicial*390;
            volumemaximo=volumeinicial*390;
           }
         if(capital>=19600 && capital<19700)
           {
            volumeoper=loteinicial*392;
            volumemaximo=volumeinicial*392;
           }
         if(capital>=19700 && capital<19800)
           {
            volumeoper=loteinicial*394;
            volumemaximo=volumeinicial*394;
           }
         if(capital>=19800 && capital<19900)
           {
            volumeoper=loteinicial*396;
            volumemaximo=volumeinicial*396;
           }
         if(capital>=19900 && capital<20000)
           {
            volumeoper=loteinicial*398;
            volumemaximo=volumeinicial*398;
           }
         if(capital>=20000 && capital<20100)
           {
            volumeoper=loteinicial*400;
            volumemaximo=volumeinicial*400;
           }
         if(capital>=20100 && capital<20200)
           {
            volumeoper=loteinicial*402;
            volumemaximo=volumeinicial*402;
           }
         if(capital>=20200 && capital<20300)
           {
            volumeoper=loteinicial*404;
            volumemaximo=volumeinicial*404;
           }
         if(capital>=20300 && capital<20400)
           {
            volumeoper=loteinicial*406;
            volumemaximo=volumeinicial*406;
           }
         if(capital>=20400 && capital<20500)
           {
            volumeoper=loteinicial*408;
            volumemaximo=volumeinicial*408;
           }
         if(capital>=20500 && capital<20600)
           {
            volumeoper=loteinicial*410;
            volumemaximo=volumeinicial*410;
           }
         if(capital>=20600 && capital<20700)
           {
            volumeoper=loteinicial*412;
            volumemaximo=volumeinicial*412;
           }
         if(capital>=20700 && capital<20800)
           {
            volumeoper=loteinicial*414;
            volumemaximo=volumeinicial*414;
           }
         if(capital>=20800 && capital<20900)
           {
            volumeoper=loteinicial*416;
            volumemaximo=volumeinicial*416;
           }
         if(capital>=20900 && capital<21000)
           {
            volumeoper=loteinicial*418;
            volumemaximo=volumeinicial*418;
           }
         if(capital>=21000 && capital<21100)
           {
            volumeoper=loteinicial*420;
            volumemaximo=volumeinicial*420;
           }
         if(capital>=21100 && capital<21200)
           {
            volumeoper=loteinicial*422;
            volumemaximo=volumeinicial*422;
           }
         if(capital>=21200 && capital<21300)
           {
            volumeoper=loteinicial*424;
            volumemaximo=volumeinicial*424;
           }
         if(capital>=21300 && capital<21400)
           {
            volumeoper=loteinicial*426;
            volumemaximo=volumeinicial*426;
           }
         if(capital>=21400 && capital<21500)
           {
            volumeoper=loteinicial*428;
            volumemaximo=volumeinicial*428;
           }
         if(capital>=21500 && capital<21600)
           {
            volumeoper=loteinicial*430;
            volumemaximo=volumeinicial*430;
           }
         if(capital>=21600 && capital<21700)
           {
            volumeoper=loteinicial*432;
            volumemaximo=volumeinicial*432;
           }
         if(capital>=21700 && capital<21800)
           {
            volumeoper=loteinicial*434;
            volumemaximo=volumeinicial*434;
           }
         if(capital>=21800 && capital<21900)
           {
            volumeoper=loteinicial*436;
            volumemaximo=volumeinicial*436;
           }
         if(capital>=21900 && capital<22000)
           {
            volumeoper=loteinicial*438;
            volumemaximo=volumeinicial*438;
           }
         if(capital>=22000 && capital<22100)
           {
            volumeoper=loteinicial*440;
            volumemaximo=volumeinicial*440;
           }
         if(capital>=22100 && capital<22200)
           {
            volumeoper=loteinicial*442;
            volumemaximo=volumeinicial*442;
           }
         if(capital>=22200 && capital<22300)
           {
            volumeoper=loteinicial*444;
            volumemaximo=volumeinicial*444;
           }
         if(capital>=22300 && capital<22400)
           {
            volumeoper=loteinicial*446;
            volumemaximo=volumeinicial*446;
           }
         if(capital>=22400 && capital<22500)
           {
            volumeoper=loteinicial*448;
            volumemaximo=volumeinicial*448;
           }
         if(capital>=22500 && capital<22600)
           {
            volumeoper=loteinicial*450;
            volumemaximo=volumeinicial*450;
           }
         if(capital>=22600 && capital<22700)
           {
            volumeoper=loteinicial*452;
            volumemaximo=volumeinicial*452;
           }
         if(capital>=22700 && capital<22800)
           {
            volumeoper=loteinicial*454;
            volumemaximo=volumeinicial*454;
           }
         if(capital>=22800 && capital<22900)
           {
            volumeoper=loteinicial*456;
            volumemaximo=volumeinicial*456;
           }
         if(capital>=22900 && capital<23000)
           {
            volumeoper=loteinicial*458;
            volumemaximo=volumeinicial*458;
           }
         if(capital>=23000 && capital<23100)
           {
            volumeoper=loteinicial*460;
            volumemaximo=volumeinicial*460;
           }
         if(capital>=23100 && capital<23200)
           {
            volumeoper=loteinicial*462;
            volumemaximo=volumeinicial*462;
           }
         if(capital>=23200 && capital<23300)
           {
            volumeoper=loteinicial*464;
            volumemaximo=volumeinicial*464;
           }
         if(capital>=23300 && capital<23400)
           {
            volumeoper=loteinicial*466;
            volumemaximo=volumeinicial*466;
           }
         if(capital>=23400 && capital<23500)
           {
            volumeoper=loteinicial*468;
            volumemaximo=volumeinicial*468;
           }
         if(capital>=23500 && capital<23600)
           {
            volumeoper=loteinicial*470;
            volumemaximo=volumeinicial*470;
           }
         if(capital>=23600 && capital<23700)
           {
            volumeoper=loteinicial*472;
            volumemaximo=volumeinicial*472;
           }
         if(capital>=23700 && capital<23800)
           {
            volumeoper=loteinicial*474;
            volumemaximo=volumeinicial*474;
           }
         if(capital>=23800 && capital<23900)
           {
            volumeoper=loteinicial*476;
            volumemaximo=volumeinicial*476;
           }
         if(capital>=23900 && capital<24000)
           {
            volumeoper=loteinicial*478;
            volumemaximo=volumeinicial*478;
           }
         if(capital>=24000 && capital<24100)
           {
            volumeoper=loteinicial*480;
            volumemaximo=volumeinicial*480;
           }
         if(capital>=24100 && capital<24200)
           {
            volumeoper=loteinicial*482;
            volumemaximo=volumeinicial*482;
           }
         if(capital>=24200 && capital<24300)
           {
            volumeoper=loteinicial*484;
            volumemaximo=volumeinicial*484;
           }
         if(capital>=24300 && capital<24400)
           {
            volumeoper=loteinicial*486;
            volumemaximo=volumeinicial*486;
           }
         if(capital>=24400 && capital<24500)
           {
            volumeoper=loteinicial*488;
            volumemaximo=volumeinicial*488;
           }
         if(capital>=24500 && capital<24600)
           {
            volumeoper=loteinicial*490;
            volumemaximo=volumeinicial*490;
           }
         if(capital>=24600 && capital<24700)
           {
            volumeoper=loteinicial*492;
            volumemaximo=volumeinicial*492;
           }
         if(capital>=24700 && capital<24800)
           {
            volumeoper=loteinicial*494;
            volumemaximo=volumeinicial*494;
           }
         if(capital>=24800 && capital<24900)
           {
            volumeoper=loteinicial*496;
            volumemaximo=volumeinicial*496;
           }
         if(capital>=24900 && capital<25000)
           {
            volumeoper=loteinicial*498;
            volumemaximo=volumeinicial*498;
           }
         if(capital>=25000 && capital<25100)
           {
            volumeoper=loteinicial*500;
            volumemaximo=volumeinicial*500;
           }
         if(capital>=25100 && capital<25200)
           {
            volumeoper=loteinicial*502;
            volumemaximo=volumeinicial*502;
           }
         if(capital>=25200 && capital<25300)
           {
            volumeoper=loteinicial*504;
            volumemaximo=volumeinicial*504;
           }
         if(capital>=25300 && capital<25400)
           {
            volumeoper=loteinicial*506;
            volumemaximo=volumeinicial*506;
           }
         if(capital>=25400 && capital<25500)
           {
            volumeoper=loteinicial*508;
            volumemaximo=volumeinicial*508;
           }
         if(capital>=25500 && capital<25600)
           {
            volumeoper=loteinicial*510;
            volumemaximo=volumeinicial*510;
           }
         if(capital>=25600 && capital<25700)
           {
            volumeoper=loteinicial*512;
            volumemaximo=volumeinicial*512;
           }
         if(capital>=25700 && capital<25800)
           {
            volumeoper=loteinicial*514;
            volumemaximo=volumeinicial*514;
           }
         if(capital>=25800 && capital<25900)
           {
            volumeoper=loteinicial*516;
            volumemaximo=volumeinicial*516;
           }
         if(capital>=25900 && capital<26000)
           {
            volumeoper=loteinicial*518;
            volumemaximo=volumeinicial*518;
           }
         if(capital>=26000 && capital<26100)
           {
            volumeoper=loteinicial*520;
            volumemaximo=volumeinicial*520;
           }
         if(capital>=26100 && capital<26200)
           {
            volumeoper=loteinicial*522;
            volumemaximo=volumeinicial*522;
           }
         if(capital>=26200 && capital<26300)
           {
            volumeoper=loteinicial*524;
            volumemaximo=volumeinicial*524;
           }
         if(capital>=26300 && capital<26400)
           {
            volumeoper=loteinicial*526;
            volumemaximo=volumeinicial*526;
           }
         if(capital>=26400 && capital<26500)
           {
            volumeoper=loteinicial*528;
            volumemaximo=volumeinicial*528;
           }
         if(capital>=26500 && capital<26600)
           {
            volumeoper=loteinicial*530;
            volumemaximo=volumeinicial*530;
           }
         if(capital>=26600 && capital<26700)
           {
            volumeoper=loteinicial*532;
            volumemaximo=volumeinicial*532;
           }
         if(capital>=26700 && capital<26800)
           {
            volumeoper=loteinicial*534;
            volumemaximo=volumeinicial*534;
           }
         if(capital>=26800 && capital<26900)
           {
            volumeoper=loteinicial*536;
            volumemaximo=volumeinicial*536;
           }
         if(capital>=26900 && capital<27000)
           {
            volumeoper=loteinicial*538;
            volumemaximo=volumeinicial*538;
           }
         if(capital>=27000 && capital<27100)
           {
            volumeoper=loteinicial*540;
            volumemaximo=volumeinicial*540;
           }
         if(capital>=27100 && capital<27200)
           {
            volumeoper=loteinicial*542;
            volumemaximo=volumeinicial*542;
           }
         if(capital>=27200 && capital<27300)
           {
            volumeoper=loteinicial*544;
            volumemaximo=volumeinicial*544;
           }
         if(capital>=27300 && capital<27400)
           {
            volumeoper=loteinicial*546;
            volumemaximo=volumeinicial*546;
           }
         if(capital>=27400 && capital<27500)
           {
            volumeoper=loteinicial*548;
            volumemaximo=volumeinicial*548;
           }
         if(capital>=27500 && capital<27600)
           {
            volumeoper=loteinicial*550;
            volumemaximo=volumeinicial*550;
           }
         if(capital>=27600 && capital<27700)
           {
            volumeoper=loteinicial*552;
            volumemaximo=volumeinicial*552;
           }
         if(capital>=27700 && capital<27800)
           {
            volumeoper=loteinicial*554;
            volumemaximo=volumeinicial*554;
           }
         if(capital>=27800 && capital<27900)
           {
            volumeoper=loteinicial*556;
            volumemaximo=volumeinicial*556;
           }
         if(capital>=27900 && capital<28000)
           {
            volumeoper=loteinicial*558;
            volumemaximo=volumeinicial*558;
           }
         if(capital>=28000 && capital<28100)
           {
            volumeoper=loteinicial*560;
            volumemaximo=volumeinicial*560;
           }
         if(capital>=28100 && capital<28200)
           {
            volumeoper=loteinicial*562;
            volumemaximo=volumeinicial*562;
           }
         if(capital>=28200 && capital<28300)
           {
            volumeoper=loteinicial*564;
            volumemaximo=volumeinicial*564;
           }
         if(capital>=28300 && capital<28400)
           {
            volumeoper=loteinicial*566;
            volumemaximo=volumeinicial*566;
           }
         if(capital>=28400 && capital<28500)
           {
            volumeoper=loteinicial*568;
            volumemaximo=volumeinicial*568;
           }
         if(capital>=28500 && capital<28600)
           {
            volumeoper=loteinicial*570;
            volumemaximo=volumeinicial*570;
           }
         if(capital>=28600 && capital<28700)
           {
            volumeoper=loteinicial*572;
            volumemaximo=volumeinicial*572;
           }
         if(capital>=28700 && capital<28800)
           {
            volumeoper=loteinicial*574;
            volumemaximo=volumeinicial*574;
           }
         if(capital>=28800 && capital<28900)
           {
            volumeoper=loteinicial*576;
            volumemaximo=volumeinicial*576;
           }
         if(capital>=28900 && capital<29000)
           {
            volumeoper=loteinicial*578;
            volumemaximo=volumeinicial*578;
           }
         if(capital>=29000 && capital<29100)
           {
            volumeoper=loteinicial*580;
            volumemaximo=volumeinicial*80;
           }
         if(capital>=29100 && capital<29200)
           {
            volumeoper=loteinicial*582;
            volumemaximo=volumeinicial*582;
           }
         if(capital>=29200 && capital<29300)
           {
            volumeoper=loteinicial*584;
            volumemaximo=volumeinicial*584;
           }
         if(capital>=29300 && capital<29400)
           {
            volumeoper=loteinicial*586;
            volumemaximo=volumeinicial*586;
           }
         if(capital>=29400 && capital<29500)
           {
            volumeoper=loteinicial*588;
            volumemaximo=volumeinicial*588;
           }
         if(capital>=29500 && capital<29600)
           {
            volumeoper=loteinicial*590;
            volumemaximo=volumeinicial*590;
           }
         if(capital>=29600 && capital<29700)
           {
            volumeoper=loteinicial*592;
            volumemaximo=volumeinicial*592;
           }
         if(capital>=29700 && capital<29800)
           {
            volumeoper=loteinicial*594;
            volumemaximo=volumeinicial*594;
           }
         if(capital>=29800 && capital<29900)
           {
            volumeoper=loteinicial*596;
            volumemaximo=volumeinicial*596;
           }
         if(capital>=29900 && capital<30000)
           {
            volumeoper=loteinicial*598;
            volumemaximo=volumeinicial*598;
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
         open1  = DoubleToString(candle[5].open,5);
         open2  = DoubleToString(candle[4].open,5);
         open3  = DoubleToString(candle[3].open,5);
         open4  = DoubleToString(candle[2].open,5);
         open5  = DoubleToString(candle[1].open,5);
         low1   = DoubleToString(candle[5].low,5);
         low2   = DoubleToString(candle[4].low,5);
         low3   = DoubleToString(candle[3].low,5);
         low4   = DoubleToString(candle[2].low,5);
         low5   = DoubleToString(candle[1].low,5);
         high1  = DoubleToString(candle[5].high,5);
         high2  = DoubleToString(candle[4].high,5);
         high3  = DoubleToString(candle[3].high,5);
         high4  = DoubleToString(candle[2].high,5);
         high5  = DoubleToString(candle[1].high,5);
         close1 = DoubleToString(candle[5].close,5);
         close2 = DoubleToString(candle[4].close,5);
         close3 = DoubleToString(candle[3].close,5);
         close4 = DoubleToString(candle[2].close,5);
         close5 = DoubleToString(candle[1].close,5);

         envioneural = open1+","+high1+","+low1+","+open2+","+high2+","+low2+","+open3+","+high3+","+low3+","+open4+","+high4+","+low4+","+close4+","+open2+","+high2+","+low2+","+open3+","+high3+","+low3+","+open4+","+high4+","+low4+","+open5+","+high5+","+low5+","+close5;

         if(SocketIsConnected(socketneural))
            enviado = socksend(socketneural,envioneural);
         else
            Print("Falhou conexão a ",endereco,":",porta,", erro ",GetLastError());

         Sleep(3);

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
                  Sleep(300);
                  trade.Buy(volnv2,_Symbol,tick.ask,slcomprapadrao,previsao,"C2");
                  return;
                 }
               if(PossuiPosVendaComentada("V2"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(300);
                  trade.Buy(volnv3,_Symbol,tick.ask,slcomprapadrao,previsao,"C3");
                  return;
                 }
               if(PossuiPosVendaComentada("V3"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(300);
                  trade.Buy(volnv4,_Symbol,tick.ask,slcomprapadrao,previsao,"C4");
                  return;
                 }
               if(PossuiPosVendaComentada("V4"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(300);
                  trade.Buy(volnv5,_Symbol,tick.ask,slcomprapadrao,previsao,"C5");
                  return;
                 }
               if(PossuiPosVendaComentada("V5"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(300);
                  trade.Buy(volnv6,_Symbol,tick.ask,slcomprapadrao,previsao,"C6");
                  return;
                 }
               if(PossuiPosVendaComentada("V6"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(300);
                  trade.Buy(volnv7,_Symbol,tick.ask,slcomprapadrao,previsao,"C7");
                  return;
                 }
               if(PossuiPosVendaComentada("V7"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(300);
                  trade.Buy(volnv8,_Symbol,tick.ask,slcomprapadrao,previsao,"C8");
                  return;
                 }
              }
            else
              {
               if(!PossuiPosCompra())
                 {
                  trade.Buy(volumeoper,_Symbol,tick.ask,slcomprapadrao,previsao,"C1");
                  return;
                 }
               if(PossuiPosCompraComentada("C1") && !PossuiPosCompraComentada("C2") && Ask<PrecoAberturaPosCompra() && VolumePos()<=5 && volnv2!=0)
                 {
                  trade.Buy(volnv2,_Symbol,tick.ask,slcomprapadrao,previsao,"C2");
                  return;
                 }
               if(PossuiPosCompraComentada("C2") && !PossuiPosCompraComentada("C3") && Ask<PrecoAberturaPosCompra() && VolumePos()<=5 && volnv3!=0)
                 {
                  trade.Buy(volnv3,_Symbol,tick.ask,slcomprapadrao,previsao,"C3");
                  return;
                 }
               if(PossuiPosCompraComentada("C3") && !PossuiPosCompraComentada("C4") && Ask<PrecoAberturaPosCompra() && VolumePos()<=5 && volnv4!=0)
                 {
                  trade.Buy(volnv4,_Symbol,tick.ask,slcomprapadrao,previsao,"C4");
                  return;
                 }
               if(PossuiPosCompraComentada("C4") && !PossuiPosCompraComentada("C5") && Ask<PrecoAberturaPosCompra() && VolumePos()<=5 && volnv5!=0)
                 {
                  trade.Buy(volnv5,_Symbol,tick.ask,slcomprapadrao,previsao,"C5");
                  return;
                 }
               if(PossuiPosCompraComentada("C5") && !PossuiPosCompraComentada("C6") && Ask<PrecoAberturaPosCompra() && VolumePos()<=5 && volnv6!=0)
                 {
                  trade.Buy(volnv6,_Symbol,tick.ask,slcomprapadrao,previsao,"C6");
                  return;
                 }
               if(PossuiPosCompraComentada("C6") && !PossuiPosCompraComentada("C7") && Ask<PrecoAberturaPosCompra() && VolumePos()<=5 && volnv7!=0)
                 {
                  trade.Buy(volnv7,_Symbol,tick.ask,slcomprapadrao,previsao,"C7");
                  return;
                 }
               if(PossuiPosCompraComentada("C7") && !PossuiPosCompraComentada("C8") && Ask<PrecoAberturaPosCompra() && VolumePos()<=5 && volnv8!=0)
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
                  Sleep(300);
                  trade.Sell(volnv2,_Symbol,tick.bid,slvendapadrao,previsao,"V2");
                  return;
                 }
               if(PossuiPosCompraComentada("C2"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(300);
                  trade.Sell(volnv3,_Symbol,tick.bid,slvendapadrao,previsao,"V3");
                  return;
                 }
               if(PossuiPosCompraComentada("C3"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(300);
                  trade.Sell(volnv4,_Symbol,tick.bid,slvendapadrao,previsao,"V4");
                  return;
                 }
               if(PossuiPosCompraComentada("C4"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(300);
                  trade.Sell(volnv5,_Symbol,tick.bid,slvendapadrao,previsao,"V5");
                  return;
                 }
               if(PossuiPosCompraComentada("C5"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(300);
                  trade.Sell(volnv6,_Symbol,tick.bid,slvendapadrao,previsao,"V6");
                  return;
                 }
               if(PossuiPosCompraComentada("C6"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(300);
                  trade.Sell(volnv7,_Symbol,tick.bid,slvendapadrao,previsao,"V7");
                  return;
                 }
               if(PossuiPosCompraComentada("C7"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(300);
                  trade.Sell(volnv8,_Symbol,tick.bid,slvendapadrao,previsao,"V8");
                  return;
                 }
              }
            else
              {
               if(!PossuiPosVenda())
                 {
                  trade.Sell(volumeoper,_Symbol,tick.bid,slvendapadrao,previsao,"V1");
                  return;
                 }
               if(PossuiPosVendaComentada("V1") && !PossuiPosVendaComentada("V2") && Bid>PrecoAberturaPosVenda() && VolumePos()<=5 && volnv2!=0)
                 {
                  trade.Sell(volnv2,_Symbol,tick.bid,slvendapadrao,previsao,"V2");
                  return;
                 }
               if(PossuiPosVendaComentada("V2") && !PossuiPosVendaComentada("V3") && Bid>PrecoAberturaPosVenda() && VolumePos()<=5 && volnv3!=0)
                 {
                  trade.Sell(volnv3,_Symbol,tick.bid,slvendapadrao,previsao,"V3");
                  return;
                 }
               if(PossuiPosVendaComentada("V3") && !PossuiPosVendaComentada("V4") && Bid>PrecoAberturaPosVenda() && VolumePos()<=5 && volnv4!=0)
                 {
                  trade.Sell(volnv4,_Symbol,tick.bid,slvendapadrao,previsao,"V4");
                  return;
                 }
               if(PossuiPosVendaComentada("V4") && !PossuiPosVendaComentada("V5") && Bid>PrecoAberturaPosVenda() && VolumePos()<=5 && volnv5!=0)
                 {
                  trade.Sell(volnv5,_Symbol,tick.bid,slvendapadrao,previsao,"V5");
                  return;
                 }
               if(PossuiPosVendaComentada("V5") && !PossuiPosVendaComentada("V6") && Bid>PrecoAberturaPosVenda() && VolumePos()<=5 && volnv6!=0)
                 {
                  trade.Sell(volnv6,_Symbol,tick.bid,slvendapadrao,previsao,"V6");
                  return;
                 }
               if(PossuiPosVendaComentada("V6") && !PossuiPosVendaComentada("V7") && Bid>PrecoAberturaPosVenda() && VolumePos()<=5 && volnv7!=0)
                 {
                  trade.Sell(volnv7,_Symbol,tick.bid,slvendapadrao,previsao,"V7");
                  return;
                 }
               if(PossuiPosVendaComentada("V7") && !PossuiPosVendaComentada("V8") && Bid>PrecoAberturaPosVenda() && VolumePos()<=5 && volnv8!=0)
                 {
                  trade.Sell(volnv8,_Symbol,tick.bid,slvendapadrao,previsao,"V8");
                  return;
                 }
              }
           }
         //////////////////////////
         //---|AJUSTE DE TAKE|---//
         //////////////////////////
         Sleep(800);
         if(TPUltimaPosAberta() != previsao && ((PossuiPosCompra() && previsao > PrecoPosCompra())||(PossuiPosVenda() && previsao < PrecoPosCompra())))
           {
            trade.PositionModify(_Symbol,0,previsao);
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
         Sleep(300);
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
