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
   dist1,        // [1]FIBONACCI P/ XAU
   dist2,        // [2]FIBONACCI P/ BTC
   dist3,        // [3]FIBONACCI P/ USD
   dist4,        // [4]FIXOS EM PONTOS
  };
enum ENUM_TP_MART
  {
   mart1,        // [1]2x VOLUME ACUMULADO
   mart2,        // [2]2x VOLUME ANTERIOR
   mart3,        // [3]VOLUME FIBONACCI
   mart4,        // [4]05 FIBO; 04 2x ANTERIOR
  };

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input ulong              magicrobo           = 940;        // MAGIC NUMBER DO ROBÔ
input group              "ENVIO P/ REDE NEURAL"
input bool               ativaenvioneural    = false;      // ATIVA ENVIO DE DADOS P/ SERVIDOR
input bool               ativaenviomedia     = false;      // ATIVA ENVIO DE MÉDIA MÓVEL
input ENUM_MA_METHOD     tipomedia           = MODE_SMA;   // TIPO DE MÉDIA
input int                periodomedia        = 200;        // QTDE DE CANDLES P/ MÉDIA
input bool               ativaenviorsi       = false;      // ATIVA ENVIO DE RSI
input int                periodorsi          = 10;         // QTDE DE CANDLES P/ RSI
//input double             rsicompra           = 30;         // VALOR DO RSI P/ COMPRA
//input double             rsivenda            = 70;         // VALOR DO RSI P/ VENDA
input string             endereco            = "127.0.0.1";// IP/SITE DO SERVIDOR NEURAL
input int                porta               = 8082;       // PORTA DO SERVIDOR NEURAL
input bool               ExtTLS              = false;      // ATIVA ENVIO POR HTTPS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "ABERTURA DE POSIÇÕES"
input bool               ativaentradaea      = true;       // ATIVA ABERTURA DE POSIÇÕES PELO EA
input double             loteoper            = 0.1;        // TAMANHO DO LOTE PADRÃO P/ OPERAÇÕES
//input double             pontostp            = 10;         // TAKE PROFIT EM PONTOS EM REL. AO PM
input group              "MARTINGALE"
input ENUM_TP_MART       tipomartingale      = mart1;      // TIPO DE MARTINGALE
input ENUM_TP_DIST       tipotunelvegas      = dist1;      // TIPO DE DISTÂNCIA ENTRE AS ORDENS
input double             pontosmart          = 40;         // DISTÂNCIA EM PONTOS ENTRE AS ORDENS
input int                multiplicador       = 2;          // MULTIPLICADOR MARTINGALE
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "BREAKEVEN E TRAILING STOP"
input bool               ativaBE             = false;      // ATIVA BREAKEVEN
input double             recuoBE             = 50;         // PONTOS PARA RECUO NO BREAKEVEN
input bool               ativaTS             = false;      // ATIVA TRAILING STOP
input double             pontosTS            = 40;         // PONTOS P/ ATIVAÇÃO TS
input double             avancoTS            = 10;         // AVANÇO DO STOP EM PONTOS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "FECHAMENTO DE POSIÇÕES"
input bool               ativasaidaea        = false;      // ATIVA FECHAMENTO DE POSIÇÕES PELO EA
input double             pontosc1            = 4000;       //PONTOS PARA FECHAR QUANDO 1 POSIÇÃO
input double             pontosc2            = 4000;       //PONTOS PARA FECHAR QUANDO 2 POSIÇÕES
input double             pontosc3            = 2000;       //PONTOS PARA FECHAR QUANDO 3 POSIÇÕES
input double             pontosc4            = 500;        //PONTOS PARA FECHAR QUANDO 4 POSIÇÕES
input double             pontosc5            = 400;        //PONTOS PARA FECHAR QUANDO 5 POSIÇÕES
input double             pontosc6            = 100;        //PONTOS PARA FECHAR QUANDO 6 POSIÇÕES
input double             pontosc7            = 100;        //PONTOS PARA FECHAR QUANDO 7 POSIÇÕES
input double             pontosc8            = 100;        //PONTOS PARA FECHAR QUANDO 8 POSIÇÕES
input double             pontosc9            = 100;        //PONTOS PARA FECHAR QUANDO 9 POSIÇÕES
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "HORáRIO DE FUNCIONAMENTO DO EA"
input string             inicio              = "00:05";    // HORáRIO DE INíCIO (ENTRADAS)
input string             termino             = "22:50";    // HORáRIO DE TéRMINO (ENTRADAS)
//input string             fechamento          = "23:45";     // HORáRIO DE FECHAMENTO (POSIçõES)
input string             pausainicio1        = "";         // HORáRIO DE INíCIO DA PAUSA 1(NOTíCIAS)
input string             pausatermino1       = "";         // HORáRIO DE TéRMINO DA PAUSA 1(NOTíCIAS)
input string             pausainicio2        = "";         // HORáRIO DE INíCIO DA PAUSA 2(NOTíCIAS)
input string             pausatermino2       = "";         // HORáRIO DE TéRMINO DA PAUSA 2(NOTíCIAS)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "Gerenciamento de risco"
input double             prctniveloper         = 3000;       // % MINIMO P/ NOVAS ORDENS
input double             stopclose           = 250.00;     // $ PRA FECHAR POSIÇÃO NO PREJU - STOP
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
string                   shortname;

//--- Variáveis temporárias e de carater geral
double                   volumecompra        = 0.0;
double                   volumevenda         = 0.0;
double                   stopcompra          = 0.0;
double                   stopvenda           = 0.0;
double                   takecompra          = 0.0;
double                   takevenda           = 0.0;
double                   previsao_temp       = 0.0;
double                   posicao_vendida     = 0.0;
double                   posicao_compra      = 0.0;
double                   PM1                 = 0.0;
double                   PM2                 = 0.0;
double                   PM3                 = 0.0;
double                   PM4                 = 0.0;
double                   PM5                 = 0.0;
double                   PM6                 = 0.0;
double                   PM7                 = 0.0;
double                   PMV1                 = 0.0;
double                   PMV2                 = 0.0;
double                   PMV3                 = 0.0;
double                   PMV4                 = 0.0;
double                   PMV5                 = 0.0;
double                   PMV6                 = 0.0;
double                   PMV7                 = 0.0;


double                   percent_margem, saldo, capital;

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
//bool                     aciona_mg_compra           = false;
//bool                     aciona_mg_venda            = false;
//int                      barras              = 0;

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
CDictionary *dict = new CDictionary();

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

   ArraySetAsSeries(candle,true);//

//--- Criação das structs de tempo
   TimeToStruct(StringToTime(inicio),horario_inicio);
   TimeToStruct(StringToTime(termino),horario_termino);
//   TimeToStruct(StringToTime(fechamento),horario_fechamento);
   TimeToStruct(StringToTime(pausainicio1),horario_inicio_pausa1);
   TimeToStruct(StringToTime(pausatermino1),horario_termino_pausa1);
   TimeToStruct(StringToTime(pausainicio2),horario_inicio_pausa2);
   TimeToStruct(StringToTime(pausatermino2),horario_termino_pausa2);

   ReadFileToDictCSV("previsoes.csv");

//--- Definição dos níveis FIBO p/ operar XAU
   if(tipotunelvegas==dist1)
     {
      //      lv1                = 5500;
      lv2                = 8900;
      lv3                = 14400;
      lv4                = 23300;
      lv45               = 30500;
      lv5                = 37700;
      lv55               = 49350;
      lv6                = 61000;
      lv65               = 79850;
      lv7                = 98700;
      lv75               = 129200;
      lv8                = 159700;
      lv85               = 209050;
      lv9                = 258400;
      lv95               = 338250;
     }
//--- Definição dos níveis FIBO p/ operar BTC
   if(tipotunelvegas==dist2)
     {
      lv95               = 3382500;
      lv9                = 2584000;
      lv85               = 2090500;
      lv8                = 1597000;
      lv75               = 1292000;
      lv7                = 987000;
      lv65               = 798500;
      lv6                = 610000;
      lv55               = 493500;
      lv5                = 377000;
      lv45               = 305000;
      lv4                = 233000;
      lv3                = 144000;
      lv2                = 89000;
      //lv1                = 55000;
     }
//--- Definição dos níveis FIBO p/ moedas normais
   if(tipotunelvegas==dist3)
     {
      lv2                = pontosmart;
      lv3                = 2*pontosmart;
      lv4                = 4*pontosmart;
      lv5                = 7*pontosmart;
      lv6                = 12*pontosmart;
      lv7                = 20*pontosmart;
      lv8                = 33*pontosmart;
      lv9                = 53*pontosmart;
     }
//--- Definição dos níveis fixos em pontos
   if(tipotunelvegas==dist4)
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
//--- Definição dos volumes de compra e venda quando utilizar martingale
   if(tipomartingale==mart1)//dobro do volume acumulado
     {
      volnv2             = loteoper*multiplicador;//2
      volnv3             = (loteoper+volnv2)*multiplicador;//6
      volnv4             = (loteoper+volnv2+volnv3)*multiplicador;//18
      volnv5             = (loteoper+volnv2+volnv3+volnv4)*multiplicador;//54
      volnv6             = (loteoper+volnv2+volnv3+volnv4+volnv5)*multiplicador;//162
      volnv7             = (loteoper+volnv2+volnv3+volnv4+volnv5+volnv6)*multiplicador;//486
      volnv8             = (loteoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7)*multiplicador;//1458
      volnv9             = (loteoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7+volnv8)*multiplicador;//4374
     }
   if(tipomartingale==mart2)//dobro do volume anterior
     {
      volnv2             = loteoper*multiplicador;//2
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
      volnv2             = 2*loteoper;//2
      volnv3             = 3*loteoper;//3
      volnv4             = 5*loteoper;//5
      volnv5             = 8*loteoper;//8
      volnv6             = 13*loteoper;//13
      volnv7             = 21*loteoper;//21
      volnv8             = 34*loteoper;//34
      volnv9             = 55*loteoper;//55
     }
   if(tipomartingale==mart4)//mix - fibo ate a 5 ordem e o dobro do anterior nas proximas ordens
     {
      volnv2             = 2*loteoper;//2
      volnv3             = 3*loteoper;//3
      volnv4             = 4*loteoper;//4
      volnv5             = 5*loteoper;//5
      volnv6             = volnv4*multiplicador;//10
      volnv7             = volnv5*multiplicador;//20
      volnv8             = volnv6*multiplicador;//30
      volnv9             = volnv7*multiplicador;//40
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
  }

//+------------------------------------------------------------------------------------------+
///////////////////////////////
//| INÍCIO DA FUNÇÃO ONTICK |//
///////////////////////////////
void OnTick()
  {
   CopyRates(_Symbol,_Period,0,5,candle);
   if(CopyRates(_Symbol,_Period,0,5,candle)<0)
     {
      Alert("Erro ao obter informações de Mqlrates: ", GetLastError());
      return;
     }
   if(!SymbolInfoTick(_Symbol,tick))
     {
      Alert("Erro ao obter informações de Mqlticks: ", GetLastError());
      return;
     }

//---Atualização dos preços, tick a tick, das variáveis dos níveis de vegas
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

   static CIsNewBar NB1,NB2/*,NB3,NB4,NB5,NB6,NB7,NB8,NB9,NB10,NB11,NB12,NB13,NB14,NB15,NB16,NB17,NB18,NB19,NB20,NB21,NB22*/;

   saldo = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
   double lucro_prejuizo = NormalizeDouble(AccountInfoDouble(ACCOUNT_PROFIT),2);
   capital = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY),2);
//   double margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN),2);
//   double margem_livre = NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN),2);
   percent_margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),2);
//   Comment("Nível de Margem: ","\n",percent_margem);

//+------------------------------------------------------------------+
//| ENVIO DE SINAIS P/ REDE NEURAL                                   |
//+------------------------------------------------------------------+
   if(ativaenvioneural==true && (percent_margem>prctniveloper||saldo==capital))
     {
      if(NB1.IsNewBar(_Symbol,_Period))  //VERIFICA SE É UM NOVO CANDLE
        {
         previsao_temp = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
         Print("a previsão é: ",previsao_temp);
         Print("O valor atual é: ",tick.ask);

         if(!PossuiPosCompra() && !PossuiPosVenda() && previsao_temp > tick.ask && previsao_temp!=0.0)
           {
            /*PM1 = ((tick.ask*loteoper+prcnvl_2*volnv2)/(loteoper+volnv2))+pontostp*_Point;
              PM2 = ((tick.ask*loteoper+prcnvl_2*volnv2+prcnvl_3*volnv3)/(loteoper+volnv2+volnv3))+pontostp*_Point;
              PM3 = ((tick.ask*loteoper+prcnvl_2*volnv2+prcnvl_3*volnv3+prcnvl_4*volnv4)/(loteoper+volnv2+volnv3+volnv4))+pontostp*_Point;
              PM4 = ((tick.ask*loteoper+prcnvl_2*volnv2+prcnvl_3*volnv3+prcnvl_4*volnv4+prcnvl_5*volnv5)/(loteoper+volnv2+volnv3+volnv4+volnv5))+pontostp*_Point;
              PM5 = ((tick.ask*loteoper+prcnvl_2*volnv2+prcnvl_3*volnv3+prcnvl_4*volnv4+prcnvl_5*volnv5+prcnvl_6*volnv6)/(loteoper+volnv2+volnv3+volnv4+volnv5+volnv6))+pontostp*_Point;
              PM6 = ((tick.ask*loteoper+prcnvl_2*volnv2+prcnvl_3*volnv3+prcnvl_4*volnv4+prcnvl_5*volnv5+prcnvl_6*volnv6+prcnvl_7*volnv7)/(loteoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7))+pontostp*_Point;
            */trade.Buy(loteoper,_Symbol,tick.ask,0.50000,0,"C1");
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
         if(!PossuiPosVenda() && !PossuiPosCompra() && previsao_temp < tick.bid && previsao_temp!=0.0)
           {
            /*PMV1 = ((tick.bid*loteoper+prcnvl2*volnv2)/(loteoper+volnv2))-pontostp*_Point;
            PMV2 = ((tick.bid*loteoper+prcnvl2*volnv2+prcnvl3*volnv3)/(loteoper+volnv2+volnv3))-pontostp*_Point;
            PMV3 = ((tick.bid*loteoper+prcnvl2*volnv2+prcnvl3*volnv3+prcnvl4*volnv4)/(loteoper+volnv2+volnv3+volnv4))-pontostp*_Point;
            PMV4 = ((tick.bid*loteoper+prcnvl2*volnv2+prcnvl3*volnv3+prcnvl4*volnv4+prcnvl5*volnv5)/(loteoper+volnv2+volnv3+volnv4+volnv5))-pontostp*_Point;
            PMV5 = ((tick.bid*loteoper+prcnvl2*volnv2+prcnvl3*volnv3+prcnvl4*volnv4+prcnvl5*volnv5+prcnvl6*volnv6)/(loteoper+volnv2+volnv3+volnv4+volnv5+volnv6))-pontostp*_Point;
            PMV6 = ((tick.bid*loteoper+prcnvl2*volnv2+prcnvl3*volnv3+prcnvl4*volnv4+prcnvl5*volnv5+prcnvl6*volnv6+prcnvl7*volnv7)/(loteoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7))-pontostp*_Point;
            */trade.Sell(loteoper,_Symbol,tick.bid,1.63000,0,"V1");
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

      ////////////////////////////////////////////////////////
      //---|Fechando as ordens pendentes não utilizadas|----//
      ////////////////////////////////////////////////////////
      if(!PossuiPosCompra() && !PossuiPosVenda() && PossuiOrdemPendente())
         ExcluiOrdensPendentes();

      ///////////////////////////////////////////////////////////////
      //---|Fechando as ordens pendentes quando margem pequena|----//
      ///////////////////////////////////////////////////////////////
      if((PossuiPosCompra() || PossuiPosVenda()) && PossuiOrdemPendente() && percent_margem<prctniveloper && saldo!=capital)
         ExcluiOrdensPendentes();

      ////////////////////////////////////
      //---|Fechamento das posições|----//
      ////////////////////////////////////
      if(ativasaidaea==true)
        {
         //////////////////////////
         //---|TRAILING STOP|----//
         //////////////////////////
         if(ativaTS==true)
           {
            TrailingStopCompra();
            TrailingStopVenda();
           }
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

         if(MathAbs(lucro_prejuizo) > stopclose && saldo != capital)
            FechaTodasPosicoesAbertas();
        }
     }
   /*
   if(PossuiPosCompra() && !aciona_mg_compra)
   {

    if(NormalizeDouble(posicao_compra - tick.ask, 5) >= 0.00070)
      {
       FechaTodasPosicoesAbertas();
       trade.Buy(loteoper,_Symbol,tick.ask,0,tick.ask+0.00050,"COMPRA MARTINGALE");
       posicao_compra = tick.ask;
       aciona_mg_compra = true;
       barras =   0;
      }
   }

   if(PossuiPosVenda() && !aciona_mg_venda)
   {

    if(NormalizeDouble(tick.bid - posicao_vendida, 5) >= 0.00070)
      {
       FechaTodasPosicoesAbertas();
       trade.Sell(loteoper,_Symbol,tick.bid,0,tick.bid-0.00050,"VENDA MARTINGALE");
       posicao_vendida = tick.bid;
       aciona_mg_venda = true;
       barras =   0;
      }


   }
   */

   /*
         if(NB1.IsNewBar(_Symbol,_Period))  //VERIFICA SE É UM NOVO CANDLE
           {
            previsao_temp = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
            Print("a previsão é: ",previsao_temp);
            Print("O valor atual é: ",tick.ask);


            if(barras == 2)
              {
               FechaTodasPosicoesAbertas();
               aciona_mg_compra = false;


              }

            if(previsao_temp != 0.0)
              {
               if(previsao_temp > tick.ask && (!PossuiPosCompra() && !PossuiPosVenda()))
                 {
                  trade.Buy(loteoper,_Symbol,tick.ask,0,previsao_temp,"COMPRA");
                  posicao_compra = tick.ask;
                  barras = 0;
                  aciona_mg_compra = false;

                 }

               if(previsao_temp < tick.bid && (!PossuiPosCompra() && !PossuiPosVenda()))
                 {
                  trade.Sell(loteoper,_Symbol,tick.bid,0,previsao_temp,"VENDA");
                  posicao_vendida  = tick.bid;
                  barras = 0;
                  aciona_mg_venda = false;
                 }

               barras = barras + 1;

              }
   */
   /*if(PossuiPosCompra() && previsao_temp>tick.ask)
      trade.Buy(loteoper+VolumePosCompra(),_Symbol,tick.ask,0,previsao_temp,"COMPRA MARTINGALE");
   if(PossuiPosCompra() && previsao_temp<tick.bid)
      FechaTodasPosicoesAbertas();

   if(PossuiPosVenda() && previsao_temp<tick.bid)
      trade.Sell(loteoper+VolumePosVenda(),_Symbol,tick.bid,0,previsao_temp,"VENDA MARTINGALE");
   if(PossuiPosVenda() && previsao_temp>tick.ask)
      FechaTodasPosicoesAbertas();

   if(!PossuiPosCompra() && !PossuiPosVenda() && previsao_temp>tick.ask)
      trade.Buy(loteoper,_Symbol,tick.ask,0,previsao_temp,"COMPRA");

   // if(!PossuiPosVenda() &&!PossuiPosCompra() && previsao_temp<tick.bid)
     // trade.Sell(loteoper,_Symbol,tick.bid,0,previsao_temp,"VENDA");
     */

   /*
            if(previsao_temp>tick.ask)
              {
               FechaTodasPosicoesAbertas();
               trade.Buy(loteoper,_Symbol,tick.ask,0,previsao_temp,"COMPRA");
              }

            if(previsao_temp<tick.bid)
              {
               FechaTodasPosicoesAbertas();
               trade.Sell(loteoper,_Symbol,tick.bid,0,previsao_temp,"VENDA");
              }
   */

   /*low1 = DoubleToString(candle[2].low,5);
   low2 = DoubleToString(candle[1].low,5);
   high1 = DoubleToString(candle[2].high,5);
   high2 = DoubleToString(candle[1].high,5);
   close1 = DoubleToString(candle[2].close,5);
   close2 = DoubleToString(candle[1].close,5);

   envioneural = low1+","+high1+","+close1+","+low2+","+high2+","+close2;

   if(socketneural!=INVALID_HANDLE)
     {
      Print("Confirmação de soquete criado, este é o número dele: ",socketneural);
      SocketConnect(socketneural,endereco,porta,1000);

      if(SocketIsConnected(socketneural))
        {
         enviado = socksend(socketneural,envioneural);
         Alert("Dados enviados: ",envioneural);
        }
      else
         Print("Falhou conexão a ",endereco,":",porta,", erro ",GetLastError());

      //Sleep(100);

      SocketConnect(socketneural,endereco,porta,1000);
      if(SocketIsConnected(socketneural))
        {
         recebido = socketreceive(socketneural,1000);
         Alert("Dados recebidos: ",recebido);
         //"1.00005"
        }
      else
         Print("soquete para recebimento não conectado!");

      SocketClose(socketneural);
     }


   if(recebido!="")
     {
      double recebido2=StringToDouble(recebido);
      if(recebido2>tick.ask)
        {
         //Alert("recebido: ",recebido);
         trade.Buy(loteoper,_Symbol,tick.ask,candle[1].low,recebido2,"NEURAL COMPRA");
        }
      else
        {
         //Alert("recebido: ",recebido);
         trade.Sell(loteoper,_Symbol,tick.bid,candle[1].high,recebido2,"NEURAL VENDA");
        }
     } */
  }
//+------------------------------------------------------------------+
//| OPERAÇÃO DO EA DENTRO DO HORÁRIO PRÉ DEFINIDO                    |
//+------------------------------------------------------------------+
/*if(HorarioEntrada()) //VERIFICAÇÃO DE HORÁRIO PARA FUNCIONAMENTO DO EA
  {
   if(!(HorarioPausa1() || HorarioPausa2()))
     {
      if(ativaentradaea==true) //ATIVA AS COMPRAS PELO EA DENTRO DO HORARIO DO FUNCIONAMENTO
        {
         if(percent_margem>prctniveloper||saldo==capital) //PERMITE OU NÃO A OPERAÇÃO EM FUNÇÃO DO NÍVEL DE MARGEM DE MARGEM LIVRE
           {
           }
        }
     }
  } */
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
//+---------------------------------+
//| FECHA TODAS AS POSIÇÕES ABERTAS |
//+---------------------------------+
void FechaTodasPosicoesAbertas()
  {
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      ulong  magic = PositionGetInteger(POSITION_MAGIC);
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
void ReadFileToDictCSV(string FileName)
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
      dict.Set<string>(result[1],result[4]);
     }


   FileClose(h);
  }
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
      ulong  magic = OrderGetInteger(ORDER_MAGIC);
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
      ulong  magic = OrderGetInteger(ORDER_MAGIC);
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
      ulong  magic = PositionGetInteger(POSITION_MAGIC);
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
      ulong  magic = PositionGetInteger(POSITION_MAGIC);
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
      ulong  magic = PositionGetInteger(POSITION_MAGIC);
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
         request.magic    = magic;                              // magic number da posição
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
      ulong  magic = PositionGetInteger(POSITION_MAGIC);
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
         request.magic    = magic;                              // magic number da posição
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
      ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double sl = PositionGetDouble(POSITION_SL);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE type =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_symbol==_Symbol && magic == magicrobo && type == POSITION_TYPE_BUY && sl >= price - recuoBE*_Point && tick.bid >= sl + pontosTS*_Point)
        {
         //--- zerar os valores do pedido e os seus resultados
         ZeroMemory(request);
         ZeroMemory(result);
         //--- composição dos parâmetros da ordem de alteração da posição
         request.action   = TRADE_ACTION_SLTP;                  // tipo de operação de negociação
         request.position = position_ticket;                    // bilhete da posição
         request.symbol   = position_symbol;                    // ativo
         request.sl       = (sl+avancoTS*_Point);               // novo stop loss
         request.magic    = magic;                              // magic number da posição
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
      ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double sl = PositionGetDouble(POSITION_SL);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE type =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_symbol==_Symbol && magic == magicrobo && type == POSITION_TYPE_SELL && sl <= price + recuoBE*_Point && tick.ask <= sl - pontosTS*_Point)
        {
         //--- zerar os valores do pedido e os seus resultados
         ZeroMemory(request);
         ZeroMemory(result);
         //--- composição dos parâmetros da ordem de alteração da posição
         request.action   = TRADE_ACTION_SLTP;                  // tipo de operação de negociação
         request.position = position_ticket;                    // bilhete da posição
         request.symbol   = position_symbol;                    // ativo
         request.sl       = (sl-avancoTS*_Point);               // novo stop loss
         request.magic    = magic;                              // magic number da posição
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
      ulong  magic = PositionGetInteger(POSITION_MAGIC);
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
      ulong  magic = PositionGetInteger(POSITION_MAGIC);
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
