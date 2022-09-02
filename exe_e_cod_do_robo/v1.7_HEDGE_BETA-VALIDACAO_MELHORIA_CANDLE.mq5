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
   mart1,        //[1]FIBONACCI
   mart2,        //[2]05 FIBO + 04 N VEZES ANT
   mart3,        //[3]N x VOL ANTERIOR
   mart4,        //[4]N x VOL ANTERIOR ACUMULADO
  };

enum ENUM_TP_ESTRAT
  {
   estrat1,      //[1]ENVELOPE/RSI/BOLINGER
   estrat2,      //[2]ENVELOPE/RSI
   estrat3,      //[3]ENVELOPE/BOLINGER
   estrat4,      //[4]ENVELOPE/SAR
   estrat5,      //[5]RSI/BOLINGER
   estrat6,      //[6]ENVELOPE
   estrat7,      //[7]RSI
   estrat8,      //[8]BOLINGER
   estrat9,      //[9]SAR
   estrat10,     //[10]NEURAL
   estrat11,     //[11]NEURAL/RSI
   estrat12,     //[12]NEURAL/BOLINGER
   estrat13,     //[13]NEURAL/ENVELOPE
   estrat14,     //[14]NEURAL/SAR
  };

enum ENUM_TP_CONTA
  {
   tipocent,     //[1]CONTA CENT
   tipoprime,    //[2]CONTA PRIME/ECN
  };

enum ENUM_TP_OPER
  {
   tipohedge,    //[1]TIPO HEDGING
   tiponet,      //[2]TIPO NETTING
  };

enum ENUM_TP_STOP
  {
   tpstopprct,   //[1]EM PERCENTUAL
   tpstoppontos, //[2]EM PONTOS
  };

enum ENUM_TP_GAIN
  {
   tpgainprct,   //[1]EM PERCENTUAL
   tpgainpontos, //[2]EM PONTOS
  };

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//input ulong              magicrobo           = 941;        //MAGIC NUMBER DO ROBÔ
input group              "ABERTURA DE ORDENS"
input bool               ativaentradaea      = true;       //ATIVA ABERTURA AUTOMÁTICA DE ORDENS
input double             loteinicial         = 1;          //TAMANHO DO LOTE INICIAL
input double             aumentoprop         = 1000.00;    //[$] VALOR P/ AUMENTO PROPORCIONAL DO LOTE
input ENUM_TP_CONTA      tipoconta           = tipocent;   //[TP] SELECIONE O TIPO DE CONTA
ENUM_TP_OPER       tipooper            = tipohedge;  //[TP] SELECIONE O TIPO DE OPERAÇÃO
input ENUM_TP_STOP       tipostop            = tpstopprct; //[TP] SELECIONE O TIPO DE STOP LOSS
input double             percentloss         = 2.5;        //[%] DE STOP LOSS P/ ABERTURA DE ORDEM
input int                stoppontos          = 500;        //[PTS] DE STOP LOSS P/ ABERTURA DE ORDENS
input group              "MARTINGALE"
input ENUM_TP_MART       tipomartingale      = mart3;      //TIPO DE MARTINGALE
input int                multiplicador       = 1;          //[INT] MULTIPLICADOR P/ MARTINGALE (N)
input int                qtdecandle          = 2;          //[INT] QTOS CANDLES P/ PX ENTRADA
//input bool               martpontos          = false;      //MARTINGALE APENAS EM PONTOS
//input int                pontos2             = 50;         //[PTS] DISTÂNCIA P/ ABERT DA 2 ORDEM
//input int                pontos3             = 50;         //[PTS] DISTÂNCIA P/ ABERT DA 3 ORDEM
//input int                pontos4             = 50;         //[PTS] DISTÂNCIA P/ ABERT DA 4 ORDEM
//input int                pontos5             = 50;         //[PTS] DISTÂNCIA P/ ABERT DA 5 ORDEM
//input int                pontos6             = 50;         //[PTS] DISTÂNCIA P/ ABERT DA 6 ORDEM
//input int                pontos7             = 50;         //[PTS] DISTÂNCIA P/ ABERT DA 7 ORDEM
//input int                pontos8             = 50;         //[PTS] DISTÂNCIA P/ ABERT DA 8 ORDEM
//input int                ptsmartprimcompra   = 10000;      //[PTS] DISTANCIA PARA 2 OPERAÇÃO
//input double             prctmart            = 50;         //[%] MÍNIMA DAS 2 ORD ANT P/ PX ORD
input group              "ESCOLHA DA ESTRATÉGIA"
input ENUM_TP_ESTRAT     estrategia          = estrat1;    //ESCOLHA A ESTRATÉGIA
input group              "VALORES DEFINIDOS P/ SAR"
input double             stepSAR             = 0.02;       //STEP do SAR
input double             maximumSAR          = 0.2;        //MAXIMUM do SAR
input int                qtdesarmax          = 15;         //QTDE MÁXIMA DE SAR'S P/ ABERT DE ORDENS
input int                pontos1SAR          = 1300;       //QTDE MÁXIMA DE PONTOS DO 1o SAR P/ ABERT
//input group              "VARIÁVEIS DE CONFIRMAÇÃO - VOLUME E PREÇO"
//input double             percentvol          = 70;         //[%] MÍN DO VOL DO CAND1 EM REL AO 2
//input double             percentprice        = 70;         //[%] MÍN DO TAM DO CAND1 EM REL AO 2
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
input group              "FECHAMENTO DE ORDENS"
//input bool               ativasaidaea        = true;       //ATIVA FECHAMENTO DE ORDENS
input ENUM_TP_GAIN       tipogain            = tpgainprct; //[TP] SELECIONE TIPO DE GANHO
input double             percentgain         = 0.1;        //[%] PORCENTAGEM DE STOP GAIN
input int                pontosc1            = 100;        //[PTS] DISTANCIA P/ FECHAM 1 ORDEM
input int                pontosc2            = 60;         //[PTS] DISTANCIA P/ FECHAM 2 ORDENS
input int                pontosc3            = 40;         //[PTS] DISTANCIA P/ FECHAM 3 ORDENS
input int                pontosc4            = 40;         //[PTS] DISTANCIA P/ FECHAM 4 ORDENS
input int                pontosc5            = 30;         //[PTS] DISTANCIA P/ FECHAM 5 ORDENS
input int                pontosc6            = 20;         //[PTS] DISTANCIA P/ FECHAM 6 ORDENS
input int                pontosc7            = 10;         //[PTS] DISTANCIA P/ FECHAM 7 ORDENS
input int                pontosc8            = 10;         //[PTS] DISTANCIA P/ FECHAM 8 ORDENS
input int                pontosc9            = 40;         //[PTS] DISTANCIA P/ FECHAM 9 ORDENS
input int                pontosc10           = 40;         //[PTS] DISTANCIA P/ FECHAM 10 ORDENS
input int                pontosc11           = 30;         //[PTS] DISTANCIA P/ FECHAM 11 ORDENS
input int                pontosc12           = 20;         //[PTS] DISTANCIA P/ FECHAM 12 ORDENS
input int                pontosc13           = 10;         //[PTS] DISTANCIA P/ FECHAM 13 ORDENS
input int                pontosc14           = 10;         //[PTS] DISTANCIA P/ FECHAM 14 ORDENS
/*input group              "BREAKEVEN/TRAILING STOP"
input bool               ativbreak           = false;      //ATIVA BREAKEVEN/TRAILING STOP
input double             pontosbreak         = 5;          //PTOS PROX AO TP PARA ATIV BREAKEVEN
input double             pontosbreak2        = 5;          //PTOS P/ MOVER TP PARA FRENTE BREAKEVEN
input double             pontosbesl          = 10;         //PTOS A MENOS PARA SL NOVO
input double             pontosts            = 5;          //PTOS DO SL NOVO PARA ATIV TS
*/
input group              "GERENCIAMENTO DE RISCO - % MÍNIMA DE CAPITAL LIQUIDO PARA OPERAR"
input double             prcentabert         = 3500;       //[%] DO CAPIT MÍNIMO P/ ABRIR ORDENS
input group              "GERENCIAMENTO DE RISCO - PARADA DO ROBÔ COM STOPS ALCANÇADOS NO DIA"
input bool               ativastopdiario     = true;       //PARA O ROBÔ NO DIA QNDO STOP > N
input int                qtdestops           = 3;          //QTDE MÁXIMA DE STOPS (N)
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

int                      handlebb,handlersi,handleMM,handleSAR,handleSARh4;

ulong                    magicrobo           = 941;

double                   percent_margem, saldo, capital, lucro_prejuizo, volumemaximo, volumeoper, valoraumento, //
                         slcomprapadrao, slvendapadrao, tpcomprapadrao, tpvendapadrao, rsi[], bbu[], bbm[], bbd[], mediamovel[], sar[], sarh4[];

//--- Definição das variáveis dos volumes para compra e venda quando utilizar martingale
double                   volnv2,volnv3,volnv4,volnv5,volnv6,volnv7,volnv8,volnv9,volnv10,volnv11,volnv12,volnv13,volnv14;

//--- Definição das variáveis dos preços médios para compra e venda quando utilizar martingale
double                   PM1, PM2, PM3, PM4, PM5, PM6, PM7, PM8, PM9, PM10, PM11, PM12, PM13, PM14;

bool                     condicaoSAR         = false;

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
   handleSARh4 = iSAR(_Symbol,PERIOD_H4,stepSAR,maximumSAR);
   ArraySetAsSeries(candle,true);
   ArraySetAsSeries(rsi,true);
   ArraySetAsSeries(bbu,true);
   ArraySetAsSeries(bbm,true);
   ArraySetAsSeries(bbd,true);
   ArraySetAsSeries(mediamovel,true);
   ArraySetAsSeries(sar,true);
   ArraySetAsSeries(sarh4,true);

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
   if(Symbol()=="USDCHF")
     {
      slcomprapadrao=0.50000;
      slvendapadrao=2.00000;
     }
   if(Symbol()=="USDCAD")
     {
      slcomprapadrao=0.50000;
      slvendapadrao=2.00000;
     }
   if(Symbol()=="AUDUSD")
     {
      slcomprapadrao=0.40000;
      slvendapadrao=1.50000;
     }
   if(Symbol()=="NZDUSD")
     {
      slcomprapadrao=0.40000;
      slvendapadrao=1.00000;
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
   CopyRates(_Symbol,_Period,0,2*qtdesarmax,candle);
   if(CopyRates(_Symbol,_Period,0,2*qtdesarmax,candle)<0)
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
   CopyBuffer(handleSARh4,0,0,2*qtdesarmax,sarh4);
   if(CopyBuffer(handleSARh4,0,0,2*qtdesarmax,sarh4)<0)
     {
      Alert("Erro ao copiar dados de SARh4: ", GetLastError());
      return;
     }

   static CIsNewBar NB1,NB2,NB3/*,NB4,NB5,NB6,NB7,NB8,NB9,NB10,NB11,NB12,NB13,NB14,NB15,NB16,NB17,NB18,NB19,NB20,NB21,NB22*/;

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
         volnv9             = 55*volumeoper;//55
         volnv10            = 89*volumeoper;//89
         volnv11            = 144*volumeoper;//144
         volnv12            = 233*volumeoper;//233
         volnv13            = 377*volumeoper;//377
         volnv14            = 610*volumeoper;//610
        }
      if(tipomartingale==mart2)//mix - fibo ate a 5 ordem e N vezes o anterior nas ordens seguintes
        {
         volnv2             = 2*volumeoper;//2
         volnv3             = 3*volumeoper;//3
         volnv4             = 5*volumeoper;//5
         volnv5             = 8*volumeoper;//8
         volnv6             = volnv5*multiplicador;
         volnv7             = volnv6*multiplicador;
         volnv8             = volnv8*multiplicador;
         volnv9             = volnv9*multiplicador;
         volnv10            = volnv10*multiplicador;
         volnv11            = volnv11*multiplicador;
         volnv12            = volnv12*multiplicador;
         volnv13            = volnv13*multiplicador;
         volnv14            = volnv14*multiplicador;
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
         volnv9             = volnv8*multiplicador;
         volnv10            = volnv9*multiplicador;
         volnv11            = volnv10*multiplicador;
         volnv12            = volnv11*multiplicador;
         volnv13            = volnv12*multiplicador;
         volnv14            = volnv13*multiplicador;
        }
      if(tipomartingale==mart4)//N vezes o volume anterior acumulado
        {
         volnv2             = volumeoper*multiplicador;//2
         volnv3             = (volumeoper+volnv2)*multiplicador;//6
         volnv4             = (volumeoper+volnv2+volnv3)*multiplicador;//18
         volnv5             = (volumeoper+volnv2+volnv3+volnv4)*multiplicador;//54
         volnv6             = (volumeoper+volnv2+volnv3+volnv4+volnv5)*multiplicador;//162
         volnv7             = (volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6)*multiplicador;//486
         volnv8             = (volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7)*multiplicador;//1458
         volnv9             = (volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7+volnv8)*multiplicador;//
         volnv10            = (volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7+volnv8+volnv9)*multiplicador;//
         volnv11            = (volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7+volnv8+volnv9+volnv10)*multiplicador;//
         volnv12            = (volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7+volnv8+volnv9+volnv10+volnv11)*multiplicador;//
         volnv13            = (volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7+volnv8+volnv9+volnv10+volnv11+volnv12)*multiplicador;//
         volnv14            = (volumeoper+volnv2+volnv3+volnv4+volnv5+volnv6+volnv7+volnv8+volnv9+volnv10+volnv11+volnv12+volnv13)*multiplicador;//
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
   if(PositionsTotal()>=1)

     {
      if(PossuiPosCompraComentada("C1") && !PossuiPosCompraComentada("C2"))
         PM1 = (tick.ask*volnv2 + PrecoPosAberta()*volumeoper)/(volnv2+volumeoper);
      if(PossuiPosCompraComentada("C2") && !PossuiPosCompraComentada("C3"))
         PM2 = (tick.ask*volnv3 + PrecoPosAberta()*VolumePos())/(volnv3+VolumePos());
      if(PossuiPosCompraComentada("C3") && !PossuiPosCompraComentada("C4"))
         PM3 = (tick.ask*volnv4 + PrecoPosAberta()*VolumePos())/(volnv4+VolumePos());
      if(PossuiPosCompraComentada("C4") && !PossuiPosCompraComentada("C5"))
         PM4 = (tick.ask*volnv5 + PrecoPosAberta()*VolumePos())/(volnv5+VolumePos());
      if(PossuiPosCompraComentada("C5") && !PossuiPosCompraComentada("C6"))
         PM5 = (tick.ask*volnv6 + PrecoPosAberta()*VolumePos())/(volnv6+VolumePos());
      if(PossuiPosCompraComentada("C6") && !PossuiPosCompraComentada("C7"))
         PM6 = (tick.ask*volnv7 + PrecoPosAberta()*VolumePos())/(volnv7+VolumePos());
      if(PossuiPosCompraComentada("C7") && !PossuiPosCompraComentada("C8"))
         PM7 = (tick.ask*volnv8 + PrecoPosAberta()*VolumePos())/(volnv8+VolumePos());
      if(PossuiPosCompraComentada("C8") && !PossuiPosCompraComentada("C9"))
         PM8 = (tick.ask*volnv9 + PrecoPosAberta()*VolumePos())/(volnv9+VolumePos());
      if(PossuiPosCompraComentada("C9") && !PossuiPosCompraComentada("C10"))
         PM9 = (tick.ask*volnv10 + PrecoPosAberta()*VolumePos())/(volnv10+VolumePos());
      if(PossuiPosCompraComentada("C10") && !PossuiPosCompraComentada("C11"))
         PM10 = (tick.ask*volnv11 + PrecoPosAberta()*VolumePos())/(volnv11+VolumePos());
      if(PossuiPosCompraComentada("C11") && !PossuiPosCompraComentada("C12"))
         PM11 = (tick.ask*volnv12 + PrecoPosAberta()*VolumePos())/(volnv12+VolumePos());
      if(PossuiPosCompraComentada("C12") && !PossuiPosCompraComentada("C13"))
         PM12 = (tick.ask*volnv13 + PrecoPosAberta()*VolumePos())/(volnv13+VolumePos());
      if(PossuiPosCompraComentada("C13") && !PossuiPosCompraComentada("C14"))
         PM13 = (tick.ask*volnv14 + PrecoPosAberta()*VolumePos())/(volnv14+VolumePos());

      if(PossuiPosVendaComentada("V1") && !PossuiPosVendaComentada("V2"))
         PM1 = (tick.bid*volnv2 + PrecoPosAberta()*volumeoper)/(volnv2+volumeoper);
      if(PossuiPosVendaComentada("V2") && !PossuiPosVendaComentada("V3"))
         PM2 = (tick.bid*volnv3 + PrecoPosAberta()*VolumePos())/(volnv3+VolumePos());
      if(PossuiPosVendaComentada("V3") && !PossuiPosVendaComentada("V4"))
         PM3 = (tick.bid*volnv4 + PrecoPosAberta()*VolumePos())/(volnv4+VolumePos());
      if(PossuiPosVendaComentada("V4") && !PossuiPosVendaComentada("V5"))
         PM4 = (tick.bid*volnv5 + PrecoPosAberta()*VolumePos())/(volnv5+VolumePos());
      if(PossuiPosVendaComentada("V5") && !PossuiPosVendaComentada("V6"))
         PM5 = (tick.bid*volnv6 + PrecoPosAberta()*VolumePos())/(volnv6+VolumePos());
      if(PossuiPosVendaComentada("V6") && !PossuiPosVendaComentada("V7"))
         PM6 = (tick.bid*volnv7 + PrecoPosAberta()*VolumePos())/(volnv7+VolumePos());
      if(PossuiPosVendaComentada("V7") && !PossuiPosVendaComentada("V8"))
         PM7 = (tick.bid*volnv8 + PrecoPosAberta()*VolumePos())/(volnv8+VolumePos());
      if(PossuiPosVendaComentada("V8") && !PossuiPosVendaComentada("V9"))
         PM8 = (tick.bid*volnv9 + PrecoPosAberta()*VolumePos())/(volnv9+VolumePos());
      if(PossuiPosVendaComentada("V9") && !PossuiPosVendaComentada("V10"))
         PM9 = (tick.bid*volnv10 + PrecoPosAberta()*VolumePos())/(volnv10+VolumePos());
      if(PossuiPosVendaComentada("V10") && !PossuiPosVendaComentada("V11"))
         PM10 = (tick.bid*volnv11 + PrecoPosAberta()*VolumePos())/(volnv11+VolumePos());
      if(PossuiPosVendaComentada("V11") && !PossuiPosVendaComentada("V12"))
         PM11 = (tick.bid*volnv12 + PrecoPosAberta()*VolumePos())/(volnv12+VolumePos());
      if(PossuiPosVendaComentada("V12") && !PossuiPosVendaComentada("V13"))
         PM12 = (tick.bid*volnv13 + PrecoPosAberta()*VolumePos())/(volnv13+VolumePos());
      if(PossuiPosVendaComentada("V13") && !PossuiPosVendaComentada("V14"))
         PM13 = (tick.bid*volnv14 + PrecoPosAberta()*VolumePos())/(volnv14+VolumePos());
     }

   TimeToStruct(TimeCurrent(),hratualstruct);
//datetime aberturacandleatual=datetime(SeriesInfoInteger(_Symbol,_Period,SERIES_LASTBAR_DATE));
   double   sarnormalizado0 = NormalizeDouble(sar[0],5);
   double   sarnormalizado1 = NormalizeDouble(sar[1],5);

   //if((PossuiPosCompra() && SarOk("COMPRA")==true) || (PossuiPosVenda() && SarOk("VENDA")==true))
   //   condicaoSAR = true;

////////////////////////////////////////////
//---| FECHA ORDENS NO FIM DO PREGÃO |----//
////////////////////////////////////////////
   if(ativafecfinaldia==true && (PossuiPosCompra()||PossuiPosVenda()) && hratualstruct.hour==hrfechstruct.hour && hratualstruct.min==hrfechstruct.min)
     {
      FechaTodasPosicoesAbertas();
     }

////////////////////////////////////////////////////////////////////////////////////
//---| FECHA ORDENS DE COMPRA QNDO TARGET DE UMA COMPRA FOR ATINGIDO - LUCRO |----//
////////////////////////////////////////////////////////////////////////////////////
   if(UltimaPosFechadaTakeCompra() && PossuiPosCompra())
     {
      for(int i=PositionsTotal()-1; i >= 0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         string position_symbol = PositionGetString(POSITION_SYMBOL);
         //ulong  magic = PositionGetInteger(POSITION_MAGIC);
         double LucroPrejuizo = PositionGetDouble(POSITION_PROFIT);
         ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(TipoPosicao==POSITION_TYPE_BUY && position_symbol==_Symbol && LucroPrejuizo>0)
            trade.PositionClose(ticket);
        }
     }

//////////////////////////////////////////////////////////////////////////////////
//---| FECHA ORDENS DE VENDA QNDO TARGET DE UMA VENDA FOR ATINGIDO - LUCRO |----//
//////////////////////////////////////////////////////////////////////////////////
   if(UltimaPosFechadaTakeVenda() && PossuiPosVenda())
     {
      for(int i=PositionsTotal()-1; i >= 0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         string position_symbol = PositionGetString(POSITION_SYMBOL);
         //ulong  magic = PositionGetInteger(POSITION_MAGIC);
         double LucroPrejuizo = PositionGetDouble(POSITION_PROFIT);
         ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(TipoPosicao==POSITION_TYPE_SELL && position_symbol==_Symbol && LucroPrejuizo>0)
            trade.PositionClose(ticket);
        }
     }

////////////////////////////////////////////////////////////////////////////////
//---| FECHA ORDENS DE COMPRA QNDO MÃO VIRADA DE VENDA COMPENSAR A PERDA |----//
////////////////////////////////////////////////////////////////////////////////
   //Print(/*DataHoraUltPosVendaFechada(),*/" ",DataHoraUltPosCompraAberta());
   /*   if(PossuiPosCompra() && UltimaPosFechadaTakeVenda() && DataHoraUltPosVendaFechada()>DataHoraUltPosCompraAberta())
        {
         for(int i=0; i<PositionsTotal(); i++)
           {
            ulong ticket=PositionGetTicket(i);
            string position_symbol = PositionGetString(POSITION_SYMBOL);
            //ulong  magic = PositionGetInteger(POSITION_MAGIC);
            double prejuPOS = PositionGetDouble(POSITION_PROFIT);
            ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if(TipoPosicao==POSITION_TYPE_BUY && position_symbol==_Symbol)
              {
               HistorySelect(0,TimeCurrent());
               ulong    ticket1=0;
               string   symbol;
               long     reason;
               long     entry;
               long     type;
               double   lucro;
               double   lucrotemp=0;
               for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
                 {
                  //--- tentar obter ticket negócios
                  if((ticket=HistoryDealGetTicket(i))>0)
                    {
                     //--- obter as propriedades negócios
                     symbol=HistoryDealGetString(ticket1,DEAL_SYMBOL);
                     reason=HistoryDealGetInteger(ticket1,DEAL_REASON);
                     entry =HistoryDealGetInteger(ticket1,DEAL_ENTRY);
                     type  =HistoryDealGetInteger(ticket1,DEAL_TYPE);
                     lucro =HistoryDealGetDouble(ticket1,DEAL_PROFIT);
                     lucrotemp=0;
                     //--- apenas para o símbolo atual
                     if(reason==DEAL_REASON_TP && entry==DEAL_ENTRY_OUT && type==DEAL_TYPE_BUY && symbol==_Symbol && MathAbs(lucrotemp)>MathAbs(prejuPOS))
                       {
                       Print("teste");
                       }
                    }
                 }
              }
           }
        }
    */

//+------------------------------------------------------------------+
//| OPERAÇÕES SEGUINDO A ESTRATÉGIA ESCOLHIDA |
//+------------------------------------------------------------------+

//   Print("ABERTURA DO CANDLE: ",aberturacandleatual);

//--- Check de posição aberta em outro ativo, horário de operação e margem suficiente pra operar
   if(ativaentradaea && !PossuiPosAbertaOutroAtivo() && HorarioEntrada()==true && (percent_margem>prcentabert||saldo==capital))
     {

      //--- Verifica se candle acabou de abrir e se o número de STOPS ultrapassou o máximo permitido no dia
      if(NB2.IsNewBar(_Symbol,_Period) && QtdeStops()<qtdestops)
        {
         if(!PossuiPosCompraComentada("C1"))
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
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
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
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
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
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            /////////////////////////////////////
            //---| ESTRATEGIA ENVELOPE/SAR |---//
            /////////////////////////////////////
            if(estrategia==estrat4)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(candle[1].close<mediamovel[1]-tamanhoenvelope*_Point && sarnormalizado0 < tick.ask && sarnormalizado1 < tick.ask)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            /////////////////////////////////////
            //---| ESTRATEGIA RSI/BOLINGER |---//
            /////////////////////////////////////
            if(estrategia==estrat5)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/ && candle[1].close<bbd[1])
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            /////////////////////////////////
            //---| ESTRATEGIA ENVELOPE |---//
            /////////////////////////////////
            if(estrategia==estrat6)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(candle[1].close<mediamovel[1]-tamanhoenvelope*_Point)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");

              }
            ////////////////////////////
            //---| ESTRATEGIA RSI |---//
            ////////////////////////////
            if(estrategia==estrat7)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            /////////////////////////////////
            //---| ESTRATEGIA BOLINGER |---//
            /////////////////////////////////
            if(estrategia==estrat8)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(candle[1].close<bbd[1])
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");

              }
            ////////////////////////////
            //---| ESTRATEGIA SAR |---//
            ////////////////////////////
            if(estrategia==estrat9)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(sarnormalizado0 < tick.ask && sarnormalizado1 < tick.ask)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");

              }
            ///////////////////////////////
            //---| ESTRATEGIA NEURAL |---//
            ///////////////////////////////
            if(estrategia==estrat10)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(previsao > tick.ask && previsao != 0 /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");

              }
            ///////////////////////////////////
            //---| ESTRATEGIA NEURAL/RSI |---//
            ///////////////////////////////////
            if(estrategia==estrat11)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(previsao > tick.ask && previsao != 0 && rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/ /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");

              }
            ////////////////////////////////////////
            //---| ESTRATEGIA NEURAL/BOLINGER |---//
            ////////////////////////////////////////
            if(estrategia==estrat12)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(previsao > tick.ask && previsao != 0 && candle[1].close<bbd[1] /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");

              }
            ///////////////////////////////////////
            //---| ESTRATEGIA NEURAL/ENVELOPE |---//
            ///////////////////////////////////////
            if(estrategia==estrat13)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(previsao > tick.ask && previsao != 0 && candle[1].close<mediamovel[1]-tamanhoenvelope*_Point /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");

              }
            ///////////////////////////////////
            //---| ESTRATEGIA NEURAL/SAR |---//
            ///////////////////////////////////
            if(estrategia==estrat14)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               //Print(previsao);
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(previsao > tick.ask && previsao != 0 && sarnormalizado0 < tick.ask && sarnormalizado1 < tick.ask)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");

              }
           }
         if(!PossuiPosVendaComentada("V1"))
           {
            //////////////////////////////////////////////
            //---| ESTRATEGIA ENVELOPE/RSI/BOLINGER |---//
            //////////////////////////////////////////////
            if(estrategia==estrat1)
              {
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ && candle[1].close>bbu[1])
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            /////////////////////////////////////
            //---| ESTRATEGIA ENVELOPE/RSI |---//
            /////////////////////////////////////
            if(estrategia==estrat2)
              {
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //////////////////////////////////////////
            //---| ESTRATEGIA ENVELOPE/BOLINGER |---//
            //////////////////////////////////////////
            if(estrategia==estrat3)
              {
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point && candle[1].close>bbu[1])
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            /////////////////////////////////////
            //---| ESTRATEGIA ENVELOPE/SAR |---//
            /////////////////////////////////////
            if(estrategia==estrat4)
              {
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point && sarnormalizado0 > tick.bid && sarnormalizado1 > tick.bid)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            /////////////////////////////////////
            //---| ESTRATEGIA RSI/BOLINGER |---//
            /////////////////////////////////////
            if(estrategia==estrat5)
              {
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ && candle[1].close>bbu[1])
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            /////////////////////////////////
            //---| ESTRATEGIA ENVELOPE |---//
            /////////////////////////////////
            if(estrategia==estrat6)
              {
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            ////////////////////////////
            //---| ESTRATEGIA RSI |---//
            ////////////////////////////
            if(estrategia==estrat7)
              {
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            /////////////////////////////////
            //---| ESTRATEGIA BOLINGER |---//
            /////////////////////////////////
            if(estrategia==estrat8)
              {
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>bbu[1])
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            ////////////////////////////
            //---| ESTRATEGIA SAR |---//
            ////////////////////////////
            if(estrategia==estrat9)
              {
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(sarnormalizado0 > tick.bid && sarnormalizado1 > tick.bid)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            ///////////////////////////////
            //---| ESTRATEGIA NEURAL |---//
            ///////////////////////////////
            if(estrategia==estrat10)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(previsao < tick.bid && previsao !=0 /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            ///////////////////////////////////
            //---| ESTRATEGIA NEURAL/RSI |---//
            ///////////////////////////////////
            if(estrategia==estrat11)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(previsao < tick.bid && previsao !=0 && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            ////////////////////////////////////////
            //---| ESTRATEGIA NEURAL/BOLINGER |---//
            ////////////////////////////////////////
            if(estrategia==estrat12)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(previsao < tick.bid && previsao !=0 && candle[1].close>bbu[1] /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            ///////////////////////////////////////
            //---| ESTRATEGIA NEURAL/ENVELOPE |---//
            ///////////////////////////////////////
            if(estrategia==estrat13)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(previsao < tick.bid && previsao !=0 && candle[1].close>mediamovel[1]+tamanhoenvelope*_Point /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            ///////////////////////////////////
            //---| ESTRATEGIA NEURAL/SAR |---//
            ///////////////////////////////////
            if(estrategia==estrat14)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(previsao < tick.bid && previsao != 0 && sarnormalizado0 > tick.bid && sarnormalizado1 > tick.bid)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
           }
         if(PositionsTotal()>=1 /*&& condicaoSAR==true*/ && ((PossuiPosCompra() && QtdeCandles("COMPRA")>qtdecandle) || (PossuiPosVenda() && QtdeCandles("VENDA")>qtdecandle)))
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
                  ComprasMartingale();
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ && candle[1].close>bbu[1])
                  VendasMartingale();
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
                  ComprasMartingale();
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/)
                  VendasMartingale();
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
                  ComprasMartingale();
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point && candle[1].close>bbu[1])
                  VendasMartingale();
              }
            /////////////////////////////////////
            //---| ESTRATEGIA ENVELOPE/SAR |---//
            /////////////////////////////////////
            if(estrategia==estrat4)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(candle[1].close<mediamovel[1]-tamanhoenvelope*_Point && sarnormalizado0 < tick.ask && sarnormalizado1 < tick.ask)
                  ComprasMartingale();
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point && sarnormalizado0 > tick.bid && sarnormalizado1 > tick.bid)
                  VendasMartingale();
              }
            /////////////////////////////////////
            //---| ESTRATEGIA RSI/BOLINGER |---//
            /////////////////////////////////////
            if(estrategia==estrat5)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/ && candle[1].close<bbd[1])
                  ComprasMartingale();
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ && candle[1].close>bbu[1])
                  VendasMartingale();
              }
            /////////////////////////////////
            //---| ESTRATEGIA ENVELOPE |---//
            /////////////////////////////////
            if(estrategia==estrat6)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(candle[1].close<mediamovel[1]-tamanhoenvelope*_Point)
                  ComprasMartingale();

               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>mediamovel[1]+tamanhoenvelope*_Point)
                  VendasMartingale();
              }
            ////////////////////////////
            //---| ESTRATEGIA RSI |---//
            ////////////////////////////
            if(estrategia==estrat7)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/)
                  ComprasMartingale();
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/)
                  VendasMartingale();
              }
            /////////////////////////////////
            //---| ESTRATEGIA BOLINGER |---//
            /////////////////////////////////
            if(estrategia==estrat8)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(candle[1].close<bbd[1])
                  ComprasMartingale();

               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>bbu[1])
                  VendasMartingale();
              }
            ////////////////////////////
            //---| ESTRATEGIA SAR |---//
            ////////////////////////////
            if(estrategia==estrat9)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(sarnormalizado0 < tick.ask && sarnormalizado1 < tick.ask)
                  ComprasMartingale();

               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(sarnormalizado0 > tick.bid && sarnormalizado1 > tick.bid)
                  VendasMartingale();
              }
            ///////////////////////////////
            //---| ESTRATEGIA NEURAL |---//
            ///////////////////////////////
            if(estrategia==estrat10)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(previsao > tick.ask && previsao != 0 /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  ComprasMartingale();

               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(previsao < tick.bid && previsao !=0 /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  VendasMartingale();
              }
            ///////////////////////////////////
            //---| ESTRATEGIA NEURAL/RSI |---//
            ///////////////////////////////////
            if(estrategia==estrat11)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(previsao > tick.ask && previsao != 0 && rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/ /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  ComprasMartingale();

               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(previsao < tick.bid && previsao !=0 && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  VendasMartingale();
              }
            ////////////////////////////////////////
            //---| ESTRATEGIA NEURAL/BOLINGER |---//
            ////////////////////////////////////////
            if(estrategia==estrat12)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(previsao > tick.ask && previsao != 0 && candle[1].close<bbd[1] /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  ComprasMartingale();

               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(previsao < tick.bid && previsao !=0 && candle[1].close>bbu[1] /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  VendasMartingale();
              }
            ///////////////////////////////////////
            //---| ESTRATEGIA NEURAL/ENVELOPE |---//
            ///////////////////////////////////////
            if(estrategia==estrat13)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(previsao > tick.ask && previsao != 0 && candle[1].close<mediamovel[1]-tamanhoenvelope*_Point /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  ComprasMartingale();

               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(previsao < tick.bid && previsao !=0 && candle[1].close>mediamovel[1]+tamanhoenvelope*_Point /*&& candle[2].close>candle[2].open && candle[1].close>candle[1].open && candle[1].tick_volume>candle[2].tick_volume*(percentvol/100) //
               && (candle[1].close-candle[1].open)>=(candle[2].close-candle[2].open)*(percentprice/100)*/)
                  VendasMartingale();
              }
            ///////////////////////////////////
            //---| ESTRATEGIA NEURAL/SAR |---//
            ///////////////////////////////////
            if(estrategia==estrat14)
              {
               double   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);
               //Print(previsao);
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(previsao > tick.ask && previsao != 0 && sarnormalizado0 < tick.ask && sarnormalizado1 < tick.ask)
                  ComprasMartingale();

               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(previsao < tick.bid && previsao != 0 && sarnormalizado0 > tick.bid && sarnormalizado1 > tick.bid)
                  VendasMartingale();
              }
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
      if(MathAbs((LucroPrejuUltPosAberta()/capital)*100)>=percentfull && LucroPrejuUltPosAberta()<0 && saldo!=capital)
        {
         FechaTodasPosicoesAbertas();
         Sleep(100);
         return;
        }

/////////////////////////////////
//---|FECHAMENTO DA ORDENS|----//
/////////////////////////////////
   /*   if(ativasaidaea==true)
        {
         if(PossuiPosCompraComentada("C1") && tick.bid>PrecoPosAberta()+pontosc1*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosCompraComentada("C2") && tick.bid>PrecoPosAberta()+pontosc2*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosCompraComentada("C3") && tick.bid>PrecoPosAberta()+pontosc3*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosCompraComentada("C4") && tick.bid>PrecoPosAberta()+pontosc4*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosCompraComentada("C5") && tick.bid>PrecoPosAberta()+pontosc5*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosCompraComentada("C6") && tick.bid>PrecoPosAberta()+pontosc6*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosCompraComentada("C7") && tick.bid>PrecoPosAberta()+pontosc7*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosCompraComentada("C8") && tick.bid>PrecoPosAberta()+pontosc8*_Point)
            FechaTodasPosicoesAbertas();

         if(PossuiPosVendaComentada("V1") && tick.ask<PrecoPosAberta()-pontosc1*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosVendaComentada("V2") && tick.ask<PrecoPosAberta()-pontosc2*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosVendaComentada("V3") && tick.ask<PrecoPosAberta()-pontosc3*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosVendaComentada("V4") && tick.ask<PrecoPosAberta()-pontosc4*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosVendaComentada("V5") && tick.ask<PrecoPosAberta()-pontosc5*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosVendaComentada("V6") && tick.ask<PrecoPosAberta()-pontosc6*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosVendaComentada("V7") && tick.ask<PrecoPosAberta()-pontosc7*_Point)
            FechaTodasPosicoesAbertas();
         if(PossuiPosVendaComentada("V8") && tick.ask<PrecoPosAberta()-pontosc8*_Point)
            FechaTodasPosicoesAbertas();
        }
        */
////////////////////////////
//---|BREAKEVEN E TS |----//
////////////////////////////
   /*   if(ativbreak==true)
        {

         if(PossuiPosCompra() && tick.bid>PrecoPosAberta() && StopUltimaPosAberta()==slcomprapadrao && tick.ask>TPUltimaPosAberta()-pontosbreak*_Point)
           {
            trade.PositionModify(_Symbol,tick.bid-pontosbesl*_Point,TPUltimaPosAberta()+pontosbreak2*_Point);
            Sleep(200);
           }
         if(PossuiPosCompra() && tick.bid>TPUltimaPosAberta()+pontosts*_Point && StopUltimaPosAberta()!=slcomprapadrao)
           {
            trade.PositionModify(_Symbol,TPUltimaPosAberta()+pontosts*_Point,TPUltimaPosAberta()+pontosts*_Point);
            Sleep(200);
           }

         if(PossuiPosVenda() && tick.ask<PrecoPosAberta() && StopUltimaPosAberta()==slvendapadrao && tick.bid<TPUltimaPosAberta()+pontosbreak*_Point)
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
         //Alert(hora_atual-hora_oper);
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
//+------------------------------------------------------------------+
//| VERIFICA CONDIÇÃO DO SAR FAVORÁVEL A ENTRADA DE ORDENS DE COMPRA |
//+------------------------------------------------------------------+
bool  SarOk(string tipo)
  {
   bool C1 = true;
   if(tipo=="COMPRA" && sarh4[qtdesarmax+1]>0 && candle[qtdesarmax+1].high>0)
     {
      for(int i=0; i<qtdesarmax+1; i++)
        {
         if(candle[i].high<sarh4[i])
            C1 = false;
        }
      if(sarh4[qtdesarmax]>tick.ask+pontos1SAR*_Point)
         C1 = false;
     }
   if(tipo=="VENDA" && sarh4[qtdesarmax+1]>0 && candle[qtdesarmax+1].low>0)
     {
      for(int i=0; i<qtdesarmax+1; i++)
        {
         if(candle[i].low>sarh4[i])
            C1 = false;
        }
      if(tick.bid>sarh4[qtdesarmax]+pontos1SAR*_Point)
         C1 = false;
     }
   return C1;
  }
//+------------------------------------------------------------------------------------------+
//+---------------------------------------------+
//| CONTADOR DE CANDLES DESDE ÚLTIMA POS ABERTA |
//+---------------------------------------------+
int   QtdeCandles(string tipo)
  {
   int qtdebars=0;
   if(PossuiPosCompra() && tipo=="COMPRA")
      qtdebars = Bars(_Symbol,_Period,DataHoraUltPosCompraAberta(),TimeCurrent());
   if(PossuiPosVenda() && tipo=="VENDA")
      qtdebars = Bars(_Symbol,_Period,DataHoraUltPosVendaAberta(),TimeCurrent());
   return qtdebars;
  }
//+------------------------------------------------------------------------------------------+
//+--------------------------+
//| LER ARQUIVOS E PREVISÕES |
//+--------------------------+
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
//+-------------------------------------------------------------+
//| RETORNA A DATA/HORA DO ABERTURA DA ULTIMA POSIÇÃO DE COMPRA |
//+-------------------------------------------------------------+
datetime DataHoraUltPosCompraAberta()
  {
   datetime timeatual=D'2002.02.01 00:00';
   if(PossuiPosCompra())
     {
      for(int i=PositionsTotal()-1; i >= 0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         string position_symbol = PositionGetString(POSITION_SYMBOL);
         datetime position_time = (datetime)PositionGetInteger(POSITION_TIME);
         //ulong  magic = PositionGetInteger(POSITION_MAGIC);
         ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(TipoPosicao==POSITION_TYPE_BUY && position_symbol==_Symbol)
           {
            return position_time;
            break;
           }
        }
     }
   else
      timeatual=D'2010.02.01 00:00';
   return timeatual;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------+
//| RETORNA A DATA/HORA DO ABERTURA DA ULTIMA POSIÇÃO DE VENDA |
//+------------------------------------------------------------+
datetime DataHoraUltPosVendaAberta()
  {
   datetime timeatual=D'2002.02.01 00:00';
   if(PossuiPosVenda())
     {
      for(int i=PositionsTotal()-1; i >= 0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         string position_symbol = PositionGetString(POSITION_SYMBOL);
         datetime position_time = (datetime)PositionGetInteger(POSITION_TIME);
         //ulong  magic = PositionGetInteger(POSITION_MAGIC);
         ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(TipoPosicao==POSITION_TYPE_SELL && position_symbol==_Symbol)
           {
            return position_time;
            break;
           }
        }
     }
   else
      timeatual=D'2010.02.01 00:00';
   return timeatual;
  }
//+------------------------------------------------------------------+
//+----------------------------------------------------+
//| RETORNA A DATA/HORA DO FECHAMENTO DA ULTIMA COMPRA |
//+----------------------------------------------------+
datetime DataHoraUltPosCompraFechada()
  {
   /*HistorySelect(0,TimeCurrent());
   ulong       ticket=0;
   string      symbol;
   long        entry;
   long        type;
   datetime    time;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
         if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
           {
            return time;
            break;
           }
        }
     }*/
   datetime timeatual=D'2010.02.01 00:00';
   return (timeatual);
  }
//+------------------------------------------------------------------+
//+---------------------------------------------------+
//| RETORNA A DATA/HORA DO FECHAMENTO DA ULTIMA VENDA |
//+---------------------------------------------------+
datetime DataHoraUltPosVendaFechada()
  {
   datetime timeatual=D'2002.02.01 00:00';
   if(UltimaPosFechadaTakeVenda())
     {
      HistorySelect(0,TimeCurrent());
      ulong       ticket=0;
      string      symbol;
      long        entry;
      long        type;
      datetime    time;
      for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
        {
         if((ticket=HistoryDealGetTicket(i))>0)
           {
            time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return time;
               break;
              }
           }
        }
     }
   else
      timeatual=D'2010.02.01 00:00';
   return timeatual;
  }
//+------------------------------------------------------------------+
//+-------------------------------------------------------------+
//| RETORNA A DATA/HORA DO ABERTURA DA ULTIMA POSIÇÃO DE COMPRA |
//+-------------------------------------------------------------+
int QtdeComprasAbertas()
  {
   int qtdeordens=0;
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      datetime position_time = (datetime)PositionGetInteger(POSITION_TIME);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(TipoPosicao==POSITION_TYPE_BUY && position_symbol==_Symbol /*&& magic == magicrobo*/)
         qtdeordens++;
     }
   return qtdeordens;
  }
//+------------------------------------------------------------------+
//+-------------------------------------------------------------+
//| RETORNA A DATA/HORA DO ABERTURA DA ULTIMA POSIÇÃO DE COMPRA |
//+-------------------------------------------------------------+
int QtdeVendasAbertas()
  {
   int qtdeordens=0;
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      datetime position_time = (datetime)PositionGetInteger(POSITION_TIME);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(TipoPosicao==POSITION_TYPE_SELL && position_symbol==_Symbol /*&& magic == magicrobo*/)
         qtdeordens++;
     }
   return qtdeordens;
  }
//+------------------------------------------------------------------+
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
         return contador;
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
//+----------------------------------------------------------------------------------------+
//| VERIFICA SE A ÚLTIMA POSICAO FECHADA FOI DE TAKE PROFIT ATINGIDO DE UMA ORDEM DE COMPRA|
//+----------------------------------------------------------------------------------------+
bool UltimaPosFechadaTakeCompra()
  {
   HistorySelect(0,TimeCurrent());
   ulong    ticket=0;
   string   symbol;
   long     reason;
   long     entry;
   long     typeorder;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      //--- tentar obter ticket negócios
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- obter as propriedades negócios
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         reason=HistoryDealGetInteger(ticket,DEAL_REASON);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         typeorder = HistoryDealGetInteger(ticket,DEAL_TYPE);
         //--- apenas para o símbolo atual
         if(reason==DEAL_REASON_TP && entry==DEAL_ENTRY_OUT && typeorder==DEAL_TYPE_SELL && symbol==_Symbol)
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
//+---------------------------------------------------------------------------------------+
//| VERIFICA SE A ÚLTIMA POSICAO FECHADA FOI DE TAKE PROFIT ATINGIDO DE UMA ORDEM DE VENDA|
//+---------------------------------------------------------------------------------------+
bool UltimaPosFechadaTakeVenda()
  {
   HistorySelect(0,TimeCurrent());
   ulong    ticket=0;
   string   symbol;
   long     reason;
   long     entry;
   long     typeorder;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      //--- tentar obter ticket negócios
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- obter as propriedades negócios
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         reason=HistoryDealGetInteger(ticket,DEAL_REASON);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         typeorder = HistoryDealGetInteger(ticket,DEAL_TYPE);
         //--- apenas para o símbolo atual
         if(reason==DEAL_REASON_TP && entry==DEAL_ENTRY_OUT && typeorder==DEAL_TYPE_BUY && symbol==_Symbol)
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
//+------------------------------------------------------------------------------------------+
//+------------------------------------+
//| RETORNA O VOLUME DA POSIÇÃO ABERTA |
//+------------------------------------+
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
//+--------------------------------------------------+
//| RETORNA O PREÇO DA MAIOR POSIÇÃO DE VENDA ABERTA |
//+--------------------------------------------------+
double MaiorPrecoPosAberta()
  {
   double precomaior=0.0;
   int posabertas = PositionsTotal();
   for(int i=0; i<posabertas; i++)
     {
      ulong ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double preco = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE tipo =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(tipo == POSITION_TYPE_SELL && position_symbol==_Symbol /*&& magic == magicrobo*/ && preco > precomaior)
         precomaior=preco;
     }
   return precomaior;
  }
//+------------------------------------------------------------------------------------------+
//+--------------------------------------------------+
//|RETORNA O PREÇO DA MENOR POSIÇÃO DE COMPRA ABERTA |
//+--------------------------------------------------+
double MenorPrecoPosAberta()
  {
   double precomenor=200000.0;
   int posabertas = PositionsTotal();
   for(int i=0; i<posabertas; i++)
     {
      ulong ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      double preco = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE tipo =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(tipo == POSITION_TYPE_BUY && position_symbol==_Symbol /*&& magic == magicrobo*/ && preco < precomenor)
         precomenor=preco;
     }
   return precomenor;
  }
//+------------------------------------------------------------------------------------------+
//+------------------------------------------+
//| RETORNA O PREÇO DA ÚLTIMA POSIÇÃO ABERTA |
//+------------------------------------------+
double PrecoPosAberta()
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
      case  8:
         if((ticket=HistoryDealGetTicket(k-8))>0)
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
      case  9:
         if((ticket=HistoryDealGetTicket(k-9))>0)
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
      case  10:
         if((ticket=HistoryDealGetTicket(k-10))>0)
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
      case  11:
         if((ticket=HistoryDealGetTicket(k-11))>0)
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
      case  12:
         if((ticket=HistoryDealGetTicket(k-12))>0)
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
      case  13:
         if((ticket=HistoryDealGetTicket(k-13))>0)
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
      case  14:
         if((ticket=HistoryDealGetTicket(k-14))>0)
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
      case  8:
         if((ticket=HistoryDealGetTicket(k-8))>0)
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
      case  9:
         if((ticket=HistoryDealGetTicket(k-9))>0)
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
      case  10:
         if((ticket=HistoryDealGetTicket(k-10))>0)
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
      case  11:
         if((ticket=HistoryDealGetTicket(k-11))>0)
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
      case  12:
         if((ticket=HistoryDealGetTicket(k-12))>0)
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
      case  13:
         if((ticket=HistoryDealGetTicket(k-13))>0)
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
      case  14:
         if((ticket=HistoryDealGetTicket(k-14))>0)
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
//+------------------------------------------------------+
//| VERIFICA O PROFIT DA N-ESIMA ORDEM DE COMPRA FECHADA |
//+------------------------------------------------------+
double ProfitNPosCompra(uint j)
  {
   HistorySelect(0,TimeCurrent());
   string   name;
   ulong    ticket=0;
   double   profit;
   string   symbol;
   long     type;
   long     entry;
   uint     k = HistoryDealsTotal();
   switch(j)
     {
      case  1:
         if((ticket=HistoryDealGetTicket(k-1))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  2:
         if((ticket=HistoryDealGetTicket(k-2))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  3:
         if((ticket=HistoryDealGetTicket(k-3))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  4:
         if((ticket=HistoryDealGetTicket(k-4))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  5:
         if((ticket=HistoryDealGetTicket(k-5))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  6:
         if((ticket=HistoryDealGetTicket(k-6))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  7:
         if((ticket=HistoryDealGetTicket(k-7))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  8:
         if((ticket=HistoryDealGetTicket(k-8))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  9:
         if((ticket=HistoryDealGetTicket(k-9))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  10:
         if((ticket=HistoryDealGetTicket(k-10))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  11:
         if((ticket=HistoryDealGetTicket(k-11))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  12:
         if((ticket=HistoryDealGetTicket(k-12))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  13:
         if((ticket=HistoryDealGetTicket(k-13))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  14:
         if((ticket=HistoryDealGetTicket(k-14))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
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
//+---------------------------------------------------+
//| VERIFICA PROFIT DA N-ESIMA ORDEM DE VENDA FECHADA |
//+---------------------------------------------------+
double ProfitNPosVenda(uint j)
  {
   HistorySelect(0,TimeCurrent());
   string   name;
   ulong    ticket=0;
   double   profit;
   string   symbol;
   long     type;
   long     entry;
   uint     k = HistoryDealsTotal();
   switch(j)
     {
      case  1:
         if((ticket=HistoryDealGetTicket(k-1))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  2:
         if((ticket=HistoryDealGetTicket(k-2))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  3:
         if((ticket=HistoryDealGetTicket(k-3))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  4:
         if((ticket=HistoryDealGetTicket(k-4))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  5:
         if((ticket=HistoryDealGetTicket(k-5))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  6:
         if((ticket=HistoryDealGetTicket(k-6))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  7:
         if((ticket=HistoryDealGetTicket(k-7))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  8:
         if((ticket=HistoryDealGetTicket(k-8))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  9:
         if((ticket=HistoryDealGetTicket(k-9))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  10:
         if((ticket=HistoryDealGetTicket(k-10))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  11:
         if((ticket=HistoryDealGetTicket(k-11))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  12:
         if((ticket=HistoryDealGetTicket(k-12))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  13:
         if((ticket=HistoryDealGetTicket(k-13))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
               break;
              }
            break;
           }
      case  14:
         if((ticket=HistoryDealGetTicket(k-14))>0)
           {
            profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return profit;
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
      case  8:
         if((ticket=HistoryDealGetTicket(k-8))>0)
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
      case  9:
         if((ticket=HistoryDealGetTicket(k-9))>0)
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
      case  10:
         if((ticket=HistoryDealGetTicket(k-10))>0)
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
      case  11:
         if((ticket=HistoryDealGetTicket(k-11))>0)
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
      case  12:
         if((ticket=HistoryDealGetTicket(k-12))>0)
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
      case  13:
         if((ticket=HistoryDealGetTicket(k-13))>0)
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
      case  14:
         if((ticket=HistoryDealGetTicket(k-14))>0)
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
      case  8:
         if((ticket=HistoryDealGetTicket(k-8))>0)
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
      case  9:
         if((ticket=HistoryDealGetTicket(k-9))>0)
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
      case  10:
         if((ticket=HistoryDealGetTicket(k-10))>0)
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
      case  11:
         if((ticket=HistoryDealGetTicket(k-11))>0)
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
      case  12:
         if((ticket=HistoryDealGetTicket(k-12))>0)
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
      case  13:
         if((ticket=HistoryDealGetTicket(k-13))>0)
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
      case  14:
         if((ticket=HistoryDealGetTicket(k-14))>0)
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
//+--------------------------------------------------------------------+
//| VERIFICA O LUCRO/PREJUIZO DA ÚLTIMA POSIÇÃO DE COMPRA/VENDA ABERTA |
//+--------------------------------------------------------------------+
double LucroPrejuUltPosAberta()
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
//+---------------------------------------------------------------+
//| VERIFICA O LUCRO/PREJUIZO DA ULTIMA POSIÇÃO DE COMPRA FECHADA |
//+---------------------------------------------------------------+
double LucroPrejuUltPosCompraAberta()
  {
   HistorySelect(0,TimeCurrent());
   ulong    ticket=0;
   double   preco=0;
   string   symbol;
   long     reason;
   long     entry;
   long     type;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      //--- tentar obter ticket negócios
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- obter as propriedades negócios
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         reason=HistoryDealGetInteger(ticket,DEAL_REASON);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
         //--- apenas para o símbolo atual
         if(type==DEAL_TYPE_BUY && reason==DEAL_REASON_TP && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
           {
            return preco;
            break;
           }
        }
     }
   return NULL;
  }
//+------------------------------------------------------------------------------------------+
//+--------------------------------------------------------------+
//| VERIFICA O LUCRO/PREJUIZO DA ULTIMA POSIÇÃO DE VENDA FECHADA |
//+--------------------------------------------------------------+
double LucroPrejuUltPosVendaFechada()
  {
   HistorySelect(0,TimeCurrent());
   ulong    ticket=0;
   double   preco=0;
   string   symbol;
   long     reason;
   long     entry;
   long     type;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      //--- tentar obter ticket negócios
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- obter as propriedades negócios
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         reason=HistoryDealGetInteger(ticket,DEAL_REASON);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
         //--- apenas para o símbolo atual
         if(type==DEAL_TYPE_SELL && reason==DEAL_REASON_TP && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
           {
            return preco;
            break;
           }
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
void  ComprasMartingale()
  {
   if(PossuiPosCompraComentada("C1") && !PossuiPosCompraComentada("C2") && tick.ask<MenorPrecoPosAberta()/*&& tick.ask<PrecoAberturaPosCompra(1)-ptsmartprimcompra*_Point*/ //
      && VolumePos()<=500 && volnv2!=0)
     {
      trade.Buy(volnv2,_Symbol,tick.ask,puxatpsl("SLC1"),puxatpsl("TPC1"),"C2");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C2") && !PossuiPosCompraComentada("C3") && tick.ask<MenorPrecoPosAberta()/*&& (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv3!=0)
     {
      trade.Buy(volnv3,_Symbol,tick.ask,puxatpsl("SLC2"),puxatpsl("TPC2"),"C3");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C3") && !PossuiPosCompraComentada("C4") && tick.ask<MenorPrecoPosAberta()/*&& (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv4!=0)
     {
      trade.Buy(volnv4,_Symbol,tick.ask,puxatpsl("SLC3"),puxatpsl("TPC3"),"C4");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C4") && !PossuiPosCompraComentada("C5") && tick.ask<MenorPrecoPosAberta()/*&& (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv5!=0)
     {
      trade.Buy(volnv5,_Symbol,tick.ask,puxatpsl("SLC4"),puxatpsl("TPC4"),"C5");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C5") && !PossuiPosCompraComentada("C6") && tick.ask<MenorPrecoPosAberta()/*&& (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv6!=0)
     {
      trade.Buy(volnv6,_Symbol,tick.ask,puxatpsl("SLC5"),puxatpsl("TPC5"),"C6");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C6") && !PossuiPosCompraComentada("C7") && tick.ask<MenorPrecoPosAberta()/*&& (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv7!=0)
     {
      trade.Buy(volnv7,_Symbol,tick.ask,puxatpsl("SLC6"),puxatpsl("TPC6"),"C7");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C7") && !PossuiPosCompraComentada("C8") && tick.ask<MenorPrecoPosAberta()/*&& (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv8!=0)
     {
      trade.Buy(volnv8,_Symbol,tick.ask,puxatpsl("SLC7"),puxatpsl("TPC7"),"C8");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C8") && !PossuiPosCompraComentada("C9") && tick.ask<MenorPrecoPosAberta()/*&& (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv9!=0)
     {
      trade.Buy(volnv9,_Symbol,tick.ask,puxatpsl("SLC8"),puxatpsl("TPC8"),"C9");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C9") && !PossuiPosCompraComentada("C10") && tick.ask<MenorPrecoPosAberta()/*&& (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv10!=0)
     {
      trade.Buy(volnv10,_Symbol,tick.ask,puxatpsl("SLC9"),puxatpsl("TPC9"),"C10");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C10") && !PossuiPosCompraComentada("C11") && tick.ask<MenorPrecoPosAberta()/*&& (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv11!=0)
     {
      trade.Buy(volnv11,_Symbol,tick.ask,puxatpsl("SLC10"),puxatpsl("TPC10"),"C11");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C11") && !PossuiPosCompraComentada("C12") && tick.ask<MenorPrecoPosAberta()/*&& (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv12!=0)
     {
      trade.Buy(volnv12,_Symbol,tick.ask,puxatpsl("SLC11"),puxatpsl("TPC11"),"C12");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C12") && !PossuiPosCompraComentada("C13") && tick.ask<MenorPrecoPosAberta()/*&& (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv13!=0)
     {
      trade.Buy(volnv13,_Symbol,tick.ask,puxatpsl("SLC12"),puxatpsl("TPC12"),"C13");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C13") && !PossuiPosCompraComentada("C14") && tick.ask<MenorPrecoPosAberta()/*&& (PrecoAberturaPosCompra(1)-tick.ask)/_Point> //
         (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv14!=0)
     {
      trade.Buy(volnv14,_Symbol,tick.ask,puxatpsl("SLC13"),puxatpsl("TPC13"),"C14");
      Sleep(500);
      return;
     }
  }
//+---------------------------------------------------------------------------------------------------------------------------------+
/////////////////////////////////////////
//---|VENDAS NORMAIS COM MARTINGALE|---//
/////////////////////////////////////////
void  VendasMartingale()
  {
   if(PossuiPosVendaComentada("V1") && !PossuiPosVendaComentada("V2") && tick.bid>MaiorPrecoPosAberta()/*&& tick.bid>PrecoAberturaPosVenda(1)+ptsmartprimcompra*_Point*///
      && VolumePos()<=500 && volnv2!=0)
     {
      trade.Sell(volnv2,_Symbol,tick.bid,puxatpsl("SLV1"),puxatpsl("TPV1"),"V2");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V2") && !PossuiPosVendaComentada("V3") && tick.bid>MaiorPrecoPosAberta()/*&& (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv3!=0)
     {
      trade.Sell(volnv3,_Symbol,tick.bid,puxatpsl("SLV2"),puxatpsl("TPV2"),"V3");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V3") && !PossuiPosVendaComentada("V4") && tick.bid>MaiorPrecoPosAberta()/*&& (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv4!=0)
     {
      trade.Sell(volnv4,_Symbol,tick.bid,puxatpsl("SLV3"),puxatpsl("TPV3"),"V4");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V4") && !PossuiPosVendaComentada("V5") && tick.bid>MaiorPrecoPosAberta()/*&& (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv5!=0)
     {
      trade.Sell(volnv5,_Symbol,tick.bid,puxatpsl("SLV4"),puxatpsl("TPV4"),"V5");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V5") && !PossuiPosVendaComentada("V6") && tick.bid>MaiorPrecoPosAberta()/*&& (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv6!=0)
     {
      trade.Sell(volnv6,_Symbol,tick.bid,puxatpsl("SLV5"),puxatpsl("TPV5"),"V6");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V6") && !PossuiPosVendaComentada("V7") && tick.bid>MaiorPrecoPosAberta()/*&& (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv7!=0)
     {
      trade.Sell(volnv7,_Symbol,tick.bid,puxatpsl("SLV6"),puxatpsl("TPV6"),"V7");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V7") && !PossuiPosVendaComentada("V8") && tick.bid>MaiorPrecoPosAberta()/*&& (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv8!=0)
     {
      trade.Sell(volnv8,_Symbol,tick.bid,puxatpsl("SLV7"),puxatpsl("TPV7"),"V8");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V8") && !PossuiPosVendaComentada("V9") && tick.bid>MaiorPrecoPosAberta()/*&& (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv9!=0)
     {
      trade.Sell(volnv9,_Symbol,tick.bid,puxatpsl("SLV8"),puxatpsl("TPV8"),"V9");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V9") && !PossuiPosVendaComentada("V10") && tick.bid>MaiorPrecoPosAberta()/*&& (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv10!=0)
     {
      trade.Sell(volnv10,_Symbol,tick.bid,puxatpsl("SLV9"),puxatpsl("TPV9"),"V10");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V10") && !PossuiPosVendaComentada("V11") && tick.bid>MaiorPrecoPosAberta()/*&& (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv11!=0)
     {
      trade.Sell(volnv11,_Symbol,tick.bid,puxatpsl("SLV10"),puxatpsl("TPV10"),"V11");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V11") && !PossuiPosVendaComentada("V12") && tick.bid>MaiorPrecoPosAberta()/*&& (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv12!=0)
     {
      trade.Sell(volnv12,_Symbol,tick.bid,puxatpsl("SLV11"),puxatpsl("TPV11"),"V12");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V12") && !PossuiPosVendaComentada("V13") && tick.bid>MaiorPrecoPosAberta()/*&& (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv13!=0)
     {
      trade.Sell(volnv13,_Symbol,tick.bid,puxatpsl("SLV12"),puxatpsl("TPV12"),"V13");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V13") && !PossuiPosVendaComentada("V14") && tick.bid>MaiorPrecoPosAberta()/*&& (tick.bid-PrecoAberturaPosVenda(1))/_Point> //
         (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point*prctmart/100*/ && VolumePos()<=500 && volnv14!=0)
     {
      trade.Sell(volnv14,_Symbol,tick.bid,puxatpsl("SLV13"),puxatpsl("TPV13"),"V14");
      Sleep(500);
      return;
     }

  }
//+---------------------------------------------------------------------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//---| AJUSTA O VALOR DE TAKE PROFIT E STOP LOSS PARA POSTERIOR INSERÇÃO NAS ORDENS DE COMPRA/VENDA |---//
//////////////////////////////////////////////////////////////////////////////////////////////////////////
double   puxatpsl(string tpsl)
  {
   string str=tpsl;

   if(tipostop==tpstopprct)
     {
      if(tipooper==tiponet)
        {
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
         if(str=="SLV8")
            return(PM8*(1+percentloss/100));
         if(str=="SLV9")
            return(PM9*(1+percentloss/100));
         if(str=="SLV10")
            return(PM10*(1+percentloss/100));
         if(str=="SLV11")
            return(PM11*(1+percentloss/100));
         if(str=="SLV12")
            return(PM12*(1+percentloss/100));
         if(str=="SLV13")
            return(PM13*(1+percentloss/100));
         if(str=="SLV14")
            return(PM14*(1+percentloss/100));

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
         if(str=="SLC8")
            return(PM8*(1-percentloss/100));
         if(str=="SLC9")
            return(PM9*(1-percentloss/100));
         if(str=="SLC10")
            return(PM10*(1-percentloss/100));
         if(str=="SLC11")
            return(PM11*(1-percentloss/100));
         if(str=="SLC12")
            return(PM12*(1-percentloss/100));
         if(str=="SLC13")
            return(PM13*(1-percentloss/100));
         if(str=="SLC14")
            return(PM14*(1-percentloss/100));
        }
      if(tipooper==tipohedge)
        {
         if(str=="SLV0"||str=="SLV1"||str=="SLV2"||str=="SLV3"||str=="SLV4"||str=="SLV5"||str=="SLV6"||str=="SLV7"|| //
            str=="SLV8"||str=="SLV9"||str=="SLV10"||str=="SLV11"||str=="SLV12"||str=="SLV13"||str=="SLV14")
            return(tick.bid*(1+percentloss/100));
         if(str=="SLC0"||str=="SLC1"||str=="SLC2"||str=="SLC3"||str=="SLC4"||str=="SLC5"||str=="SLC6"||str=="SLC7"|| //
            str=="SLC8"||str=="SLC9"||str=="SLC10"||str=="SLC11"||str=="SLC12"||str=="SLC13"||str=="SLC14")
            return(tick.ask*(1-percentloss/100));
        }
     }
   if(tipostop==tpstoppontos)
     {
      if(tipooper==tiponet)
        {
         if(str=="SLV0")
            return(tick.bid+stoppontos*_Point);
         if(str=="SLV1")
            return(PM1+stoppontos*_Point);
         if(str=="SLV2")
            return(PM2+stoppontos*_Point);
         if(str=="SLV3")
            return(PM3+stoppontos*_Point);
         if(str=="SLV4")
            return(PM4+stoppontos*_Point);
         if(str=="SLV5")
            return(PM5+stoppontos*_Point);
         if(str=="SLV6")
            return(PM6+stoppontos*_Point);
         if(str=="SLV7")
            return(PM7+stoppontos*_Point);
         if(str=="SLV8")
            return(PM8+stoppontos*_Point);
         if(str=="SLV9")
            return(PM9+stoppontos*_Point);
         if(str=="SLV10")
            return(PM10+stoppontos*_Point);
         if(str=="SLV11")
            return(PM11+stoppontos*_Point);
         if(str=="SLV12")
            return(PM12+stoppontos*_Point);
         if(str=="SLV13")
            return(PM13+stoppontos*_Point);
         if(str=="SLV14")
            return(PM14+stoppontos*_Point);

         if(str=="SLC0")
            return(tick.ask-stoppontos*_Point);
         if(str=="SLC1")
            return(PM1-stoppontos*_Point);
         if(str=="SLC2")
            return(PM2-stoppontos*_Point);
         if(str=="SLC3")
            return(PM3-stoppontos*_Point);
         if(str=="SLC4")
            return(PM4-stoppontos*_Point);
         if(str=="SLC5")
            return(PM5-stoppontos*_Point);
         if(str=="SLC6")
            return(PM6-stoppontos*_Point);
         if(str=="SLC7")
            return(PM7-stoppontos*_Point);
         if(str=="SLC8")
            return(PM8-stoppontos*_Point);
         if(str=="SLC9")
            return(PM9-stoppontos*_Point);
         if(str=="SLC10")
            return(PM10-stoppontos*_Point);
         if(str=="SLC11")
            return(PM11-stoppontos*_Point);
         if(str=="SLC12")
            return(PM12-stoppontos*_Point);
         if(str=="SLC13")
            return(PM13-stoppontos*_Point);
         if(str=="SLC14")
            return(PM14-stoppontos*_Point);
        }
      if(tipooper==tipohedge)
        {
         if(str=="SLV0"||str=="SLV1"||str=="SLV2"||str=="SLV3"||str=="SLV4"||str=="SLV5"||str=="SLV6"||str=="SLV7"|| //
            str=="SLV8"||str=="SLV9"||str=="SLV10"||str=="SLV11"||str=="SLV12"||str=="SLV13"||str=="SLV14")
            return(tick.bid+stoppontos*_Point);
         if(str=="SLC0"||str=="SLC1"||str=="SLC2"||str=="SLC3"||str=="SLC4"||str=="SLC5"||str=="SLC6"||str=="SLC7"|| //
            str=="SLC8"||str=="SLC9"||str=="SLC10"||str=="SLC11"||str=="SLC12"||str=="SLC13"||str=="SLC14")
            return(tick.ask-stoppontos*_Point);
        }
     }
   if(tipogain==tpgainprct)
     {
      if(tipooper==tiponet)
        {
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
         if(str=="TPC8")
            return(PM8*(1+percentgain/100));
         if(str=="TPC9")
            return(PM9*(1+percentgain/100));
         if(str=="TPC10")
            return(PM10*(1+percentgain/100));
         if(str=="TPC11")
            return(PM11*(1+percentgain/100));
         if(str=="TPC12")
            return(PM12*(1+percentgain/100));
         if(str=="TPC13")
            return(PM13*(1+percentgain/100));
         if(str=="TPC14")
            return(PM14*(1+percentgain/100));

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
         if(str=="TPV8")
            return(PM8*(1-percentgain/100));
         if(str=="TPV9")
            return(PM9*(1-percentgain/100));
         if(str=="TPV10")
            return(PM10*(1-percentgain/100));
         if(str=="TPV11")
            return(PM11*(1-percentgain/100));
         if(str=="TPV12")
            return(PM12*(1-percentgain/100));
         if(str=="TPV13")
            return(PM13*(1-percentgain/100));
         if(str=="TPV14")
            return(PM14*(1-percentgain/100));
        }
      if(tipooper==tipohedge)
        {
         if(str=="TPV0"||str=="TPV1"||str=="TPV2"||str=="TPV3"||str=="TPV4"||str=="TPV5"||str=="TPV6"||str=="TPV7"|| //
            str=="TPV8"||str=="TPV9"||str=="TPV10"||str=="TPV11"||str=="TPV12"||str=="TPV13"||str=="TPV14")
            return(tick.ask*(1-percentgain/100));
         if(str=="TPC0"||str=="TPC1"||str=="TPC2"||str=="TPC3"||str=="TPC4"||str=="TPC5"||str=="TPC6"||str=="TPC7"|| //
            str=="TPC8"||str=="TPC9"||str=="TPC10"||str=="TPC11"||str=="TPC12"||str=="TPC13"||str=="TPC14")
            return(tick.bid*(1+percentgain/100));
        }
     }
   if(tipogain==tpgainpontos)
     {
      if(tipooper==tiponet)
        {
         if(str=="TPC0")
            return(tick.bid+pontosc1*_Point);
         if(str=="TPC1")
            return(PM1+pontosc2*_Point);
         if(str=="TPC2")
            return(PM2+pontosc3*_Point);
         if(str=="TPC3")
            return(PM3+pontosc4*_Point);
         if(str=="TPC4")
            return(PM4+pontosc5*_Point);
         if(str=="TPC5")
            return(PM5+pontosc6*_Point);
         if(str=="TPC6")
            return(PM6+pontosc7*_Point);
         if(str=="TPC7")
            return(PM7+pontosc8*_Point);
         if(str=="TPC8")
            return(PM8+pontosc9*_Point);
         if(str=="TPC9")
            return(PM9+pontosc10*_Point);
         if(str=="TPC10")
            return(PM10+pontosc11*_Point);
         if(str=="TPC11")
            return(PM11+pontosc12*_Point);
         if(str=="TPC12")
            return(PM12+pontosc13*_Point);
         if(str=="TPC13")
            return(PM13+pontosc14*_Point);

         if(str=="TPV0")
            return(tick.ask-pontosc1*_Point);
         if(str=="TPV1")
            return(PM1-pontosc2*_Point);
         if(str=="TPV2")
            return(PM2-pontosc3*_Point);
         if(str=="TPV3")
            return(PM3-pontosc4*_Point);
         if(str=="TPV4")
            return(PM4-pontosc5*_Point);
         if(str=="TPV5")
            return(PM5-pontosc6*_Point);
         if(str=="TPV6")
            return(PM6-pontosc7*_Point);
         if(str=="TPV7")
            return(PM7-pontosc8*_Point);
         if(str=="TPV8")
            return(PM8-pontosc9*_Point);
         if(str=="TPV9")
            return(PM9-pontosc10*_Point);
         if(str=="TPV10")
            return(PM10-pontosc11*_Point);
         if(str=="TPV11")
            return(PM11-pontosc12*_Point);
         if(str=="TPV12")
            return(PM12-pontosc13*_Point);
         if(str=="TPV13")
            return(PM13-pontosc14*_Point);
        }
      if(tipooper==tipohedge)
        {
         if(str=="TPV0"||str=="TPV1"||str=="TPV2"||str=="TPV3"||str=="TPV4"||str=="TPV5"||str=="TPV6"||str=="TPV7"|| //
            str=="TPV8"||str=="TPV9"||str=="TPV10"||str=="TPV11"||str=="TPV12"||str=="TPV13"||str=="TPV14")
            return(tick.ask-pontosc1*_Point);
         if(str=="TPC0"||str=="TPC1"||str=="TPC2"||str=="TPC3"||str=="TPC4"||str=="TPC5"||str=="TPC6"||str=="TPC7"|| //
            str=="TPC8"||str=="TPC9"||str=="TPC10"||str=="TPC11"||str=="TPC12"||str=="TPC13"||str=="TPC14")
            return(tick.bid+pontosc1*_Point);
        }
     }
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

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
