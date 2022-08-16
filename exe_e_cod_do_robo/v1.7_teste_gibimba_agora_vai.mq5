//+------------------------------------------------------------------+
//|                                            ROBÔ FOREX NEURAL.mq5 |
//|                                            gibranvalle@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Gibran, Borges e James"
#property link      "gibranvalle@gmail.com"
#property version   "1.7"
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Bibliotecas utilizadas
#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/HistoryOrderInfo.mqh>
#include <Dictionary.mqh>
#include <IsNewBar.mqh>

enum ENUM_TP_MART
  {
   mart1,        //[1]VOLUME FIBONACCI
   mart2,        //[2]05 FIBO + 04 2x ANT
   mart3,        //[3]2x VOL ANTERIOR
   mart4,        //[4]2x VOL ACUMULADO
  };

enum ENUM_TP_ESTRAT
  {
   estrat1,      //[1]ENVELOPE/RSI/BOLINGER
   estrat2,      //[2]ENVELOPE/RSI
   estrat3,      //[3]ENVELOPE/BOLINGER
   estrat4,      //[4]RSI/BOLINGER
   estrat5,      //[5]ENVELOPE
   estrat6,      //[6]RSI
   estrat7,      //[7]BOLINGER
   estrat8,      //[8]NEURAL
   estrat9,      //[9]NEURAL/RSI
   estrat10,     //[10]NEURAL/BOLINGER
   estrat11,     //[11]NEURAL/ENVELOPE
   estrat12,     //[12]NEURAL/SAR
  };

enum ENUM_TP_CONTA
  {
   tipocent,     //[1]CONTA CENT
   tipoprime,    //[2]CONTA PRIME/ECN
  };

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input ulong              magicrobo           = 941;        //MAGIC NUMBER DO ROBÔ
input group              "ABERTURA DE POSIÇÕES"
input bool               ativaentradaea      = true;       //ATIVA ABERTURA
input double             loteinicial         = 1;          //TAMANHO DO LOTE INICIAL
input double             aumentoprop         = 1000.00;    //[$] VALOR P/ AUMENTO DO VALOR DO LOTE
input ENUM_TP_CONTA      tipoconta           = tipocent;   //[TP] SELECIONE TIPO DE CONTA
input double             percentgain         = 0.1;        //[%] PORCENTAGEM DE STOP GAIN
input double             percentloss         = 2.5;        //[%] PORCENTAGEM DE STOP LOSS
input group              "MARTINGALE"
input ENUM_TP_MART       tipomartingale      = mart3;      //TIPO DE MARTINGALE
input int                multiplicador       = 1;          //[INT] MULTIPLICADOR P/ MARTINGALE
input int                ptsmartprimcompra   = 10000;      //[PTS] DISTANCIA PARA 2 OPERAÇÃO
input double             prctmart            = 50;         //[%] MÍNIMA DAS 2 ORD ANT P/ PX ORD
input group              "ESCOLHA DA ESTRATÉGIA"
input ENUM_TP_ESTRAT     estrategia          = estrat1;    //ESCOLHA A ESTRATÉGIA
input group              "VALORES DEFINIDOS P/ SAR"
input double             stepSAR             = 0.02;       //STEP do SAR
input double             maximumSAR          = 0.2;        //MAXIMUM do SAR
input group              "VARIÁVEIS DE CONFIRMAÇÃO - VOLUME E PREÇO"
input double             percentvol          = 70;         //[%] MÍN DO VOL DO CAND1 EM REL AO 2
input double             percentprice        = 70;         //[%] MÍN DO TAM DO CAND1 EM REL AO 2
input group              "VALORES DEFINIDOS P/ RSI"
input int                periodorsi          = 14;         //[INT] PERIODO P/ RSI
input int                sobrevrsi           = 70;         //[%] PORCENTAGEM DE SOBREVENDA
input int                sobrecrsi           = 30;         //[%] PORCENTAGEM DE SOBRECOMPRA
input group              "VALORES DEFINIDOS P/ BANDAS DE BOLLINGER"
input int                periodobb           = 14;         //[INT] PERIODO P/ BANDAS DE BOLINGER
input double             desviobb            = 2.0;        //[DEC] DESVIO P/ BANDAS DE BOLINGER
input group              "VALORES DEFINIDOS P/ ENVELOPE"
input int                periodm1            = 14;         //[INT] PERIODO DA MÉDIA P/ ENVELOPE
input double             tamanhoenvelope     = 100000;     //[PTS] DISTÂNCIA P/ ENVELOPE
input group              "REDE NEURAL"
input int                PrevForaVal         = 3600;       //(S) TEMPO DE VALIDADE DA PREVISÃO

/*input group              "BREAKEVEN/TRAILING STOP"
input bool               ativbreak           = false;      //ATIVA BREAKEVEN/TRAILING STOP
input double             pontosbreak         = 5;          //PTOS PROX AO TP PARA ATIV BREAKEVEN
input double             pontosbreak2        = 5;          //PTOS P/ MOVER TP PARA FRENTE BREAKEVEN
input double             pontosbesl          = 10;         //PTOS A MENOS PARA SL NOVO
input double             pontosts            = 5;          //PTOS DO SL NOVO PARA ATIV TS
*/
input group              "GERENCIAMENTO DE RISCO - PARADA DO ROBÔ COM STOPS ALCANÇADOS NO DIA"
input bool               ativastopdiario     = true;       //PARA O ROBÔ NO DIA QNDO STOP > N
input int                qtdestops           = 3;          //QTDE MÁXIMA DE STOPS (N)
input group              "GERENCIAMENTO DE RISCO - FECHAMENTO DE ORDENS LONGAS COM PERDA MENOR"
input bool               ativafeclongas      = false;      //ATIVA FECHAMENTO DE ORDENS LONGAS
input group              "GERENCIAMENTO DE RISCO - STOP FULL"
input bool               ativastopfull       = true;       //ATIVA STOP P/ LIMITE DE CAPITAL INVESTIDO
input double             percentfull         = 5;          //% DO CAPITAL PARA FECHAR TODAS AS ORDENS
input group              "GERENCIAMENTO DE RISCO - HORÁRIOS DE P/ ABERTURA/FECHAMENTO DE ORDENS"
input string             horainicial         = "01:00";    //HORA INICIAL P/ ABERTURA DE ORDENS
input string             horafinal           = "22:59";    //HORA FINAL P/ ABERTURA DE ORDENS
input bool               ativafecfinaldia    = false;      //ATIVA FECHAMENTO DE ORDENS
input string             horafechamento      = "23:00";    //HORA PARA FECHAMENTO DE ORDENS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

string                   shortname;

//--- Variáveis
double                   stopcompra          = 0.0;
double                   stopvenda           = 0.0;
double                   takecompra          = 0.0;
double                   takevenda           = 0.0;

int                      handlebb,handlersi,handleMM,handleSAR;

double                   percent_margem, saldo, capital, lucro_prejuizo, volumemaximo, volumeoper, valoraumento, //
                         slcomprapadrao, slvendapadrao, tpcomprapadrao, tpvendapadrao, rsi[], bbu[], bbm[], bbd[], mediamovel[], sar[];

//--- Definição das variáveis dos volumes para compra e venda quando utilizar martingale
double                   volnv2,volnv3,volnv4,volnv5,volnv6,volnv7,volnv8;
double                   volnv_2,volnv_3,volnv_4,volnv_5,volnv_6,volnv_7,volnv_8;

//--- Definição das variáveis dos preços médios para compra e venda quando utilizar martingale
double                   PM1, PM2, PM3, PM4, PM5, PM6, PM7;

//--- Variáveis p/ ticks, candles e tempo
MqlTick                  tick;
MqlRates                 candle[];
MqlDateTime              hratualstruct,hrinicialstruct,hrfinalstruct,hrfechstruct;

//--- Usa a classe responsável pela execução das ordens - Ctrade
CTrade                   trade;

CDictionary *dict = new CDictionary();

//+--------------------------------+
//| Expert initialization function |
//+--------------------------------+
int OnInit()
  {
//--- Ajusta horarios segundo inputs inseridos
   TimeToStruct(StringToTime(horainicial),hrinicialstruct);
   TimeToStruct(StringToTime(horafinal),hrfinalstruct);
   TimeToStruct(StringToTime(horafechamento),hrfechstruct);

//--- Seta o magic number do robô
   trade.SetExpertMagicNumber(magicrobo);

   handlersi = iRSI(_Symbol,_Period,periodorsi,PRICE_CLOSE);
   handlebb = iBands(_Symbol,_Period,periodobb,0,desviobb,PRICE_CLOSE);
   handleMM = iMA(_Symbol,_Period,periodm1,0,MODE_SMA,PRICE_CLOSE);
   handleSAR = iSAR(_Symbol,_Period,stepSAR,maximumSAR);
   ArraySetAsSeries(candle,true);
   ArraySetAsSeries(rsi,true);
   ArraySetAsSeries(bbu,true);
   ArraySetAsSeries(bbm,true);
   ArraySetAsSeries(bbd,true);
   ArraySetAsSeries(mediamovel,true);
   ArraySetAsSeries(sar,true);

   ReadFileToDictCSV("previsoes.csv");

//--- Definição dos preços dos inputs em função do tipo de conta selecionada
   if(tipoconta==tipocent)
      valoraumento=aumentoprop*100;
   if(tipoconta==tipoprime)
      valoraumento=aumentoprop;

//--- Definição dos preços de stoploss padrão quando não utilizando estratégias de SL e TP programados
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
   if(Symbol()=="BTCUSD")
     {
      slcomprapadrao=10.000;
      slvendapadrao=100000.000;
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
   CopyBuffer(handlebb,1,0,5,bbu);
   if(CopyBuffer(handlebb,1,0,5,bbu)<0)
     {
      Alert("Erro ao copiar dados de Banda Superior Bolinger: ", GetLastError());
      return;
     }
   CopyBuffer(handlebb,0,0,5,bbm);
   if(CopyBuffer(handlebb,0,0,5,bbm)<0)
     {
      Alert("Erro ao copiar dados de Banda Média Bolinger: ", GetLastError());
      return;
     }
   CopyBuffer(handlebb,2,0,5,bbd);
   if(CopyBuffer(handlebb,2,0,5,bbd)<0)
     {
      Alert("Erro ao copiar dados de Banda Inferior Bolinger: ", GetLastError());
      return;
     }
   CopyBuffer(handleMM,0,0,5,mediamovel);
   if(CopyBuffer(handleMM,0,0,5,mediamovel)<0)
     {
      Alert("Erro ao copiar dados de Média Móvel: ", GetLastError());
      return;
     }
   CopyBuffer(handleSAR,0,0,5,sar);
   if(CopyBuffer(handleSAR,0,0,5,sar)<0)
     {
      Alert("Erro ao copiar dados de SAR: ", GetLastError());
      return;
     }


   static CIsNewBar NB1,NB2/*,NB3,NB4,NB5,NB6,NB7,NB8,NB9,NB10,NB11,NB12,NB13,NB14,NB15,NB16,NB17,NB18,NB19,NB20,NB21,NB22*/;

//   double margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN),2);
//   double margem_livre = NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN),2);
   saldo = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
   lucro_prejuizo = NormalizeDouble(AccountInfoDouble(ACCOUNT_PROFIT),2);
   capital = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY),2);
   percent_margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),2);

   if(NB1.IsNewBar(_Symbol,_Period)) //VERIFICA SE É UM NOVO CANDLE
     {

      //--- Definição dos lotes iniciais de compra e venda
      if(saldo<valoraumento)
         volumeoper=loteinicial;
      else
         volumeoper = NormalizeDouble((capital/valoraumento)*loteinicial,2);

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
        }
      if(tipomartingale==mart2)//mix - fibo ate a 5 ordem e o dobro do anterior nas proximas ordens
        {
         volnv2             = 2*volumeoper;//2
         volnv3             = 3*volumeoper;//3
         volnv4             = 5*volumeoper;//5
         volnv5             = 8*volumeoper;//8
         volnv6             = volnv5*multiplicador;
         volnv7             = volnv6*multiplicador;
         volnv8             = volnv7*multiplicador;
        }
      if(tipomartingale==mart3)//N vezes o volume anterior conforme tabela de inputs
        {
         volnv2             = volumeoper*multiplicador;
         volnv3             = volnv2*multiplicador;
         volnv4             = volnv3*multiplicador;
         volnv5             = volnv4*multiplicador;
         volnv6             = volnv5*multiplicador;
         volnv7             = volnv6*multiplicador;
         volnv8             = volnv7*multiplicador;
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

//--- Definição dos preços médios para quando houver 2 ou mais compras/vendas
   /*   if(PositionsTotal()>=1)
        {
         if(PossuiPosCompraComentada("C1") && !PossuiPosCompraComentada("C2"))
            PM1 = (tick.ask*volnv2 + PrecoPosCompra()*volumeoper)/(volnv2+volumeoper);
         if(PossuiPosCompraComentada("C2") && !PossuiPosCompraComentada("C3"))
            PM2 = (tick.ask*volnv3 + PrecoAberturaPosCompra(2)*volnv2 + PrecoAberturaPosCompra(1)*volumeoper)/(volnv3+volnv2+volumeoper);
         if(PossuiPosCompraComentada("C3") && !PossuiPosCompraComentada("C4"))
            PM3 = (tick.ask*volnv4 + PrecoAberturaPosCompra(3)*volnv3 + PrecoAberturaPosCompra(2)*volnv2 + //
                   PrecoAberturaPosCompra(1)*volumeoper)/(volnv4+volnv3+volnv2+volumeoper);
         if(PossuiPosCompraComentada("C4") && !PossuiPosCompraComentada("C5"))
            PM4 = (tick.ask*volnv5 + PrecoAberturaPosCompra(4)*volnv4 + PrecoAberturaPosCompra(3)*volnv3 + PrecoAberturaPosCompra(2)*volnv2 + //
                   PrecoAberturaPosCompra(1)*volumeoper)/(volnv5+volnv4+volnv3+volnv2+volumeoper);
         if(PossuiPosCompraComentada("C5") && !PossuiPosCompraComentada("C6"))
            PM5 = (tick.ask*volnv6 + PrecoAberturaPosCompra(5)*volnv5 + PrecoAberturaPosCompra(4)*volnv4 + PrecoAberturaPosCompra(3)*volnv3 + //
                   PrecoAberturaPosCompra(2)*volnv2 + PrecoAberturaPosCompra(1)*volumeoper)/(volnv6+volnv5+volnv4+volnv3+volnv2+volumeoper);
         if(PossuiPosCompraComentada("C6") && !PossuiPosCompraComentada("C7"))
            PM6 = (tick.ask*volnv7 + PrecoAberturaPosCompra(6)*volnv6 + PrecoAberturaPosCompra(5)*volnv5 + PrecoAberturaPosCompra(4)*volnv4 + //
                   PrecoAberturaPosCompra(3)*volnv3 + PrecoAberturaPosCompra(2)*volnv2 + PrecoAberturaPosCompra(1)*volumeoper)/(volnv7+volnv6+volnv5+//
                         volnv4+volnv3+volnv2+volumeoper);
         if(PossuiPosCompraComentada("C7") && !PossuiPosCompraComentada("C8"))
            PM7 = (tick.ask*volnv8 + PrecoAberturaPosCompra(7)*volnv7 + PrecoAberturaPosCompra(6)*volnv6 + PrecoAberturaPosCompra(5)*volnv5 + //
                   PrecoAberturaPosCompra(4)*volnv4 + PrecoAberturaPosCompra(3)*volnv3 + PrecoAberturaPosCompra(2)*volnv2 + PrecoAberturaPosCompra(1)* //
                   volumeoper)/(volnv8+volnv7+volnv6+volnv5+volnv4+volnv3+volnv2+volumeoper);

         if(PossuiPosVendaComentada("C1") && !PossuiPosVendaComentada("C2"))
            PM1 = (tick.bid*volnv2 + PrecoAberturaPosVenda(1)*volumeoper)/(volnv2+volumeoper);
         if(PossuiPosVendaComentada("C2") && !PossuiPosVendaComentada("C3"))
            PM2 = (tick.bid*volnv3 + PrecoAberturaPosVenda(2)*volnv2 + PrecoAberturaPosVenda(1)*volumeoper)/(volnv3+volnv2+volumeoper);
         if(PossuiPosVendaComentada("C3") && !PossuiPosVendaComentada("C4"))
            PM3 = (tick.bid*volnv4 + PrecoAberturaPosVenda(3)*volnv3 + PrecoAberturaPosVenda(2)*volnv2 + //
                   PrecoAberturaPosVenda(1)*volumeoper)/(volnv4+volnv3+volnv2+volumeoper);
         if(PossuiPosVendaComentada("C4") && !PossuiPosVendaComentada("C5"))
            PM4 = (tick.bid*volnv5 + PrecoAberturaPosVenda(4)*volnv4 + PrecoAberturaPosVenda(3)*volnv3 + PrecoAberturaPosVenda(2)*volnv2 + //
                   PrecoAberturaPosVenda(1)*volumeoper)/(volnv5+volnv4+volnv3+volnv2+volumeoper);
         if(PossuiPosVendaComentada("C5") && !PossuiPosVendaComentada("C6"))
            PM5 = (tick.bid*volnv6 + PrecoAberturaPosVenda(5)*volnv5 + PrecoAberturaPosVenda(4)*volnv4 + PrecoAberturaPosVenda(3)*volnv3 + //
                   PrecoAberturaPosVenda(2)*volnv2 + PrecoAberturaPosVenda(1)*volumeoper)/(volnv6+volnv5+volnv4+volnv3+volnv2+volumeoper);
         if(PossuiPosVendaComentada("C6") && !PossuiPosVendaComentada("C7"))
            PM6 = (tick.bid*volnv7 + PrecoAberturaPosVenda(6)*volnv6 + PrecoAberturaPosVenda(5)*volnv5 + PrecoAberturaPosVenda(4)*volnv4 + //
                   PrecoAberturaPosVenda(3)*volnv3 + PrecoAberturaPosVenda(2)*volnv2 + PrecoAberturaPosVenda(1)*volumeoper)/(volnv7+volnv6+volnv5+//
                         volnv4+volnv3+volnv2+volumeoper);
         if(PossuiPosVendaComentada("C7") && !PossuiPosVendaComentada("C8"))
            PM7 = (tick.bid*volnv8 + PrecoAberturaPosVenda(7)*volnv7 + PrecoAberturaPosVenda(6)*volnv6 + PrecoAberturaPosVenda(5)*volnv5 + //
                   PrecoAberturaPosVenda(4)*volnv4 + PrecoAberturaPosVenda(3)*volnv3 + PrecoAberturaPosVenda(2)*volnv2 + PrecoAberturaPosVenda(1)* //
                   volumeoper)/(volnv8+volnv7+volnv6+volnv5+volnv4+volnv3+volnv2+volumeoper);
        }
   */

   if(PositionsTotal()==1)

     {
      if(PossuiPosCompraComentada("C1") && !PossuiPosCompraComentada("C2"))
         PM1 = (tick.ask*volnv2 + PrecoPosCompra()*volumeoper)/(volnv2+volumeoper);
      if(PossuiPosCompraComentada("C2") && !PossuiPosCompraComentada("C3"))
         PM2 = (tick.ask*volnv3 + PrecoPosCompra()*VolumePos())/(volnv3+VolumePos());
      if(PossuiPosCompraComentada("C3") && !PossuiPosCompraComentada("C4"))
         PM3 = (tick.ask*volnv4 + PrecoPosCompra()*VolumePos())/(volnv4+VolumePos());
      if(PossuiPosCompraComentada("C4") && !PossuiPosCompraComentada("C5"))
         PM4 = (tick.ask*volnv5 + PrecoPosCompra()*VolumePos())/(volnv5+VolumePos());
      if(PossuiPosCompraComentada("C5") && !PossuiPosCompraComentada("C6"))
         PM5 = (tick.ask*volnv6 + PrecoPosCompra()*VolumePos())/(volnv6+VolumePos());
      if(PossuiPosCompraComentada("C6") && !PossuiPosCompraComentada("C7"))
         PM6 = (tick.ask*volnv7 + PrecoPosCompra()*VolumePos())/(volnv7+VolumePos());
      if(PossuiPosCompraComentada("C7") && !PossuiPosCompraComentada("C8"))
         PM7 = (tick.ask*volnv8 + PrecoPosCompra()*VolumePos())/(volnv8+VolumePos());

      if(PossuiPosVendaComentada("V1") && !PossuiPosVendaComentada("V2"))
         PM1 = (tick.bid*volnv2 + PrecoPosCompra()*volumeoper)/(volnv2+volumeoper);
      if(PossuiPosVendaComentada("V2") && !PossuiPosVendaComentada("V3"))
         PM2 = (tick.bid*volnv3 + PrecoPosCompra()*VolumePos())/(volnv3+VolumePos());
      if(PossuiPosVendaComentada("V3") && !PossuiPosVendaComentada("V4"))
         PM3 = (tick.bid*volnv4 + PrecoPosCompra()*VolumePos())/(volnv4+VolumePos());
      if(PossuiPosVendaComentada("V4") && !PossuiPosVendaComentada("V5"))
         PM4 = (tick.bid*volnv5 + PrecoPosCompra()*VolumePos())/(volnv5+VolumePos());
      if(PossuiPosVendaComentada("V5") && !PossuiPosVendaComentada("V6"))
         PM5 = (tick.bid*volnv6 + PrecoPosCompra()*VolumePos())/(volnv6+VolumePos());
      if(PossuiPosVendaComentada("V6") && !PossuiPosVendaComentada("V7"))
         PM6 = (tick.bid*volnv7 + PrecoPosCompra()*VolumePos())/(volnv7+VolumePos());
      if(PossuiPosVendaComentada("V7") && !PossuiPosVendaComentada("V8"))
         PM7 = (tick.bid*volnv8 + PrecoPosCompra()*VolumePos())/(volnv8+VolumePos());
     }

   TimeToStruct(TimeCurrent(),hratualstruct);
   datetime aberturacandleatual=datetime(SeriesInfoInteger(_Symbol,_Period,SERIES_LASTBAR_DATE));

////////////////////////////////////////////
//---| FECHA ORDENS NO FIM DO PREGÃO |----//
////////////////////////////////////////////
   if(ativafecfinaldia==true && (PossuiPosCompra()||PossuiPosVenda()) && hratualstruct.hour==hrfechstruct.hour && hratualstruct.min==hrfechstruct.min)
     {
      FechaTodasPosicoesAbertas();
     }

//////////////////////////////////
//---| FECHA ORDENS LONGAS |----//
//////////////////////////////////
   if(ativafeclongas)
     {
      if(PossuiPosCompra())
        {
         if((PossuiPosCompraComentada("C3")||PossuiPosCompraComentada("C4")||PossuiPosCompraComentada("C5")|| //
             PossuiPosCompraComentada("C6")||PossuiPosCompraComentada("C7")||PossuiPosCompraComentada("C8")) && //
            (candle[1].close>bbu[1]||candle[1].close>mediamovel[1]+tamanhoenvelope*_Point))
           {
            FechaTodasPosicoesAbertas();
           }
        }
      if(PossuiPosVenda())
        {
         if((PossuiPosVendaComentada("V3")||PossuiPosVendaComentada("V4")||PossuiPosVendaComentada("V5")|| //
             PossuiPosVendaComentada("V6")||PossuiPosVendaComentada("V7")||PossuiPosVendaComentada("V8")) && //
            (candle[1].close<bbd[1]||candle[1].close<mediamovel[1]-tamanhoenvelope*_Point))
           {
            FechaTodasPosicoesAbertas();
           }
        }
     }

//+------------------------------------------------------------------+
//| OPERAÇÕES SEGUINDO A ESTRATÉGIA ESCOLHIDA |
//+------------------------------------------------------------------+

//   Print("ABERTURA DO CANDLE: ",aberturacandleatual);

   if(ativaentradaea && !PossuiPosAbertaOutroAtivo() && HorarioEntrada()==true && (percent_margem>3500||saldo==capital) /*&& DataHoraUltPosFechada()<aberturacandleatual*/)
     {
      //      Print("QTDE STOPS: ",QtdeStops());
      if(NB2.IsNewBar(_Symbol,_Period) && QtdeStops()<qtdestops) //VERIFICA SE O CANDLE ACABOU DE ABRIR E SE NÃO STOPOU MUITO
        {
         //////////////////////////////////////////////
         //---| ESTRATEGIA ENVELOPE/RSI/BOLINGER |---//
         //////////////////////////////////////////////
         if(estrategia==estrat1)
           {
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(candle[1].close<mediamovel[1]-tamanhoenvelope*_Point && rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/ && candle[1].close<bbd[1])
               ComprasNormais();
            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ && candle[1].close>bbu[1])
               VendasNormais();
           }
         /////////////////////////////////////
         //---| ESTRATEGIA ENVELOPE/RSI |---//
         /////////////////////////////////////
         if(estrategia==estrat2)
           {
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(candle[1].close<mediamovel[1]-tamanhoenvelope*_Point && rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/)
               ComprasNormais();
            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/)
               VendasNormais();
           }
         //////////////////////////////////////////
         //---| ESTRATEGIA ENVELOPE/BOLINGER |---//
         //////////////////////////////////////////
         if(estrategia==estrat3)
           {
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(candle[1].close<mediamovel[1]-tamanhoenvelope*_Point && candle[1].close<bbd[1])
               ComprasNormais();
            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point && candle[1].close>bbu[1])
               VendasNormais();
           }
         /////////////////////////////////////
         //---| ESTRATEGIA RSI/BOLINGER |---//
         /////////////////////////////////////
         if(estrategia==estrat4)
           {
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/ && candle[1].close<bbd[1])
               ComprasNormais();
            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ && candle[1].close>bbu[1])
               VendasNormais();
           }
         /////////////////////////////////
         //---| ESTRATEGIA ENVELOPE |---//
         /////////////////////////////////
         if(estrategia==estrat5)
           {
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(candle[1].close<mediamovel[1]-tamanhoenvelope*_Point)
               ComprasNormais();

            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point)
               VendasNormais();
           }
         ////////////////////////////
         //---| ESTRATEGIA RSI |---//
         ////////////////////////////
         if(estrategia==estrat6)
           {
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/)
               ComprasNormais();
            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/)
               VendasNormais();
           }
         /////////////////////////////////
         //---| ESTRATEGIA BOLINGER |---//
         /////////////////////////////////
         if(estrategia==estrat7)
           {
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(candle[1].close<bbd[1])
               ComprasNormais();

            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(candle[1].close>bbu[1])
               VendasNormais();
           }
         ///////////////////////////////
         //---| ESTRATEGIA NEURAL |---//
         ///////////////////////////////
         if(estrategia==estrat8)
           {
            double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(previsao > tick.ask && previsao != 0 && candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100))
               ComprasNormais();

            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(previsao < tick.bid && previsao !=0 && candle[2].close<candle[2].open && candle[1].close<candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].open-candle[1].close)>=(candle[2].open-candle[2].close)*(percentprice/100))
               VendasNormais();
           }
         ///////////////////////////////////
         //---| ESTRATEGIA NEURAL/RSI |---//
         ///////////////////////////////////
         if(estrategia==estrat9)
           {
            double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(previsao > tick.ask && previsao != 0 && rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/ && candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100))
               ComprasNormais();

            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(previsao < tick.bid && previsao !=0 && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ && candle[2].close<candle[2].open && candle[1].close<candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].open-candle[1].close)>=(candle[2].open-candle[2].close)*(percentprice/100))
               VendasNormais();
           }
         ////////////////////////////////////////
         //---| ESTRATEGIA NEURAL/BOLINGER |---//
         ////////////////////////////////////////
         if(estrategia==estrat10)
           {
            double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(previsao > tick.ask && previsao != 0 && candle[1].close<bbd[1] && candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100))
               ComprasNormais();

            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(previsao < tick.bid && previsao !=0 && candle[1].close>bbu[1] && candle[2].close<candle[2].open && candle[1].close<candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].open-candle[1].close)>=(candle[2].open-candle[2].close)*(percentprice/100))
               VendasNormais();
           }
         ///////////////////////////////////////
         //---| ESTRATEGIA NEURAL/ENVELOPE |---//
         ///////////////////////////////////////
         if(estrategia==estrat11)
           {
            double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(previsao > tick.ask && previsao != 0 && candle[1].close<mediamovel[1]-tamanhoenvelope*_Point && candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100))
               ComprasNormais();

            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(previsao < tick.bid && previsao !=0 && candle[1].close>mediamovel[1]+tamanhoenvelope*_Point && candle[2].close<candle[2].open && candle[1].close<candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].open-candle[1].close)>=(candle[2].open-candle[2].close)*(percentprice/100))
               VendasNormais();
           }
         ///////////////////////////////////
         //---| ESTRATEGIA NEURAL/SAR |---//
         ///////////////////////////////////
         if(estrategia==estrat12)
           {
            double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
            double   sarnormalizado = NormalizeDouble(sar[0],5);
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(previsao > tick.ask && previsao != 0 && sarnormalizado < tick.ask)
               ComprasNormais();

            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(previsao < tick.bid && previsao !=0 && sarnormalizado > tick.bid)
               VendasNormais();
           }

        }
     }

/////////////////////////////////
//---|AJUSTE DE TAKE E STOP|---//
/////////////////////////////////
//         if(PositionsTotal()==1 && )
//            AjustaTPSL();

///////////////////////
//---|STOP FULL |----//
///////////////////////
   if(ativastopfull==true)
      if(MathAbs((LucroPrejuizoPosAberta()/capital)*100)>=percentfull && LucroPrejuizoPosAberta()<0 && saldo!=capital)
        {
         FechaTodasPosicoesAbertas();
         Sleep(100);
         return;
        }

////////////////////////////
//---|BREAKEVEN E TS |----//
////////////////////////////
   /*   if(ativbreak==true)
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
   */
  }

//+------------------------------------------------------------------------------------------+
////////////////////////////
//| FIM DA FUNÇÃO ONTICK |//
////////////////////////////
/////////////////////////////////////
//| INÍCIO DAS FUNÇÕES AUXILIARES |//
/////////////////////////////////////
//+----------------------------------------------------+
//| VERIFICA PREVISÃO FORA DA VALIDADE CONFORME INPUTS |
//+----------------------------------------------------+
bool PrevForaVal()
  {
   HistorySelect(0,TimeCurrent());
   string   name;
   ulong    ticket=0;
   string   symbol;
   datetime hora_atual = TimeCurrent();
   datetime hora_oper;
   long     type;
   long     entry;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      //--- tentar obter ticket negócios
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- obter as propriedades negócios
         hora_oper  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         Alert(hora_atual-hora_oper);
         //--- apenas para o símbolo atual
         if((type==DEAL_TYPE_BUY || type==DEAL_TYPE_SELL) && entry==DEAL_ENTRY_IN && symbol==_Symbol && hora_atual-hora_oper>PrevForaVal)
           {
            return true;
            break;
           }
         else
           {
            return false;
            break;
           }
        }
     }
   return false;
  }
//+------------------------------------------------------------------------------------------+
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
      dict.Set<string>(result[0],result[3]);
     }

   FileClose(h);
  }
//+------------------------------------------------------------------+
//+---------------------------------------------------+
//| RETORNA A DATA/HORA DO FECHAMENTO DA ULTIMA ORDEM |
//+---------------------------------------------------+
datetime DataHoraUltPosFechada()
  {
   HistorySelect(0,TimeCurrent());
   ulong       ticket=0;
   string      symbol;
   long        entry;
   datetime    time;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         if(entry==DEAL_ENTRY_OUT && symbol==_Symbol)
           {
            return time;
            break;
           }
        }
     }
   datetime timeatual=D'2018.01.01 00:00';
   return (timeatual);
  }
//+--------------------------------------------+
//| VERIFICA QUANTOS STOPS OCORRERAM EM UM DIA |
//+--------------------------------------------+
int QtdeStops()
  {
   HistorySelect(0,TimeCurrent());
   ulong       ticket=0;
   string      symbol;
   long        reason;
   long        entry;
   int         contador=0;
   MqlDateTime timecorrente;
   MqlDateTime timedaoper;
   datetime    time;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         reason=HistoryDealGetInteger(ticket,DEAL_REASON);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         TimeToStruct(TimeCurrent(),timecorrente);
         TimeToStruct(time,timedaoper);
         if(reason==DEAL_REASON_SL && entry==DEAL_ENTRY_OUT && symbol==_Symbol && timecorrente.day==timedaoper.day && timecorrente.year==timedaoper.year)
            contador++;
        }
      else
         return(contador);
     }
   return contador;
  }
//+------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| VERIFICA SE A ÚLTIMA POSICAO FECHADA FOI DE TAKE PROFIT ATINGIDO |
//+------------------------------------------------------------------+
bool UltimaPosFechadaTake()
  {
   HistorySelect(0,TimeCurrent());
   ulong    ticket=0;
   string   symbol;
   long     reason;
   long     entry;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      //--- tentar obter ticket negócios
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- obter as propriedades negócios
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         reason=HistoryDealGetInteger(ticket,DEAL_REASON);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         //--- apenas para o símbolo atual
         if(reason==DEAL_REASON_TP && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
           {
            return true;
            break;
           }
         return false;
         break;
        }
     }
   return false;
  }
//+------------------------------------------------------------------------------------------+
//+----------------------------------------------------------------+
//| VERIFICA SE A ÚLTIMA POSICAO FECHADA FOI DE STOP LOSS ATINGIDO |
//+----------------------------------------------------------------+
bool UltimaPosFechadaStop()
  {
   HistorySelect(0,TimeCurrent());
   ulong    ticket=0;
   string   symbol;
   long     reason;
   long     entry;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      //--- tentar obter ticket negócios
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- obter as propriedades negócios
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         reason=HistoryDealGetInteger(ticket,DEAL_REASON);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         //--- apenas para o símbolo atual
         if(reason==DEAL_REASON_SL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
           {
            return true;
            break;
           }
         return false;
         break;
        }
     }
   return false;
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
//+-------------------------------------------------+
//| VERIFICA VOLUME DE ABERTURA POSIÇÃO DE COMPRA N |
//+-------------------------------------------------+
double VolumePosCompra(uint j)
  {
   HistorySelect(0,TimeCurrent());
   string   name;
   ulong    ticket=0;
   double   volume;
   string   symbol;
   long     type;
   long     entry;
   uint     k = HistoryDealsTotal();
   switch(j)
     {
      case  1:
         if((ticket=HistoryDealGetTicket(k-1))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }
      case  2:
         if((ticket=HistoryDealGetTicket(k-2))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }
      case  3:
         if((ticket=HistoryDealGetTicket(k-3))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }
      case  4:
         if((ticket=HistoryDealGetTicket(k-4))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }
      case  5:
         if((ticket=HistoryDealGetTicket(k-5))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }
      case  6:
         if((ticket=HistoryDealGetTicket(k-6))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }
      case  7:
         if((ticket=HistoryDealGetTicket(k-7))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }

      default:
         break;
     }

   return NULL;
  }
//+------------------------------------------------------------------------------------------+
//+------------------------------------------------+
//| VERIFICA VOLUME DE ABERTURA POSIÇÃO DE VENDA N |
//+------------------------------------------------+
double VolumePosVenda(uint j)
  {
   HistorySelect(0,TimeCurrent());
   string   name;
   ulong    ticket=0;
   double   volume;
   string   symbol;
   long     type;
   long     entry;
   uint     k = HistoryDealsTotal();
   switch(j)
     {
      case  1:
         if((ticket=HistoryDealGetTicket(k-1))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }
      case  2:
         if((ticket=HistoryDealGetTicket(k-2))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }
      case  3:
         if((ticket=HistoryDealGetTicket(k-3))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }
      case  4:
         if((ticket=HistoryDealGetTicket(k-4))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }
      case  5:
         if((ticket=HistoryDealGetTicket(k-5))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }
      case  6:
         if((ticket=HistoryDealGetTicket(k-6))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }
      case  7:
         if((ticket=HistoryDealGetTicket(k-7))>0)
           {
            volume =HistoryDealGetDouble(ticket,DEAL_VOLUME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return volume;
               break;
              }
            break;
           }

      default:
         break;
     }

   return NULL;
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
   return NULL;
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
      if(order_symbol==_Symbol /*&& magic == magicrobo*/ && (type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_SELL_LIMIT || //
            type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_SELL_STOP))
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
      if(order_symbol==_Symbol /*&& magic == magicrobo*/ && (type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_SELL_LIMIT || //
            type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_SELL_STOP))
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
//+------------------------------------------------+
//| VERIFICA PREÇO DE ABERTURA POSIÇÃO DE COMPRA N |
//+------------------------------------------------+
double PrecoAberturaPosCompra(uint j)
  {
   HistorySelect(0,TimeCurrent());
   string   name;
   ulong    ticket=0;
   double   price;
   string   symbol;
   long     type;
   long     entry;
   uint     k = HistoryDealsTotal();
   switch(j)
     {
      case  1:
         if((ticket=HistoryDealGetTicket(k-1))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }
      case  2:
         if((ticket=HistoryDealGetTicket(k-2))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }
      case  3:
         if((ticket=HistoryDealGetTicket(k-3))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }
      case  4:
         if((ticket=HistoryDealGetTicket(k-4))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }
      case  5:
         if((ticket=HistoryDealGetTicket(k-5))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }
      case  6:
         if((ticket=HistoryDealGetTicket(k-6))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }
      case  7:
         if((ticket=HistoryDealGetTicket(k-7))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }

      default:
         break;
     }

   return NULL;
  }
//+------------------------------------------------------------------------------------------+
//+-----------------------------------------------+
//| VERIFICA PREÇO DE ABERTURA POSIÇÃO DE VENDA N |
//+-----------------------------------------------+
double PrecoAberturaPosVenda(uint j)
  {
   HistorySelect(0,TimeCurrent());
   string   name;
   ulong    ticket=0;
   double   price;
   string   symbol;
   long     type;
   long     entry;
   uint     k = HistoryDealsTotal();
   switch(j)
     {
      case  1:
         if((ticket=HistoryDealGetTicket(k-1))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }
      case  2:
         if((ticket=HistoryDealGetTicket(k-2))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }
      case  3:
         if((ticket=HistoryDealGetTicket(k-3))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }
      case  4:
         if((ticket=HistoryDealGetTicket(k-4))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }
      case  5:
         if((ticket=HistoryDealGetTicket(k-5))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }
      case  6:
         if((ticket=HistoryDealGetTicket(k-6))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }
      case  7:
         if((ticket=HistoryDealGetTicket(k-7))>0)
           {
            price =HistoryDealGetDouble(ticket,DEAL_PRICE);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               return price;
               break;
              }
            break;
           }

      default:
         break;
     }

   return NULL;
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
   return NULL;
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
   return NULL;
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
   return NULL;
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
   return NULL;
  }
//+------------------------------------------------------------------------------------------+
//+--------------------------------------------+
//| AJUSTA O SL E O TP DAS DUAS ÚLTIMAS ORDENS |
//+--------------------------------------------+
void AjustaTPSL()
  {
   int posabertas = PositionsTotal();
   for(int i = posabertas-1; i >= 0; i--)
     {
      ulong ticket1 = PositionGetTicket(i);
      string position_symbol1 = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      //ENUM_POSITION_TYPE tipo =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double sl1 = PositionGetDouble(POSITION_SL);
      double tp1 = PositionGetDouble(POSITION_TP);
      for(int j = posabertas-2; j >= 0; j--)
        {
         ulong ticket2 = PositionGetTicket(j);
         string position_symbol2 = PositionGetString(POSITION_SYMBOL);
         //ulong  magic = PositionGetInteger(POSITION_MAGIC);
         //ENUM_POSITION_TYPE tipo =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double sl2 = PositionGetDouble(POSITION_SL);
         double tp2 = PositionGetDouble(POSITION_TP);
         if(position_symbol1==_Symbol && position_symbol2==_Symbol && (sl1!=sl2||tp1!=tp2))
            trade.PositionModify(ticket2,sl1,tp1);
        }
     }
  }
//+------------------------------------------------------------------------------------------+

//////////////////////////////////////////
//---|COMPRAS NORMAIS COM MARTINGALE|---//
//////////////////////////////////////////
void  ComprasNormais()
  {
   if(estrategia==estrat8||estrategia==estrat9||estrategia==estrat10||estrategia==estrat11||estrategia==estrat12)
     {
      double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
      if(PositionsTotal()==0 /*&& tick.ask>candle[1].open*/)
        {
         trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),previsao,"C1");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C1") && !PossuiPosCompraComentada("C2") && tick.ask<PrecoAberturaPosCompra(1)-ptsmartprimcompra*_Point //
         && VolumePos()<=500 && volnv2!=0)
        {
         trade.Buy(volnv2,_Symbol,tick.ask,puxatpsl("SLC1"),previsao,"C2");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C2") && !PossuiPosCompraComentada("C3") && (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100 && VolumePos()<=500 && volnv3!=0)
        {
         trade.Buy(volnv3,_Symbol,tick.ask,puxatpsl("SLC2"),previsao,"C3");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C3") && !PossuiPosCompraComentada("C4") && (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100 && VolumePos()<=500 && volnv4!=0)
        {
         trade.Buy(volnv4,_Symbol,tick.ask,puxatpsl("SLC3"),previsao,"C4");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C4") && !PossuiPosCompraComentada("C5") && (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100 && VolumePos()<=500 && volnv5!=0)
        {
         trade.Buy(volnv5,_Symbol,tick.ask,puxatpsl("SLC4"),previsao,"C5");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C5") && !PossuiPosCompraComentada("C6") && (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100 && VolumePos()<=500 && volnv6!=0)
        {
         trade.Buy(volnv6,_Symbol,tick.ask,puxatpsl("SLC5"),previsao,"C6");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C6") && !PossuiPosCompraComentada("C7") && (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100 && VolumePos()<=500 && volnv7!=0)
        {
         trade.Buy(volnv7,_Symbol,tick.ask,puxatpsl("SLC6"),previsao,"C7");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C7") && !PossuiPosCompraComentada("C8") && (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100 && VolumePos()<=500 && volnv8!=0)
        {
         trade.Buy(volnv8,_Symbol,tick.ask,puxatpsl("SLC7"),previsao,"C8");
         Sleep(500);
         return;
        }
     }
   if(estrategia==estrat1||estrategia==estrat2||estrategia==estrat3||estrategia==estrat4||estrategia==estrat5||estrategia==estrat6||estrategia==estrat7)
     {
      if(PositionsTotal()==0 /*&& tick.ask>candle[1].open*/)
        {
         trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C1") && !PossuiPosCompraComentada("C2") && tick.ask<PrecoAberturaPosCompra(1)-ptsmartprimcompra*_Point //
         && VolumePos()<=500 && volnv2!=0)
        {
         trade.Buy(volnv2,_Symbol,tick.ask,puxatpsl("SLC1"),puxatpsl("TPC1"),"C2");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C2") && !PossuiPosCompraComentada("C3") && (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100 && VolumePos()<=500 && volnv3!=0)
        {
         trade.Buy(volnv3,_Symbol,tick.ask,puxatpsl("SLC2"),puxatpsl("TPC2"),"C3");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C3") && !PossuiPosCompraComentada("C4") && (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100 && VolumePos()<=500 && volnv4!=0)
        {
         trade.Buy(volnv4,_Symbol,tick.ask,puxatpsl("SLC3"),puxatpsl("TPC3"),"C4");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C4") && !PossuiPosCompraComentada("C5") && (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100 && VolumePos()<=500 && volnv5!=0)
        {
         trade.Buy(volnv5,_Symbol,tick.ask,puxatpsl("SLC4"),puxatpsl("TPC4"),"C5");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C5") && !PossuiPosCompraComentada("C6") && (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100 && VolumePos()<=500 && volnv6!=0)
        {
         trade.Buy(volnv6,_Symbol,tick.ask,puxatpsl("SLC5"),puxatpsl("TPC5"),"C6");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C6") && !PossuiPosCompraComentada("C7") && (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100 && VolumePos()<=500 && volnv7!=0)
        {
         trade.Buy(volnv7,_Symbol,tick.ask,puxatpsl("SLC6"),puxatpsl("TPC6"),"C7");
         Sleep(500);
         return;
        }
      if(PossuiPosCompraComentada("C7") && !PossuiPosCompraComentada("C8") && (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100 && VolumePos()<=500 && volnv8!=0)
        {
         trade.Buy(volnv8,_Symbol,tick.ask,puxatpsl("SLC7"),puxatpsl("TPC7"),"C8");
         Sleep(500);
         return;
        }
     }
  }
//+---------------------------------------------------------------------------------------------------------------------------------+
/////////////////////////////////////////
//---|VENDAS NORMAIS COM MARTINGALE|---//
/////////////////////////////////////////
void  VendasNormais()
  {
   if(estrategia==estrat8||estrategia==estrat9||estrategia==estrat10||estrategia==estrat11||estrategia==estrat12)
     {
      double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
      if(PositionsTotal()==0)
        {
         trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),previsao,"V1");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V1") && !PossuiPosVendaComentada("V2") && tick.bid>PrecoAberturaPosVenda(1)+ptsmartprimcompra*_Point//
         && VolumePos()<=500 && volnv2!=0)
        {
         trade.Sell(volnv2,_Symbol,tick.bid,puxatpsl("SLV1"),previsao,"V2");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V2") && !PossuiPosVendaComentada("V3") && (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100 && VolumePos()<=500 && volnv3!=0)
        {
         trade.Sell(volnv3,_Symbol,tick.bid,puxatpsl("SLV2"),previsao,"V3");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V3") && !PossuiPosVendaComentada("V4") && (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100 && VolumePos()<=500 && volnv4!=0)
        {
         trade.Sell(volnv4,_Symbol,tick.bid,puxatpsl("SLV3"),previsao,"V4");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V4") && !PossuiPosVendaComentada("V5") && (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100 && VolumePos()<=500 && volnv5!=0)
        {
         trade.Sell(volnv5,_Symbol,tick.bid,puxatpsl("SLV4"),previsao,"V5");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V5") && !PossuiPosVendaComentada("V6") && (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100 && VolumePos()<=500 && volnv6!=0)
        {
         trade.Sell(volnv6,_Symbol,tick.bid,puxatpsl("SLV5"),previsao,"V6");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V6") && !PossuiPosVendaComentada("V7") && (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100 && VolumePos()<=500 && volnv7!=0)
        {
         trade.Sell(volnv7,_Symbol,tick.bid,puxatpsl("SLV6"),previsao,"V7");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V7") && !PossuiPosVendaComentada("V8") && (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100 && VolumePos()<=500 && volnv8!=0)
        {
         trade.Sell(volnv8,_Symbol,tick.bid,puxatpsl("SLV7"),previsao,"V8");
         Sleep(500);
         return;
        }
     }
   if(estrategia==estrat1||estrategia==estrat2||estrategia==estrat3||estrategia==estrat4||estrategia==estrat5||estrategia==estrat6||estrategia==estrat7)
     {
      if(PositionsTotal()==0)
        {
         trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V1") && !PossuiPosVendaComentada("V2") && tick.bid>PrecoAberturaPosVenda(1)+ptsmartprimcompra*_Point //
         && VolumePos()<=500 && volnv2!=0)
        {
         trade.Sell(volnv2,_Symbol,tick.bid,puxatpsl("SLV1"),puxatpsl("TPV1"),"V2");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V2") && !PossuiPosVendaComentada("V3") && (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100 && VolumePos()<=500 && volnv3!=0)
        {
         trade.Sell(volnv3,_Symbol,tick.bid,puxatpsl("SLV2"),puxatpsl("TPV2"),"V3");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V3") && !PossuiPosVendaComentada("V4") && (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100 && VolumePos()<=500 && volnv4!=0)
        {
         trade.Sell(volnv4,_Symbol,tick.bid,puxatpsl("SLV3"),puxatpsl("TPV3"),"V4");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V4") && !PossuiPosVendaComentada("V5") && (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100 && VolumePos()<=500 && volnv5!=0)
        {
         trade.Sell(volnv5,_Symbol,tick.bid,puxatpsl("SLV4"),puxatpsl("TPV4"),"V5");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V5") && !PossuiPosVendaComentada("V6") && (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100 && VolumePos()<=500 && volnv6!=0)
        {
         trade.Sell(volnv6,_Symbol,tick.bid,puxatpsl("SLV5"),puxatpsl("TPV5"),"V6");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V6") && !PossuiPosVendaComentada("V7") && (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100 && VolumePos()<=500 && volnv7!=0)
        {
         trade.Sell(volnv7,_Symbol,tick.bid,puxatpsl("SLV6"),puxatpsl("TPV6"),"V7");
         Sleep(500);
         return;
        }
      if(PossuiPosVendaComentada("V7") && !PossuiPosVendaComentada("V8") && (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100 && VolumePos()<=500 && volnv8!=0)
        {
         trade.Sell(volnv8,_Symbol,tick.bid,puxatpsl("SLV7"),puxatpsl("TPV7"),"V8");
         Sleep(500);
         return;
        }
     }
  }
//+---------------------------------------------------------------------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//---| AJUSTA O VALOR DE TAKE PROFIT E STOP LOSS PARA POSTERIOR INSERÇÃO NAS ORDENS DE COMPRA/VENDA |---//
//////////////////////////////////////////////////////////////////////////////////////////////////////////
double   puxatpsl(string tpsl)
  {
   string str=tpsl;
   if(str=="SLV0")
      return(tick.bid*(1+percentloss/100));
   if(str=="SLV1")
      return(PM1*(1+percentloss/100));
   if(str=="SLV2")
      return(PM2*(1+percentloss/100));
   if(str=="SLV3")
      return(PM3*(1+percentloss/100));
   if(str=="SLV4")
      return(PM4*(1+percentloss/100));
   if(str=="SLV5")
      return(PM5*(1+percentloss/100));
   if(str=="SLV6")
      return(PM6*(1+percentloss/100));
   if(str=="SLV7")
      return(PM7*(1+percentloss/100));

   if(str=="SLC0")
      return(tick.ask*(1-percentloss/100));
   if(str=="SLC1")
      return(PM1*(1-percentloss/100));
   if(str=="SLC2")
      return(PM2*(1-percentloss/100));
   if(str=="SLC3")
      return(PM3*(1-percentloss/100));
   if(str=="SLC4")
      return(PM4*(1-percentloss/100));
   if(str=="SLC5")
      return(PM5*(1-percentloss/100));
   if(str=="SLC6")
      return(PM6*(1-percentloss/100));
   if(str=="SLC7")
      return(PM7*(1-percentloss/100));

   if(str=="TPC0")
      return(tick.bid*(1+percentgain/100));
   if(str=="TPC1")
      return(PM1*(1+percentgain/100));
   if(str=="TPC2")
      return(PM2*(1+percentgain/100));
   if(str=="TPC3")
      return(PM3*(1+percentgain/100));
   if(str=="TPC4")
      return(PM4*(1+percentgain/100));
   if(str=="TPC5")
      return(PM5*(1+percentgain/100));
   if(str=="TPC6")
      return(PM6*(1+percentgain/100));
   if(str=="TPC7")
      return(PM7*(1+percentgain/100));

   if(str=="TPV0")
      return(tick.ask*(1-percentgain/100));
   if(str=="TPV1")
      return(PM1*(1-percentgain/100));
   if(str=="TPV2")
      return(PM2*(1-percentgain/100));
   if(str=="TPV3")
      return(PM3*(1-percentgain/100));
   if(str=="TPV4")
      return(PM4*(1-percentgain/100));
   if(str=="TPV5")
      return(PM5*(1-percentgain/100));
   if(str=="TPV6")
      return(PM6*(1-percentgain/100));
   if(str=="TPV7")
      return(PM7*(1-percentgain/100));
   return(NULL);
  }
//+------------------------------------------------------------------+
//| FUNÇÃO DE VERIFICAÇÃO DE HORÁRIO DE PARA ABERTURA DE ORDENS      |
//+------------------------------------------------------------------+
bool HorarioEntrada() //VERIFICA SE ESTÁ NO HORARIO DE FUNCIONAMENTO DO ROBÔ
  {

// Hora dentro do horário de entradas
   if(hratualstruct.hour >= hrinicialstruct.hour && hratualstruct.hour <= hrfinalstruct.hour)
     {
      // Hora atual igual a de início
      if(hratualstruct.hour == hrinicialstruct.hour)
         // Se minuto atual maior ou igual ao de início => está no horário de entradas
         if(hratualstruct.min >= hrinicialstruct.min)
            return true;
      // Do contrário não está no horário de entradas
         else
            return false;

      // Hora atual igual a de término
      if(hratualstruct.hour == hrfinalstruct.hour)
         // Se minuto atual menor ou igual ao de término => está no horário de entradas
         if(hratualstruct.min <= hrfinalstruct.min)
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
/*bool HorarioPausa1() //VERIFICA SE ESTÁ NO HORÁRIO DE PAUSA DO ROBÔ
  {
   TimeToStruct(TimeCurrent(), hratualstruct); // Obtenção do horário atual

// Hora dentro do horário de entradas
   if(hratualstruct.hour >= horario_inicio_pausa1.hour && hratualstruct.hour <= horario_termino_pausa1.hour)
     {
      // Hora atual igual a de início
      if(hratualstruct.hour == horario_inicio_pausa1.hour)
         // Se minuto atual maior ou igual ao de início => não está no horário de entradas
         if(hratualstruct.min >= horario_inicio_pausa1.min)
            return true;
      // Do contrário está no horário de entradas
         else
            return false;

      // Hora atual igual a de término
      if(hratualstruct.hour == horario_termino_pausa1.hour)
         // Se minuto atual menor ou igual ao de término => não está no horário de entradas
         if(hratualstruct.min <= horario_termino_pausa1.min)
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
  */
//+------------------------------------------------------------------------------------------+
