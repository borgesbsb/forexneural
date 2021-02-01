//+------------------------------------------------------------------+
//|                                            ROBÔ FOREX NEURAL.mq5 |
//|                                            gibranvalle@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Gibran, Borges e James"
#property link      "gibranvalle@gmail.com"
#property version   "1.00"
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Bibliotecas utilizadas
#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/HistoryOrderInfo.mqh>
#include <IsNewBar.mqh>
#include <Dictionary.mqh>

enum ENUM_TP_DIST
  {
   dist1,        // [1]PONTOS FIXOS
   dist2,        // [2]PONTOS FIBONACCI
  };
enum ENUM_TP_MART
  {
   mart1,        // [1]2x VOL ACUMULADO
   mart2,        // [2]2x VOL ANTERIOR
   mart3,        // [3]VOLUME FIBONACCI
   mart4,        // [4]05 FIBO + 04 2x ANT
  };

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input ulong              magicrobo           = 940;        // MAGIC NUMBER DO ROBÔ
input group              "REDE NEURAL"
input bool               ativaenvioneural    = false;      // ATIVA ENVIO DE DADOS P/ SERVIDOR
input string             endereco            = "127.0.0.1";// IP/SITE DO SERVIDOR NEURAL
input int                porta               = 8082;       // PORTA DO SERVIDOR NEURAL
//input bool               ExtTLS              = false;      // ATIVA ENVIO POR HTTPS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "ABERTURA DE POSIÇÕES"
input bool               ativaentradaea      = true;       // ATIVA ABERTURA DE POSIÇÕES PELO EA
input double             loteinicial         = 0.03;       // TAMANHO DO LOTE P/ CADA $50,00
//input double             pontostp            = 10;         // TAKE PROFIT EM PONTOS EM REL. AO PM
input group              "MARTINGALE"
input ENUM_TP_MART       tipomartingale      = mart1;      // TIPO DE VOLUME MARTINGALE
input ENUM_TP_DIST       tipotunelvegas      = dist1;      // TIPO DE DISTÂNCIA MARTINGALE
input double             pontosmart          = 60;         // DISTÂNCIA ENTRE AS POSIÇÕES
input int                multiplicador       = 2;          // MULTIPLICADOR P/ MARTINGALE
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "BREAKEVEN E TRAILING STOP"
input bool               ativaBE             = false;      // ATIVA BREAKEVEN
input double             recuoBE             = 50;         // PONTOS PARA RECUO NO BREAKEVEN
input bool               ativaTS             = false;      // ATIVA TRAILING STOP
input double             pontosTS            = 40;         // PONTOS P/ ATIVAÇÃO TS
input double             avancoTS            = 10;         // AVANÇO DO STOP EM PONTOS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "FECHAMENTO DE POSIÇÕES"
input bool               ativasaidaea        = true;       // ATIVA FECHAMENTO DE POSIÇÕES PELO EA
input double             pontosc1            = 120;        // PONTOS PARA FECHAR QUANDO 1 POSIÇÃO
input double             pontosc2            = 140;        // PONTOS PARA FECHAR QUANDO 2 POSIÇÕES
input double             pontosc3            = 140;        // PONTOS PARA FECHAR QUANDO 3 POSIÇÕES
input double             pontosc4            = 100;        // PONTOS PARA FECHAR QUANDO 4 POSIÇÕES
input double             pontosc5            = 20;         // PONTOS PARA FECHAR QUANDO 5 POSIÇÕES
input double             pontosc6            = 20;         // PONTOS PARA FECHAR QUANDO 6 POSIÇÕES
input double             pontosc7            = 20;         // PONTOS PARA FECHAR QUANDO 7 POSIÇÕES
input double             pontosc8            = 30;         // PONTOS PARA FECHAR QUANDO 8 POSIÇÕES
input double             pontosc9            = 30;         // PONTOS PARA FECHAR QUANDO 9 POSIÇÕES
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "HORáRIO DE FUNCIONAMENTO DO EA"
input string             inicio              = "00:05";    // HORáRIO DE INíCIO (ENTRADAS)
input string             termino             = "23:55";    // HORáRIO DE TéRMINO (ENTRADAS)
//input string             fechamento          = "23:45";     // HORáRIO DE FECHAMENTO (POSIçõES)
input string             pausainicio1        = "";         // HORáRIO DE INíCIO DA PAUSA 1(NOTíCIAS)
input string             pausatermino1       = "";         // HORáRIO DE TéRMINO DA PAUSA 1(NOTíCIAS)
input string             pausainicio2        = "";         // HORáRIO DE INíCIO DA PAUSA 2(NOTíCIAS)
input string             pausatermino2       = "";         // HORáRIO DE TéRMINO DA PAUSA 2(NOTíCIAS)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "GERENCIAMENTO DE RISCO - NÃO ABRE NOVAS POSIÇÕES"
input double             prctniveloper       = 3000;       // MARGEM MINIMA P/ ABRIR POSIÇÕES
input double             volumeinicial       = 0.7;        // VOLUME MÁXIMO P/ ABRIR OPERAÇÕES
input group              "GERENCIAMENTO DE RISCO - FECHA AS POSIÇÕES NO PREJU"
input bool               ativastop           = false;      // ATIVA STOP FORÇADO
input double             stopemdolar         = 250.00;     // VALOR EM $ PARA "STOPAR"
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
string                   shortname;

//--- Variáveis temporárias e de carater geral
double                   stopcompra          = 0.0;
double                   stopvenda           = 0.0;
double                   takecompra          = 0.0;
double                   takevenda           = 0.0;
double                   previsao_temp       = 0.0;
double                   posicao_vendida     = 0.0;
double                   posicao_compra      = 0.0;

double                   percent_margem, saldo, capital, lucro_prejuizo, volumemaximo, volumeoper, rsi[];
int                      handlersi;

//--- Variáveis p/ envio de dados à rede neural
int                      socketneural        = SocketCreate();//quando chamado, cria o soquete para conexão ao servidor de previsões
string                   recebido            = "";//string para receber a previsão do servidor
string                   open1               = "";
string                   open2               = "";
string                   close1              = "";
string                   close2              = "";
string                   low1                = "";
string                   low2                = "";
string                   high1               = "";
string                   high2               = "";
string                   envioneural         = "";//string contendo os dados a serem enviados para o servidor
bool                     enviado;

//--- Definição das variáveis dos volumes para compra e venda quando utilizar martingale
double                   volnv2,volnv3,volnv4,volnv5,volnv6,volnv7,volnv8,volnv9;
double                   volnv_2,volnv_3,volnv_4,volnv_5,volnv_6,volnv_7,volnv_8,volnv_9;

//--- Definição das variáveis dos níveis do túnel de vegas
double                   lv2,lv3,lv4,lv45,lv5,lv55,lv6,lv65,lv7,lv75,lv8,lv85,lv9,lv95;//qtde de pontos a partir da média para cada nível do túnel de vegas
double                   prcnvl2,prcnvl3,prcnvl4,prcnvl45,prcnvl5,prcnvl55,prcnvl6,prcnvl65,prcnvl7,prcnvl75,prcnvl8,prcnvl85,prcnvl9,prcnvl95;//preços dos níveis positivos - acima da média
double                   prcnvl_2,prcnvl_3,prcnvl_4,prcnvl_45,prcnvl_5,prcnvl_55,prcnvl_6,prcnvl_65,prcnvl_7,prcnvl_75,prcnvl_8,prcnvl_85,prcnvl_9;//preços dos níveis negativos - abaixo da média

//--- Variáveis p/ ticks e candles
MqlTick                  tick;
MqlRates                 candle[];

// Cria estruturas de tempo para manipulação de horários
MqlDateTime horario_inicio, horario_termino,/* horario_fechamento,*/ //
            horario_atual, horario_inicio_pausa1, horario_termino_pausa1, //
            horario_inicio_pausa2, horario_termino_pausa2, horario_posicao;

//--- Usa a classe responsável pela execução das ordens - Ctrade
CTrade                   trade;

//--- Usa a classe responsável pela leitura dos dados do arquivo contendo as previsões
//CDictionary *dict = new CDictionary();

//+--------------------------------+
//| Expert initialization function |
//+--------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {

//--- Seta o magic number do robô
   trade.SetExpertMagicNumber(magicrobo);

   handlersi = iRSI(_Symbol,_Period,10,PRICE_CLOSE);
   ArraySetAsSeries(rsi,true);
   ArraySetAsSeries(candle,true);

//--- Criação das structs de tempo
   TimeToStruct(StringToTime(inicio),horario_inicio);
   TimeToStruct(StringToTime(termino),horario_termino);
//   TimeToStruct(StringToTime(fechamento),horario_fechamento);
   TimeToStruct(StringToTime(pausainicio1),horario_inicio_pausa1);
   TimeToStruct(StringToTime(pausatermino1),horario_termino_pausa1);
   TimeToStruct(StringToTime(pausainicio2),horario_inicio_pausa2);
   TimeToStruct(StringToTime(pausatermino2),horario_termino_pausa2);

   //ReadFileToDictCSV("previsoes.csv");

   if(socketneural!=INVALID_HANDLE)
      Print("Confirmação de soquete criado, este é o número dele: ",socketneural);

//--- Definição dos níveis fixos em pontos
   if(tipotunelvegas==dist1)
     {
      lv2                = pontosmart;
      lv3                = 2*pontosmart;
      lv4                = 3*pontosmart;
      lv5                = 4*pontosmart;
      lv6                = 5*pontosmart;
      lv7                = 6*pontosmart;
      lv8                = 7*pontosmart;
      lv9                = 8*pontosmart;
     }
//--- Definição dos níveis FIBO p/ moedas normais
   if(tipotunelvegas==dist2)
     {
      lv2                = pontosmart;
      lv3                = 2*pontosmart;
      lv4                = 4*pontosmart;
      lv5                = 7*pontosmart;
      lv6                = 12*pontosmart;
      lv7                = 20*pontosmart;
      lv8                = 33*pontosmart;
      lv9                = 54*pontosmart;
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
   CopyRates(_Symbol,_Period,0,5,candle);
   if(CopyRates(_Symbol,_Period,0,5,candle)<0)
     {
      Alert("Erro ao obter informações de Mqlrates: ", GetLastError());
      return;
     }
   CopyBuffer(handlersi,0,0,5,rsi);
   if(CopyBuffer(handlersi,0,0,5,rsi)<0)
     {
      Alert("Erro ao copiar dados de RSI: ", GetLastError());
      return;
     }

   static CIsNewBar NB1,NB2,NB3,NB4,NB5,NB6/*,NB7,NB8,NB9,NB10,NB11,NB12,NB13,NB14,NB15,NB16,NB17,NB18,NB19,NB20,NB21,NB22*/;

//---Atualização dos preços dos níveis tick a tick
   prcnvl9 = tick.bid+lv9*_Point;
   prcnvl8 = tick.bid+lv8*_Point;
   prcnvl7 = tick.bid+lv7*_Point;
   prcnvl6 = tick.bid+lv6*_Point;
   prcnvl5 = tick.bid+lv5*_Point;
   prcnvl4 = tick.bid+lv4*_Point;
   prcnvl3 = tick.bid+lv3*_Point;
   prcnvl2 = tick.bid+lv2*_Point;
   prcnvl_2= tick.ask-lv2*_Point;
   prcnvl_3 = tick.ask-lv3*_Point;
   prcnvl_4 = tick.ask-lv4*_Point;
   prcnvl_5 = tick.ask-lv5*_Point;
   prcnvl_6 = tick.ask-lv6*_Point;
   prcnvl_7 = tick.ask-lv7*_Point;
   prcnvl_8 = tick.ask-lv8*_Point;
   prcnvl_9 = tick.ask-lv9*_Point;

   if(NB1.IsNewBar(_Symbol,_Period)) //VERIFICA SE É UM NOVO CANDLE
     {
      if(capital>=5000 && saldo<10000)
        {
         volumeoper=loteinicial;
         volumemaximo=volumeinicial;
        }
      if(capital>=10000 && saldo<20000)
        {
         volumeoper=loteinicial*2;
         volumemaximo=volumeinicial*2;
        }
      if(capital>=20000 && saldo<30000)
        {
         volumeoper=loteinicial*4;
         volumemaximo=volumeinicial*4;
        }
      if(capital>=30000 && saldo<40000)
        {
         volumeoper=loteinicial*6;
         volumemaximo=volumeinicial*6;
        }
      if(capital>=40000 && saldo<50000)
        {
         volumeoper=loteinicial*8;
         volumemaximo=volumeinicial*8;
        }
      if(capital>=50000 && saldo<60000)
        {
         volumeoper=loteinicial*10;
         volumemaximo=volumeinicial*10;
        }
      if(capital>=60000 && saldo<70000)
        {
         volumeoper=loteinicial*12;
         volumemaximo=volumeinicial*12;
        }
      if(capital>=70000 && saldo<80000)
        {
         volumeoper=loteinicial*14;
         volumemaximo=volumeinicial*14;
        }
      if(capital>=80000 && saldo<90000)
        {
         volumeoper=loteinicial*16;
         volumemaximo=volumeinicial*16;
        }
      if(capital>=90000 && saldo<100000)
        {
         volumeoper=loteinicial*18;
         volumemaximo=volumeinicial*18;
        }
      if(capital>=100000 && saldo<110000)
        {
         volumeoper=loteinicial*20;
         volumemaximo=volumeinicial*20;
        }
      if(capital>=110000 && saldo<120000)
        {
         volumeoper=loteinicial*22;
         volumemaximo=volumeinicial*22;
        }
      if(capital>=120000 && saldo<130000)
        {
         volumeoper=loteinicial*24;
         volumemaximo=volumeinicial*24;
        }
      if(capital>=130000 && saldo<140000)
        {
         volumeoper=loteinicial*26;
         volumemaximo=volumeinicial*26;
        }
      if(capital>=140000 && saldo<150000)
        {
         volumeoper=loteinicial*28;
         volumemaximo=volumeinicial*28;
        }
      if(capital>=150000 && saldo<160000)
        {
         volumeoper=loteinicial*30;
         volumemaximo=volumeinicial*30;
        }
      if(capital>=160000 && saldo<170000)
        {
         volumeoper=loteinicial*32;
         volumemaximo=volumeinicial*32;
        }
      if(capital>=170000 && saldo<180000)
        {
         volumeoper=loteinicial*34;
         volumemaximo=volumeinicial*34;
        }
      if(capital>=180000 && saldo<190000)
        {
         volumeoper=loteinicial*36;
         volumemaximo=volumeinicial*36;
        }
      if(capital>=190000 && saldo<200000)
        {
         volumeoper=loteinicial*38;
         volumemaximo=volumeinicial*38;
        }
      if(capital>=200000 && saldo<210000)
        {
         volumeoper=loteinicial*40;
         volumemaximo=volumeinicial*40;
        }
      if(capital>=210000 && saldo<220000)
        {
         volumeoper=loteinicial*42;
         volumemaximo=volumeinicial*42;
        }
      if(capital>=220000 && saldo<230000)
        {
         volumeoper=loteinicial*44;
         volumemaximo=volumeinicial*44;
        }
      if(capital>=230000 && saldo<240000)
        {
         volumeoper=loteinicial*46;
         volumemaximo=volumeinicial*46;
        }
      if(capital>=240000 && saldo<250000)
        {
         volumeoper=loteinicial*48;
         volumemaximo=volumeinicial*48;
        }
      if(capital>=250000 && saldo<260000)
        {
         volumeoper=loteinicial*50;
         volumemaximo=volumeinicial*50;
        }
      if(capital>=260000 && saldo<270000)
        {
         volumeoper=loteinicial*52;
         volumemaximo=volumeinicial*52;
        }
      if(capital>=270000 && saldo<280000)
        {
         volumeoper=loteinicial*54;
         volumemaximo=volumeinicial*54;
        }
      if(capital>=280000 && saldo<290000)
        {
         volumeoper=loteinicial*56;
         volumemaximo=volumeinicial*56;
        }
      if(capital>=290000 && saldo<300000)
        {
         volumeoper=loteinicial*58;
         volumemaximo=volumeinicial*58;
        }
      if(capital>=300000 && saldo<310000)
        {
         volumeoper=loteinicial*60;
         volumemaximo=volumeinicial*60;
        }
      if(capital>=310000 && saldo<320000)
        {
         volumeoper=loteinicial*62;
         volumemaximo=volumeinicial*62;
        }
      if(capital>=320000 && saldo<330000)
        {
         volumeoper=loteinicial*64;
         volumemaximo=volumeinicial*64;
        }
      if(capital>=330000 && saldo<340000)
        {
         volumeoper=loteinicial*66;
         volumemaximo=volumeinicial*66;
        }
      if(capital>=340000 && saldo<350000)
        {
         volumeoper=loteinicial*68;
         volumemaximo=volumeinicial*68;
        }
      if(capital>=350000 && saldo<360000)
        {
         volumeoper=loteinicial*70;
         volumemaximo=volumeinicial*70;
        }
      if(capital>=360000 && saldo<370000)
        {
         volumeoper=loteinicial*72;
         volumemaximo=volumeinicial*72;
        }
      if(capital>=370000 && saldo<380000)
        {
         volumeoper=loteinicial*74;
         volumemaximo=volumeinicial*74;
        }
      if(capital>=380000 && saldo<390000)
        {
         volumeoper=loteinicial*76;
         volumemaximo=volumeinicial*76;
        }
      if(capital>=390000 && saldo<400000)
        {
         volumeoper=loteinicial*78;
         volumemaximo=volumeinicial*78;
        }
      if(capital>=400000 && saldo<410000)
        {
         volumeoper=loteinicial*80;
         volumemaximo=volumeinicial*80;
        }
      if(capital>=410000 && saldo<420000)
        {
         volumeoper=loteinicial*82;
         volumemaximo=volumeinicial*82;
        }
      if(capital>=420000 && saldo<430000)
        {
         volumeoper=loteinicial*84;
         volumemaximo=volumeinicial*84;
        }
      if(capital>=430000 && saldo<440000)
        {
         volumeoper=loteinicial*86;
         volumemaximo=volumeinicial*86;
        }
      if(capital>=440000 && saldo<450000)
        {
         volumeoper=loteinicial*88;
         volumemaximo=volumeinicial*88;
        }
      if(capital>=450000 && saldo<460000)
        {
         volumeoper=loteinicial*90;
         volumemaximo=volumeinicial*90;
        }
      if(capital>=460000 && saldo<470000)
        {
         volumeoper=loteinicial*92;
         volumemaximo=volumeinicial*92;
        }
      if(capital>=470000 && saldo<480000)
        {
         volumeoper=loteinicial*94;
         volumemaximo=volumeinicial*94;
        }
      if(capital>=480000 && saldo<490000)
        {
         volumeoper=loteinicial*96;
         volumemaximo=volumeinicial*96;
        }
      if(capital>=490000 && saldo<500000)
        {
         volumeoper=loteinicial*98;
         volumemaximo=volumeinicial*98;
        }
      if(capital>=500000 && saldo<510000)
        {
         volumeoper=loteinicial*100;
         volumemaximo=volumeinicial*100;
        }
      if(capital>=510000 && saldo<520000)
        {
         volumeoper=loteinicial*102;
         volumemaximo=volumeinicial*102;
        }
      if(capital>=520000 && saldo<530000)
        {
         volumeoper=loteinicial*104;
         volumemaximo=volumeinicial*104;
        }
      if(capital>=530000 && saldo<540000)
        {
         volumeoper=loteinicial*106;
         volumemaximo=volumeinicial*106;
        }
      if(capital>=540000 && saldo<550000)
        {
         volumeoper=loteinicial*108;
         volumemaximo=volumeinicial*108;
        }
      if(capital>=550000 && saldo<560000)
        {
         volumeoper=loteinicial*110;
         volumemaximo=volumeinicial*110;
        }
      if(capital>=560000 && saldo<570000)
        {
         volumeoper=loteinicial*112;
         volumemaximo=volumeinicial*112;
        }
      if(capital>=570000 && saldo<580000)
        {
         volumeoper=loteinicial*114;
         volumemaximo=volumeinicial*114;
        }
      if(capital>=580000 && saldo<590000)
        {
         volumeoper=loteinicial*116;
         volumemaximo=volumeinicial*116;
        }
      if(capital>=590000 && saldo<600000)
        {
         volumeoper=loteinicial*118;
         volumemaximo=volumeinicial*118;
        }
      if(capital>=600000 && saldo<610000)
        {
         volumeoper=loteinicial*120;
         volumemaximo=volumeinicial*120;
        }
      if(capital>=610000 && saldo<620000)
        {
         volumeoper=loteinicial*122;
         volumemaximo=volumeinicial*122;
        }
      if(capital>=620000 && saldo<630000)
        {
         volumeoper=loteinicial*124;
         volumemaximo=volumeinicial*124;
        }
      if(capital>=630000 && saldo<640000)
        {
         volumeoper=loteinicial*126;
         volumemaximo=volumeinicial*126;
        }
      if(capital>=640000 && saldo<650000)
        {
         volumeoper=loteinicial*128;
         volumemaximo=volumeinicial*128;
        }
      if(capital>=650000 && saldo<660000)
        {
         volumeoper=loteinicial*130;
         volumemaximo=volumeinicial*130;
        }
      if(capital>=660000 && saldo<670000)
        {
         volumeoper=loteinicial*132;
         volumemaximo=volumeinicial*132;
        }
      if(capital>=670000 && saldo<680000)
        {
         volumeoper=loteinicial*134;
         volumemaximo=volumeinicial*134;
        }
      if(capital>=680000 && saldo<690000)
        {
         volumeoper=loteinicial*136;
         volumemaximo=volumeinicial*136;
        }
      if(capital>=690000 && saldo<700000)
        {
         volumeoper=loteinicial*138;
         volumemaximo=volumeinicial*138;
        }
      if(capital>=700000 && saldo<710000)
        {
         volumeoper=loteinicial*140;
         volumemaximo=volumeinicial*140;
        }
      if(capital>=710000 && saldo<720000)
        {
         volumeoper=loteinicial*142;
         volumemaximo=volumeinicial*142;
        }
      if(capital>=720000 && saldo<730000)
        {
         volumeoper=loteinicial*144;
         volumemaximo=volumeinicial*144;
        }
      if(capital>=730000 && saldo<740000)
        {
         volumeoper=loteinicial*146;
         volumemaximo=volumeinicial*146;
        }
      if(capital>=740000 && saldo<750000)
        {
         volumeoper=loteinicial*148;
         volumemaximo=volumeinicial*148;
        }
      if(capital>=750000 && saldo<760000)
        {
         volumeoper=loteinicial*150;
         volumemaximo=volumeinicial*150;
        }
      if(capital>=760000 && saldo<770000)
        {
         volumeoper=loteinicial*152;
         volumemaximo=volumeinicial*152;
        }
      if(capital>=770000 && saldo<780000)
        {
         volumeoper=loteinicial*154;
         volumemaximo=volumeinicial*154;
        }
      if(capital>=780000 && saldo<790000)
        {
         volumeoper=loteinicial*156;
         volumemaximo=volumeinicial*156;
        }
      if(capital>=790000 && saldo<800000)
        {
         volumeoper=loteinicial*158;
         volumemaximo=volumeinicial*158;
        }
      if(capital>=800000 && saldo<810000)
        {
         volumeoper=loteinicial*160;
         volumemaximo=volumeinicial*160;
        }
      if(capital>=810000 && saldo<820000)
        {
         volumeoper=loteinicial*162;
         volumemaximo=volumeinicial*162;
        }
      if(capital>=820000 && saldo<830000)
        {
         volumeoper=loteinicial*164;
         volumemaximo=volumeinicial*164;
        }
      if(capital>=830000 && saldo<840000)
        {
         volumeoper=loteinicial*166;
         volumemaximo=volumeinicial*166;
        }
      if(capital>=840000 && saldo<850000)
        {
         volumeoper=loteinicial*168;
         volumemaximo=volumeinicial*168;
        }
      if(capital>=850000 && saldo<860000)
        {
         volumeoper=loteinicial*170;
         volumemaximo=volumeinicial*170;
        }
      if(capital>=860000 && saldo<870000)
        {
         volumeoper=loteinicial*172;
         volumemaximo=volumeinicial*172;
        }
      if(capital>=870000 && saldo<880000)
        {
         volumeoper=loteinicial*174;
         volumemaximo=volumeinicial*174;
        }
      if(capital>=880000 && saldo<890000)
        {
         volumeoper=loteinicial*176;
         volumemaximo=volumeinicial*176;
        }
      if(capital>=890000 && saldo<900000)
        {
         volumeoper=loteinicial*178;
         volumemaximo=volumeinicial*178;
        }
      if(capital>=900000 && saldo<910000)
        {
         volumeoper=loteinicial*180;
         volumemaximo=volumeinicial*80;
        }
      if(capital>=910000 && saldo<920000)
        {
         volumeoper=loteinicial*182;
         volumemaximo=volumeinicial*182;
        }
      if(capital>=920000 && saldo<930000)
        {
         volumeoper=loteinicial*184;
         volumemaximo=volumeinicial*184;
        }
      if(capital>=930000 && saldo<940000)
        {
         volumeoper=loteinicial*186;
         volumemaximo=volumeinicial*186;
        }
      if(capital>=940000 && saldo<950000)
        {
         volumeoper=loteinicial*188;
         volumemaximo=volumeinicial*188;
        }
      if(capital>=950000 && saldo<960000)
        {
         volumeoper=loteinicial*190;
         volumemaximo=volumeinicial*190;
        }
      if(capital>=960000 && saldo<970000)
        {
         volumeoper=loteinicial*192;
         volumemaximo=volumeinicial*192;
        }
      if(capital>=970000 && saldo<980000)
        {
         volumeoper=loteinicial*194;
         volumemaximo=volumeinicial*194;
        }
      if(capital>=980000 && saldo<990000)
        {
         volumeoper=loteinicial*196;
         volumemaximo=volumeinicial*196;
        }
      if(capital>=990000 && saldo<1000000)
        {
         volumeoper=loteinicial*198;
         volumemaximo=volumeinicial*198;
        }



      if(capital>=1000000 && saldo<1010000)
        {
         volumeoper=loteinicial*200;
         volumemaximo=volumeinicial*200;
        }
      if(capital>=1010000 && saldo<1020000)
        {
         volumeoper=loteinicial*202;
         volumemaximo=volumeinicial*202;
        }
      if(capital>=1020000 && saldo<1030000)
        {
         volumeoper=loteinicial*204;
         volumemaximo=volumeinicial*204;
        }
      if(capital>=1030000 && saldo<1040000)
        {
         volumeoper=loteinicial*206;
         volumemaximo=volumeinicial*206;
        }
      if(capital>=1040000 && saldo<1050000)
        {
         volumeoper=loteinicial*208;
         volumemaximo=volumeinicial*208;
        }
      if(capital>=1050000 && saldo<1060000)
        {
         volumeoper=loteinicial*210;
         volumemaximo=volumeinicial*210;
        }
      if(capital>=1060000 && saldo<1070000)
        {
         volumeoper=loteinicial*212;
         volumemaximo=volumeinicial*212;
        }
      if(capital>=1070000 && saldo<1080000)
        {
         volumeoper=loteinicial*214;
         volumemaximo=volumeinicial*214;
        }
      if(capital>=1080000 && saldo<1090000)
        {
         volumeoper=loteinicial*216;
         volumemaximo=volumeinicial*216;
        }
      if(capital>=1090000 && saldo<1100000)
        {
         volumeoper=loteinicial*218;
         volumemaximo=volumeinicial*218;
        }
      if(capital>=1100000 && saldo<1110000)
        {
         volumeoper=loteinicial*220;
         volumemaximo=volumeinicial*220;
        }
      if(capital>=1110000 && saldo<1120000)
        {
         volumeoper=loteinicial*222;
         volumemaximo=volumeinicial*222;
        }
      if(capital>=1120000 && saldo<1130000)
        {
         volumeoper=loteinicial*224;
         volumemaximo=volumeinicial*224;
        }
      if(capital>=1130000 && saldo<1140000)
        {
         volumeoper=loteinicial*226;
         volumemaximo=volumeinicial*226;
        }
      if(capital>=1140000 && saldo<1150000)
        {
         volumeoper=loteinicial*228;
         volumemaximo=volumeinicial*228;
        }
      if(capital>=1150000 && saldo<1160000)
        {
         volumeoper=loteinicial*230;
         volumemaximo=volumeinicial*230;
        }
      if(capital>=1160000 && saldo<1170000)
        {
         volumeoper=loteinicial*232;
         volumemaximo=volumeinicial*232;
        }
      if(capital>=1170000 && saldo<1180000)
        {
         volumeoper=loteinicial*234;
         volumemaximo=volumeinicial*234;
        }
      if(capital>=1180000 && saldo<1190000)
        {
         volumeoper=loteinicial*236;
         volumemaximo=volumeinicial*236;
        }
      if(capital>=1190000 && saldo<1200000)
        {
         volumeoper=loteinicial*238;
         volumemaximo=volumeinicial*238;
        }
      if(capital>=1200000 && saldo<1210000)
        {
         volumeoper=loteinicial*240;
         volumemaximo=volumeinicial*240;
        }
      if(capital>=1210000 && saldo<1220000)
        {
         volumeoper=loteinicial*242;
         volumemaximo=volumeinicial*242;
        }
      if(capital>=1220000 && saldo<1230000)
        {
         volumeoper=loteinicial*244;
         volumemaximo=volumeinicial*244;
        }
      if(capital>=1230000 && saldo<1240000)
        {
         volumeoper=loteinicial*246;
         volumemaximo=volumeinicial*246;
        }
      if(capital>=1240000 && saldo<1250000)
        {
         volumeoper=loteinicial*248;
         volumemaximo=volumeinicial*248;
        }
      if(capital>=1250000 && saldo<1260000)
        {
         volumeoper=loteinicial*250;
         volumemaximo=volumeinicial*250;
        }
      if(capital>=1260000 && saldo<1270000)
        {
         volumeoper=loteinicial*252;
         volumemaximo=volumeinicial*252;
        }
      if(capital>=1270000 && saldo<1280000)
        {
         volumeoper=loteinicial*254;
         volumemaximo=volumeinicial*254;
        }
      if(capital>=1280000 && saldo<1290000)
        {
         volumeoper=loteinicial*256;
         volumemaximo=volumeinicial*256;
        }
      if(capital>=1290000 && saldo<1300000)
        {
         volumeoper=loteinicial*258;
         volumemaximo=volumeinicial*258;
        }
      if(capital>=1300000 && saldo<1310000)
        {
         volumeoper=loteinicial*260;
         volumemaximo=volumeinicial*260;
        }
      if(capital>=1310000 && saldo<1320000)
        {
         volumeoper=loteinicial*262;
         volumemaximo=volumeinicial*262;
        }
      if(capital>=1320000 && saldo<1330000)
        {
         volumeoper=loteinicial*264;
         volumemaximo=volumeinicial*264;
        }
      if(capital>=1330000 && saldo<1340000)
        {
         volumeoper=loteinicial*266;
         volumemaximo=volumeinicial*266;
        }
      if(capital>=1340000 && saldo<1350000)
        {
         volumeoper=loteinicial*268;
         volumemaximo=volumeinicial*268;
        }
      if(capital>=1350000 && saldo<1360000)
        {
         volumeoper=loteinicial*270;
         volumemaximo=volumeinicial*270;
        }
      if(capital>=1360000 && saldo<1370000)
        {
         volumeoper=loteinicial*272;
         volumemaximo=volumeinicial*272;
        }
      if(capital>=1370000 && saldo<1380000)
        {
         volumeoper=loteinicial*274;
         volumemaximo=volumeinicial*274;
        }
      if(capital>=1380000 && saldo<1390000)
        {
         volumeoper=loteinicial*276;
         volumemaximo=volumeinicial*276;
        }
      if(capital>=1390000 && saldo<1400000)
        {
         volumeoper=loteinicial*278;
         volumemaximo=volumeinicial*278;
        }
      if(capital>=1400000 && saldo<1410000)
        {
         volumeoper=loteinicial*280;
         volumemaximo=volumeinicial*280;
        }
      if(capital>=1410000 && saldo<1420000)
        {
         volumeoper=loteinicial*282;
         volumemaximo=volumeinicial*282;
        }
      if(capital>=1420000 && saldo<1430000)
        {
         volumeoper=loteinicial*284;
         volumemaximo=volumeinicial*284;
        }
      if(capital>=1430000 && saldo<1440000)
        {
         volumeoper=loteinicial*286;
         volumemaximo=volumeinicial*286;
        }
      if(capital>=1440000 && saldo<1450000)
        {
         volumeoper=loteinicial*288;
         volumemaximo=volumeinicial*288;
        }
      if(capital>=1450000 && saldo<1460000)
        {
         volumeoper=loteinicial*290;
         volumemaximo=volumeinicial*290;
        }
      if(capital>=1460000 && saldo<1470000)
        {
         volumeoper=loteinicial*292;
         volumemaximo=volumeinicial*292;
        }
      if(capital>=1470000 && saldo<1480000)
        {
         volumeoper=loteinicial*294;
         volumemaximo=volumeinicial*294;
        }
      if(capital>=1480000 && saldo<1490000)
        {
         volumeoper=loteinicial*296;
         volumemaximo=volumeinicial*296;
        }
      if(capital>=1490000 && saldo<1500000)
        {
         volumeoper=loteinicial*298;
         volumemaximo=volumeinicial*298;
        }
      if(capital>=1500000 && saldo<1510000)
        {
         volumeoper=loteinicial*300;
         volumemaximo=volumeinicial*300;
        }
      if(capital>=1510000 && saldo<1520000)
        {
         volumeoper=loteinicial*302;
         volumemaximo=volumeinicial*302;
        }
      if(capital>=1520000 && saldo<1530000)
        {
         volumeoper=loteinicial*304;
         volumemaximo=volumeinicial*304;
        }
      if(capital>=1530000 && saldo<1540000)
        {
         volumeoper=loteinicial*306;
         volumemaximo=volumeinicial*306;
        }
      if(capital>=1540000 && saldo<1550000)
        {
         volumeoper=loteinicial*308;
         volumemaximo=volumeinicial*308;
        }
      if(capital>=1550000 && saldo<1560000)
        {
         volumeoper=loteinicial*310;
         volumemaximo=volumeinicial*310;
        }
      if(capital>=1560000 && saldo<1570000)
        {
         volumeoper=loteinicial*312;
         volumemaximo=volumeinicial*312;
        }
      if(capital>=1570000 && saldo<1580000)
        {
         volumeoper=loteinicial*314;
         volumemaximo=volumeinicial*314;
        }
      if(capital>=1580000 && saldo<1590000)
        {
         volumeoper=loteinicial*316;
         volumemaximo=volumeinicial*316;
        }
      if(capital>=1590000 && saldo<1600000)
        {
         volumeoper=loteinicial*318;
         volumemaximo=volumeinicial*318;
        }
      if(capital>=1600000 && saldo<1610000)
        {
         volumeoper=loteinicial*320;
         volumemaximo=volumeinicial*320;
        }
      if(capital>=1610000 && saldo<1620000)
        {
         volumeoper=loteinicial*322;
         volumemaximo=volumeinicial*322;
        }
      if(capital>=1620000 && saldo<1630000)
        {
         volumeoper=loteinicial*324;
         volumemaximo=volumeinicial*324;
        }
      if(capital>=1630000 && saldo<1640000)
        {
         volumeoper=loteinicial*326;
         volumemaximo=volumeinicial*326;
        }
      if(capital>=1640000 && saldo<1650000)
        {
         volumeoper=loteinicial*328;
         volumemaximo=volumeinicial*328;
        }
      if(capital>=1650000 && saldo<1660000)
        {
         volumeoper=loteinicial*330;
         volumemaximo=volumeinicial*330;
        }
      if(capital>=1660000 && saldo<1670000)
        {
         volumeoper=loteinicial*332;
         volumemaximo=volumeinicial*332;
        }
      if(capital>=1670000 && saldo<1680000)
        {
         volumeoper=loteinicial*334;
         volumemaximo=volumeinicial*334;
        }
      if(capital>=1680000 && saldo<1690000)
        {
         volumeoper=loteinicial*336;
         volumemaximo=volumeinicial*336;
        }
      if(capital>=1690000 && saldo<1700000)
        {
         volumeoper=loteinicial*338;
         volumemaximo=volumeinicial*338;
        }
      if(capital>=1700000 && saldo<1710000)
        {
         volumeoper=loteinicial*340;
         volumemaximo=volumeinicial*340;
        }
      if(capital>=1710000 && saldo<1720000)
        {
         volumeoper=loteinicial*342;
         volumemaximo=volumeinicial*342;
        }
      if(capital>=1720000 && saldo<1730000)
        {
         volumeoper=loteinicial*344;
         volumemaximo=volumeinicial*344;
        }
      if(capital>=1730000 && saldo<1740000)
        {
         volumeoper=loteinicial*346;
         volumemaximo=volumeinicial*346;
        }
      if(capital>=1740000 && saldo<1750000)
        {
         volumeoper=loteinicial*348;
         volumemaximo=volumeinicial*348;
        }
      if(capital>=1750000 && saldo<1760000)
        {
         volumeoper=loteinicial*350;
         volumemaximo=volumeinicial*350;
        }
      if(capital>=1760000 && saldo<1770000)
        {
         volumeoper=loteinicial*352;
         volumemaximo=volumeinicial*352;
        }
      if(capital>=1770000 && saldo<1780000)
        {
         volumeoper=loteinicial*354;
         volumemaximo=volumeinicial*354;
        }
      if(capital>=1780000 && saldo<1790000)
        {
         volumeoper=loteinicial*356;
         volumemaximo=volumeinicial*356;
        }
      if(capital>=1790000 && saldo<1800000)
        {
         volumeoper=loteinicial*358;
         volumemaximo=volumeinicial*358;
        }
      if(capital>=1800000 && saldo<1810000)
        {
         volumeoper=loteinicial*360;
         volumemaximo=volumeinicial*360;
        }
      if(capital>=1810000 && saldo<1820000)
        {
         volumeoper=loteinicial*362;
         volumemaximo=volumeinicial*362;
        }
      if(capital>=1820000 && saldo<1830000)
        {
         volumeoper=loteinicial*364;
         volumemaximo=volumeinicial*364;
        }
      if(capital>=1830000 && saldo<1840000)
        {
         volumeoper=loteinicial*366;
         volumemaximo=volumeinicial*366;
        }
      if(capital>=1840000 && saldo<1850000)
        {
         volumeoper=loteinicial*368;
         volumemaximo=volumeinicial*368;
        }
      if(capital>=1850000 && saldo<1860000)
        {
         volumeoper=loteinicial*370;
         volumemaximo=volumeinicial*370;
        }
      if(capital>=1860000 && saldo<1870000)
        {
         volumeoper=loteinicial*372;
         volumemaximo=volumeinicial*372;
        }
      if(capital>=1870000 && saldo<1880000)
        {
         volumeoper=loteinicial*374;
         volumemaximo=volumeinicial*374;
        }
      if(capital>=1880000 && saldo<1890000)
        {
         volumeoper=loteinicial*376;
         volumemaximo=volumeinicial*376;
        }
      if(capital>=1890000 && saldo<1900000)
        {
         volumeoper=loteinicial*378;
         volumemaximo=volumeinicial*378;
        }
      if(capital>=1900000 && saldo<1910000)
        {
         volumeoper=loteinicial*380;
         volumemaximo=volumeinicial*80;
        }
      if(capital>=1910000 && saldo<1920000)
        {
         volumeoper=loteinicial*382;
         volumemaximo=volumeinicial*382;
        }
      if(capital>=1920000 && saldo<1930000)
        {
         volumeoper=loteinicial*384;
         volumemaximo=volumeinicial*384;
        }
      if(capital>=1930000 && saldo<1940000)
        {
         volumeoper=loteinicial*386;
         volumemaximo=volumeinicial*386;
        }
      if(capital>=1940000 && saldo<1950000)
        {
         volumeoper=loteinicial*388;
         volumemaximo=volumeinicial*388;
        }
      if(capital>=1950000 && saldo<1960000)
        {
         volumeoper=loteinicial*390;
         volumemaximo=volumeinicial*390;
        }
      if(capital>=1960000 && saldo<1970000)
        {
         volumeoper=loteinicial*392;
         volumemaximo=volumeinicial*392;
        }
      if(capital>=1970000 && saldo<1980000)
        {
         volumeoper=loteinicial*394;
         volumemaximo=volumeinicial*394;
        }
      if(capital>=1980000 && saldo<1990000)
        {
         volumeoper=loteinicial*396;
         volumemaximo=volumeinicial*396;
        }
      if(capital>=1990000 && saldo<2000000)
        {
         volumeoper=loteinicial*398;
         volumemaximo=volumeinicial*398;
        }




      if(capital>=2000000 && saldo<2010000)
        {
         volumeoper=loteinicial*400;
         volumemaximo=volumeinicial*400;
        }
      if(capital>=2010000 && saldo<2020000)
        {
         volumeoper=loteinicial*402;
         volumemaximo=volumeinicial*402;
        }
      if(capital>=2020000 && saldo<2030000)
        {
         volumeoper=loteinicial*404;
         volumemaximo=volumeinicial*404;
        }
      if(capital>=2030000 && saldo<2040000)
        {
         volumeoper=loteinicial*406;
         volumemaximo=volumeinicial*406;
        }
      if(capital>=2040000 && saldo<2050000)
        {
         volumeoper=loteinicial*408;
         volumemaximo=volumeinicial*408;
        }
      if(capital>=2050000 && saldo<2060000)
        {
         volumeoper=loteinicial*410;
         volumemaximo=volumeinicial*410;
        }
      if(capital>=2060000 && saldo<2070000)
        {
         volumeoper=loteinicial*412;
         volumemaximo=volumeinicial*412;
        }
      if(capital>=2070000 && saldo<2080000)
        {
         volumeoper=loteinicial*414;
         volumemaximo=volumeinicial*414;
        }
      if(capital>=2080000 && saldo<2090000)
        {
         volumeoper=loteinicial*416;
         volumemaximo=volumeinicial*416;
        }
      if(capital>=2090000 && saldo<2100000)
        {
         volumeoper=loteinicial*418;
         volumemaximo=volumeinicial*418;
        }
      if(capital>=2100000 && saldo<2110000)
        {
         volumeoper=loteinicial*420;
         volumemaximo=volumeinicial*420;
        }
      if(capital>=2110000 && saldo<2120000)
        {
         volumeoper=loteinicial*422;
         volumemaximo=volumeinicial*422;
        }
      if(capital>=2120000 && saldo<2130000)
        {
         volumeoper=loteinicial*424;
         volumemaximo=volumeinicial*424;
        }
      if(capital>=2130000 && saldo<2140000)
        {
         volumeoper=loteinicial*426;
         volumemaximo=volumeinicial*426;
        }
      if(capital>=2140000 && saldo<2150000)
        {
         volumeoper=loteinicial*428;
         volumemaximo=volumeinicial*428;
        }
      if(capital>=2150000 && saldo<2160000)
        {
         volumeoper=loteinicial*430;
         volumemaximo=volumeinicial*430;
        }
      if(capital>=2160000 && saldo<2170000)
        {
         volumeoper=loteinicial*432;
         volumemaximo=volumeinicial*432;
        }
      if(capital>=2170000 && saldo<2180000)
        {
         volumeoper=loteinicial*434;
         volumemaximo=volumeinicial*434;
        }
      if(capital>=2180000 && saldo<2190000)
        {
         volumeoper=loteinicial*436;
         volumemaximo=volumeinicial*436;
        }
      if(capital>=2190000 && saldo<2200000)
        {
         volumeoper=loteinicial*438;
         volumemaximo=volumeinicial*438;
        }
      if(capital>=2200000 && saldo<2210000)
        {
         volumeoper=loteinicial*440;
         volumemaximo=volumeinicial*440;
        }
      if(capital>=2210000 && saldo<2220000)
        {
         volumeoper=loteinicial*442;
         volumemaximo=volumeinicial*442;
        }
      if(capital>=2220000 && saldo<2230000)
        {
         volumeoper=loteinicial*444;
         volumemaximo=volumeinicial*444;
        }
      if(capital>=2230000 && saldo<2240000)
        {
         volumeoper=loteinicial*446;
         volumemaximo=volumeinicial*446;
        }
      if(capital>=2240000 && saldo<2250000)
        {
         volumeoper=loteinicial*448;
         volumemaximo=volumeinicial*448;
        }
      if(capital>=2250000 && saldo<2260000)
        {
         volumeoper=loteinicial*450;
         volumemaximo=volumeinicial*450;
        }
      if(capital>=2260000 && saldo<2270000)
        {
         volumeoper=loteinicial*452;
         volumemaximo=volumeinicial*452;
        }
      if(capital>=2270000 && saldo<2280000)
        {
         volumeoper=loteinicial*454;
         volumemaximo=volumeinicial*454;
        }
      if(capital>=2280000 && saldo<2290000)
        {
         volumeoper=loteinicial*456;
         volumemaximo=volumeinicial*456;
        }
      if(capital>=2290000 && saldo<2300000)
        {
         volumeoper=loteinicial*458;
         volumemaximo=volumeinicial*458;
        }
      if(capital>=2300000 && saldo<2310000)
        {
         volumeoper=loteinicial*460;
         volumemaximo=volumeinicial*460;
        }
      if(capital>=2310000 && saldo<2320000)
        {
         volumeoper=loteinicial*462;
         volumemaximo=volumeinicial*462;
        }
      if(capital>=2320000 && saldo<2330000)
        {
         volumeoper=loteinicial*464;
         volumemaximo=volumeinicial*464;
        }
      if(capital>=2330000 && saldo<2340000)
        {
         volumeoper=loteinicial*466;
         volumemaximo=volumeinicial*466;
        }
      if(capital>=2340000 && saldo<2350000)
        {
         volumeoper=loteinicial*468;
         volumemaximo=volumeinicial*468;
        }
      if(capital>=2350000 && saldo<2360000)
        {
         volumeoper=loteinicial*470;
         volumemaximo=volumeinicial*470;
        }
      if(capital>=2360000 && saldo<2370000)
        {
         volumeoper=loteinicial*472;
         volumemaximo=volumeinicial*472;
        }
      if(capital>=2370000 && saldo<2380000)
        {
         volumeoper=loteinicial*474;
         volumemaximo=volumeinicial*474;
        }
      if(capital>=2380000 && saldo<2390000)
        {
         volumeoper=loteinicial*476;
         volumemaximo=volumeinicial*476;
        }
      if(capital>=2390000 && saldo<2400000)
        {
         volumeoper=loteinicial*478;
         volumemaximo=volumeinicial*478;
        }
      if(capital>=2400000 && saldo<2410000)
        {
         volumeoper=loteinicial*480;
         volumemaximo=volumeinicial*480;
        }
      if(capital>=2410000 && saldo<2420000)
        {
         volumeoper=loteinicial*482;
         volumemaximo=volumeinicial*482;
        }
      if(capital>=2420000 && saldo<2430000)
        {
         volumeoper=loteinicial*484;
         volumemaximo=volumeinicial*484;
        }
      if(capital>=2430000 && saldo<2440000)
        {
         volumeoper=loteinicial*486;
         volumemaximo=volumeinicial*486;
        }
      if(capital>=2440000 && saldo<2450000)
        {
         volumeoper=loteinicial*488;
         volumemaximo=volumeinicial*488;
        }
      if(capital>=2450000 && saldo<2460000)
        {
         volumeoper=loteinicial*490;
         volumemaximo=volumeinicial*490;
        }
      if(capital>=2460000 && saldo<2470000)
        {
         volumeoper=loteinicial*492;
         volumemaximo=volumeinicial*492;
        }
      if(capital>=2470000 && saldo<2480000)
        {
         volumeoper=loteinicial*494;
         volumemaximo=volumeinicial*494;
        }
      if(capital>=2480000 && saldo<2490000)
        {
         volumeoper=loteinicial*496;
         volumemaximo=volumeinicial*496;
        }
      if(capital>=2490000 && saldo<2500000)
        {
         volumeoper=loteinicial*498;
         volumemaximo=volumeinicial*498;
        }
      if(capital>=2500000 && saldo<2510000)
        {
         volumeoper=loteinicial*500;
         volumemaximo=volumeinicial*500;
        }
      if(capital>=2510000 && saldo<2520000)
        {
         volumeoper=loteinicial*502;
         volumemaximo=volumeinicial*502;
        }
      if(capital>=2520000 && saldo<2530000)
        {
         volumeoper=loteinicial*504;
         volumemaximo=volumeinicial*504;
        }
      if(capital>=2530000 && saldo<2540000)
        {
         volumeoper=loteinicial*506;
         volumemaximo=volumeinicial*506;
        }
      if(capital>=2540000 && saldo<2550000)
        {
         volumeoper=loteinicial*508;
         volumemaximo=volumeinicial*508;
        }
      if(capital>=2550000 && saldo<2560000)
        {
         volumeoper=loteinicial*510;
         volumemaximo=volumeinicial*510;
        }
      if(capital>=2560000 && saldo<2570000)
        {
         volumeoper=loteinicial*512;
         volumemaximo=volumeinicial*512;
        }
      if(capital>=2570000 && saldo<2580000)
        {
         volumeoper=loteinicial*514;
         volumemaximo=volumeinicial*514;
        }
      if(capital>=2580000 && saldo<2590000)
        {
         volumeoper=loteinicial*516;
         volumemaximo=volumeinicial*516;
        }
      if(capital>=2590000 && saldo<2600000)
        {
         volumeoper=loteinicial*518;
         volumemaximo=volumeinicial*518;
        }
      if(capital>=2600000 && saldo<2610000)
        {
         volumeoper=loteinicial*520;
         volumemaximo=volumeinicial*520;
        }
      if(capital>=2610000 && saldo<2620000)
        {
         volumeoper=loteinicial*522;
         volumemaximo=volumeinicial*522;
        }
      if(capital>=2620000 && saldo<2630000)
        {
         volumeoper=loteinicial*524;
         volumemaximo=volumeinicial*524;
        }
      if(capital>=2630000 && saldo<2640000)
        {
         volumeoper=loteinicial*526;
         volumemaximo=volumeinicial*526;
        }
      if(capital>=2640000 && saldo<2650000)
        {
         volumeoper=loteinicial*528;
         volumemaximo=volumeinicial*528;
        }
      if(capital>=2650000 && saldo<2660000)
        {
         volumeoper=loteinicial*530;
         volumemaximo=volumeinicial*530;
        }
      if(capital>=2660000 && saldo<2670000)
        {
         volumeoper=loteinicial*532;
         volumemaximo=volumeinicial*532;
        }
      if(capital>=2670000 && saldo<2680000)
        {
         volumeoper=loteinicial*534;
         volumemaximo=volumeinicial*534;
        }
      if(capital>=2680000 && saldo<2690000)
        {
         volumeoper=loteinicial*536;
         volumemaximo=volumeinicial*536;
        }
      if(capital>=2690000 && saldo<2700000)
        {
         volumeoper=loteinicial*538;
         volumemaximo=volumeinicial*538;
        }
      if(capital>=2700000 && saldo<2710000)
        {
         volumeoper=loteinicial*540;
         volumemaximo=volumeinicial*540;
        }
      if(capital>=2710000 && saldo<2720000)
        {
         volumeoper=loteinicial*542;
         volumemaximo=volumeinicial*542;
        }
      if(capital>=2720000 && saldo<2730000)
        {
         volumeoper=loteinicial*544;
         volumemaximo=volumeinicial*544;
        }
      if(capital>=2730000 && saldo<2740000)
        {
         volumeoper=loteinicial*546;
         volumemaximo=volumeinicial*546;
        }
      if(capital>=2740000 && saldo<2750000)
        {
         volumeoper=loteinicial*548;
         volumemaximo=volumeinicial*548;
        }
      if(capital>=2750000 && saldo<2760000)
        {
         volumeoper=loteinicial*550;
         volumemaximo=volumeinicial*550;
        }
      if(capital>=2760000 && saldo<2770000)
        {
         volumeoper=loteinicial*552;
         volumemaximo=volumeinicial*552;
        }
      if(capital>=2770000 && saldo<2780000)
        {
         volumeoper=loteinicial*554;
         volumemaximo=volumeinicial*554;
        }
      if(capital>=2780000 && saldo<2790000)
        {
         volumeoper=loteinicial*556;
         volumemaximo=volumeinicial*556;
        }
      if(capital>=2790000 && saldo<2800000)
        {
         volumeoper=loteinicial*558;
         volumemaximo=volumeinicial*558;
        }
      if(capital>=2800000 && saldo<2810000)
        {
         volumeoper=loteinicial*560;
         volumemaximo=volumeinicial*560;
        }
      if(capital>=2810000 && saldo<2820000)
        {
         volumeoper=loteinicial*562;
         volumemaximo=volumeinicial*562;
        }
      if(capital>=2820000 && saldo<2830000)
        {
         volumeoper=loteinicial*564;
         volumemaximo=volumeinicial*564;
        }
      if(capital>=2830000 && saldo<2840000)
        {
         volumeoper=loteinicial*566;
         volumemaximo=volumeinicial*566;
        }
      if(capital>=2840000 && saldo<2850000)
        {
         volumeoper=loteinicial*568;
         volumemaximo=volumeinicial*568;
        }
      if(capital>=2850000 && saldo<2860000)
        {
         volumeoper=loteinicial*570;
         volumemaximo=volumeinicial*570;
        }
      if(capital>=2860000 && saldo<2870000)
        {
         volumeoper=loteinicial*572;
         volumemaximo=volumeinicial*572;
        }
      if(capital>=2870000 && saldo<2880000)
        {
         volumeoper=loteinicial*574;
         volumemaximo=volumeinicial*574;
        }
      if(capital>=2880000 && saldo<2890000)
        {
         volumeoper=loteinicial*576;
         volumemaximo=volumeinicial*576;
        }
      if(capital>=2890000 && saldo<2900000)
        {
         volumeoper=loteinicial*578;
         volumemaximo=volumeinicial*578;
        }
      if(capital>=2900000 && saldo<2910000)
        {
         volumeoper=loteinicial*580;
         volumemaximo=volumeinicial*80;
        }
      if(capital>=2910000 && saldo<2920000)
        {
         volumeoper=loteinicial*582;
         volumemaximo=volumeinicial*582;
        }
      if(capital>=2920000 && saldo<2930000)
        {
         volumeoper=loteinicial*584;
         volumemaximo=volumeinicial*584;
        }
      if(capital>=2930000 && saldo<2940000)
        {
         volumeoper=loteinicial*586;
         volumemaximo=volumeinicial*586;
        }
      if(capital>=2940000 && saldo<2950000)
        {
         volumeoper=loteinicial*588;
         volumemaximo=volumeinicial*588;
        }
      if(capital>=2950000 && saldo<2960000)
        {
         volumeoper=loteinicial*590;
         volumemaximo=volumeinicial*590;
        }
      if(capital>=2960000 && saldo<2970000)
        {
         volumeoper=loteinicial*592;
         volumemaximo=volumeinicial*592;
        }
      if(capital>=2970000 && saldo<2980000)
        {
         volumeoper=loteinicial*594;
         volumemaximo=volumeinicial*594;
        }
      if(capital>=2980000 && saldo<2990000)
        {
         volumeoper=loteinicial*596;
         volumemaximo=volumeinicial*596;
        }
      if(capital>=2990000 && saldo<3000000)
        {
         volumeoper=loteinicial*598;
         volumemaximo=volumeinicial*598;
        }

     }

//--- Definição dos volumes de compra e venda quando utilizar martingale
   if(tipomartingale==mart1)//dobro do volume acumulado
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
   if(tipomartingale==mart2)//dobro do volume anterior
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
   if(tipomartingale==mart3)//sequência de fibonacci p/ volume
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
   if(tipomartingale==mart4)//mix - fibo ate a 5 ordem e o dobro do anterior nas proximas ordens
     {
      volnv2             = 2*volumeoper;//2
      volnv3             = 3*volumeoper;//3
      volnv4             = 4*volumeoper;//4
      volnv5             = 5*volumeoper;//5
      volnv6             = volnv4*multiplicador;//10
      volnv7             = volnv5*multiplicador;//20
      volnv8             = volnv6*multiplicador;//30
      volnv9             = volnv7*multiplicador;//40
     }

   saldo = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
   lucro_prejuizo = NormalizeDouble(AccountInfoDouble(ACCOUNT_PROFIT),2);
   capital = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY),2);
//   double margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN),2);
//   double margem_livre = NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN),2);
   percent_margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),2);

//+------------------------------------------------------------------+
//| ENVIO DE SINAIS P/ REDE NEURAL                                   |
//+------------------------------------------------------------------+
   if(ativaenvioneural==true)
     {
      if(!PossuiPosCompra() && !PossuiPosVenda())
        {
         open1  = DoubleToString(candle[2].open,5);
         open2  = DoubleToString(candle[1].open,5);
         low1   = DoubleToString(candle[2].low,5);
         low2   = DoubleToString(candle[1].low,5);
         high1  = DoubleToString(candle[2].high,5);
         high2  = DoubleToString(candle[1].high,5);
         close1 = DoubleToString(candle[2].close,5);
         close2 = DoubleToString(candle[1].close,5);

         envioneural = open1+","+low1+","+high1+","+close1+","+open2+","+low2+","+high2+","+close2;

         if(NB2.IsNewBar(_Symbol,_Period)) //VERIFICA SE É UM NOVO CANDLE
           {
            if(SocketIsConnected(socketneural))
              {
               enviado = socksend(socketneural,envioneural);
               Alert("Dados enviados: ",envioneural);
              }
            else
               Print("Falhou conexão a ",endereco,":",porta,", erro ",GetLastError());

            Sleep(300);

            if(SocketIsConnected(socketneural))
              {
               recebido = socketreceive(socketneural,1000);
               Print("Dados recebidos: ",recebido);
              }
            else
               Print("soquete para recebimento não conectado!");
           }

         //+------------------------------------------------------------------+
         //| APÓS PREVISÃO RECEBIDA EFETUAR AS OPERAÇÕES DENTRO DA ESTRATÉGIA |
         //+------------------------------------------------------------------+
         if(recebido!="")
           {
            previsao_temp=StringToDouble(recebido);
            //previsao_temp = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
            if(ativaentradaea==true && (percent_margem>prctniveloper||saldo==capital))
              {
               if(previsao_temp > tick.ask && previsao_temp!=0.0 && rsi[0]<30)
                 {
                  trade.Buy(volumeoper,_Symbol,tick.ask,0.50000,0,"C1");
                  trade.BuyLimit(volnv2,prcnvl_2,_Symbol,0.50000,0,0,0,"C2");
                  trade.BuyLimit(volnv3,prcnvl_3,_Symbol,0.50000,0,0,0,"C3");
                  trade.BuyLimit(volnv4,prcnvl_4,_Symbol,0.50000,0,0,0,"C4");
                  trade.BuyLimit(volnv5,prcnvl_5,_Symbol,0.50000,0,0,0,"C5");
                  trade.BuyLimit(volnv6,prcnvl_6,_Symbol,0.50000,0,0,0,"C6");
                  trade.BuyLimit(volnv7,prcnvl_7,_Symbol,0.50000,0,0,0,"C7");
                  trade.BuyLimit(volnv8,prcnvl_8,_Symbol,0.50000,0,0,0,"C8");
                  trade.BuyLimit(volnv9,prcnvl_9,_Symbol,0.50000,0,0,0,"C9");
                  return;
                 }
               if(previsao_temp < tick.bid && previsao_temp!=0.0 && rsi[0]>70)
                 {
                  trade.Sell(volumeoper,_Symbol,tick.bid,1.63000,0,"V1");
                  trade.SellLimit(volnv2,prcnvl2,_Symbol,1.63000,0,0,0,"V2");
                  trade.SellLimit(volnv3,prcnvl3,_Symbol,1.63000,0,0,0,"V3");
                  trade.SellLimit(volnv4,prcnvl4,_Symbol,1.63000,0,0,0,"V4");
                  trade.SellLimit(volnv5,prcnvl5,_Symbol,1.63000,0,0,0,"V5");
                  trade.SellLimit(volnv6,prcnvl6,_Symbol,1.63000,0,0,0,"V6");
                  trade.SellLimit(volnv7,prcnvl7,_Symbol,1.63000,0,0,0,"V7");
                  trade.SellLimit(volnv8,prcnvl8,_Symbol,1.63000,0,0,0,"V8");
                  trade.SellLimit(volnv9,prcnvl9,_Symbol,1.63000,0,0,0,"V9");
                  return;
                 }
              }
           }
        }

      ////////////////////////////////////////////////////////
      //---|Fechando as ordens pendentes não utilizadas|----//
      ////////////////////////////////////////////////////////
      if(!PossuiPosCompra() && !PossuiPosVenda() && PossuiOrdemPendente())
         ExcluiOrdensPendentes();

      ///////////////////////////////////////////////////////////////
      //---|Fechando as ordens pendentes quando margem pequena|----//
      ///////////////////////////////////////////////////////////////
      if((PossuiPosCompra() || PossuiPosVenda()) && PossuiOrdemPendente() && (percent_margem<prctniveloper||VolumePos()>volumemaximo) && saldo!=capital)
         ExcluiOrdensPendentes();

      ////////////////////////////////////
      //---|Fechamento das posições|----//
      ////////////////////////////////////
      if(ativasaidaea==true)
        {
         if(PossuiPosCompraComentada("C1") && tick.bid>PrecoAberturaPosCompra()+pontosc1*_Point)
           {
            if(ativaBE==true)
               BreakEvenCompra();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosCompraComentada("C2") && tick.bid>PrecoAberturaPosCompra()+pontosc2*_Point)
           {
            if(ativaBE==true)
               BreakEvenCompra();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosCompraComentada("C3") && tick.bid>PrecoAberturaPosCompra()+pontosc3*_Point)
           {
            if(ativaBE==true)
               BreakEvenCompra();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosCompraComentada("C4") && tick.bid>PrecoAberturaPosCompra()+pontosc4*_Point)
           {
            if(ativaBE==true)
               BreakEvenCompra();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosCompraComentada("C5") && tick.bid>PrecoAberturaPosCompra()+pontosc5*_Point)
           {
            if(ativaBE==true)
               BreakEvenCompra();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosCompraComentada("C6") && tick.bid>PrecoAberturaPosCompra()+pontosc6*_Point)
           {
            if(ativaBE==true)
               BreakEvenCompra();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosCompraComentada("C7") && tick.bid>PrecoAberturaPosCompra()+pontosc7*_Point)
           {
            if(ativaBE==true)
               BreakEvenCompra();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosCompraComentada("C8") && tick.bid>PrecoAberturaPosCompra()+pontosc8*_Point)
           {
            if(ativaBE==true)
               BreakEvenCompra();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosCompraComentada("C9") && tick.bid>PrecoAberturaPosCompra()+pontosc9*_Point)
           {
            if(ativaBE==true)
               BreakEvenCompra();
            else
               FechaTodasPosicoesAbertas();
           }

         if(PossuiPosVendaComentada("V1") && tick.ask<PrecoAberturaPosVenda()-pontosc1*_Point)
           {
            if(ativaBE==true)
               BreakEvenVenda();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosVendaComentada("V2") && tick.ask<PrecoAberturaPosVenda()-pontosc2*_Point)
           {
            if(ativaBE==true)
               BreakEvenVenda();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosVendaComentada("V3") && tick.ask<PrecoAberturaPosVenda()-pontosc3*_Point)
           {
            if(ativaBE==true)
               BreakEvenVenda();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosVendaComentada("V4") && tick.ask<PrecoAberturaPosVenda()-pontosc4*_Point)
           {
            if(ativaBE==true)
               BreakEvenVenda();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosVendaComentada("V5") && tick.ask<PrecoAberturaPosVenda()-pontosc5*_Point)
           {
            if(ativaBE==true)
               BreakEvenVenda();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosVendaComentada("V6") && tick.ask<PrecoAberturaPosVenda()-pontosc6*_Point)
           {
            if(ativaBE==true)
               BreakEvenVenda();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosVendaComentada("V7") && tick.ask<PrecoAberturaPosVenda()-pontosc7*_Point)
           {
            if(ativaBE==true)
               BreakEvenVenda();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosVendaComentada("V8") && tick.ask<PrecoAberturaPosVenda()-pontosc8*_Point)
           {
            if(ativaBE==true)
               BreakEvenVenda();
            else
               FechaTodasPosicoesAbertas();
           }
         if(PossuiPosVendaComentada("V9") && tick.ask<PrecoAberturaPosVenda()-pontosc9*_Point)
           {
            if(ativaBE==true)
               BreakEvenVenda();
            else
               FechaTodasPosicoesAbertas();
           }

         //////////////////////////
         //---|TRAILING STOP|----//
         //////////////////////////
         if(ativaTS==true)
           {
            TrailingStopCompra();
            TrailingStopVenda();
           }
        }
     }
//////////////////////////
//---|STOP FORÇADO |----//
//////////////////////////
   if(ativastop==true)
     {
      if(MathAbs(lucro_prejuizo) > stopemdolar && saldo != capital)
         FechaTodasPosicoesAbertas();
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
//+--------------------------------------------------------+
//| VERIFICA SE HÁ PELO MENOS UMA POSIÇÃO DE COMPRA ABERTA |
//+--------------------------------------------------------+
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
//+-------------------------------------------------------+
//| VERIFICA SE HÁ PELO MENOS UMA POSIÇÃO DE VENDA ABERTA |
//+-------------------------------------------------------+
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
//+------------------------------------------------------------------+
//| FUNÇÃO DE VERIFICAÇÃO DE HORÁRIO DE PARA ABERTURA DE ORDENS      |
//+------------------------------------------------------------------+
bool HorarioEntrada() //VERIFICA SE ESTÁ NO HORARIO DE FUNCIONAMENTO DO ROBÔ
  {
   TimeToStruct(TimeCurrent(), horario_atual); // Obtenção do horário atual

// Hora dentro do horário de entradas
   if(horario_atual.hour >= horario_inicio.hour && horario_atual.hour <= horario_termino.hour)
     {
      // Hora atual igual a de início
      if(horario_atual.hour == horario_inicio.hour)
         // Se minuto atual maior ou igual ao de início => está no horário de entradas
         if(horario_atual.min >= horario_inicio.min)
            return true;
      // Do contrário não está no horário de entradas
         else
            return false;

      // Hora atual igual a de término
      if(horario_atual.hour == horario_termino.hour)
         // Se minuto atual menor ou igual ao de término => está no horário de entradas
         if(horario_atual.min <= horario_termino.min)
            return true;
      // Do contrário não está no horário de entradas
         else
            return false;

      // Hora atual maior que a de início e menor que a de término
      return true;
     }

// Hora fora do horário de entradas
   return false;
  }
//+------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| FUNÇÃO DE VERIFICAÇÃO DE HORA PARA PAUSAR O ROBÔ CONTRA NOTÍCIAS |
//+------------------------------------------------------------------+
bool HorarioPausa1() //VERIFICA SE ESTÁ NO HORÁRIO DE PAUSA DO ROBÔ
  {
   TimeToStruct(TimeCurrent(), horario_atual); // Obtenção do horário atual

// Hora dentro do horário de entradas
   if(horario_atual.hour >= horario_inicio_pausa1.hour && horario_atual.hour <= horario_termino_pausa1.hour)
     {
      // Hora atual igual a de início
      if(horario_atual.hour == horario_inicio_pausa1.hour)
         // Se minuto atual maior ou igual ao de início => não está no horário de entradas
         if(horario_atual.min >= horario_inicio_pausa1.min)
            return true;
      // Do contrário está no horário de entradas
         else
            return false;

      // Hora atual igual a de término
      if(horario_atual.hour == horario_termino_pausa1.hour)
         // Se minuto atual menor ou igual ao de término => não está no horário de entradas
         if(horario_atual.min <= horario_termino_pausa1.min)
            return true;
      // Do contrário está no horário de entradas
         else
            return false;

      // Hora atual maior que a de início da pausa1 e menor que a de término da pausa
      return true;
     }
// Hora dentro do horário de entradas(fora do intervalo acima)
   return false;
  }
//+------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| FUNÇÃO DE VERIFICAÇÃO DE HORA PARA PAUSAR O ROBÔ CONTRA NOTÍCIAS |
//+------------------------------------------------------------------+
bool HorarioPausa2() //VERIFICA SE ESTÁ NO HORÁRIO DE PAUSA DO ROBÔ
  {
   TimeToStruct(TimeCurrent(), horario_atual); // Obtenção do horário atual

// Hora dentro do horário de entradas
   if(horario_atual.hour >= horario_inicio_pausa2.hour && horario_atual.hour <= horario_termino_pausa2.hour)
     {
      // Hora atual igual a de início
      if(horario_atual.hour == horario_inicio_pausa2.hour)
         // Se minuto atual maior ou igual ao de início => não está no horário de entradas
         if(horario_atual.min >= horario_inicio_pausa2.min)
            return true;
      // Do contrário está no horário de entradas
         else
            return false;

      // Hora atual igual a de término
      if(horario_atual.hour == horario_termino_pausa2.hour)
         // Se minuto atual menor ou igual ao de término => não está no horário de entradas
         if(horario_atual.min <= horario_termino_pausa2.min)
            return true;
      // Do contrário está no horário de entradas
         else
            return false;

      // Hora atual maior que a de início da pausa2 e menor que a de término da pausa
      return true;
     }
// Hora dentro do horário de entradas(fora do intervalo acima)
   return false;
  }
//+-------
//+------------------------------------------------------------------+
//+----------------------------------------------+
//| FUNÇÃO PARA LER OS ARQUIVOS E SUAS PREVISÕES |
//+----------------------------------------------+
/*void ReadFileToDictCSV(string FileName)
  {
   int h=FileOpen(FileName,FILE_READ|FILE_ANSI|FILE_CSV|FILE_COMMON);
   string result[];
   string sep=",";
   ushort u_sep;

   u_sep=StringGetCharacter(sep,0);

   if(h==INVALID_HANDLE)
     {
      Alert("Error opening file",GetLastError());
      return;
     }
   while(!FileIsEnding(h))
     {
      //Print(FileReadString(h));
      StringSplit(FileReadString(h),u_sep,result);
      dict.Set<string>(result[0],result[3]);
     }

   FileClose(h);
  } */
//+------------------------------------------------------------------+
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
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(TipoPosicao==POSITION_TYPE_BUY && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return price;
         break;
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
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(TipoPosicao==POSITION_TYPE_SELL && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return price;
         break;
        }
     }
   return 0;
  }
//+------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| BREAKEVEN PARA POSIÇÕES DE COMPRA                                |
//+------------------------------------------------------------------+
void BreakEvenCompra()
  {
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total = PositionsTotal(); // número de posições abertas
   for(int i = total-1; i >= 0; i--)
     {
      //--- aquisição dos parâmetros da posição para posterior composição da ordem de breakeven
      ulong  position_ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double sl = PositionGetDouble(POSITION_SL);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_symbol==_Symbol /*&& magic == magicrobo*/ && type == POSITION_TYPE_BUY && sl < price - recuoBE*_Point)
        {
         //--- zerar os valores do pedido e os seus resultados
         ZeroMemory(request);
         ZeroMemory(result);
         //--- composição dos parâmetros da ordem de alteração da posição
         request.action   = TRADE_ACTION_SLTP;                  // tipo de operação de negociação
         request.position = position_ticket;                    // bilhete da posição
         request.symbol   = position_symbol;                    // ativo
         request.sl       = tick.bid-recuoBE*_Point;            // novo stoploss no preço corrente mais os pontos definidos no input
         //request.magic    = magic;                              // magic number da posição
         if(!OrderSend(request,result))                         // envio da ordem para a corretora
            PrintFormat("OrderSend error %d",GetLastError());   // se não for possível enviar o pedido, exibir um código de erro
         //PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
        }
     }
  }
//+------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| BREAKEVEN PARA POSIÇÕES DE VENDA                                 |
//+------------------------------------------------------------------+
void BreakEvenVenda()
  {
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total = PositionsTotal(); // número de posições abertas
   for(int i = total-1; i >= 0; i--)
     {
      //--- aquisição dos parâmetros da posição para posterior composição da ordem de breakeven
      ulong  position_ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double sl = PositionGetDouble(POSITION_SL);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_symbol==_Symbol /*&& magic == magicrobo*/ && type == POSITION_TYPE_SELL && sl > price + recuoBE*_Point)
        {
         //--- zerar os valores do pedido e os seus resultados
         ZeroMemory(request);
         ZeroMemory(result);
         //--- composição dos parâmetros da ordem de alteração da posição
         request.action   = TRADE_ACTION_SLTP;                  // tipo de operação de negociação
         request.position = position_ticket;                    // bilhete da posição
         request.symbol   = position_symbol;                    // ativo
         request.sl       = tick.ask+recuoBE*_Point;            // novo stoploss no preço corrente mais os pontos definidos no input
         //request.magic    = magic;                              // magic number da posição
         if(!OrderSend(request,result))                         // envio da ordem para a corretora
            PrintFormat("OrderSend error %d",GetLastError());   // se não for possível enviar o pedido, exibir um código de erro
         //PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
        }
     }
  }
//+------------------------------------------------------------------------------------------+
//+----------------------------------------+
//| TRAILLING STOP PARA POSIÇÕES DE COMPRA |
//+----------------------------------------+
void  TrailingStopCompra()
  {
   MqlTradeRequest request;
   MqlTradeResult  result;
   stopcompra = StopUltimaPosCompraAberta();
   int total = PositionsTotal(); // número de posições abertas
   for(int i = total-1; i >= 0; i--)
     {
      //--- aquisição dos parâmetros da posição para posterior composição da ordem de trailling stop
      ulong  position_ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double sl = PositionGetDouble(POSITION_SL);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE type =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_symbol==_Symbol /*&& magic == magicrobo*/ && type == POSITION_TYPE_BUY && sl >= price - recuoBE*_Point && tick.bid >= sl + pontosTS*_Point)
        {
         //--- zerar os valores do pedido e os seus resultados
         ZeroMemory(request);
         ZeroMemory(result);
         //--- composição dos parâmetros da ordem de alteração da posição
         request.action   = TRADE_ACTION_SLTP;                  // tipo de operação de negociação
         request.position = position_ticket;                    // bilhete da posição
         request.symbol   = position_symbol;                    // ativo
         request.sl       = (sl+avancoTS*_Point);               // novo stop loss
         //request.magic    = magic;                              // magic number da posição
         if(!OrderSend(request,result))                         // envio da ordem para a corretora
            PrintFormat("OrderSend error %d",GetLastError());   // se não for possível enviar o pedido, exibir um código de erro
         //PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
        }
     }
  }
//+------------------------------------------------------------------------------------------+
//+---------------------------------------+
//| TRAILLING STOP PARA POSIÇÕES DE VENDA |
//+---------------------------------------+
void  TrailingStopVenda()
  {
   MqlTradeRequest request;
   MqlTradeResult  result;
   stopvenda = StopUltimaPosVendaAberta();
   int total = PositionsTotal(); // número de posições abertas
   for(int i = total-1; i >= 0; i--)
     {
      //--- aquisição dos parâmetros da posição para posterior composição da ordem de trailling stop
      ulong  position_ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double sl = PositionGetDouble(POSITION_SL);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE type =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_symbol==_Symbol /*&& magic == magicrobo*/ && type == POSITION_TYPE_SELL && sl <= price + recuoBE*_Point && tick.ask <= sl - pontosTS*_Point)
        {
         //--- zerar os valores do pedido e os seus resultados
         ZeroMemory(request);
         ZeroMemory(result);
         //--- composição dos parâmetros da ordem de alteração da posição
         request.action   = TRADE_ACTION_SLTP;                  // tipo de operação de negociação
         request.position = position_ticket;                    // bilhete da posição
         request.symbol   = position_symbol;                    // ativo
         request.sl       = (sl-avancoTS*_Point);               // novo stop loss
         //request.magic    = magic;                              // magic number da posição
         if(!OrderSend(request,result))                         // envio da ordem para a corretora
            PrintFormat("OrderSend error %d",GetLastError());   // se não for possível enviar o pedido, exibir um código de erro
         //PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
        }
     }
  }
//+------------------------------------------------------------------------------------------+
//+-------------------------------------------------------+
//| RETORNA O STOPLOSS DA ÚLTIMA POSIÇÃO DE COMPRA ABERTA |
//+-------------------------------------------------------+
double StopUltimaPosCompraAberta()
  {
   int posabertas = PositionsTotal();
   for(int i = posabertas-1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double sl = PositionGetDouble(POSITION_SL);
      ENUM_POSITION_TYPE tipo =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(tipo == POSITION_TYPE_BUY && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return sl;
         break;
        }
     }
   return 0;
  }
//+------------------------------------------------------------------------------------------+
//+------------------------------------------------------+
//| RETORNA O STOPLOSS DA ÚLTIMA POSIÇÃO DE VENDA ABERTA |
//+------------------------------------------------------+
double StopUltimaPosVendaAberta()
  {
   int posabertas = PositionsTotal();
   for(int i = posabertas-1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double sl = PositionGetDouble(POSITION_SL);
      ENUM_POSITION_TYPE tipo =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(tipo == POSITION_TYPE_SELL && position_symbol==_Symbol /*&& magic == magicrobo*/)
        {
         return sl;
         break;
        }
     }
   return 0;
  }
//+------------------------------------------------------------------------------------------+

/*PM1 = ((tick.ask*volumeoper+prcnvl_2*volnv2)/(volumeoper+volnv2))+pontostp*_Point;
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
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
