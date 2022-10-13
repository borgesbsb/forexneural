//+------------------------------------------------------------------+
//|                                            ROBÔ FOREX NEURAL.mq5 |
//|                                            gibranvalle@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Gibran, Borges e James"
#property link      "gibranvalle@gmail.com"
#property version   "2.0"

//////////////////////////////////
//--- Bibliotecas utilizadas ---//
//////////////////////////////////
#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/HistoryOrderInfo.mqh>
#include <Dictionary.mqh>
#include <IsNewBar.mqh>
//////////////////////////////////////
//--- DEFINIÇÃO DOS ENUMERADORES ---//
//////////////////////////////////////

//--- ENUMERADOR DO TIPO DE MARTINGALE
enum ENUM_TP_MART
  {
   mart1,        //[1]FIBONACCI
   mart2,        //[2]05 FIBO + 04 N VEZES ANT
   mart3,        //[3]N x VOL ANTERIOR
   mart4,        //[4]N x VOL ANTERIOR ACUMULADO
  };

//--- ENUMERADOR DA ESTRATÉGIA PRINCIPAL A SER UTILIZADA
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
  };

//--- ENUMERADOR DO TIPO DE ALAVANCAGEM DA CONTA A SER UTILIZADA
enum ENUM_TP_CONTA
  {
   tipocent,     //[1]CONTA CENT
   tipoprime,    //[2]CONTA PRIME/ECN/B3
  };

//--- ENUMERADOR DO TIPO DE OPERAÇÃO DA CONTA
enum ENUM_TP_OPER
  {
   tipohedge,    //[1]TIPO HEDGING
   tiponet,      //[2]TIPO NETTING
  };

//--- ENUMERADOR DO TIPO DE STOP A SER UTILIZADO
enum ENUM_TP_STOP
  {
   tpstopprct,   //[1]EM PERCENTUAL
   tpstoppontos, //[2]EM PONTOS
  };

//--- ENUMERADOR DO TIPO DE TAKE PROFIT A SER UTILIZADO
enum ENUM_TP_GAIN
  {
   tpgainprct,   //[1]EM PERCENTUAL
   tpgainpontos, //[2]EM PONTOS
  };

////////////////////////////////////////////////////////////////////////////////////////
//--- TABELA DOS INPUTS - VALOR DAS VARIÁVEIS A SEREM ESCOLHIDAS PARA OS BACKTESTS ---//
////////////////////////////////////////////////////////////////////////////////////////
input group              "ABERTURA DE ORDENS"
input bool               ativaentradaea      = true;         //ATIVA ABERTURA AUTOMÁTICA DE ORDENS
input double             loteinicial         = 0.1;          //TAMANHO DO LOTE INICIAL(WIN$-1CONTRATO)
input double             aumentoprop         = 500.00;       //VALOR P AUMENTO PROPORCIONAL DO LOTE
input ENUM_TP_CONTA      tipoconta           = tipoprime;    //SELECIONE O TIPO DE CONTA
input ENUM_TP_OPER       tipooper            = tiponet;      //SELECIONE O TIPO DE OPERAÇÃO DA CONTA
input ENUM_TP_STOP       tipostop            = tpstoppontos; //SELECIONE O TIPO DE STOP LOSS
input double             percentloss         = 2.5;          //% DE STOP LOSS P ABERTURA DE ORDEM
input int                stoppontos          = 800;          //PTS DE STOP LOSS P ABERTURA DE ORDENS
input double             maximopontossar     = 100;          //MÁXIMO DE PONTOS APÓS VIRADA DO SAR
input group              "MARTINGALE"
input bool               ativamartingale     = false;        //ATIVA USO DE MARTINGALE
input ENUM_TP_MART       tipomartingale      = mart3;        //TIPO DE MARTINGALE
input int                multiplicador       = 2;            //MULTIPLICADOR P MARTINGALE (N)
input int                qtdecandle          = 1;            //QTOS CANDLES P PX ENTRADA
input int                pontosmart          = 80;           //PTS P PX ENTRADA - MARTINGALE
input int                qtdedemart          = 2;            //QTDE MÁXIMA DE MARTINGALES
input group              "ESCOLHA DA ESTRATÉGIA"
input ENUM_TP_ESTRAT     estrategia          = estrat9;      //ESCOLHA A ESTRATÉGIA
input group              "VALORES DEFINIDOS P/ SAR"
input double             stepSAR             = 0.014;        //STEP do SAR
input double             maximumSAR          = 0.14;         //MAXIMUM do SAR
/*input*/ //group              "VALORES DEFINIDOS P/ RSI"
/*input*/ int                periodorsi          = 14;           //PERIODO P RSI
/*input*/ int                sobrevrsi           = 70;           //PORCENTAGEM DE SOBREVENDA
/*input*/ int                sobrecrsi           = 30;           //PORCENTAGEM DE SOBRECOMPRA
/*input*/ //group              "VALORES DEFINIDOS P/ BANDAS DE BOLLINGER"
/*input*/ int                periodobb           = 14;           //PERIODO P BANDAS DE BOLINGER
/*input*/ double             desviobb            = 2.0;          //DESVIO P BANDAS DE BOLINGER
/*input*/ //group              "VALORES DEFINIDOS P/ ENVELOPE"
/*input*/ int                periodm1            = 63;           //PERIODO DA MÉDIA P/ ENVELOPE
/*input*/ double             tamanhoenvelope     = 150;          //DISTÂNCIA P ENVELOPE
input group              "FECHAMENTO DE ORDENS"
//input bool               ativasaidaea        = true;         //ATIVA FECHAMENTO DE ORDENS
input ENUM_TP_GAIN       tipogain            = tpgainpontos; //SELECIONE TIPO DE GANHO
input double             percentgain         = 0.1;          //PORCENTAGEM DE STOP GAIN
input int                pontosc1            = 15;           //DISTANCIA P FECHAM 1 ORDEM
input int                pontosc2            = 40;           //DISTANCIA P FECHAM 2 ORDENS
input int                pontosc3            = 40;           //DISTANCIA P FECHAM 3 ORDENS
input int                pontosc4            = 40;           //DISTANCIA P FECHAM 4 ORDENS
input int                pontosc5            = 30;           //DISTANCIA P FECHAM 5 ORDENS
input int                pontosc6            = 20;           //DISTANCIA P FECHAM 6 ORDENS
input int                pontosc7            = 10;           //DISTANCIA P FECHAM 7 ORDENS
input int                pontosc8            = 10;           //DISTANCIA P FECHAM 8 ORDENS
input int                pontosc9            = 30;           //DISTANCIA P FECHAM 9 ORDENS
input int                pontosc10           = 30;           //DISTANCIA P FECHAM 10 ORDENS
input int                pontosc11           = 30;           //DISTANCIA P FECHAM 11 ORDENS
input int                pontosc12           = 20;           //DISTANCIA P FECHAM 12 ORDENS
input int                pontosc13           = 10;           //DISTANCIA P FECHAM 13 ORDENS
input int                pontosc14           = 10;           //DISTANCIA P FECHAM 14 ORDENS
//input group              "BREAKEVEN/TRAILING STOP"
//input bool               ativbreak           = false;        //ATIVA BREAKEVEN/TRAILING STOP
//input double             pontosbesl          = 10;           //PTOS A MENOS PARA SL NOVO DO BE
input group              "GERENCIAMENTO DE RISCO - CONDIÇÕES MÍNIMAS PARA OPERAR"
input double             prcentabert         = 2000;         //% MÍNIMA DO CAPIT P ABRIR ORDENS
input double             somapreju           = 300;          //QTDE MÁXIMA DE PONTOS STOPADOS NO DIA
input group              "GERENCIAMENTO DE RISCO - STOP FULL"
input bool               ativastopfull       = true;         //ATIVA STOP P LIMITE DE CAPITAL INVESTIDO
input double             percentfull         = 5;            //% DO CAPITAL PARA FECHAR TODAS AS ORDENS
input group              "GERENCIAMENTO DE RISCO - HORÁRIO P ABERTURA/FECHAMENTO DE ORDENS"
input string             horainicial         = "09:15";      //HORA INICIAL P ABERTURA DE ORDENS
input string             horafinal           = "17:30";      //HORA FINAL P ABERTURA DE ORDENS
input bool               ativafecfinaldia    = false;        //ATIVA FECHAMENTO FINAL DO PREGÃO
input string             horafechamento      = "17:35";      //HORA PARA FECHAMENTO DE ORDENS
input group              "GERENCIAMENTO DE RISCO - HORÁRIO DE PAUSA P ABERTURA DE ORDENS"
input string             hriniciopausa1      = "20:00";      //HORA DE INICIO DA PAUSA 1
input string             hrterminopausa1     = "20:01";      //HORA DE TÉRMINO DA PAUSA 1
/////////////////////////////////////////////////////////////////////////////////////////////////////////

string                   shortname;

//--- Definição do "magic number" do robô
ulong                    magicrobo           = 941;

//--- Definição dos ints
int                      handlebb,handlersi,handleMM,handleSAR,qtdecandposabertcompra,qtdecandposabertvenda;
int                      sarcompra = 0;
int                      sarvenda = 0;

//--- Definição dos bools
bool                     possuicompra,possuicompra1,possuicompra2,possuicompra3,possuicompra4,possuicompra5,possuicompra6,possuicompra7,possuicompra8, //
                         possuicompra9,possuicompra10,possuicompra11,possuicompra12,possuicompra13,possuicompra14, //
                         possuivenda,possuivenda1,possuivenda2,possuivenda3,possuivenda4,possuivenda5,possuivenda6,possuivenda7,possuivenda8, //
                         possuivenda9,possuivenda10,possuivenda11,possuivenda12,possuivenda13,possuivenda14;

bool                     mitigacaook = true;

//--- Definição dos doubles
double                   percent_margem,saldo,capital,lucro_prejuizo,volumemaximo,volumeoper,valoraumento,sarnormalizado0,sarnormalizado1,sarnormalizado2, //
                         sarnormalizado3,sarnormalizado4,slcomprapadrao,slvendapadrao,tpcomprapadrao,tpvendapadrao,rsi[],bbu[],bbm[],bbd[],mm[],sar[], //
                         precoultimacompra,precoultimavenda,volumeultimacompra,volumeultimavenda,VMultimacompra,VMultimavenda,PMultimacompra,PMultimavenda, //
                         slultimaposcompra,slultimaposvenda,tpultimaposcompra,tpultimaposvenda, //
                         volnv2,volnv3,volnv4,volnv5,volnv6,volnv7,volnv8,volnv9,volnv10,volnv11,volnv12,volnv13,volnv14, //
                         PMC1,PMC2,PMC3,PMC4,PMC5,PMC6,PMC7,PMC8,PMC9,PMC10,PMC11,PMC12,PMC13,PMC14,PMV1,PMV2,PMV3,PMV4,PMV5,PMV6,PMV7,PMV8,PMV9,PMV10,PMV11,PMV12,PMV13,PMV14;

double                   prejudodia=0.0;
double                   controlepontossar = 0.0;

//--- Variáveis p/ ticks, candles e tempo
MqlTick                  tick;
MqlRates                 candle[];
MqlDateTime              hratualstruct,hrinicialstruct,hrfinalstruct,hrfechstruct,hrinipausa1,hrterpausa1;
datetime                 dataultimaposabertacompra,dataultimaposabertavenda,aberturacandleatual;
datetime                 datahoraviradasar = D'2000.01.01 01:00';

//--- Classe responsável pela execução das ordens - Ctrade
CTrade                   trade;

//+-----------------------------------------+
//| Expert initialization function - ONINIT |
//+-----------------------------------------+
int OnInit()
  {

//--- Ajusta o timer do EA para o tempo em milisegundos entre parenteses
   EventSetMillisecondTimer(50);

//--- Ajusta horarios para structs conforme inputs
   TimeToStruct(StringToTime(horainicial),hrinicialstruct);
   TimeToStruct(StringToTime(horafinal),hrfinalstruct);
   TimeToStruct(StringToTime(horafechamento),hrfechstruct);
   TimeToStruct(StringToTime(hriniciopausa1),hrinipausa1);
   TimeToStruct(StringToTime(hrterminopausa1),hrterpausa1);

//--- Seta o magic number do robô
   trade.SetExpertMagicNumber(magicrobo);

//--- Prepara os Handles necessários segundo a estratégia escolhida
   if(estrategia==estrat1 || estrategia==estrat2 || estrategia==estrat5 || estrategia==estrat7)
     {
      handlersi = iRSI(_Symbol,_Period,periodorsi,PRICE_CLOSE);
      ArraySetAsSeries(rsi,true);
     }
   if(estrategia==estrat1 || estrategia==estrat3 || estrategia==estrat5 || estrategia==estrat8)
     {
      handlebb = iBands(_Symbol,_Period,periodobb,0,desviobb,PRICE_CLOSE);
      ArraySetAsSeries(bbu,true);
      ArraySetAsSeries(bbm,true);
      ArraySetAsSeries(bbd,true);
     }
   if(estrategia==estrat1 || estrategia==estrat2 || estrategia==estrat3 || estrategia==estrat4 || estrategia==estrat6)
     {
      handleMM = iMA(_Symbol,_Period,periodm1,0,MODE_SMA,PRICE_CLOSE);
      ArraySetAsSeries(mm,true);
     }
   if(estrategia==estrat4 || estrategia==estrat9)
     {
      handleSAR = iSAR(_Symbol,_Period,stepSAR,maximumSAR);
      ArraySetAsSeries(sar,true);
     }

   ArraySetAsSeries(candle,true);

//--- Definição dos preços dos inputs em função do tipo de conta selecionada para ajuste lote
   if(tipoconta==tipocent)
      valoraumento=aumentoprop*100;
   if(tipoconta==tipoprime)
      valoraumento=aumentoprop;

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
   EventKillTimer();
// Motivo da desinicialização do EA
   printf("Deinit reason: %d", reason);
  }

//+------------------------------------------------------------------------------------------+
///////////////////////////////
//| INÍCIO DA FUNÇÃO ONTICK |//
///////////////////////////////
void OnTick()
  {

//--- AJUSTA HORA ATUAL PARA O FORMATO STRUCT
   TimeToStruct(TimeCurrent(),hratualstruct);

//--- RECEBE O HORÁRIO DE ABERTURA DO PREGÃO DO DIA
   aberturacandleatual=datetime(SeriesInfoInteger(_Symbol,PERIOD_D1,SERIES_LASTBAR_DATE));

//--- Cópia dos dados dos handles para as variáveis, necessários de acordo com a estratégia escolhida
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
   if(estrategia==estrat4 || estrategia==estrat9)
     {
      CopyBuffer(handleSAR,0,0,5,sar);
      if(CopyBuffer(handleSAR,0,0,5,sar)<0)
        {
         Alert("Erro ao copiar dados de SAR: ", GetLastError());
         return;
        }
     }

//--- ESTABELECE EM QUANTAS CONDIÇÕES NO ROBÔ, A CADA TICK, SERÁ UTILIZADA A FUNÇÃO DE VERIFICAÇÃO DE NOVO CANDLE
   static CIsNewBar NB1,NB2,NB3,NB4/*,NB5,NB6,NB7,NB8,NB9,NB10,NB11,NB12,NB13,NB14,NB15,NB16,NB17,NB18,NB19,NB20,NB21,NB22*/;

//   double margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN),2);
//   double margem_livre = NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN),2);
   saldo = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
//   lucro_prejuizo = NormalizeDouble(AccountInfoDouble(ACCOUNT_PROFIT),2);
   capital = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY),2);
   percent_margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),2);

//--- MELHORIAS PARA OTIMIZAR TEMPO DE CÓDIGO
   possuicompra = PosAberta("POSSUI","COMPRA","");
   possuicompra1 = PosAberta("POSSUI","COMPRA","C1");
   possuicompra2 = PosAberta("POSSUI","COMPRA","C2");
   possuicompra3 = PosAberta("POSSUI","COMPRA","C3");
   possuicompra4 = PosAberta("POSSUI","COMPRA","C4");
   possuicompra5 = PosAberta("POSSUI","COMPRA","C5");
   possuicompra6 = PosAberta("POSSUI","COMPRA","C6");
   possuicompra7 = PosAberta("POSSUI","COMPRA","C7");
   possuicompra8 = PosAberta("POSSUI","COMPRA","C8");
   possuicompra9 = PosAberta("POSSUI","COMPRA","C9");
   possuicompra10 = PosAberta("POSSUI","COMPRA","C10");
   possuicompra11 = PosAberta("POSSUI","COMPRA","C11");
   possuicompra12 = PosAberta("POSSUI","COMPRA","C12");
   possuicompra13 = PosAberta("POSSUI","COMPRA","C13");
   possuicompra14 = PosAberta("POSSUI","COMPRA","C14");

   possuivenda = PosAberta("POSSUI","VENDA","");
   possuivenda1 = PosAberta("POSSUI","VENDA","V1");
   possuivenda2 = PosAberta("POSSUI","VENDA","V2");
   possuivenda3 = PosAberta("POSSUI","VENDA","V3");
   possuivenda4 = PosAberta("POSSUI","VENDA","V4");
   possuivenda5 = PosAberta("POSSUI","VENDA","V5");
   possuivenda6 = PosAberta("POSSUI","VENDA","V6");
   possuivenda7 = PosAberta("POSSUI","VENDA","V7");
   possuivenda8 = PosAberta("POSSUI","VENDA","V8");
   possuivenda9 = PosAberta("POSSUI","VENDA","V9");
   possuivenda10 = PosAberta("POSSUI","VENDA","V10");
   possuivenda11 = PosAberta("POSSUI","VENDA","V11");
   possuivenda12 = PosAberta("POSSUI","VENDA","V12");
   possuivenda13 = PosAberta("POSSUI","VENDA","V13");
   possuivenda14 = PosAberta("POSSUI","VENDA","V14");

   if(possuicompra)
     {
      precoultimacompra = DadosPosFechada("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA");
      volumeultimacompra = DadosPosFechada("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA");
      PMultimacompra = DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA");
      VMultimacompra = DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA");
      slultimaposcompra = DadosPos("SL DA ÚLTIMA POSIÇÃO ABERTA","COMPRA");
      tpultimaposcompra = DadosPos("TP DA ÚLTIMA POSIÇÃO ABERTA","COMPRA");
      dataultimaposabertacompra = DataHoraUltPosAberta("COMPRA");
      qtdecandposabertcompra = QtdeCandlesPosAberta("COMPRA");
     }
   else
     {
      precoultimacompra = 0;
      volumeultimacompra = 0;
      PMultimacompra = 0;
      VMultimacompra = 0;
      slultimaposcompra = 0;
      tpultimaposcompra = 0;
      dataultimaposabertacompra = TimeCurrent();
     }

   if(possuivenda)
     {
      precoultimavenda = DadosPosFechada("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA");
      volumeultimavenda = DadosPosFechada("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA");
      PMultimavenda = DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA");
      VMultimavenda = DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA");
      slultimaposvenda = DadosPos("SL DA ÚLTIMA POSIÇÃO ABERTA","VENDA");
      tpultimaposvenda = DadosPos("TP DA ÚLTIMA POSIÇÃO ABERTA","VENDA");
      dataultimaposabertavenda = DataHoraUltPosAberta("VENDA");
      qtdecandposabertvenda = QtdeCandlesPosAberta("VENDA");
     }
   else
     {
      precoultimavenda = 0;
      volumeultimavenda = 0;
      PMultimavenda = 0;
      VMultimavenda = 0;
      slultimaposvenda = 0;
      tpultimaposvenda = 0;
      dataultimaposabertavenda = TimeCurrent();
     }

//--------------------------------------------------------------------

   if(NB1.IsNewBar(_Symbol,_Period)) //VERIFICA SE É UM NOVO CANDLE
     {
      //--- Mostrar na aba "EXPERT" os saldos do dia
      //      double ganhos = DadosPosFechada("QTDE DE GANHOS DO DIA","");
      //      double perdas = DadosPosFechada("QTDE DE PERDAS DO DIA","");
      //      Print("ORDENS COM LUCRO: ",ganhos," ORDENS COM PERDAS: ",perdas," SALDO DO DIA:",ganhos-perdas);

      //--- Definição dos lotes iniciais de compra e venda
      if(saldo<valoraumento)
         volumeoper=loteinicial;
      else
        {
         string simbolo = _Symbol;
         if(StringFind(simbolo,"WIN",0)!=-1 || StringFind(simbolo,"WDO",0)!=-1)
            volumeoper = NormalizeDouble((capital/valoraumento)*loteinicial,0);
         else
            volumeoper = NormalizeDouble((capital/valoraumento)*loteinicial,2);
        }
      //--- Definição dos volumes de compra e venda quando utilizar martingale
      if(ativamartingale)
        {
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
        }

      //      if(volnv2>220.0)
      //         volnv2=0;
      //      if(volnv3>220.0)
      //         volnv3=0;
      //      if(volnv4>220.0)
      //         volnv4=0;
      //      if(volnv5>220.0)
      //         volnv5=0;
      //      if(volnv6>220.0)
      //         volnv6=0;
      //      if(volnv7>220.0)
      //         volnv7=0;
      //      if(volnv8>220.0)
      //         volnv8=0;

     }

//--- Definição dos preços médios para quando houver 2 ou mais compras/vendas
   if(ativamartingale && tipooper==tiponet)
     {
      if(PositionsTotal()>=1)
        {
         if(possuicompra1 && !possuicompra2)
            PMC1 = (tick.ask*volnv2 + precoultimacompra*volumeoper)/(volnv2+volumeoper);
         if(possuicompra2 && !possuicompra3)
            PMC2 = (tick.ask*volnv3 + PMultimacompra*VMultimacompra)/(volnv3+VMultimacompra);
         if(possuicompra3 && !possuicompra4)
            PMC3 = (tick.ask*volnv4 + PMultimacompra*VMultimacompra)/(volnv4+VMultimacompra);
         if(possuicompra4 && !possuicompra5)
            PMC4 = (tick.ask*volnv5 + PMultimacompra*VMultimacompra)/(volnv5+VMultimacompra);
         if(possuicompra5 && !possuicompra6)
            PMC5 = (tick.ask*volnv6 + PMultimacompra*VMultimacompra)/(volnv6+VMultimacompra);
         if(possuicompra6 && !possuicompra7)
            PMC6 = (tick.ask*volnv7 + PMultimacompra*VMultimacompra)/(volnv7+VMultimacompra);
         if(possuicompra7 && !possuicompra8)
            PMC7 = (tick.ask*volnv8 + PMultimacompra*VMultimacompra)/(volnv8+VMultimacompra);
         if(possuicompra8 && !possuicompra9)
            PMC8 = (tick.ask*volnv9 + PMultimacompra*VMultimacompra)/(volnv9+VMultimacompra);
         if(possuicompra9 && !possuicompra10)
            PMC9 = (tick.ask*volnv10 + PMultimacompra*VMultimacompra)/(volnv10+VMultimacompra);
         if(possuicompra10 && !possuicompra11)
            PMC10 = (tick.ask*volnv11 + PMultimacompra*VMultimacompra)/(volnv11+VMultimacompra);
         if(possuicompra11 && !possuicompra12)
            PMC11 = (tick.ask*volnv12 + PMultimacompra*VMultimacompra)/(volnv12+VMultimacompra);
         if(possuicompra12 && !possuicompra13)
            PMC12 = (tick.ask*volnv13 + PMultimacompra*VMultimacompra)/(volnv13+VMultimacompra);
         if(possuicompra13 && !possuicompra14)
            PMC13 = (tick.ask*volnv14 + PMultimacompra*VMultimacompra)/(volnv14+VMultimacompra);

         if(possuivenda1 && !possuivenda2)
            PMV1 = (tick.bid*volnv2 + PMultimavenda*volumeoper)/(volnv2+volumeoper);
         if(possuivenda2 && !possuivenda3)
            PMV2 = (tick.bid*volnv3 + PMultimavenda*VMultimavenda)/(volnv3+VMultimavenda);
         if(possuivenda3 && !possuivenda4)
            PMV3 = (tick.bid*volnv4 + PMultimavenda*VMultimavenda)/(volnv4+VMultimavenda);
         if(possuivenda4 && !possuivenda5)
            PMV4 = (tick.bid*volnv5 + PMultimavenda*VMultimavenda)/(volnv5+VMultimavenda);
         if(possuivenda5 && !possuivenda6)
            PMV5 = (tick.bid*volnv6 + PMultimavenda*VMultimavenda)/(volnv6+VMultimavenda);
         if(possuivenda6 && !possuivenda7)
            PMV6 = (tick.bid*volnv7 + PMultimavenda*VMultimavenda)/(volnv7+VMultimavenda);
         if(possuivenda7 && !possuivenda8)
            PMV7 = (tick.bid*volnv8 + PMultimavenda*VMultimavenda)/(volnv8+VMultimavenda);
         if(possuivenda8 && !possuivenda9)
            PMV8 = (tick.bid*volnv9 + PMultimavenda*VMultimavenda)/(volnv9+VMultimavenda);
         if(possuivenda9 && !possuivenda10)
            PMV9 = (tick.bid*volnv10 + PMultimavenda*VMultimavenda)/(volnv10+VMultimavenda);
         if(possuivenda10 && !possuivenda11)
            PMV10 = (tick.bid*volnv11 + PMultimavenda*VMultimavenda)/(volnv11+VMultimavenda);
         if(possuivenda11 && !possuivenda12)
            PMV11 = (tick.bid*volnv12 + PMultimavenda*VMultimavenda)/(volnv12+VMultimavenda);
         if(possuivenda12 && !possuivenda13)
            PMV12 = (tick.bid*volnv13 + PMultimavenda*VMultimavenda)/(volnv13+VMultimavenda);
         if(possuivenda13 && !possuivenda14)
            PMV13 = (tick.bid*volnv14 + PMultimavenda*VMultimavenda)/(volnv14+VMultimavenda);
        }
     }

   if(estrategia==estrat4 || estrategia==estrat9)
     {
      sarnormalizado0 = NormalizeDouble(sar[0],5);
      sarnormalizado1 = NormalizeDouble(sar[1],5);
      sarnormalizado2 = NormalizeDouble(sar[2],5);
      sarnormalizado3 = NormalizeDouble(sar[3],5);
      sarnormalizado4 = NormalizeDouble(sar[4],5);
     }

//--- Cálculo da condição para operar no SAR dentro do número de pontos de lucro definidos nos inputs
   if(((sarnormalizado0>tick.bid && sarnormalizado1<tick.ask) || (sarnormalizado0<tick.ask && sarnormalizado1>tick.bid)) && mitigacaook == false)
     {
      mitigacaook = true;
      datahoraviradasar = TimeCurrent();
     }
   if(mitigacaook == true)
     {
      HistorySelect(aberturacandleatual,TimeCurrent());
      if(HistoryDealsTotal()>1)
        {
         if(datahoraviradasar!=D'2000.01.01 01:00')
           {
            controlepontossar = NormalizeDouble(PontosGanhosAposViradaSar(datahoraviradasar),2);
            if(controlepontossar>=maximopontossar)
              {
               Print("CONTROLE DE GANHO OK: ",controlepontossar);
               mitigacaook = false;
              }
           }
         else
           {
            controlepontossar = NormalizeDouble(PontosGanhosAposViradaSar(aberturacandleatual),2);
            if(controlepontossar>=maximopontossar)
              {
               Print("CONTROLE DE GANHO OK: ",controlepontossar);
               mitigacaook = false;
              }
           }
        }
     }


////////////////////////////////////////////
//---| FECHA ORDENS NO FIM DO PREGÃO |----//
////////////////////////////////////////////
   if(ativafecfinaldia)
     {
      if(PositionsTotal()>=1)
         if((possuicompra||possuivenda) && hratualstruct.hour==hrfechstruct.hour && hratualstruct.min==hrfechstruct.min)
            FechaTodasPosicoesAbertas("FIM DO PREGÃO");
     }

/////////////////////////////////////////////
//---| FECHA ORDENS QNDO SAR INVERTER |----//
/////////////////////////////////////////////
   if(PositionsTotal()>=1)
     {
      if((possuicompra && sarnormalizado0>tick.bid)||(possuivenda && sarnormalizado0<tick.ask))
        {
         FechaTodasPosicoesAbertas("SAR INVERTIDO");
         Sleep(100);
         if(sarnormalizado0 < tick.ask)
           {
            trade.Buy(3,_Symbol,tick.ask,puxatpsl("SLC0"),0,"COMPRA MÃO VIRADA");
           }
         if(sarnormalizado0 > tick.bid)
           {
            trade.Sell(3,_Symbol,tick.bid,puxatpsl("SLV0"),0,"VENDA MÃO VIRADA");
           }
        }
     }

//+-------------------------------------------+
//| OPERAÇÕES SEGUINDO A ESTRATÉGIA ESCOLHIDA |
//+-------------------------------------------+

//--- Check de posição aberta em outro ativo, horário de operação, margem suficiente pra operar e se o número de stops setado nos inputs já foram alcançados
   if(ativaentradaea && HorarioEntrada() && !HorarioPausa1() /*&& DadosPosFechada("QTDE DE SL DO DIA","")<somapreju*/ && (percent_margem>prcentabert||saldo==capital))
     {
      //--- Verifica se candle acabou de abrir
      if(NB2.IsNewBar(_Symbol,_Period))
        {
         //////////////////////////////////////////////////////
         //---| PRIMEIRA COMPRA/VENDA DE CADA ESTRATÉGIA |---//
         //////////////////////////////////////////////////////
         if(PositionsTotal()==0 && mitigacaook)
           {
            //---| ESTRATEGIA SAR |---//
            if(estrategia==estrat9)
              {
               if(sarnormalizado0 < tick.ask/* && sarnormalizado1 < tick.ask*/)
                 {
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),0,"ABERTURA SAR DE COMPRA");
                 }
               Sleep(100);
               if(sarnormalizado0 > tick.bid/* && sarnormalizado1 > tick.bid*/)
                 {
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),0,"ABERTURA SAR DE VENDA");
                 }
               Sleep(100);
              }
           }
        }
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(hratualstruct.sec==58 || hratualstruct.sec==59)
     {
      FechaTodasPosicoesAbertas("FECHAMENTO FINAL DO CANDLE");
     }

//Print(NormalizeDouble(sarnormalizado4-sarnormalizado3,0),";",NormalizeDouble(sarnormalizado3-sarnormalizado2,0),";",NormalizeDouble(sarnormalizado2-sarnormalizado1,0),";",NormalizeDouble(sarnormalizado1-sarnormalizado0,0));

////////////////////////////////////////////////////////////////////////////////////
//---| DEMAIS COMPRAS E VENDAS DE CADA ESTATÉGIA - CASO MARTINGALE HABILITADO |---//
////////////////////////////////////////////////////////////////////////////////////
   if(ativamartingale)
     {
      if(PositionsTotal()>=1 && ((possuicompra && qtdecandposabertcompra>=qtdecandle) || (possuivenda && qtdecandposabertvenda>=qtdecandle)) && QtsMartingale()<=qtdedemart)
        {
         //---| ESTRATEGIA ENVELOPE/RSI/BOLINGER |---//
         if(estrategia==estrat1)
           {
            if(candle[1].close<mm[1]-tamanhoenvelope*_Point && rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/ && candle[1].close<bbd[1])
               ComprasMartingale();
            if(candle[1].close>mm[1]+tamanhoenvelope*_Point && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ && candle[1].close>bbu[1])
               VendasMartingale();
           }
         //---| ESTRATEGIA ENVELOPE/RSI |---//
         if(estrategia==estrat2)
           {
            if(candle[1].close<mm[1]-tamanhoenvelope*_Point && rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/)
               ComprasMartingale();
            if(candle[1].close>mm[1]+tamanhoenvelope*_Point && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/)
               VendasMartingale();
           }
         //---| ESTRATEGIA ENVELOPE/BOLINGER |---//
         if(estrategia==estrat3)
           {
            if(candle[1].close<mm[1]-tamanhoenvelope*_Point && candle[1].close<bbd[1])
               ComprasMartingale();
            if(candle[1].close>mm[1]+tamanhoenvelope*_Point && candle[1].close>bbu[1])
               VendasMartingale();
           }
         //---| ESTRATEGIA ENVELOPE/SAR |---//
         if(estrategia==estrat4)
           {
            if(candle[1].close<mm[1]-tamanhoenvelope*_Point && sarnormalizado0 < tick.ask && sarnormalizado1 < tick.ask)
               ComprasMartingale();
            if(candle[1].close>mm[1]+tamanhoenvelope*_Point && sarnormalizado0 > tick.bid && sarnormalizado1 > tick.bid)
               VendasMartingale();
           }
         //---| ESTRATEGIA RSI/BOLINGER |---//
         if(estrategia==estrat5)
           {
            if(rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/ && candle[1].close<bbd[1])
               ComprasMartingale();
            if(rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ && candle[1].close>bbu[1])
               VendasMartingale();
           }
         //---| ESTRATEGIA ENVELOPE |---//
         if(estrategia==estrat6)
           {
            if(candle[1].close<mm[1]-tamanhoenvelope*_Point)
               ComprasMartingale();
            if(candle[1].close>mm[1]+tamanhoenvelope*_Point)
               VendasMartingale();
           }
         //---| ESTRATEGIA RSI |---//
         if(estrategia==estrat7)
           {
            if(rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/)
               ComprasMartingale();
            if(rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/)
               VendasMartingale();
           }
         //---| ESTRATEGIA BOLINGER |---//
         if(estrategia==estrat8)
           {
            if(candle[1].close<bbd[1])
               ComprasMartingale();
            if(candle[1].close>bbu[1])
               VendasMartingale();
           }
         //---| ESTRATEGIA SAR |---//
         if(estrategia==estrat9)
           {
            //if(sarnormalizado0 < tick.ask/* && sarnormalizado1 < tick.ask*/)
            ComprasMartingale();
            //if(sarnormalizado0 > tick.bid/* && sarnormalizado1 > tick.bid*/)
            VendasMartingale();
           }
        }
     }

///////////////////////
//---|STOP FULL |----//
///////////////////////
   if(ativastopfull)
     {
      prejudodia = DadosPos("PREJUÍZO DO DIA","");
      if(MathAbs(prejudodia)/capital*100>=percentfull && prejudodia<0 && saldo!=capital)
        {
         //Print("STOP FULL ACIONADO");
         FechaTodasPosicoesAbertas("STOP FULL");
         Sleep(300);
         return;
        }
     }

/////////////////////////////////////////////////////////////////////////////////////
//---|FECHAMENTO DA ORDENS CRIADAS ERRADAMENTE - CORREÇÃO PARA CORRETORA CLEAR|----//
/////////////////////////////////////////////////////////////////////////////////////
//   if(estrategia==estrat9 || estrategia==estrat14 || estrategia==estrat16)
//     {
//      if((possuicompra && slultimaposcompra==0) || (possuivenda && slultimaposvenda==0))
//        {
//         Print("ERRO DA CORRETORA - ORDEM SEM STOP LOSS CRIADA");
//         FechaTodasPosicoesAbertas("ERRO CORRETORA");
//         Sleep(100);
//        }
//     }

////////////////////////////
//---|BREAKEVEN E TS |----//
////////////////////////////
   /*   if(ativbreak)
        {
         if(possuicompra && tick.bid>=PMultimacompra+pontosc1*_Point && tpultimaposcompra==0)
           {
            trade.PositionModify(_Symbol,tick.bid-pontosbesl*_Point,tick.ask+5*pontosc1*_Point);
           }
         if(possuivenda && tick.ask<=PMultimavenda-pontosc1*_Point && tpultimaposvenda==0)
           {
            trade.PositionModify(_Symbol,tick.ask+pontosbesl*_Point,tick.bid-5*pontosc1*_Point);
           }
         if(possuicompra && tick.bid>=slultimaposcompra+2*pontosbesl*_Point && tpultimaposcompra!=0)
           {
            trade.PositionModify(_Symbol,slultimaposcompra+pontosbesl*_Point,tpultimaposcompra+pontosbesl*_Point);
           }
         if(possuivenda && tick.ask<=slultimaposvenda-2*pontosbesl*_Point && tpultimaposvenda!=0)
           {
            trade.PositionModify(_Symbol,slultimaposvenda-pontosbesl*_Point,tpultimaposvenda-pontosbesl*_Point);
           }
        }*/
  }

////////////////////////////
//| FIM DA FUNÇÃO ONTICK |//
////////////////////////////

//+------------------------------------------------------------------------------------------------------------------------------------------------+

/////////////////////////////////////
//| INÍCIO DAS FUNÇÕES AUXILIARES |//
/////////////////////////////////////
//+--------------------------------------+
//| REQUISIÇÃO/RECEPÇÃO HTTP DA PREVISÃO |
//+--------------------------------------+
void WebPrevision()
  {
   string cookie=NULL,headers;
   char   post[],result[];
   string url="https://finance.yahoo.com";
//--- para trabalhar com o servidor é necessário adicionar a URL "https://finance.yahoo.com"
//--- na lista de URLs permitidas (menu Principal->Ferramentas->Opções, guia "Experts"):
//--- redefinimos o código do último erro
   ResetLastError();
//--- download da página html do Yahoo Finance
   int res=WebRequest("GET",url,cookie,NULL,500,post,0,result,headers);
   if(res==-1)
     {
      Print("Erro no WebRequest. Código de erro =",GetLastError());
      //--- é possível que a URL não esteja na lista, exibimos uma mensagem sobre a necessidade de adicioná-la
      MessageBox("É necessário adicionar um endereço '"+url+"' à lista de URL permitidas na guia 'Experts'","Erro",MB_ICONINFORMATION);
     }
   else
     {
      if(res==200)
        {
         //--- download bem-sucedido
         PrintFormat("O arquivo foi baixado com sucesso, tamanho %d bytes.",ArraySize(result));
         //PrintFormat("Cabeçalhos do servidor: %s",headers);
         //--- salvamos os dados em um arquivo
         int filehandle=FileOpen("url.htm",FILE_WRITE|FILE_BIN);
         if(filehandle!=INVALID_HANDLE)
           {
            //--- armazenamos o conteúdo do array result[] no arquivo
            FileWriteArray(filehandle,result,0,ArraySize(result));
            //--- fechamos o arquivo
            FileClose(filehandle);
           }
         else
            Print("Erro em FileOpen. Código de erro =",GetLastError());
        }
      else
         PrintFormat("Erro de download '%s', código %d",url,res);
     }
  }
//+------------------------------------------------------------------------------------------+
//+---------------------------------------------+
//| CONTADOR DE CANDLES DESDE ÚLTIMA POS ABERTA |
//+---------------------------------------------+
int   QtdeCandlesPosAberta(string tipo)
  {
   int qtdebars=0;
   if(possuicompra && tipo=="COMPRA")
      qtdebars = Bars(_Symbol,_Period,dataultimaposabertacompra,TimeCurrent());
   if(possuivenda && tipo=="VENDA")
      qtdebars = Bars(_Symbol,_Period,dataultimaposabertavenda,TimeCurrent());
   return qtdebars;
  }
//+------------------------------------------------------------------------------------------+
//+----------------------------------------------+
//| CONTADOR DE CANDLES DESDE ÚLTIMA POS FECHADA |
//+----------------------------------------------+
int   QtdeCandlesPosFechada()
  {
   int qtdebars=0;
   if(PosFechadaTrueFalse("EXISTE AO MENOS UMA POSIÇÃO FECHADA",""))
      qtdebars = Bars(_Symbol,_Period,DataHoraUltPosFechada(),TimeCurrent());
   return qtdebars;
  }
//+------------------------------------------------------------------------------------------+
//+------------------------------------------------+
//| FECHA TODAS AS POSIÇÕES ABERTAS COM COMENTÁRIO |
//+------------------------------------------------+
void FechaTodasPosicoesAbertas(string comentario)
  {
   for(int i=PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      string symbol = PositionGetString(POSITION_SYMBOL);
      double volume = PositionGetDouble(POSITION_VOLUME);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(TipoPosicao==POSITION_TYPE_BUY && symbol==_Symbol /*&& magic == magicrobo*/)
         trade.Sell(volume,_Symbol,tick.bid,0,0,comentario);
      if(TipoPosicao==POSITION_TYPE_SELL && symbol==_Symbol /*&& magic == magicrobo*/)
         trade.Buy(volume,_Symbol,tick.ask,0,0,comentario);
     }
  }
//+------------------------------------------------------------------------------------------+
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
//+---------------------------------------+
//| RETORNA O TICKET DA ÚLTIMA POS ABERTA |
//+---------------------------------------+
ulong TicketPosAberta()
  {
   if(PositionsTotal()>0)
     {
      for(int i=PositionsTotal()-1; i >= 0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         string symbol = PositionGetString(POSITION_SYMBOL);
         ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if((TipoPosicao==POSITION_TYPE_BUY||TipoPosicao==POSITION_TYPE_SELL) && symbol==_Symbol)
           {
            return ticket;
            break;
           }
        }
     }
   return NULL;
  }
//+------------------------------------------------------------------------------------------+
//+---------------------------------------------------------------+
//| FUNÇÃO DE VERIFICAÇÃO DE POSIÇÕES ABERTAS E SUAS RAMIFICAÇÕES |
//+---------------------------------------------------------------+
bool PosAberta(string acao, string tipo, string comentario)
  {
   if(PositionsTotal()>0)
     {
      for(int i=PositionsTotal()-1; i >= 0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         string symbol = PositionGetString(POSITION_SYMBOL);
         string coment = PositionGetString(POSITION_COMMENT);
         ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(TipoPosicao==POSITION_TYPE_BUY && symbol==_Symbol)
           {
            if(acao=="POSSUI")
              {
               if(tipo=="COMPRA" && (comentario==""||comentario==coment))
                 {
                  return true;
                  break;
                 }
              }
           }
         if(TipoPosicao==POSITION_TYPE_SELL && symbol==_Symbol)
           {
            if(acao=="POSSUI")
              {
               if(tipo=="VENDA" && (comentario==""||comentario==coment))
                 {
                  return true;
                  break;
                 }
              }
           }
        }
     }
   return false;
  }
//+------------------------------------------------------------------------------------------+
//+-----------------------------------------------------+
//| FUNÇÃO DE VERIFICAÇÃO DE DADOS DAS POSIÇÕES ABERTAS |
//+-----------------------------------------------------+
double DadosPos(string acao, string tipo)
  {
   double precomenor=200000.0;
   double precomaior=0.0;
   double preju=0.0;
   int posabertas = PositionsTotal();
   for(int i = posabertas-1; i >= 0; i--)
     {
      ulong  ticket = PositionGetTicket(i);
      string symbol = PositionGetString(POSITION_SYMBOL);
      double volume = PositionGetDouble(POSITION_VOLUME);
      double preco  = PositionGetDouble(POSITION_PRICE_OPEN);
      double profit = PositionGetDouble(POSITION_PROFIT);
      double tp     = PositionGetDouble(POSITION_TP);
      double sl     = PositionGetDouble(POSITION_SL);
      ENUM_POSITION_TYPE tipo1 =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(tipo1 == POSITION_TYPE_BUY && symbol==_Symbol)
        {
         if(tipo=="COMPRA")
           {
            if(acao=="VOLUME DA ÚLTIMA POSIÇÃO ABERTA")
              {
               return volume;
               break;
              }
            if(acao=="PREÇO DA ÚLTIMA POSIÇÃO ABERTA")
              {
               return preco;
               break;
              }
            if(acao=="PROFIT DA ÚLTIMA POSIÇÃO ABERTA")
              {
               return profit;
               break;
              }
            if(acao=="TP DA ÚLTIMA POSIÇÃO ABERTA")
              {
               return tp;
               break;
              }
            if(acao=="SL DA ÚLTIMA POSIÇÃO ABERTA")
              {
               return sl;
               break;
              }
            if(acao=="PREÇO DA MENOR POSIÇÃO ABERTA")
              {
               if(preco < precomenor)
                  precomenor=preco;
              }
           }
        }
      if(tipo1 == POSITION_TYPE_SELL && symbol==_Symbol)
        {
         if(tipo=="VENDA")
           {
            if(acao=="VOLUME DA ÚLTIMA POSIÇÃO ABERTA")
              {
               return volume;
               break;
              }
            if(acao=="PREÇO DA ÚLTIMA POSIÇÃO ABERTA")
              {
               return preco;
               break;
              }
            if(acao=="PROFIT DA ÚLTIMA POSIÇÃO ABERTA")
              {
               return profit;
               break;
              }
            if(acao=="TP DA ÚLTIMA POSIÇÃO ABERTA")
              {
               return tp;
               break;
              }
            if(acao=="SL DA ÚLTIMA POSIÇÃO ABERTA")
              {
               return sl;
               break;
              }
            if(acao=="PREÇO DA MAIOR POSIÇÃO ABERTA")
              {
               if(preco > precomaior)
                  precomaior=preco;
              }
           }
        }
      if(acao=="PREJUÍZO DO DIA")
        {
         if(tipo1==POSITION_TYPE_BUY || tipo1==POSITION_TYPE_SELL)
           {
            preju=preju+profit;
           }
        }
     }
   if(acao=="PREÇO DA MENOR POSIÇÃO ABERTA")
      return precomenor;
   if(acao=="PREÇO DA MAIOR POSIÇÃO ABERTA")
      return precomaior;
   if(acao=="PREJUÍZO DO DIA")
      return preju;

   return NULL;
  }
//+------------------------------------------------------------------------------------------+
//+-------------------------------------------------- +
//| RETORNA A DATA/HORA DA ABERTURA DA ULTIMA POSIÇÃO |
//+---------------------------------------------------+
datetime DataHoraUltPosAberta(string tipo)
  {
   datetime timedefault=D'2000.01.01 01:00';
   if(possuicompra && tipo=="COMPRA")
     {
      for(int i=PositionsTotal()-1; i >= 0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         string symbol = PositionGetString(POSITION_SYMBOL);
         datetime time = (datetime)PositionGetInteger(POSITION_TIME);
         //ulong  magic = PositionGetInteger(POSITION_MAGIC);
         ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(TipoPosicao==POSITION_TYPE_BUY && symbol==_Symbol)
           {
            return time;
            break;
           }
        }
     }
   if(possuivenda && tipo=="VENDA")
     {
      for(int i=PositionsTotal()-1; i >= 0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         string symbol = PositionGetString(POSITION_SYMBOL);
         datetime time = (datetime)PositionGetInteger(POSITION_TIME);
         //ulong  magic = PositionGetInteger(POSITION_MAGIC);
         ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(TipoPosicao==POSITION_TYPE_SELL && symbol==_Symbol)
           {
            return time;
            break;
           }
        }
     }
   return timedefault;
  }
//+------------------------------------------------------------------+
//+-----------------------------------------------------+
//| RETORNA A DATA/HORA DO FECHAMENTO DA ULTIMA POSIÇÃO |
//+-----------------------------------------------------+
datetime DataHoraUltPosFechada()
  {
   datetime timedefault=D'2000.01.01 01:00';
   HistorySelect(aberturacandleatual,TimeCurrent());
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
         if(entry==DEAL_ENTRY_OUT && symbol==_Symbol)
           {
            return time;
            break;
           }
        }
     }

   return timedefault;
  }
//+------------------------------------------------------------------+
//+-----------------------------------------------------+
//| RETORNA OS DADOS RELACIONADOS AS POSIÇÕES FECHADAS |
//+-----------------------------------------------------+
double DadosPosFechada(string acao, string tipo)
  {
   ulong       ticket=0;
   double      profit=0;
   double      profit1=0;
   double      volume=0;
   double      volume1=0;
   double      preco=0;
   double      preco1=0;
   double      pontossldia=0;
   double      ganhodia=0;
   double      perdadia=0;
   string      symbol;
   long        reason;
   long        entry;
   long        type;
   datetime    time;
   datetime    time1=D'2000.01.01 01:00';
   datetime    tempopos=D'2000.01.01 01:00';
   HistorySelect(0,TimeCurrent());
   uint        dealstotal = HistoryDealsTotal();
   for(uint i=0; i < dealstotal; i++)
     {
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         reason=HistoryDealGetInteger(ticket,DEAL_REASON);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
         profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         volume=HistoryDealGetDouble(ticket,DEAL_VOLUME);
         preco =HistoryDealGetDouble(ticket,DEAL_PRICE);
         time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         if(tipo=="COMPRA")
           {
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               if(acao=="VOLUME DA ÚLTIMA POSIÇÃO FECHADA")
                  volume1=volume;
              }
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               if(acao=="PREÇO DA ÚLTIMA POSIÇÃO ABERTA")
                  if(possuicompra && entry==DEAL_ENTRY_IN)
                     preco1=preco;
               if(acao=="VOLUME DA ÚLTIMA POSIÇÃO ABERTA")
                  if(possuicompra && entry==DEAL_ENTRY_IN)
                     volume1=volume;
              }
           }
         if(tipo=="VENDA")
           {
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               if(acao=="VOLUME DA ÚLTIMA POSIÇÃO FECHADA")
                  volume1=volume;
              }
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_IN && symbol==_Symbol)
              {
               if(acao=="PREÇO DA ÚLTIMA POSIÇÃO ABERTA")
                  if(possuivenda && entry==DEAL_ENTRY_IN)
                     preco1=preco;
               if(acao=="VOLUME DA ÚLTIMA POSIÇÃO ABERTA")
                  if(possuivenda && entry==DEAL_ENTRY_IN)
                     volume1=volume;
              }

           }
         if(acao=="QTDE DE SL DO DIA")
           {
            MqlDateTime timestruct;
            TimeToStruct(time,timestruct);
            if(timestruct.day==hratualstruct.day && profit<0 && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               ulong ticket1=HistoryDealGetTicket(i-1);
               double preco2 = HistoryDealGetDouble(ticket1,DEAL_PRICE);
               pontossldia = pontossldia+MathAbs(preco-preco2);
              }
           }
         if(acao=="QTDE DE GANHOS DO DIA")
           {
            MqlDateTime timestruct;
            TimeToStruct(time,timestruct);
            if(timestruct.day==hratualstruct.day && profit>0 && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               ganhodia = ganhodia+profit;
              }
           }
         if(acao=="QTDE DE PERDAS DO DIA")
           {
            MqlDateTime timestruct;
            TimeToStruct(time,timestruct);
            if(timestruct.day==hratualstruct.day && profit<0 && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               perdadia = perdadia+MathAbs(profit);
              }
           }
         if(acao=="PROFIT DA ÚLTIMA POSIÇÃO FECHADA")
            profit1 = profit;

        }
      else
         break;
     }
   if(acao=="PROFIT DA ÚLTIMA POSIÇÃO FECHADA")
      return profit1;
   if(acao=="VOLUME DA ÚLTIMA POSIÇÃO FECHADA")
      return volume1;
   if(acao=="PREÇO DA ÚLTIMA POSIÇÃO ABERTA")
      return preco1;
   if(acao=="VOLUME DA ÚLTIMA POSIÇÃO ABERTA")
      return volume1;
   if(acao=="QTDE DE SL DO DIA")
      return pontossldia;
   if(acao=="QTDE DE PERDAS DO DIA")
      return perdadia;
   if(acao=="QTDE DE GANHOS DO DIA")
      return ganhodia;
   return NULL;
  }
//+------------------------------------------------------------------------------------------+
//+---------------------------------------------------------------+
//| RETORNA OS DADOS TRUE/FALSE RELACIONADOS AS POSIÇÕES FECHADAS |
//+---------------------------------------------------------------+
bool PosFechadaTrueFalse(string acao,string tipo)
  {
   bool     condicao=false;
   HistorySelect(0,TimeCurrent());
   ulong    ticket=0;
   string   symbol;
   long     reason;
   long     entry;
   long     type;
   uint     dealstotal=HistoryDealsTotal();
   for(uint i=0; i < dealstotal; i++)
     {
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         reason=HistoryDealGetInteger(ticket,DEAL_REASON);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         type  = HistoryDealGetInteger(ticket,DEAL_TYPE);
         if(entry==DEAL_ENTRY_OUT && type==DEAL_TYPE_SELL && symbol==_Symbol)
           {
            if(tipo=="COMPRA")
              {
               if(acao=="ÚLTIMA POSIÇÃO FECHADA FOI DE SL")
                 {
                  if(reason==DEAL_REASON_SL)
                    {
                     condicao=true;
                    }
                  else
                    {
                     condicao=false;
                    }
                 }
               if(acao=="ÚLTIMA POSIÇÃO FECHADA FOI DE TP")
                 {
                  if(reason==DEAL_REASON_TP)
                    {
                     condicao=true;
                    }
                  else
                    {
                     condicao=false;
                    }
                 }
              }
           }
         if(entry==DEAL_ENTRY_OUT && type==DEAL_TYPE_BUY && symbol==_Symbol)
           {
            if(tipo=="VENDA")
              {
               if(acao=="ÚLTIMA POSIÇÃO FECHADA FOI DE SL")
                 {
                  if(reason==DEAL_REASON_SL)
                    {
                     condicao=true;
                    }
                  else
                    {
                     condicao=false;
                    }
                 }
               if(acao=="ÚLTIMA POSIÇÃO FECHADA FOI DE TP")
                 {
                  if(reason==DEAL_REASON_TP)
                    {
                     condicao=true;
                    }
                  else
                    {
                     condicao=false;
                    }
                 }
              }
           }
         if(entry==DEAL_ENTRY_OUT && symbol==_Symbol && acao=="EXISTE AO MENOS UMA POSIÇÃO FECHADA")
            condicao=true;

         if(entry==DEAL_ENTRY_OUT && symbol==_Symbol && acao=="ÚLTIMA POSIÇÃO FECHADA FOI DE SL")
            if(reason==DEAL_REASON_SL)
               condicao=true;
            else
               condicao=false;

        }
     }

   return condicao;
  }
//+------------------------------------------------------------------------------------------+
//+-------------------------------------------------------------------+
//| RETORNA A DATA/HORA DO DA ÚLTIMA POSIÇÃO FECHADA DE VIRADA DE SAR |
//+-------------------------------------------------------------------+
datetime DataHoraUltPosFechadaViradaSar(string comentario)
  {
   datetime timedefault=D'2000.01.01 01:00';
   HistorySelect(aberturacandleatual,TimeCurrent());
   ulong       ticket=0;
   string      symbol;
   long        entry;
   datetime    time;
   string      coment="";
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         coment=HistoryDealGetString(ticket,DEAL_COMMENT);
         if(entry==DEAL_ENTRY_OUT && coment==comentario && symbol==_Symbol)
           {
            return time;
            break;
           }
        }
      else
         return timedefault;
     }

   return timedefault;
  }
//+------------------------------------------------------------------+
//+---------------------------------------------+
//| RETORNA OS PONTOS GANHOS APÓS VIRADA DO SAR |
//+---------------------------------------------+
double PontosGanhosAposViradaSar(datetime tempo)
  {
   ulong       ticket=0;
   double      profit=0;
   double      profit1=0;
   string      symbol;
   long        reason;
   long        entry;
   long        type;
   HistorySelect(tempo,TimeCurrent());
   uint        dealstotal = HistoryDealsTotal();
   for(uint i=0; i < dealstotal; i++)
     {
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         reason=HistoryDealGetInteger(ticket,DEAL_REASON);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
         profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         if(/*profit>0 &&*/ entry==DEAL_ENTRY_OUT && symbol==_Symbol)
           {
            profit1 = profit1+profit;
           }
        }
      else
         break;
     }
   double profitempontos = profit1/_Point;
   return profitempontos;
  }
//+------------------------------------------------------------------------------------------+
//////////////////////////////////////////
//---|COMPRAS NORMAIS COM MARTINGALE|---//
//////////////////////////////////////////
void  ComprasMartingale()
  {
   if(possuicompra1 && !possuicompra2 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv2!=0)
     {
      trade.Buy(volnv2,_Symbol,tick.ask,slultimaposcompra,0,"C2");
      Sleep(100);
      return;
     }
   if(possuicompra2 && !possuicompra3 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv3!=0)
     {
      trade.Buy(volnv3,_Symbol,tick.ask,slultimaposcompra,0,"C3");
      Sleep(100);
      return;
     }
   if(possuicompra3 && !possuicompra4 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv4!=0)
     {
      trade.Buy(volnv4,_Symbol,tick.ask,slultimaposcompra,0,"C4");
      Sleep(100);
      return;
     }
   if(possuicompra4 && !possuicompra5 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv5!=0)
     {
      trade.Buy(volnv5,_Symbol,tick.ask,slultimaposcompra,0,"C5");
      Sleep(100);
      return;
     }
   if(possuicompra5 && !possuicompra6 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv6!=0)
     {
      trade.Buy(volnv6,_Symbol,tick.ask,slultimaposcompra,0,"C6");
      Sleep(100);
      return;
     }
   if(possuicompra6 && !possuicompra7 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv7!=0)
     {
      trade.Buy(volnv7,_Symbol,tick.ask,slultimaposcompra,0,"C7");
      Sleep(100);
      return;
     }
   if(possuicompra7 && !possuicompra8 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv8!=0)
     {
      trade.Buy(volnv8,_Symbol,tick.ask,slultimaposcompra,0,"C8");
      Sleep(100);
      return;
     }
   if(possuicompra8 && !possuicompra9 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv9!=0)
     {
      trade.Buy(volnv9,_Symbol,tick.ask,slultimaposcompra,0,"C9");
      Sleep(100);
      return;
     }
   if(possuicompra9 && !possuicompra10 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv10!=0)
     {
      trade.Buy(volnv10,_Symbol,tick.ask,slultimaposcompra,0,"C10");
      Sleep(100);
      return;
     }
   if(possuicompra10 && !possuicompra11 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv11!=0)
     {
      trade.Buy(volnv11,_Symbol,tick.ask,slultimaposcompra,0,"C11");
      Sleep(100);
      return;
     }
   if(possuicompra11 && !possuicompra12 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv12!=0)
     {
      trade.Buy(volnv12,_Symbol,tick.ask,slultimaposcompra,0,"C12");
      Sleep(100);
      return;
     }
   if(possuicompra12 && !possuicompra13 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv13!=0)
     {
      trade.Buy(volnv13,_Symbol,tick.ask,slultimaposcompra,0,"C13");
      Sleep(100);
      return;
     }
   if(possuicompra13 && !possuicompra14 && tick.ask<precoultimacompra-pontosmart*_Point && volumeultimacompra<=500 && volnv14!=0)
     {
      trade.Buy(volnv14,_Symbol,tick.ask,slultimaposcompra,0,"C14");
      Sleep(100);
      return;
     }
  }
//+---------------------------------------------------------------------------------------------------------------------------------+
/////////////////////////////////////////
//---|VENDAS NORMAIS COM MARTINGALE|---//
/////////////////////////////////////////
void  VendasMartingale()
  {
   if(possuivenda1 && !possuivenda2 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv2!=0)
     {
      trade.Sell(volnv2,_Symbol,tick.bid,slultimaposvenda,0,"V2");
      Sleep(100);
      return;
     }
   if(possuivenda2 && !possuivenda3 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv3!=0)
     {
      trade.Sell(volnv3,_Symbol,tick.bid,slultimaposvenda,0,"V3");
      Sleep(100);
      return;
     }
   if(possuivenda3 && !possuivenda4 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv4!=0)
     {
      trade.Sell(volnv4,_Symbol,tick.bid,slultimaposvenda,0,"V4");
      Sleep(100);
      return;
     }
   if(possuivenda4 && !possuivenda5 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv5!=0)
     {
      trade.Sell(volnv5,_Symbol,tick.bid,slultimaposvenda,0,"V5");
      Sleep(100);
      return;
     }
   if(possuivenda5 && !possuivenda6 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv6!=0)
     {
      trade.Sell(volnv6,_Symbol,tick.bid,slultimaposvenda,0,"V6");
      Sleep(100);
      return;
     }
   if(possuivenda6 && !possuivenda7 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv7!=0)
     {
      trade.Sell(volnv7,_Symbol,tick.bid,slultimaposvenda,0,"V7");
      Sleep(100);
      return;
     }
   if(possuivenda7 && !possuivenda8 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv8!=0)
     {
      trade.Sell(volnv8,_Symbol,tick.bid,slultimaposvenda,0,"V8");
      Sleep(100);
      return;
     }
   if(possuivenda8 && !possuivenda9 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv9!=0)
     {
      trade.Sell(volnv9,_Symbol,tick.bid,slultimaposvenda,0,"V9");
      Sleep(100);
      return;
     }
   if(possuivenda9 && !possuivenda10 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv10!=0)
     {
      trade.Sell(volnv10,_Symbol,tick.bid,slultimaposvenda,0,"V10");
      Sleep(100);
      return;
     }
   if(possuivenda10 && !possuivenda11 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv11!=0)
     {
      trade.Sell(volnv11,_Symbol,tick.bid,slultimaposvenda,0,"V11");
      Sleep(100);
      return;
     }
   if(possuivenda11 && !possuivenda12 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv12!=0)
     {
      trade.Sell(volnv12,_Symbol,tick.bid,slultimaposvenda,0,"V12");
      Sleep(100);
      return;
     }
   if(possuivenda12 && !possuivenda13 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv13!=0)
     {
      trade.Sell(volnv13,_Symbol,tick.bid,slultimaposvenda,0,"V13");
      Sleep(100);
      return;
     }
   if(possuivenda13 && !possuivenda14 && tick.bid>precoultimavenda+pontosmart*_Point && volumeultimavenda<=500 && volnv14!=0)
     {
      trade.Sell(volnv14,_Symbol,tick.bid,slultimaposvenda,0,"V14");
      Sleep(100);
      return;
     }
  }
//+---------------------------------------------------------------------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//---| AJUSTA O VALOR DE TAKE PROFIT E STOP LOSS PARA POSTERIOR INSERÇÃO NAS ORDENS DE COMPRA/VENDA |---//
//////////////////////////////////////////////////////////////////////////////////////////////////////////
int   QtsMartingale()
  {
   int maximo = 0;
   if(possuicompra1 || possuivenda1)
      maximo = 1;
   if(possuicompra2 || possuivenda2)
      maximo = 2;
   if(possuicompra3 || possuivenda3)
      maximo = 3;
   if(possuicompra4 || possuivenda4)
      maximo = 4;
   if(possuicompra5 || possuivenda5)
      maximo = 5;
   if(possuicompra6 || possuivenda6)
      maximo = 6;
   if(possuicompra7 || possuivenda7)
      maximo = 7;
   if(possuicompra8 || possuivenda8)
      maximo = 8;
   if(possuicompra9 || possuivenda9)
      maximo = 9;
   if(possuicompra10 || possuivenda10)
      maximo = 10;
   if(possuicompra11 || possuivenda11)
      maximo = 11;
   if(possuicompra12 || possuivenda12)
      maximo = 12;
   if(possuicompra13 || possuivenda13)
      maximo = 13;
   if(possuicompra14 || possuivenda14)
      maximo = 14;
   return maximo;

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
            return(PMV1*(1+percentloss/100));
         if(str=="SLV2")
            return(PMV2*(1+percentloss/100));
         if(str=="SLV3")
            return(PMV3*(1+percentloss/100));
         if(str=="SLV4")
            return(PMV4*(1+percentloss/100));
         if(str=="SLV5")
            return(PMV5*(1+percentloss/100));
         if(str=="SLV6")
            return(PMV6*(1+percentloss/100));
         if(str=="SLV7")
            return(PMV7*(1+percentloss/100));
         if(str=="SLV8")
            return(PMV8*(1+percentloss/100));
         if(str=="SLV9")
            return(PMV9*(1+percentloss/100));
         if(str=="SLV10")
            return(PMV10*(1+percentloss/100));
         if(str=="SLV11")
            return(PMV11*(1+percentloss/100));
         if(str=="SLV12")
            return(PMV12*(1+percentloss/100));
         if(str=="SLV13")
            return(PMV13*(1+percentloss/100));
         if(str=="SLV14")
            return(PMV14*(1+percentloss/100));

         if(str=="SLC0")
            return(tick.ask*(1-percentloss/100));
         if(str=="SLC1")
            return(PMC1*(1-percentloss/100));
         if(str=="SLC2")
            return(PMC2*(1-percentloss/100));
         if(str=="SLC3")
            return(PMC3*(1-percentloss/100));
         if(str=="SLC4")
            return(PMC4*(1-percentloss/100));
         if(str=="SLC5")
            return(PMC5*(1-percentloss/100));
         if(str=="SLC6")
            return(PMC6*(1-percentloss/100));
         if(str=="SLC7")
            return(PMC7*(1-percentloss/100));
         if(str=="SLC8")
            return(PMC8*(1-percentloss/100));
         if(str=="SLC9")
            return(PMC9*(1-percentloss/100));
         if(str=="SLC10")
            return(PMC10*(1-percentloss/100));
         if(str=="SLC11")
            return(PMC11*(1-percentloss/100));
         if(str=="SLC12")
            return(PMC12*(1-percentloss/100));
         if(str=="SLC13")
            return(PMC13*(1-percentloss/100));
         if(str=="SLC14")
            return(PMC14*(1-percentloss/100));
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
            return(PMV1+stoppontos*_Point);
         if(str=="SLV2")
            return(PMV2+stoppontos*_Point);
         if(str=="SLV3")
            return(PMV3+stoppontos*_Point);
         if(str=="SLV4")
            return(PMV4+stoppontos*_Point);
         if(str=="SLV5")
            return(PMV5+stoppontos*_Point);
         if(str=="SLV6")
            return(PMV6+stoppontos*_Point);
         if(str=="SLV7")
            return(PMV7+stoppontos*_Point);
         if(str=="SLV8")
            return(PMV8+stoppontos*_Point);
         if(str=="SLV9")
            return(PMV9+stoppontos*_Point);
         if(str=="SLV10")
            return(PMV10+stoppontos*_Point);
         if(str=="SLV11")
            return(PMV11+stoppontos*_Point);
         if(str=="SLV12")
            return(PMV12+stoppontos*_Point);
         if(str=="SLV13")
            return(PMV13+stoppontos*_Point);
         if(str=="SLV14")
            return(PMV14+stoppontos*_Point);

         if(str=="SLC0")
            return(tick.ask-stoppontos*_Point);
         if(str=="SLC1")
            return(PMC1-stoppontos*_Point);
         if(str=="SLC2")
            return(PMC2-stoppontos*_Point);
         if(str=="SLC3")
            return(PMC3-stoppontos*_Point);
         if(str=="SLC4")
            return(PMC4-stoppontos*_Point);
         if(str=="SLC5")
            return(PMC5-stoppontos*_Point);
         if(str=="SLC6")
            return(PMC6-stoppontos*_Point);
         if(str=="SLC7")
            return(PMC7-stoppontos*_Point);
         if(str=="SLC8")
            return(PMC8-stoppontos*_Point);
         if(str=="SLC9")
            return(PMC9-stoppontos*_Point);
         if(str=="SLC10")
            return(PMC10-stoppontos*_Point);
         if(str=="SLC11")
            return(PMC11-stoppontos*_Point);
         if(str=="SLC12")
            return(PMC12-stoppontos*_Point);
         if(str=="SLC13")
            return(PMC13-stoppontos*_Point);
         if(str=="SLC14")
            return(PMC14-stoppontos*_Point);
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
            return(PMC1*(1+percentgain/100));
         if(str=="TPC2")
            return(PMC2*(1+percentgain/100));
         if(str=="TPC3")
            return(PMC3*(1+percentgain/100));
         if(str=="TPC4")
            return(PMC4*(1+percentgain/100));
         if(str=="TPC5")
            return(PMC5*(1+percentgain/100));
         if(str=="TPC6")
            return(PMC6*(1+percentgain/100));
         if(str=="TPC7")
            return(PMC7*(1+percentgain/100));
         if(str=="TPC8")
            return(PMC8*(1+percentgain/100));
         if(str=="TPC9")
            return(PMC9*(1+percentgain/100));
         if(str=="TPC10")
            return(PMC10*(1+percentgain/100));
         if(str=="TPC11")
            return(PMC11*(1+percentgain/100));
         if(str=="TPC12")
            return(PMC12*(1+percentgain/100));
         if(str=="TPC13")
            return(PMC13*(1+percentgain/100));
         if(str=="TPC14")
            return(PMC14*(1+percentgain/100));

         if(str=="TPV0")
            return(tick.ask*(1-percentgain/100));
         if(str=="TPV1")
            return(PMV1*(1-percentgain/100));
         if(str=="TPV2")
            return(PMV2*(1-percentgain/100));
         if(str=="TPV3")
            return(PMV3*(1-percentgain/100));
         if(str=="TPV4")
            return(PMV4*(1-percentgain/100));
         if(str=="TPV5")
            return(PMV5*(1-percentgain/100));
         if(str=="TPV6")
            return(PMV6*(1-percentgain/100));
         if(str=="TPV7")
            return(PMV7*(1-percentgain/100));
         if(str=="TPV8")
            return(PMV8*(1-percentgain/100));
         if(str=="TPV9")
            return(PMV9*(1-percentgain/100));
         if(str=="TPV10")
            return(PMV10*(1-percentgain/100));
         if(str=="TPV11")
            return(PMV11*(1-percentgain/100));
         if(str=="TPV12")
            return(PMV12*(1-percentgain/100));
         if(str=="TPV13")
            return(PMV13*(1-percentgain/100));
         if(str=="TPV14")
            return(PMV14*(1-percentgain/100));
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
            return(PMC1+pontosc2*_Point);
         if(str=="TPC2")
            return(PMC2+pontosc3*_Point);
         if(str=="TPC3")
            return(PMC3+pontosc4*_Point);
         if(str=="TPC4")
            return(PMC4+pontosc5*_Point);
         if(str=="TPC5")
            return(PMC5+pontosc6*_Point);
         if(str=="TPC6")
            return(PMC6+pontosc7*_Point);
         if(str=="TPC7")
            return(PMC7+pontosc8*_Point);
         if(str=="TPC8")
            return(PMC8+pontosc9*_Point);
         if(str=="TPC9")
            return(PMC9+pontosc10*_Point);
         if(str=="TPC10")
            return(PMC10+pontosc11*_Point);
         if(str=="TPC11")
            return(PMC11+pontosc12*_Point);
         if(str=="TPC12")
            return(PMC12+pontosc13*_Point);
         if(str=="TPC13")
            return(PMC13+pontosc14*_Point);

         if(str=="TPV0")
            return(tick.ask-pontosc1*_Point);
         if(str=="TPV1")
            return(PMV1-pontosc2*_Point);
         if(str=="TPV2")
            return(PMV2-pontosc3*_Point);
         if(str=="TPV3")
            return(PMV3-pontosc4*_Point);
         if(str=="TPV4")
            return(PMV4-pontosc5*_Point);
         if(str=="TPV5")
            return(PMV5-pontosc6*_Point);
         if(str=="TPV6")
            return(PMV6-pontosc7*_Point);
         if(str=="TPV7")
            return(PMV7-pontosc8*_Point);
         if(str=="TPV8")
            return(PMV8-pontosc9*_Point);
         if(str=="TPV9")
            return(PMV9-pontosc10*_Point);
         if(str=="TPV10")
            return(PMV10-pontosc11*_Point);
         if(str=="TPV11")
            return(PMV11-pontosc12*_Point);
         if(str=="TPV12")
            return(PMV12-pontosc13*_Point);
         if(str=="TPV13")
            return(PMV13-pontosc14*_Point);
        }
      if(tipooper==tipohedge)
        {
         if(str=="TPC0")
            return(tick.bid+pontosc1*_Point);
         if(str=="TPC1")
            return(tick.bid+pontosc2*_Point);
         if(str=="TPC2")
            return(tick.bid+pontosc3*_Point);
         if(str=="TPC3")
            return(tick.bid+pontosc4*_Point);
         if(str=="TPC4")
            return(tick.bid+pontosc5*_Point);
         if(str=="TPC5")
            return(tick.bid+pontosc6*_Point);
         if(str=="TPC6")
            return(tick.bid+pontosc7*_Point);
         if(str=="TPC7")
            return(tick.bid+pontosc8*_Point);
         if(str=="TPC8")
            return(tick.bid+pontosc9*_Point);
         if(str=="TPC9")
            return(tick.bid+pontosc10*_Point);
         if(str=="TPC10")
            return(tick.bid+pontosc11*_Point);
         if(str=="TPC11")
            return(tick.bid+pontosc12*_Point);
         if(str=="TPC12")
            return(tick.bid+pontosc13*_Point);
         if(str=="TPC13")
            return(tick.bid+pontosc14*_Point);

         if(str=="TPV0")
            return(tick.ask-pontosc1*_Point);
         if(str=="TPV1")
            return(tick.ask-pontosc2*_Point);
         if(str=="TPV2")
            return(tick.ask-pontosc3*_Point);
         if(str=="TPV3")
            return(tick.ask-pontosc4*_Point);
         if(str=="TPV4")
            return(tick.ask-pontosc5*_Point);
         if(str=="TPV5")
            return(tick.ask-pontosc6*_Point);
         if(str=="TPV6")
            return(tick.ask-pontosc7*_Point);
         if(str=="TPV7")
            return(tick.ask-pontosc8*_Point);
         if(str=="TPV8")
            return(tick.ask-pontosc9*_Point);
         if(str=="TPV9")
            return(tick.ask-pontosc10*_Point);
         if(str=="TPV10")
            return(tick.ask-pontosc11*_Point);
         if(str=="TPV11")
            return(tick.ask-pontosc12*_Point);
         if(str=="TPV12")
            return(tick.ask-pontosc13*_Point);
         if(str=="TPV13")
            return(tick.ask-pontosc14*_Point);
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
bool HorarioPausa1() //VERIFICA SE ESTÁ NO HORÁRIO DE PAUSA DO ROBÔ
  {

// Hora dentro do horário de entradas
   if(hratualstruct.hour >= hrinipausa1.hour && hratualstruct.hour <= hrterpausa1.hour)
     {
      // Hora atual igual a de início
      if(hratualstruct.hour == hrinipausa1.hour)
         // Se minuto atual maior ou igual ao de início => não está no horário de entradas
         if(hratualstruct.min >= hrinipausa1.min)
            return true;
      // Do contrário está no horário de entradas
         else
            return false;

      // Hora atual igual a de término
      if(hratualstruct.hour == hrterpausa1.hour)
         // Se minuto atual menor ou igual ao de término => não está no horário de entradas
         if(hratualstruct.min <= hrterpausa1.min)
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


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
