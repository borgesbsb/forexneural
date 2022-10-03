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
   estrat10,     //[10]NEURAL
   estrat11,     //[11]NEURAL/RSI
   estrat12,     //[12]NEURAL/BOLINGER
   estrat13,     //[13]NEURAL/ENVELOPE
   estrat14,     //[14]NEURAL/SAR
   estrat15,     //[15]TENDÊNCIA
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
input group              "MARTINGALE"
input bool               ativamartingale     = false;        //ATIVA USO DE MARTINGALE
input ENUM_TP_MART       tipomartingale      = mart3;        //TIPO DE MARTINGALE
input int                multiplicador       = 1;            //MULTIPLICADOR P MARTINGALE (N)
input int                qtdecandle          = 2;            //QTOS CANDLES P PX ENTRADA
input group              "ESCOLHA DA ESTRATÉGIA"
input ENUM_TP_ESTRAT     estrategia          = estrat1;      //ESCOLHA A ESTRATÉGIA
input group              "VALORES DEFINIDOS P/ SAR"
input double             stepSAR             = 0.014;        //STEP do SAR
input double             maximumSAR          = 0.14;         //MAXIMUM do SAR
input group              "VALORES DEFINIDOS P/ RSI"
input int                periodorsi          = 14;           //PERIODO P RSI
input int                sobrevrsi           = 70;           //PORCENTAGEM DE SOBREVENDA
input int                sobrecrsi           = 30;           //PORCENTAGEM DE SOBRECOMPRA
input group              "VALORES DEFINIDOS P/ BANDAS DE BOLLINGER"
input int                periodobb           = 14;           //PERIODO P BANDAS DE BOLINGER
input double             desviobb            = 2.0;          //DESVIO P BANDAS DE BOLINGER
input group              "VALORES DEFINIDOS P/ ENVELOPE"
input int                periodm1            = 63;           //PERIODO DA MÉDIA P/ ENVELOPE
input double             tamanhoenvelope     = 150;          //DISTÂNCIA P ENVELOPE
input group              "TENDÊNCIA"
input int                qtdecandlestend     = 5;            //QTDE N ÚLTIMOS TICKS P COMPARAR
input double             prctsingle          = 0.2;          //PERCENTUAL MÍNIMO VAR UMA ORDEM
input double             prctfull            = 75;           //PERCENTUAL MÍNIMO VAR TODAS AS ORDENS
input long               timevar             = 500;          //TEMPO QUE OCORREU A VARIAÇÃO EM MS
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
input group              "BREAKEVEN/TRAILING STOP"
input bool               ativbreak           = false;        //ATIVA BREAKEVEN/TRAILING STOP
input double             pontospxbe          = 5;            //PTOS PX AO TP P ATIVAR BE
input double             pontosbesl          = 10;           //PTOS A MENOS PARA SL NOVO DO BE
input double             pontosts            = 5;            //PTOS P ATIV TS
input double             pontosts2           = 5;            //PTOS SL NOVO DO TS
input group              "GERENCIAMENTO DE RISCO-ATIVAÇÃO DE FUNÇÕES(MINICONTRATO N USAR)"
input bool               fechaordensnozero   = false;        //ATIVA FECHAMENTO NO ZERO A ZERO
input int                qtdezero            = 4;            //QTDE MINIMA ORDENS FECHADAS P/ 0x0
//input bool               ativafechafull      = true;       //ATIVA FECHAMENTO DE ORDENS QNDO LUCRO >=0
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

//--- Variáveis
double                   stopcompra          = 0.0;
double                   stopvenda           = 0.0;
double                   takecompra          = 0.0;
double                   takevenda           = 0.0;
double                   prejudodia          = 0.0;

//--- Definição dos Handles
int                      handlebb,handlersi,handleMM,handleSAR;

//--- Definição do "magic number" do robô
ulong                    magicrobo           = 941;

double                   percent_margem,saldo,capital,lucro_prejuizo,volumemaximo,volumeoper,valoraumento,sarnormalizado0,sarnormalizado1, //
                         slcomprapadrao,slvendapadrao,tpcomprapadrao,tpvendapadrao,previsao,rsi[],bbu[],bbm[],bbd[],mm[],sar[];

//--- Definição das variáveis dos volumes para compra e venda quando utilizar martingale
double                   volnv2,volnv3,volnv4,volnv5,volnv6,volnv7,volnv8,volnv9,volnv10,volnv11,volnv12,volnv13,volnv14;

//--- Definição das variáveis dos preços médios para compra e venda quando utilizar martingale
double                   PM1,PM2,PM3,PM4,PM5,PM6,PM7,PM8,PM9,PM10,PM11,PM12,PM13,PM14;

//--- Variáveis p/ ticks, candles e tempo
MqlTick                  tick, ticks[];
MqlRates                 candle[];
MqlDateTime              hratualstruct,hrinicialstruct,hrfinalstruct,hrfechstruct,hrinipausa1,hrterpausa1;

//--- Classe responsável pela execução das ordens - Ctrade
CTrade                   trade;

//--- Quando for executar backtest com o arquivo gerado da rede neural
CDictionary *dict = new CDictionary();

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
   if(estrategia==estrat1 || estrategia==estrat2 || estrategia==estrat5 || estrategia==estrat7 || estrategia==estrat11)
     {
      handlersi = iRSI(_Symbol,_Period,periodorsi,PRICE_CLOSE);
      ArraySetAsSeries(rsi,true);
     }
   if(estrategia==estrat1 || estrategia==estrat3 || estrategia==estrat5 || estrategia==estrat8 || estrategia==estrat12)
     {
      handlebb = iBands(_Symbol,_Period,periodobb,0,desviobb,PRICE_CLOSE);
      ArraySetAsSeries(bbu,true);
      ArraySetAsSeries(bbm,true);
      ArraySetAsSeries(bbd,true);
     }
   if(estrategia==estrat1 || estrategia==estrat2 || estrategia==estrat3 || estrategia==estrat4 || estrategia==estrat6 || estrategia==estrat13)
     {
      handleMM = iMA(_Symbol,_Period,periodm1,0,MODE_SMA,PRICE_CLOSE);
      ArraySetAsSeries(mm,true);
     }
   if(estrategia==estrat4 || estrategia==estrat9 || estrategia==estrat14)
     {
      handleSAR = iSAR(_Symbol,_Period,stepSAR,maximumSAR);
      ArraySetAsSeries(sar,true);
     }
   if(estrategia==estrat15)
     {
      ArraySetAsSeries(ticks,true);
     }

   ArraySetAsSeries(candle,true);

   if(estrategia==estrat10 || estrategia==estrat11 || estrategia==estrat12 || estrategia==estrat13 || estrategia==estrat14)
     {
      //--- Função para selecionar o arquivo de previsões quando utilizar backtest
      ReadFileToDictCSV("previsoes.csv");
     }

//--- Definição dos preços dos inputs em função do tipo de conta selecionada para ajuste lote
   if(tipoconta==tipocent)
      valoraumento=aumentoprop*100;
   if(tipoconta==tipoprime)
      valoraumento=aumentoprop;

//--- Definição do preço de stoploss padrão quando não utilizar estratégias de SL e TP programados
   slcomprapadrao=0.40000;
   slvendapadrao=100000.00000;

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

//--- Cópia dos dados dos handles para as variáveis, necessários de acordo com a estratégia escolhida
   if(!SymbolInfoTick(_Symbol,tick))
     {
      Alert("Erro ao obter informações de Mqlticks: ", GetLastError());
      return;
     }
   CopyRates(_Symbol,_Period,0,5,candle);

   if(estrategia==estrat15)
      CopyTicks(_Symbol,ticks,COPY_TICKS_ALL/*,aberturacandleatual,4000&*/);

   if(CopyRates(_Symbol,_Period,0,5,candle)<0)
     {
      Alert("Erro ao obter informações de Mqlrates: ", GetLastError());
      return;
     }
   if(estrategia==estrat1 || estrategia==estrat2 || estrategia==estrat5 || estrategia==estrat7 || estrategia==estrat11)
     {
      CopyBuffer(handlersi,0,0,5,rsi);
      if(CopyBuffer(handlersi,0,0,5,rsi)<0)
        {
         Alert("Erro ao copiar dados de RSI: ", GetLastError());
         return;
        }
     }
   if(estrategia==estrat1 || estrategia==estrat3 || estrategia==estrat5 || estrategia==estrat8 || estrategia==estrat12)
     {
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
     }
   if(estrategia==estrat1 || estrategia==estrat2 || estrategia==estrat3 || estrategia==estrat4 || estrategia==estrat6 || estrategia==estrat13)
     {
      CopyBuffer(handleMM,0,0,5,mm);
      if(CopyBuffer(handleMM,0,0,5,mm)<0)
        {
         Alert("Erro ao copiar dados de Média Móvel: ", GetLastError());
         return;
        }
     }
   if(estrategia==estrat4 || estrategia==estrat9 || estrategia==estrat14)
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

   if(NB1.IsNewBar(_Symbol,_Period)) //VERIFICA SE É UM NOVO CANDLE
     {
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
         if(PosAberta("POSSUI","COMPRA","C1") && !PosAberta("POSSUI","COMPRA","C2"))
            PM1 = (tick.ask*volnv2 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*volumeoper)/(volnv2+volumeoper);
         if(PosAberta("POSSUI","COMPRA","C2") && !PosAberta("POSSUI","COMPRA","C3"))
            PM2 = (tick.ask*volnv3 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"))/(volnv3+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"));
         if(PosAberta("POSSUI","COMPRA","C3") && !PosAberta("POSSUI","COMPRA","C4"))
            PM3 = (tick.ask*volnv4 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"))/(volnv4+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"));
         if(PosAberta("POSSUI","COMPRA","C4") && !PosAberta("POSSUI","COMPRA","C5"))
            PM4 = (tick.ask*volnv5 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"))/(volnv5+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"));
         if(PosAberta("POSSUI","COMPRA","C5") && !PosAberta("POSSUI","COMPRA","C6"))
            PM5 = (tick.ask*volnv6 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"))/(volnv6+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"));
         if(PosAberta("POSSUI","COMPRA","C6") && !PosAberta("POSSUI","COMPRA","C7"))
            PM6 = (tick.ask*volnv7 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"))/(volnv7+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"));
         if(PosAberta("POSSUI","COMPRA","C7") && !PosAberta("POSSUI","COMPRA","C8"))
            PM7 = (tick.ask*volnv8 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"))/(volnv8+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"));
         if(PosAberta("POSSUI","COMPRA","C8") && !PosAberta("POSSUI","COMPRA","C9"))
            PM8 = (tick.ask*volnv9 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"))/(volnv9+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"));
         if(PosAberta("POSSUI","COMPRA","C9") && !PosAberta("POSSUI","COMPRA","C10"))
            PM9 = (tick.ask*volnv10 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"))/(volnv10+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"));
         if(PosAberta("POSSUI","COMPRA","C10") && !PosAberta("POSSUI","COMPRA","C11"))
            PM10 = (tick.ask*volnv11 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"))/(volnv11+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"));
         if(PosAberta("POSSUI","COMPRA","C11") && !PosAberta("POSSUI","COMPRA","C12"))
            PM11 = (tick.ask*volnv12 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"))/(volnv12+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"));
         if(PosAberta("POSSUI","COMPRA","C12") && !PosAberta("POSSUI","COMPRA","C13"))
            PM12 = (tick.ask*volnv13 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"))/(volnv13+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"));
         if(PosAberta("POSSUI","COMPRA","C13") && !PosAberta("POSSUI","COMPRA","C14"))
            PM13 = (tick.ask*volnv14 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"))/(volnv14+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA"));

         if(PosAberta("POSSUI","VENDA","V1") && !PosAberta("POSSUI","VENDA","V2"))
            PM1 = (tick.bid*volnv2 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*volumeoper)/(volnv2+volumeoper);
         if(PosAberta("POSSUI","VENDA","V2") && !PosAberta("POSSUI","VENDA","V3"))
            PM2 = (tick.bid*volnv3 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"))/(volnv3+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"));
         if(PosAberta("POSSUI","VENDA","V3") && !PosAberta("POSSUI","VENDA","V4"))
            PM3 = (tick.bid*volnv4 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"))/(volnv4+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"));
         if(PosAberta("POSSUI","VENDA","V4") && !PosAberta("POSSUI","VENDA","V5"))
            PM4 = (tick.bid*volnv5 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"))/(volnv5+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"));
         if(PosAberta("POSSUI","VENDA","V5") && !PosAberta("POSSUI","VENDA","V6"))
            PM5 = (tick.bid*volnv6 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"))/(volnv6+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"));
         if(PosAberta("POSSUI","VENDA","V6") && !PosAberta("POSSUI","VENDA","V7"))
            PM6 = (tick.bid*volnv7 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"))/(volnv7+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"));
         if(PosAberta("POSSUI","VENDA","V7") && !PosAberta("POSSUI","VENDA","V8"))
            PM7 = (tick.bid*volnv8 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"))/(volnv8+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"));
         if(PosAberta("POSSUI","VENDA","V8") && !PosAberta("POSSUI","VENDA","V9"))
            PM8 = (tick.bid*volnv9 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"))/(volnv9+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"));
         if(PosAberta("POSSUI","VENDA","V9") && !PosAberta("POSSUI","VENDA","V10"))
            PM9 = (tick.bid*volnv10 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"))/(volnv10+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"));
         if(PosAberta("POSSUI","VENDA","V10") && !PosAberta("POSSUI","VENDA","V11"))
            PM10 = (tick.bid*volnv11 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"))/(volnv11+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"));
         if(PosAberta("POSSUI","VENDA","V11") && !PosAberta("POSSUI","VENDA","V12"))
            PM11 = (tick.bid*volnv12 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"))/(volnv12+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"));
         if(PosAberta("POSSUI","VENDA","V12") && !PosAberta("POSSUI","VENDA","V13"))
            PM12 = (tick.bid*volnv13 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"))/(volnv13+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"));
         if(PosAberta("POSSUI","VENDA","V13") && !PosAberta("POSSUI","VENDA","V14"))
            PM13 = (tick.bid*volnv14 + DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")*DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"))/(volnv14+DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA"));
        }
     }

//--- AJUSTA HORA ATUAL PARA O FORMATO STRUCT E RECEBE O HORÁRIO DE ABERTURA DO CANDLE ATUAL
   TimeToStruct(TimeCurrent(),hratualstruct);
   datetime aberturacandleatual=datetime(SeriesInfoInteger(_Symbol,_Period,SERIES_LASTBAR_DATE));

//--- SE ESTRATÉGIA QUE UTILIZA SAR FOR ESCOLHIDA, ARMAZENA O VALOR DOS 2 ÚLTIMOS VALORES DE SAR
   if(estrategia==estrat4 || estrategia==estrat9 || estrategia==estrat14)
     {
      sarnormalizado0 = NormalizeDouble(sar[0],5);
      sarnormalizado1 = NormalizeDouble(sar[1],5);
     }

//--- SE UTILIZAR DICIONARIO PARA TESTE DE ESTRATÉGIA QUE UTILIZA NEURAL, ARMAZENA NA VARIÁVEL A PREVISÃO DO HORARIO
   if(estrategia==estrat10 || estrategia==estrat11 || estrategia==estrat12 || estrategia==estrat13 || estrategia==estrat14)
      previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);

////////////////////////////////////////////
//---| FECHA ORDENS NO FIM DO PREGÃO |----//
////////////////////////////////////////////
   if(ativafecfinaldia)
     {
      if(PositionsTotal()>=1)
         if((PosAberta("POSSUI","COMPRA","")||PosAberta("POSSUI","VENDA","")) && hratualstruct.hour==hrfechstruct.hour && hratualstruct.min==hrfechstruct.min)
            FechaTodasPosicoesAbertas();
     }

////////////////////////////////////////////////////////////////////////////////////////////////////
//---| FECHA TODAS AS ORDENS COM LUCROS MAIORES OU IGUAIS A ZERO QNDO TARGETS FOREM ATINGIDO |----//
////////////////////////////////////////////////////////////////////////////////////////////////////
//   if(ativafechafull==true)
//     {
//      FechaPosAbertasNoLucro();
//     }

///////////////////////////////////////////////////
//---| FECHA ORDENS PRA SAIR NO ZERO A ZERO |----//
///////////////////////////////////////////////////
   if(fechaordensnozero)
      if(PositionsTotal()>=1)
         FechaOrdensNozero();

//+------------------------------------------------------------------+
//| OPERAÇÕES SEGUINDO A ESTRATÉGIA ESCOLHIDA |
//+------------------------------------------------------------------+

//--- Check de posição aberta em outro ativo, horário de operação, margem suficiente pra operar e se o número de stops setado nos inputs já foram alcançados
   if(ativaentradaea && !PossuiPosAbertaOutroAtivo() && HorarioEntrada() && !HorarioPausa1() /*&& DadosPosFechada("QTDE DE SL DO DIA","")<somapreju*/ && //
      (percent_margem>prcentabert||saldo==capital))
     {
      //--- Verifica se candle acabou de abrir
      if(NB2.IsNewBar(_Symbol,_Period))
        {
         ////////////////////////////////////////////////
         //---| PRIMEIRA COMPRA DE CADA ESTRATÉGIA |---//
         ////////////////////////////////////////////////
         if(!PosAberta("POSSUI","COMPRA",""))
           {
            //---| ESTRATEGIA ENVELOPE/RSI/BOLINGER |---//
            if(estrategia==estrat1)
              {
               if(candle[1].close<mm[1]-tamanhoenvelope*_Point && rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/ && candle[1].close<bbd[1])
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA ENVELOPE/RSI |---//
            if(estrategia==estrat2)
              {
               if(candle[1].close<mm[1]-tamanhoenvelope*_Point && rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA ENVELOPE/BOLINGER |---//
            if(estrategia==estrat3)
              {
               if(candle[1].close<mm[1]-tamanhoenvelope*_Point && candle[1].close<bbd[1])
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA ENVELOPE/SAR |---//
            if(estrategia==estrat4)
              {
               if(candle[1].close<mm[1]-tamanhoenvelope*_Point && sarnormalizado0 < tick.ask && sarnormalizado1 < tick.ask)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA RSI/BOLINGER |---//
            if(estrategia==estrat5)
              {
               if(rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/ && candle[1].close<bbd[1])
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA ENVELOPE |---//
            if(estrategia==estrat6)
              {
               if(candle[1].close<mm[1]-tamanhoenvelope*_Point)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA RSI |---//
            if(estrategia==estrat7)
              {
               if(rsi[1]<sobrecrsi/* && rsi[0]>sobrecrsi*/)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA BOLINGER |---//
            if(estrategia==estrat8)
              {
               if(candle[1].close<bbd[1])
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA SAR |---//
            if(estrategia==estrat9)
              {
               if(sarnormalizado0 < tick.ask && sarnormalizado1 < tick.ask)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA NEURAL |---//
            if(estrategia==estrat10)
              {
               if(previsao > tick.ask && previsao != 0)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA NEURAL/RSI |---//
            if(estrategia==estrat11)
              {
               if(previsao > tick.ask && previsao != 0 && rsi[1]<sobrecrsi)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA NEURAL/BOLINGER |---//
            if(estrategia==estrat12)
              {
               if(previsao > tick.ask && previsao != 0 && candle[1].close<bbd[1])
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA NEURAL/ENVELOPE |---//
            if(estrategia==estrat13)
              {
               if(previsao > tick.ask && previsao != 0 && candle[1].close<mm[1]-tamanhoenvelope*_Point)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
            //---| ESTRATEGIA NEURAL/SAR |---//
            if(estrategia==estrat14)
              {
               if(previsao > tick.ask && previsao != 0 && sarnormalizado0 < tick.ask && sarnormalizado1 < tick.ask)
                  trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"C1");
              }
           }

         ///////////////////////////////////////////////
         //---| PRIMEIRA VENDA DE CADA ESTRATÉGIA |---//
         ///////////////////////////////////////////////
         if(!PosAberta("POSSUI","VENDA",""))
           {
            //---| ESTRATEGIA ENVELOPE/RSI/BOLINGER |---//
            if(estrategia==estrat1)
              {
               if(candle[1].close>mm[1]+tamanhoenvelope*_Point && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ && candle[1].close>bbu[1])
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA ENVELOPE/RSI |---//
            if(estrategia==estrat2)
              {
               if(candle[1].close>mm[1]+tamanhoenvelope*_Point && rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA ENVELOPE/BOLINGER |---//
            if(estrategia==estrat3)
              {
               if(candle[1].close>mm[1]+tamanhoenvelope*_Point && candle[1].close>bbu[1])
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA ENVELOPE/SAR |---//
            if(estrategia==estrat4)
              {
               if(candle[1].close>mm[1]+tamanhoenvelope*_Point && sarnormalizado0 > tick.bid && sarnormalizado1 > tick.bid)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA RSI/BOLINGER |---//
            if(estrategia==estrat5)
              {
               if(rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/ && candle[1].close>bbu[1])
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA ENVELOPE |---//
            if(estrategia==estrat6)
              {
               if(candle[1].close>mm[1]+tamanhoenvelope*_Point)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA RSI |---//
            if(estrategia==estrat7)
              {
               if(rsi[1]>sobrevrsi/* && rsi[0]<sobrevrsi*/)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA BOLINGER |---//
            if(estrategia==estrat8)
              {
               if(candle[1].close>bbu[1])
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA SAR |---//
            if(estrategia==estrat9)
              {
               if(sarnormalizado0 > tick.bid && sarnormalizado1 > tick.bid)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA NEURAL |---//
            if(estrategia==estrat10)
              {
               if(previsao < tick.bid && previsao !=0)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA NEURAL/RSI |---//
            if(estrategia==estrat11)
              {
               if(previsao < tick.bid && previsao !=0 && rsi[1]>sobrevrsi)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA NEURAL/BOLINGER |---//
            if(estrategia==estrat12)
              {
               if(previsao < tick.bid && previsao !=0 && candle[1].close>bbu[1])
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA NEURAL/ENVELOPE |---//
            if(estrategia==estrat13)
              {
               if(previsao < tick.bid && previsao !=0 && candle[1].close>mm[1]+tamanhoenvelope*_Point)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
            //---| ESTRATEGIA NEURAL/SAR |---//
            if(estrategia==estrat14)
              {
               if(previsao < tick.bid && previsao != 0 && sarnormalizado0 > tick.bid && sarnormalizado1 > tick.bid)
                  trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"V1");
              }
           }

         ////////////////////////////////////////////////////////////////////////////////////
         //---| DEMAIS COMPRAS E VENDAS DE CADA ESTATÉGIA - CASO MARTINGALE HABILITADO |---//
         ////////////////////////////////////////////////////////////////////////////////////
         if(ativamartingale)
           {
            if(PositionsTotal()>=1 /*&& condicaoSAR==true*/ && ((PosAberta("POSSUI","COMPRA","") && QtdeCandles("COMPRA")>qtdecandle) || //
                  (PosAberta("POSSUI","VENDA","") && QtdeCandles("VENDA")>qtdecandle)))
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
                  if(sarnormalizado0 < tick.ask && sarnormalizado1 < tick.ask)
                     ComprasMartingale();
                  if(sarnormalizado0 > tick.bid && sarnormalizado1 > tick.bid)
                     VendasMartingale();
                 }
               //---| ESTRATEGIA NEURAL |---//
               if(estrategia==estrat10)
                 {
                  if(previsao > tick.ask && previsao != 0)
                     ComprasMartingale();
                  if(previsao < tick.bid && previsao !=0)
                     VendasMartingale();
                 }
               //---| ESTRATEGIA NEURAL/RSI |---//
               if(estrategia==estrat11)
                 {
                  if(previsao > tick.ask && previsao != 0 && rsi[1]<sobrecrsi)
                     ComprasMartingale();
                  if(previsao < tick.bid && previsao !=0 && rsi[1]>sobrevrsi)
                     VendasMartingale();
                 }
               //---| ESTRATEGIA NEURAL/BOLINGER |---//
               if(estrategia==estrat12)
                 {
                  if(previsao > tick.ask && previsao != 0 && candle[1].close<bbd[1])
                     ComprasMartingale();
                  if(previsao < tick.bid && previsao !=0 && candle[1].close>bbu[1])
                     VendasMartingale();
                 }
               //---| ESTRATEGIA NEURAL/ENVELOPE |---//
               if(estrategia==estrat13)
                 {
                  if(previsao > tick.ask && previsao != 0 && candle[1].close<mm[1]-tamanhoenvelope*_Point)
                     ComprasMartingale();
                  if(previsao < tick.bid && previsao !=0 && candle[1].close>mm[1]+tamanhoenvelope*_Point)
                     VendasMartingale();
                 }
               //---| ESTRATEGIA NEURAL/SAR |---//
               if(estrategia==estrat14)
                 {
                  if(previsao > tick.ask && previsao != 0 && sarnormalizado0 < tick.ask && sarnormalizado1 < tick.ask)
                     ComprasMartingale();
                  if(previsao < tick.bid && previsao != 0 && sarnormalizado0 > tick.bid && sarnormalizado1 > tick.bid)
                     VendasMartingale();
                 }
              }
           }

         //---| ESTRATEGIA TENDÊNCIA |---//
         if(estrategia==estrat15)
           {
            if(ProbTicks("COMPRA") && (!PosAberta("POSSUI","COMPRA","BE COMPRA") && !PosAberta("POSSUI","VENDA","BE VENDA")))
              {
               trade.Buy(volumeoper,_Symbol,tick.ask,puxatpsl("SLC0"),puxatpsl("TPC0"),"BE COMPRA");
               Sleep(500);
              }
            if(ProbTicks("VENDA") && (!PosAberta("POSSUI","COMPRA","BE COMPRA") && !PosAberta("POSSUI","VENDA","BE VENDA")))
              {
               trade.Sell(volumeoper,_Symbol,tick.bid,puxatpsl("SLV0"),puxatpsl("TPV0"),"BE VENDA");
               Sleep(500);
              }
           }
        }
     }

///////////////////////
//---|STOP FULL |----//
///////////////////////
   if(ativastopfull)
      prejudodia = DadosPos("PREJUÍZO DO DIA","");
   if(MathAbs(prejudodia)/capital*100>=percentfull && prejudodia<0 && saldo!=capital)
     {
      FechaTodasPosicoesAbertas();
      Sleep(500);
      return;
     }

///////////////////////////////////////////////
//---|FECHAMENTO DA ORDENS - SAR REVERSO|----//
///////////////////////////////////////////////
//   if(ativasaidaea==true)
//     {
//      if(estrategia==estrat9 || estrategia==estrat14)
//         if((PosAberta("POSSUI","COMPRA","C1") && sarnormalizado0 > tick.bid) || (PosAberta("POSSUI","VENDA","V1") && sarnormalizado0 < tick.ask))
//            FechaTodasPosicoesAbertas();
//     }

/////////////////////////////////////////////////////////////////////////////////////
//---|FECHAMENTO DA ORDENS CRIADAS ERRADAMENTE - CORREÇÃO PARA CORRETORA CLEAR|----//
/////////////////////////////////////////////////////////////////////////////////////
   if(estrategia==estrat9 || estrategia==estrat14)
     {
      if(PosAberta("POSSUI","COMPRA",""))
         if((DadosPos("SL DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")==0) || (PosAberta("POSSUI","VENDA","") && DadosPos("SL DA ÚLTIMA POSIÇÃO ABERTA","VENDA")==0))
            FechaTodasPosicoesAbertas();
     }

////////////////////////////
//---|BREAKEVEN E TS |----//
////////////////////////////
   if(ativbreak)
     {
      if(PosAberta("POSSUI","COMPRA","") && tick.bid>=DadosPos("TP DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")-pontospxbe*_Point && DadosPos("TP DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")!=0)
        {
         trade.PositionModify(_Symbol,tick.bid-pontosbesl*_Point,0);
        }
      if(PosAberta("POSSUI","VENDA","") && tick.ask<=DadosPos("PREÇO DA ÚLTIMA POSIÇÃO ABERTA","VENDA")+pontospxbe*_Point && DadosPos("TP DA ÚLTIMA POSIÇÃO ABERTA","VENDA")!=0)
        {
         trade.PositionModify(_Symbol,tick.ask+pontosbesl*_Point,0);
        }
      if(PosAberta("POSSUI","COMPRA","") && tick.bid>=DadosPos("SL DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")+pontosts*_Point && DadosPos("TP DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")==0)
        {
         trade.PositionModify(_Symbol,DadosPos("SL DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")+pontosts2*_Point,0);
        }
      if(PosAberta("POSSUI","VENDA","") && tick.ask<=DadosPos("SL DA ÚLTIMA POSIÇÃO ABERTA","VENDA")-pontosts*_Point && DadosPos("TP DA ÚLTIMA POSIÇÃO ABERTA","VENDA")==0)
        {
         trade.PositionModify(_Symbol,DadosPos("SL DA ÚLTIMA POSIÇÃO ABERTA","VENDA")-pontosts2*_Point,0);
        }

      /*      if(PosFechadaTrueFalse("ÚLTIMA POSIÇÃO FECHADA FOI DE TP","COMPRA") && PosAberta("POSSUI","COMPRA","BE COMPRA")==false)
              {
               trade.Buy(DadosPosFechada("VOLUME DA ÚLTIMA POSIÇÃO FECHADA","COMPRA"),_Symbol,tick.ask,tick.bid-pontosbesl*_Point,NULL,"BE COMPRA");
               Sleep(200);
              }
            if(PosAberta("POSSUI","COMPRA","BE COMPRA") && tick.bid>DadosPos("SL DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")+pontosts*_Point)
              {
               trade.PositionModify(TicketPosAberta(),DadosPos("SL DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")+pontosts2*_Point,NULL);
              }

            if(PosFechadaTrueFalse("ÚLTIMA POSIÇÃO FECHADA FOI DE TP","VENDA") && PosAberta("POSSUI","VENDA","BE VENDA")==false)
              {
               trade.Sell(DadosPosFechada("VOLUME DA ÚLTIMA POSIÇÃO FECHADA","VENDA"),_Symbol,tick.bid,tick.ask+pontosbesl*_Point,NULL,"BE VENDA");
               Sleep(200);
              }
            if(PosAberta("POSSUI","VENDA","BE VENDA") && tick.ask<DadosPos("SL DA ÚLTIMA POSIÇÃO ABERTA","VENDA")-pontosts*_Point)
              {
               trade.PositionModify(TicketPosAberta(),DadosPos("SL DA ÚLTIMA POSIÇÃO ABERTA","VENDA")-pontosts2*_Point,NULL);
              }
      */
     }
  }

////////////////////////////
//| FIM DA FUNÇÃO ONTICK |//
////////////////////////////

//+------------------------------------------------------------------------------------------------------------------------------------------------+

/////////////////////////////////////
//| INÍCIO DAS FUNÇÕES AUXILIARES |//
/////////////////////////////////////
//+-------------------------------------------------------------------------------+
//|VERIFICA A PROBABILIDADE DE COMPRA/VENDA ATRAVÉS DA VARIAÇÃO DOS TICKS NO TEMPO|
//+-------------------------------------------------------------------------------+
bool ProbTicks(string tipo)
  {
   bool tempook = false;
   long ultimotick=0;
   long primeirotick=0;
   double varcompra=0;
   double varvenda=0;
   double favoravelcompra=0;
   double favoravelvenda=0;
   double percentfavorcompra=0;
   double percentfavorvenda=0;

   if(tipo=="COMPRA")
     {
      for(int i=0; i<qtdecandlestend-1; i++)
        {
         varcompra = NormalizeDouble(((ticks[i].ask-ticks[qtdecandlestend-1].ask)/ticks[qtdecandlestend-1].ask*100),4);
         if(varcompra>(prctsingle/100))
            favoravelcompra++;
         if(i==0)
            ultimotick = ticks[i].time_msc;
         if(i==qtdecandlestend-2 && ultimotick<ticks[i].time_msc+timevar)
           {
            primeirotick = ticks[i].time_msc;
            tempook = true;
           }
         percentfavorcompra = NormalizeDouble((favoravelcompra/qtdecandlestend*100),2);
        }
     }
//   if(percentfavorcompra*100>prctfull && !PosAberta("POSSUI","COMPRA","BE COMPRA"))
//      trade.Buy(0.01,_Symbol,tick.ask,tick.bid-pontosbesl*_Point,0,"BE COMPRA");

   if(tipo=="VENDA")
     {
      for(int i=0; i<qtdecandlestend-1; i++)
        {
         varvenda = NormalizeDouble(((ticks[i].bid-ticks[qtdecandlestend-1].bid)/ticks[qtdecandlestend-1].bid*100),4);
         if(varvenda<-1*(prctsingle/100))
            favoravelvenda++;
         if(i==0)
            ultimotick = ticks[i].time_msc;
         if(i==qtdecandlestend-2 && ultimotick<ticks[i].time_msc+timevar)
           {
            primeirotick = ticks[i].time_msc;
            tempook = true;
           }
        }
      percentfavorvenda = NormalizeDouble((favoravelvenda/qtdecandlestend*100),2);
     }
//   if(percentfavorvenda*100>prctfull && !PosAberta("POSSUI","VENDA","BE VENDA"))
//      trade.Sell(0.01,_Symbol,tick.bid,tick.ask+pontosbesl*_Point,0,"BE VENDA");
   Print(" Probabilidade de Compra: ",percentfavorcompra," Probabilidade de venda: ",percentfavorvenda);
   if((tipo=="COMPRA" && percentfavorcompra>=prctfull && tempook) || (tipo=="VENDA" && percentfavorvenda>=prctfull && tempook))
     {
      Print("Hora ultimo tick: ",ultimotick," Hora primeiro tick: ",primeirotick," Ultimo menos o primeiro: ",ultimotick-primeirotick," Hora máxima da condição: ",primeirotick+timevar);
      return true;
     }

   return false;
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
//+------------------------------------------------------------------------------------------+
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
int   QtdeCandles(string tipo)
  {
   int qtdebars=0;
   if(PosAberta("POSSUI","COMPRA","") && tipo=="COMPRA")
      qtdebars = Bars(_Symbol,_Period,DataHoraUltPosAberta("COMPRA"),TimeCurrent());
   if(PosAberta("POSSUI","VENDA","") && tipo=="VENDA")
      qtdebars = Bars(_Symbol,_Period,DataHoraUltPosAberta("VENDA"),TimeCurrent());
   return qtdebars;
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
      string symbol = PositionGetString(POSITION_SYMBOL);
      //ulong  magic = PositionGetInteger(POSITION_MAGIC);
      ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if((TipoPosicao==POSITION_TYPE_SELL||TipoPosicao==POSITION_TYPE_BUY) && symbol==_Symbol /*&& magic == magicrobo*/)
         trade.PositionClose(ticket);
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
   Sleep(200);
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
   if(PosAberta("POSSUI","COMPRA","") && tipo=="COMPRA")
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
   if(PosAberta("POSSUI","VENDA","") && tipo=="VENDA")
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
datetime DataHoraUltPosFechada(string tipo)
  {
   datetime timedefault=D'2000.01.01 01:00';
   if(PosFechadaTrueFalse("ÚLTIMA POSIÇÃO FECHADA FOI DE TP","COMPRA"))
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
            if(type==DEAL_TYPE_SELL && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               return time;
               break;
              }
           }
        }
     }
   if(PosFechadaTrueFalse("ÚLTIMA POSIÇÃO FECHADA FOI DE TP","VENDA"))
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

   return timedefault;
  }
//+------------------------------------------------------------------+
//+-----------------------------------------------------+
//| RETORNA OS DADOS RELACIONADOS AS POSIÇÕES FECHADAS |
//+-----------------------------------------------------+
double DadosPosFechada(string acao, string tipo)
  {
   double      qtdeordens=0;
   ulong       ticket=0;
   double      profit=0;
   double      profit1=0;
   double      volume=0;
   double      volume1=0;
   double      preco=0;
   double      pontossldia=0;
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
               if(acao=="PROFIT DA ÚLTIMA POSIÇÃO FECHADA")
                 {
                  if(time>time1)
                    {
                     time1=time;
                     profit1=profit;
                    }
                 }
               if(acao=="VOLUME DA ÚLTIMA POSIÇÃO FECHADA")
                 {
                  if(time>time1)
                    {
                     time1=time;
                     volume1=volume;
                    }
                 }
               if(acao=="QTDE DE POSIÇÕES FECHADAS APÓS A ULTIMA POSIÇÃO ABERTA")
                 {
                  if(tempopos!=D'2000.01.01 01:00')
                    {
                     if(time>tempopos)
                        qtdeordens++;
                    }
                  else
                     tempopos = DataHoraUltPosAberta("COMPRA");
                 }
              }
           }
         if(tipo=="VENDA")
           {
            if(type==DEAL_TYPE_BUY && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               if(acao=="PROFIT DA ÚLTIMA POSIÇÃO FECHADA")
                 {
                  if(time>time1)
                    {
                     time1=time;
                     profit1=profit;
                    }
                 }
               if(acao=="VOLUME DA ÚLTIMA POSIÇÃO FECHADA")
                 {
                  if(time>time1)
                    {
                     time1=time;
                     volume1=volume;
                    }
                 }
               if(acao=="QTDE DE POSIÇÕES FECHADAS APÓS A ULTIMA POSIÇÃO ABERTA")
                 {
                  if(tempopos!=D'2000.01.01 01:00')
                    {
                     if(time>tempopos)
                        qtdeordens++;
                    }
                  else
                     tempopos = DataHoraUltPosAberta("VENDA");
                 }
              }
           }
         if(acao=="QTDE DE SL DO DIA")
           {
            MqlDateTime timestruct;
            TimeToStruct(time,timestruct);
            if(timestruct.day==hratualstruct.day && profit<0 && entry==DEAL_ENTRY_OUT && symbol==_Symbol)
              {
               ulong ticket1=HistoryDealGetTicket(i-1);
               double preco1 = HistoryDealGetDouble(ticket1,DEAL_PRICE);
               pontossldia = pontossldia+MathAbs(preco-preco1);
              }
           }
        }
      else
         break;
     }
   if(acao=="PROFIT DA ÚLTIMA POSIÇÃO FECHADA")
      return profit1;
   if(acao=="VOLUME DA ÚLTIMA POSIÇÃO FECHADA")
      return volume1;
   if(acao=="QTDE DE POSIÇÕES FECHADAS APÓS A ULTIMA POSIÇÃO ABERTA")
      return qtdeordens;
   if(acao=="QTDE DE SL DO DIA")
      return pontossldia;
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
               if(acao=="EXISTE AO MENOS UMA POSIÇÃO FECHADA")
                 {
                  condicao=true;
                 }
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
               if(acao=="EXISTE AO MENOS UMA POSIÇÃO FECHADA")
                 {
                  condicao=true;
                 }
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
        }
     }

   return condicao;
  }
//+------------------------------------------------------------------------------------------+
//////////////////////////////////////////
//---|COMPRAS NORMAIS COM MARTINGALE|---//
//////////////////////////////////////////
void  ComprasMartingale()
  {
   if(PosAberta("POSSUI","COMPRA","C1") && !PosAberta("POSSUI","COMPRA","C2") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv2!=0)
     {
      trade.Buy(volnv2,_Symbol,tick.ask,puxatpsl("SLC1"),puxatpsl("TPC1"),"C2");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","COMPRA","C2") && !PosAberta("POSSUI","COMPRA","C3") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv3!=0)
     {
      trade.Buy(volnv3,_Symbol,tick.ask,puxatpsl("SLC2"),puxatpsl("TPC2"),"C3");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","COMPRA","C3") && !PosAberta("POSSUI","COMPRA","C4") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv4!=0)
     {
      trade.Buy(volnv4,_Symbol,tick.ask,puxatpsl("SLC3"),puxatpsl("TPC3"),"C4");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","COMPRA","C4") && !PosAberta("POSSUI","COMPRA","C5") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv5!=0)
     {
      trade.Buy(volnv5,_Symbol,tick.ask,puxatpsl("SLC4"),puxatpsl("TPC4"),"C5");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","COMPRA","C5") && !PosAberta("POSSUI","COMPRA","C6") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv6!=0)
     {
      trade.Buy(volnv6,_Symbol,tick.ask,puxatpsl("SLC5"),puxatpsl("TPC5"),"C6");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","COMPRA","C6") && !PosAberta("POSSUI","COMPRA","C7") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv7!=0)
     {
      trade.Buy(volnv7,_Symbol,tick.ask,puxatpsl("SLC6"),puxatpsl("TPC6"),"C7");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","COMPRA","C7") && !PosAberta("POSSUI","COMPRA","C8") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv8!=0)
     {
      trade.Buy(volnv8,_Symbol,tick.ask,puxatpsl("SLC7"),puxatpsl("TPC7"),"C8");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","COMPRA","C8") && !PosAberta("POSSUI","COMPRA","C9") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv9!=0)
     {
      trade.Buy(volnv9,_Symbol,tick.ask,puxatpsl("SLC8"),puxatpsl("TPC8"),"C9");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","COMPRA","C9") && !PosAberta("POSSUI","COMPRA","C10") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv10!=0)
     {
      trade.Buy(volnv10,_Symbol,tick.ask,puxatpsl("SLC9"),puxatpsl("TPC9"),"C10");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","COMPRA","C10") && !PosAberta("POSSUI","COMPRA","C11") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv11!=0)
     {
      trade.Buy(volnv11,_Symbol,tick.ask,puxatpsl("SLC10"),puxatpsl("TPC10"),"C11");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","COMPRA","C11") && !PosAberta("POSSUI","COMPRA","C12") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv12!=0)
     {
      trade.Buy(volnv12,_Symbol,tick.ask,puxatpsl("SLC11"),puxatpsl("TPC11"),"C12");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","COMPRA","C12") && !PosAberta("POSSUI","COMPRA","C13") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv13!=0)
     {
      trade.Buy(volnv13,_Symbol,tick.ask,puxatpsl("SLC12"),puxatpsl("TPC12"),"C13");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","COMPRA","C13") && !PosAberta("POSSUI","COMPRA","C14") && tick.ask<DadosPos("PREÇO DA MENOR POSIÇÃO ABERTA","COMPRA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","COMPRA")<=500 && volnv14!=0)
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
   if(PosAberta("POSSUI","VENDA","V1") && !PosAberta("POSSUI","VENDA","V2") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv2!=0)
     {
      trade.Sell(volnv2,_Symbol,tick.bid,puxatpsl("SLV1"),puxatpsl("TPV1"),"V2");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","VENDA","V2") && !PosAberta("POSSUI","VENDA","V3") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv3!=0)
     {
      trade.Sell(volnv3,_Symbol,tick.bid,puxatpsl("SLV2"),puxatpsl("TPV2"),"V3");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","VENDA","V3") && !PosAberta("POSSUI","VENDA","V4") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv4!=0)
     {
      trade.Sell(volnv4,_Symbol,tick.bid,puxatpsl("SLV3"),puxatpsl("TPV3"),"V4");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","VENDA","V4") && !PosAberta("POSSUI","VENDA","V5") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv5!=0)
     {
      trade.Sell(volnv5,_Symbol,tick.bid,puxatpsl("SLV4"),puxatpsl("TPV4"),"V5");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","VENDA","V5") && !PosAberta("POSSUI","VENDA","V6") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv6!=0)
     {
      trade.Sell(volnv6,_Symbol,tick.bid,puxatpsl("SLV5"),puxatpsl("TPV5"),"V6");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","VENDA","V6") && !PosAberta("POSSUI","VENDA","V7") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv7!=0)
     {
      trade.Sell(volnv7,_Symbol,tick.bid,puxatpsl("SLV6"),puxatpsl("TPV6"),"V7");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","VENDA","V7") && !PosAberta("POSSUI","VENDA","V8") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv8!=0)
     {
      trade.Sell(volnv8,_Symbol,tick.bid,puxatpsl("SLV7"),puxatpsl("TPV7"),"V8");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","VENDA","V8") && !PosAberta("POSSUI","VENDA","V9") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv9!=0)
     {
      trade.Sell(volnv9,_Symbol,tick.bid,puxatpsl("SLV8"),puxatpsl("TPV8"),"V9");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","VENDA","V9") && !PosAberta("POSSUI","VENDA","V10") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv10!=0)
     {
      trade.Sell(volnv10,_Symbol,tick.bid,puxatpsl("SLV9"),puxatpsl("TPV9"),"V10");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","VENDA","V10") && !PosAberta("POSSUI","VENDA","V11") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv11!=0)
     {
      trade.Sell(volnv11,_Symbol,tick.bid,puxatpsl("SLV10"),puxatpsl("TPV10"),"V11");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","VENDA","V11") && !PosAberta("POSSUI","VENDA","V12") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv12!=0)
     {
      trade.Sell(volnv12,_Symbol,tick.bid,puxatpsl("SLV11"),puxatpsl("TPV11"),"V12");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","VENDA","V12") && !PosAberta("POSSUI","VENDA","V13") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv13!=0)
     {
      trade.Sell(volnv13,_Symbol,tick.bid,puxatpsl("SLV12"),puxatpsl("TPV12"),"V13");
      Sleep(500);
      return;
     }
   if(PosAberta("POSSUI","VENDA","V13") && !PosAberta("POSSUI","VENDA","V14") && tick.bid>DadosPos("PREÇO DA MAIOR POSIÇÃO ABERTA","VENDA") && DadosPos("VOLUME DA ÚLTIMA POSIÇÃO ABERTA","VENDA")<=500 && volnv14!=0)
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
//+----------------------------------------------------------------------------------------------------------+
//| FECHA AS POSIÇÕES ABERTAS QUANDO AO MENOS UMA FECHAR NO LUCRO E AS DEMAIS ESTIVEREM COM LUCRO NO MOMENTO |
//+----------------------------------------------------------------------------------------------------------+
void FechaPosAbertasNoLucro()
  {
   if(PosAberta("POSSUI","COMPRA","") && PosFechadaTrueFalse("ÚLTIMA POSIÇÃO FECHADA FOI DE TP","COMPRA"))
     {
      for(int i=PositionsTotal()-1; i >= 0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         string symbol = PositionGetString(POSITION_SYMBOL);
         //ulong  magic = PositionGetInteger(POSITION_MAGIC);
         double LucroPrejuizo = PositionGetDouble(POSITION_PROFIT);
         ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(TipoPosicao==POSITION_TYPE_BUY && symbol==_Symbol && LucroPrejuizo>0)
            trade.PositionClose(ticket);
        }
     }
   if(PosAberta("POSSUI","VENDA","") && PosFechadaTrueFalse("ÚLTIMA POSIÇÃO FECHADA FOI DE TP","VENDA"))
     {
      for(int i=PositionsTotal()-1; i >= 0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         string symbol = PositionGetString(POSITION_SYMBOL);
         //ulong  magic = PositionGetInteger(POSITION_MAGIC);
         double LucroPrejuizo = PositionGetDouble(POSITION_PROFIT);
         ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(TipoPosicao==POSITION_TYPE_SELL && symbol==_Symbol && LucroPrejuizo>0)
            trade.PositionClose(ticket);
        }
     }
  }
//+-------------------------------------------------------------------------------------------------------------+
//| FECHA TODAS AS ORDENS APÓS AS POSIÇÕES ABERTAS DE FORMA QUE NO TOTAL SAIA NO MINIMO NO ZERO A ZERO DE LUCRO |
//+-------------------------------------------------------------------------------------------------------------+
void FechaOrdensNozero()
  {
   if(PosAberta("POSSUI","COMPRA","") && DataHoraUltPosFechada("COMPRA")>DataHoraUltPosAberta("COMPRA") && DadosPosFechada("QTDE DE POSIÇÕES FECHADAS APÓS A ULTIMA POSIÇÃO ABERTA","COMPRA")>=qtdezero)
     {
      HistorySelect(0,TimeCurrent());
      uint     dealstotal=HistoryDealsTotal();
      ulong    ticket=0;
      string   symbol;
      long     entry;
      long     type;
      datetime time;
      double   lucro;
      double   somalucrofechados=0;
      for(uint j=0; j<dealstotal; j++)
        {
         //--- tentar obter ticket negócios
         if((ticket=HistoryDealGetTicket(j))>0)
           {
            //--- obter as propriedades negócios
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            lucro =HistoryDealGetDouble(ticket,DEAL_PROFIT);
            time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
            //--- apenas para o símbolo atual
            if(entry==DEAL_ENTRY_OUT && type==DEAL_TYPE_SELL && symbol==_Symbol /*&& lucro>0*/ && time>DataHoraUltPosAberta("COMPRA"))
               somalucrofechados = somalucrofechados + lucro;
           }
        }
      if(PositionsTotal()>0)
        {
         for(int i=PositionsTotal()-1; i>=0; i--)
           {
            ulong ticket1   = PositionGetTicket(i);
            string symbol1  = PositionGetString(POSITION_SYMBOL);
            double preju    = PositionGetDouble(POSITION_PROFIT);
            ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if(TipoPosicao==POSITION_TYPE_BUY && symbol1==_Symbol && MathAbs(preju)<somalucrofechados && preju<0)
              {
               somalucrofechados = somalucrofechados-MathAbs(preju);
               trade.PositionClose(ticket1);
              }
           }
        }
     }

   if(PosAberta("POSSUI","COMPRA","") && DataHoraUltPosFechada("VENDA")>DataHoraUltPosAberta("COMPRA"))
     {
      HistorySelect(0,TimeCurrent());
      uint     dealstotal=HistoryDealsTotal();
      ulong    ticket=0;
      string   symbol;
      long     entry;
      long     type;
      datetime time;
      double   lucro;
      double   somalucrofechados=0;
      for(uint j=0; j<dealstotal; j++)
        {
         //--- tentar obter ticket negócios
         if((ticket=HistoryDealGetTicket(j))>0)
           {
            //--- obter as propriedades negócios
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            lucro =HistoryDealGetDouble(ticket,DEAL_PROFIT);
            time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
            //--- apenas para o símbolo atual
            if(entry==DEAL_ENTRY_OUT && type==DEAL_TYPE_BUY && symbol==_Symbol /*&& lucro>0*/ && time>DataHoraUltPosAberta("COMPRA"))
               somalucrofechados = somalucrofechados + lucro;
           }
        }
      if(PositionsTotal()>0)
        {
         for(int i=PositionsTotal()-1; i>=0; i--)
           {
            ulong ticket1   = PositionGetTicket(i);
            string symbol1  = PositionGetString(POSITION_SYMBOL);
            double preju    = PositionGetDouble(POSITION_PROFIT);
            ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if(TipoPosicao==POSITION_TYPE_BUY && symbol1==_Symbol && MathAbs(preju)<somalucrofechados && preju<0)
              {
               somalucrofechados = somalucrofechados-MathAbs(preju);
               trade.PositionClose(ticket1);
              }
           }
        }
     }

   if(PosAberta("POSSUI","VENDA","")  && DataHoraUltPosFechada("VENDA")>DataHoraUltPosAberta("VENDA") && DadosPosFechada("QTDE DE POSIÇÕES FECHADAS APÓS A ULTIMA POSIÇÃO ABERTA","VENDA")>=qtdezero)
     {
      HistorySelect(0,TimeCurrent());
      uint     dealstotal=HistoryDealsTotal();
      ulong    ticket=0;
      string   symbol;
      long     entry;
      long     type;
      datetime time;
      double   lucro;
      double   somalucrofechados=0;
      for(uint j=0; j<dealstotal; j++)
        {
         //--- tentar obter ticket negócios
         if((ticket=HistoryDealGetTicket(j))>0)
           {
            //--- obter as propriedades negócios
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            lucro =HistoryDealGetDouble(ticket,DEAL_PROFIT);
            time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
            //--- apenas para o símbolo atual
            if(entry==DEAL_ENTRY_OUT && type==DEAL_TYPE_BUY && symbol==_Symbol /*&& lucro>0*/ && time>DataHoraUltPosAberta("VENDA"))
               somalucrofechados = somalucrofechados + lucro;
           }
        }
      if(PositionsTotal()>0)
        {
         for(int i=PositionsTotal()-1; i>=0; i--)
           {
            ulong ticket1   = PositionGetTicket(i);
            string symbol1  = PositionGetString(POSITION_SYMBOL);
            double preju    = PositionGetDouble(POSITION_PROFIT);
            ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if(TipoPosicao==POSITION_TYPE_SELL && symbol1==_Symbol && MathAbs(preju)<somalucrofechados && preju<0)
              {
               somalucrofechados = somalucrofechados-MathAbs(preju);
               trade.PositionClose(ticket1);
              }
           }
        }
     }

   if(PosAberta("POSSUI","VENDA","") && DataHoraUltPosFechada("COMPRA")>DataHoraUltPosAberta("VENDA"))
     {
      HistorySelect(0,TimeCurrent());
      uint     dealstotal=HistoryDealsTotal();
      ulong    ticket=0;
      string   symbol;
      long     entry;
      long     type;
      datetime time;
      double   lucro;
      double   somalucrofechados=0;
      for(uint j=0; j<dealstotal; j++)
        {
         //--- tentar obter ticket negócios
         if((ticket=HistoryDealGetTicket(j))>0)
           {
            //--- obter as propriedades negócios
            symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
            type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
            lucro =HistoryDealGetDouble(ticket,DEAL_PROFIT);
            time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
            //--- apenas para o símbolo atual
            if(entry==DEAL_ENTRY_OUT && type==DEAL_TYPE_SELL && symbol==_Symbol /*&& lucro>0*/ && time>DataHoraUltPosAberta("VENDA"))
               somalucrofechados = somalucrofechados + lucro;
           }
        }
      if(PositionsTotal()>0)
        {
         for(int i=PositionsTotal()-1; i>=0; i--)
           {
            ulong ticket1   = PositionGetTicket(i);
            string symbol1  = PositionGetString(POSITION_SYMBOL);
            double preju    = PositionGetDouble(POSITION_PROFIT);
            ENUM_POSITION_TYPE TipoPosicao=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if(TipoPosicao==POSITION_TYPE_SELL && symbol1==_Symbol && MathAbs(preju)<somalucrofechados && preju<0)
              {
               somalucrofechados = somalucrofechados-MathAbs(preju);
               trade.PositionClose(ticket1);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
