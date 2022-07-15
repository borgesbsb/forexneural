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
#include <IsNewBar.mqh>

enum ENUM_TP_MART
  {
   mart1,        // [1]VOLUME FIBONACCI
   mart2,        // [2]05 FIBO + 04 2x ANT
   mart3,        // [3]2x VOL ANTERIOR
   mart4,        // [4]2x VOL ACUMULADO
  };

enum ENUM_TIPO_PORCENT
  {
   tipoprc1,     // [1]PORCENTAGEM DO PREÇO
   tipoprc2,     // [2]PORCENTAGEM DO CAPITAL
  };

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input ulong              magicrobo           = 941;        // MAGIC NUMBER DO ROBÔ
input bool               ativahedge          = true;       // ATIVA A OPERAÇÃO EM CONTAS HEDGE
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "ABERTURA DE POSIÇÕES"
input bool               ativaentradaea      = true;       // ATIVA ABERTURA
input double             loteinicial         = 1;          // TAMANHO DO LOTE INICIAL
input double             valoraumento        = 100000.00;  // VALOR PARA AUMENTO DE LOTE
input ENUM_TIPO_PORCENT  tipopercent         = tipoprc2;   // TIPO DE PERCENTUAL PARA STOP/GAIN
input double             percentgain         = 0.1;        // % GAIN
input double             percentloss         = 2.5;        // % LOSS
input group              "MARTINGALE"
input ENUM_TP_MART       tipomartingale      = mart3;      // TIPO DE VOLUME MARTINGALE
input int                multiplicador       = 1;          // MULTIPLICADOR P/ MARTINGALE
input double             prctmart            = 50;         // % DE PTS P/ PX OPERAÇÃO
input group              "RSI"
input bool               ativarsi            = true;       // ATIVA RSI
input int                periodorsi          = 14;         // PERIODO RSI
input int                sobrevrsi           = 70;         // PORCENTAGEM SOBREVENDA
input int                sobrecrsi           = 30;         // PORCENTAGEM SOBRECOMPRA
input bool               ativafiltrobb       = false;      // ATIVA FILTRO BOLINGER
input group              "BANDAS DE BOLLINGER"
input bool               ativabb             = false;      // ATIVA BOLINGER
input int                periodobb           = 14;         // PERIODO BOLINGER
input double             desviobb            = 2.0;        // DESVIO BOLINGER
input bool               ativafiltrorsi      = false;      // ATIVA FILTRO RSI
input group              "CRUZAMENTO DE MÉDIAS"
input bool               ativamedia          = false;      // ATIVA CRUZAMENTO DE MÉDIAS
input int                periodm1            = 7;          // PERÍODO DA MEDIA MENOR
input int                periodm2            = 21;         // PERÍODO DA MEDIA MAIOR
input group              "BREAKEVEN/TRAILING STOP"
input bool               ativbreak           = false;      // ATIVA BREAKEVEN/TRAILING STOP
input double             pontosbreak         = 5;          // PTOS PROX AO TP PARA ATIV BREAKEVEN
input double             pontosbreak2        = 5;          // PTOS P/ MOVER TP PARA FRENTE BREAKEVEN
input double             pontosbesl          = 10;         // PTOS A MENOS PARA SL NOVO
input double             pontosts            = 5;          // PTOS DO SL NOVO PARA ATIV TS
input group              "GERENCIAMENTO DE RISCO - PARADA DIÁRIA DO ROBÔ"
input bool               ativastopdiario     = true;       // PARA O ROBÔ NO DIA QNDO STOP > N
input int                qtdestops           = 3;          // QTDE MÁXIMA DE STOPS (N)
input group              "GERENCIAMENTO DE RISCO - FECHAMENTO DE ORDENS ABERTAS NO FIM DO DIA"
input bool               ativafecfinaldia    = true;       // ATIVA FECHAMENTO DE OPERAÇÕES FIM DO DIA
input group              "GERENCIAMENTO DE RISCO - STOP FULL"
input bool               ativastopfull       = true;       // ATIVA STOP FORÇADO QNDO CAPITAL
input double             percentfull         = 5;          // % DO CAPITAL PARA FECHAR TODAS AS ORDENS

string                   shortname;

//--- Variáveis temporárias e de carater geral
double                   stopcompra          = 0.0;
double                   stopvenda           = 0.0;
double                   takecompra          = 0.0;
double                   takevenda           = 0.0;

int                      handlebb,handlersi,handlem1,handlem2;

double                   percent_margem, saldo, capital, lucro_prejuizo, volumemaximo, volumeoper, //
                         slcomprapadrao, slvendapadrao, tpcomprapadrao, tpvendapadrao, rsi[], bbu[], bbm[], bbd[], mediam1[], mediam2[];

//--- Definição das variáveis dos volumes para compra e venda quando utilizar martingale
double                   volnv2,volnv3,volnv4,volnv5,volnv6,volnv7,volnv8,volnv9;
double                   volnv_2,volnv_3,volnv_4,volnv_5,volnv_6,volnv_7,volnv_8,volnv_9;

//--- Definição das variáveis dos preços médios para compra e venda quando utilizar martingale
double                   PM1, PM2, PM3, PM4, PM5, PM6, PM7, PM8;

//--- Variáveis p/ ticks e candles
MqlTick                  tick;
MqlRates                 candle[];
MqlDateTime              TempoStruct;

// Cria estruturas de tempo para manipulação de horários
//MqlDateTime hora_oper, hora_atual;

//--- Usa a classe responsável pela execução das ordens - Ctrade
CTrade                   trade;

//+--------------------------------+
//| Expert initialization function |
//+--------------------------------+
int OnInit()
  {

//--- Criação das structs de tempo
//   TimeToStruct(StringToTime(inicio),horario_inicio);
//   TimeToStruct(StringToTime(termino),horario_termino);

//--- Seta o magic number do robô
   trade.SetExpertMagicNumber(magicrobo);

   handlersi = iRSI(_Symbol,_Period,periodorsi,PRICE_CLOSE);
   handlebb = iBands(_Symbol,_Period,periodobb,0,desviobb,PRICE_CLOSE);
   handlem1 = iMA(_Symbol,_Period,periodm1,0,MODE_SMA,PRICE_CLOSE);
   handlem2 = iMA(_Symbol,_Period,periodm2,0,MODE_SMA,PRICE_CLOSE);
   ArraySetAsSeries(candle,true);
   ArraySetAsSeries(rsi,true);
   ArraySetAsSeries(bbu,true);
   ArraySetAsSeries(bbm,true);
   ArraySetAsSeries(bbd,true);
   ArraySetAsSeries(mediam1,true);
   ArraySetAsSeries(mediam2,true);

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
   CopyBuffer(handlem1,0,0,5,mediam1);
   if(CopyBuffer(handlem1,0,0,5,mediam1)<0)
     {
      Alert("Erro ao copiar dados de Média Móvel Menor: ", GetLastError());
      return;
     }
   CopyBuffer(handlebb,0,0,5,mediam2);
   if(CopyBuffer(handlebb,0,0,5,mediam2)<0)
     {
      Alert("Erro ao copiar dados de Média Móvel Maior: ", GetLastError());
      return;
     }


   static CIsNewBar NB1,NB2/*,NB3,NB4,NB5,NB6,NB7,NB8,NB9,NB10,NB11,NB12,NB13,NB14,NB15,NB16,NB17,NB18,NB19,NB20,NB21,NB22*/;

   saldo = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
   lucro_prejuizo = NormalizeDouble(AccountInfoDouble(ACCOUNT_PROFIT),2);
   capital = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY),2);
//   double margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN),2);
//   double margem_livre = NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN),2);
   percent_margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),2);

   if(NB1.IsNewBar(_Symbol,_Period)) //VERIFICA SE É UM NOVO CANDLE
     {

      //--- Definição dos lotes iniciais de compra e venda, bem como os lotes quando utilizar martingale
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
         volnv9             = volnv8*multiplicador;
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

      //--- Definição do sl e tp padrões a serem usados nas ordens
      if(ativahedge==true && tipopercent==tipoprc2)
        {
         slcomprapadrao = tick.bid*(1-percentloss/100);
         slvendapadrao  = tick.ask*(1+percentloss/100);
         tpcomprapadrao = tick.ask*(1+percentgain/100);
         tpvendapadrao  = tick.bid*(1-percentgain/100);
        }

     }

//--- Definição dos preços médios para quando houver 2 ou mais compras/vendas

   if(PositionsTotal()>=1 && ativahedge==true)
     {
      if(PossuiPosCompraComentada("C1") && !PossuiPosCompraComentada("C2"))
         PM1 = (tick.ask*volnv2 + PrecoAberturaPosCompra(1)*volumeoper)/(volnv2+volumeoper);
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
                PrecoAberturaPosCompra(4)*volnv4 + PrecoAberturaPosCompra(3)*volnv3 + PrecoAberturaPosCompra(2)*volnv2 + PrecoAberturaPosCompra(1)*//
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
                PrecoAberturaPosVenda(4)*volnv4 + PrecoAberturaPosVenda(3)*volnv3 + PrecoAberturaPosVenda(2)*volnv2 + PrecoAberturaPosVenda(1)*//
                volumeoper)/(volnv8+volnv7+volnv6+volnv5+volnv4+volnv3+volnv2+volumeoper);
     }

//Print("PrecoC1: ",PrecoAberturaPosCompra(1)," PrecoC2: ",PrecoAberturaPosCompra(2)," PrecoV1: ",PrecoAberturaPosVenda(1)," PrecoV2: ",//
//      PrecoAberturaPosVenda(2)," Pontos Compra: ",(PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))/_Point,"Pontos Venda: ",//
//      (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))/_Point);

//+------------------------------------------------------------------+
//| OPERAÇÕES SEGUINDO A ESTRATÉGIA ESCOLHIDA |
//+------------------------------------------------------------------+

   TimeToStruct(TimeCurrent(),TempoStruct);

//double Ask = NormalizeDouble(tick.ask,5);
//double Bid = NormalizeDouble(tick.bid,5);

   if(ativaentradaea==true && !PossuiPosAbertaOutroAtivo() && TempoStruct.hour<=23 && TempoStruct.min<=50 && (percent_margem>3500||saldo==capital))
     {
      if(NB2.IsNewBar(_Symbol,_Period) && StopouMuito()==false) //VERIFICA SE O CANDLE ACABOU DE ABRIR E SE < N STOPS NO DIA
        {
         ////////////////////////////////////
         //---|ESTRATEGIA PRINCIPAL RSI|---//
         ////////////////////////////////////
         if(ativarsi == true)
           {
            if(ativafiltrobb == true)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(rsi[1]<sobrecrsi/* && rsi[0]>30*/ && candle[1].close<bbd[1])
                  ComprasNormais();
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(rsi[1]>sobrevrsi/* && rsi[0]<70*/ && candle[1].close>bbu[1])
                  VendasNormais();
              }
            else
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(rsi[1]<sobrecrsi/*&& rsi[0]>30*/)
                  ComprasNormais();
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(rsi[1]>sobrevrsi/* && rsi[0]<70*/)
                  VendasNormais();
              }
           }
         /////////////////////////////////////////
         //---|ESTRATEGIA PRINCIPAL BOLINGER|---//
         /////////////////////////////////////////

         if(ativabb == true)
           {
            if(ativafiltrorsi == true)
              {
               ///////////////////
               //---|COMPRAS|---//
               ///////////////////
               if(candle[1].close<bbd[1] && rsi[1]<sobrecrsi/* && rsi[0]>30*/)
                  ComprasNormais();
               //////////////////
               //---|VENDAS|---//
               //////////////////
               if(candle[1].close>bbu[1] && rsi[1]>sobrevrsi/* && rsi[0]<70*/)
                  VendasNormais();
              }
            else
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
           }
         /////////////////////////////////////////////////////
         //---|ESTRATEGIA PRINCIPAL CRUZAMENTO DE MÉDIAS|---//
         /////////////////////////////////////////////////////
         if(ativamedia == true)
           {
            ///////////////////
            //---|COMPRAS|---//
            ///////////////////
            if(mediam1[2]<mediam2[2] && mediam1[1]>mediam2[1])
               ComprasNormais();
            //////////////////
            //---|VENDAS|---//
            //////////////////
            if(mediam1[2]>mediam2[2] && mediam1[1]<mediam2[1])
               VendasNormais();

           }
         //////////////////////////////////////////////////////////
         //---|AJUSTE DE TAKE E STOP - AJUSTE P/ CONTA HEDGE |---//
         //////////////////////////////////////////////////////////
         if(PositionsTotal()>=2)
            AjustaTPSL();

        }
     }

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

//////////////////////////////////////////////////////////////////////
//---|FECHA TUDO QUANDO FINAL DO DIA ALCANÇADO COM ORDEM ATIVA |----//
//////////////////////////////////////////////////////////////////////
   if(ativafecfinaldia==true && (PossuiPosCompra()||PossuiPosVenda()) && TempoStruct.hour==23 && TempoStruct.min==50)
     {
      FechaTodasPosicoesAbertas();
     }

//////////////////////////////////////////////////////////////////////////////////
//---|FECHA TUDO QUANDO TAKE OU STOP LOSS ATINGIDO - AJUSTE P/ CONTA HEDGE |----//
//////////////////////////////////////////////////////////////////////////////////
   if(ativahedge==true && (PossuiPosCompra()||PossuiPosVenda()) && (UltimaPosFechadaTake()==true||UltimaPosFechadaStop()==true))
     {
      FechaTodasPosicoesAbertas();
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
//+----------------------------------------------------------+
//| VERIFICA SE AS ÚLTIMAS N POSICÕES FECHADAS FORAM DE STOP |
//+----------------------------------------------------------+
bool StopouMuito()
  {
   HistorySelect(0,TimeCurrent());
   ulong       ticket1=0;
   ulong       ticket2=0;
   string      symbol1;
   string      symbol2;
   long        reason1;
   long        reason2;
   long        entry1;
   long        entry2;
   datetime    time1;
   datetime    time2;
   MqlDateTime DataHoraDaUltimaOper;
   MqlDateTime DataHoraDaPenultimaOper;
   int         contador=1;
   for(uint i=HistoryDealsTotal()-1; i >= 0; i--)
     {
      if((ticket1=HistoryDealGetTicket(i))>1)
        {
         symbol1=HistoryDealGetString(ticket1,DEAL_SYMBOL);
         reason1=HistoryDealGetInteger(ticket1,DEAL_REASON);
         entry1 =HistoryDealGetInteger(ticket1,DEAL_ENTRY);
         time1  =(datetime)HistoryDealGetInteger(ticket1,DEAL_TIME);
         TimeToStruct(time1,DataHoraDaUltimaOper);
         if((ticket2=HistoryDealGetTicket(i-1))>1)
           {
            symbol2=HistoryDealGetString(ticket2,DEAL_SYMBOL);
            reason2=HistoryDealGetInteger(ticket2,DEAL_REASON);
            entry2 =HistoryDealGetInteger(ticket2,DEAL_ENTRY);
            time2  =(datetime)HistoryDealGetInteger(ticket2,DEAL_TIME);
            TimeToStruct(time2,DataHoraDaPenultimaOper);

            if(reason1==DEAL_REASON_SL && entry1==DEAL_ENTRY_OUT && symbol1==_Symbol && reason2==DEAL_REASON_SL && //
               entry2==DEAL_ENTRY_OUT && symbol2==_Symbol  && time1-time2>30 && DataHoraDaUltimaOper.day==DataHoraDaPenultimaOper.day)
              {
               contador++;
               if(contador>qtdestops)
                 {
                  return true;
                  break;
                 }
              }
           }
         return false;
         break;
        }
      return false;
      break;
     }
   return false;
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
//+------------------------------------------------------------------+
//| VERIFICA SE A ÚLTIMA POSICAO FECHADA FOI DE TAKE PROFIT ATINGIDO |
//+------------------------------------------------------------------+
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
   if(PositionsTotal()==0 /*&& tick.ask>candle[1].open*/)
     {
      trade.Buy(volumeoper,_Symbol,tick.ask,slcomprapadrao,tpcomprapadrao,"C1");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C1") && !PossuiPosCompraComentada("C2") && tick.ask<PrecoAberturaPosCompra(1)-10000*_Point //
      && VolumePos()<=500 && volnv2!=0)
     {
      if(ativahedge==true)
         slcomprapadrao=PM1*(1-percentloss/100);
      trade.Buy(volnv2,_Symbol,tick.ask,slcomprapadrao,tpcomprapadrao,"C2");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C2") && !PossuiPosCompraComentada("C3") && (PrecoAberturaPosCompra(1)-tick.ask)*_Point>//
      (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))*_Point*prctmart/100 && VolumePos()<=500 && volnv3!=0)
     {
      if(ativahedge==true)
         slcomprapadrao=PM2*(1-percentloss/100);
      trade.Buy(volnv3,_Symbol,tick.ask,slcomprapadrao,tpcomprapadrao,"C3");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C3") && !PossuiPosCompraComentada("C4") && (PrecoAberturaPosCompra(1)-tick.ask)*_Point>//
      (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))*_Point*prctmart/100 && VolumePos()<=500 && volnv4!=0)
     {
      if(ativahedge==true)
         slcomprapadrao=PM3*(1-percentloss/100);
      trade.Buy(volnv4,_Symbol,tick.ask,slcomprapadrao,tpcomprapadrao,"C4");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C4") && !PossuiPosCompraComentada("C5") && (PrecoAberturaPosCompra(1)-tick.ask)*_Point>//
      (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))*_Point*prctmart/100 && VolumePos()<=500 && volnv5!=0)
     {
      if(ativahedge==true)
         slcomprapadrao=PM4*(1-percentloss/100);
      trade.Buy(volnv5,_Symbol,tick.ask,slcomprapadrao,tpcomprapadrao,"C5");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C5") && !PossuiPosCompraComentada("C6") && (PrecoAberturaPosCompra(1)-tick.ask)*_Point>//
      (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))*_Point*prctmart/100 && VolumePos()<=500 && volnv6!=0)
     {
      if(ativahedge==true)
         slcomprapadrao=PM5*(1-percentloss/100);
      trade.Buy(volnv6,_Symbol,tick.ask,slcomprapadrao,tpcomprapadrao,"C6");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C6") && !PossuiPosCompraComentada("C7") && (PrecoAberturaPosCompra(1)-tick.ask)*_Point>//
      (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))*_Point*prctmart/100 && VolumePos()<=500 && volnv7!=0)
     {
      if(ativahedge==true)
         slcomprapadrao=PM6*(1-percentloss/100);
      trade.Buy(volnv7,_Symbol,tick.ask,slcomprapadrao,tpcomprapadrao,"C7");
      Sleep(500);
      return;
     }
   if(PossuiPosCompraComentada("C7") && !PossuiPosCompraComentada("C8") && (PrecoAberturaPosCompra(1)-tick.ask)*_Point>//
      (PrecoAberturaPosCompra(2)-PrecoAberturaPosCompra(1))*_Point*prctmart/100 && VolumePos()<=500 && volnv8!=0)
     {
      if(ativahedge==true)
         slcomprapadrao=PM7*(1-percentloss/100);
      trade.Buy(volnv8,_Symbol,tick.ask,slcomprapadrao,tpcomprapadrao,"C8");
      Sleep(500);
      return;
     }
  }
//+---------------------------------------------------------------------------------------------------------------------------------+
/////////////////////////////////////////
//---|VENDAS NORMAIS COM MARTINGALE|---//
/////////////////////////////////////////
void  VendasNormais()
  {
   if(PositionsTotal()==0 /*&& tick.bid < candle[1].open*/)
     {
      trade.Sell(volumeoper,_Symbol,tick.bid,slvendapadrao,tpvendapadrao,"V1");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V1") && !PossuiPosVendaComentada("V2") && tick.bid>PrecoAberturaPosVenda(1)+10000*_Point//
      && VolumePos()<=500 && volnv2!=0)
     {
      if(ativahedge==true)
         slvendapadrao=PM1*(1+percentloss/100);
      trade.Sell(volnv2,_Symbol,tick.bid,slvendapadrao,tpvendapadrao,"V2");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V2") && !PossuiPosVendaComentada("V3") && (PrecoAberturaPosVenda(1)-tick.ask)*_Point>//
      (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))*_Point*prctmart/100 && VolumePos()<=500 && volnv3!=0)
     {
      if(ativahedge==true)
         slvendapadrao=PM2*(1+percentloss/100);
      trade.Sell(volnv3,_Symbol,tick.bid,slvendapadrao,tpvendapadrao,"V3");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V3") && !PossuiPosVendaComentada("V4") && (PrecoAberturaPosVenda(1)-tick.ask)*_Point>//
      (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))*_Point*prctmart/100 && VolumePos()<=500 && volnv4!=0)
     {
      if(ativahedge==true)
         slvendapadrao=PM3*(1+percentloss/100);
      trade.Sell(volnv4,_Symbol,tick.bid,slvendapadrao,tpvendapadrao,"V4");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V4") && !PossuiPosVendaComentada("V5") && (PrecoAberturaPosVenda(1)-tick.ask)*_Point>//
      (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))*_Point*prctmart/100 && VolumePos()<=500 && volnv5!=0)
     {
      if(ativahedge==true)
         slvendapadrao=PM4*(1+percentloss/100);
      trade.Sell(volnv5,_Symbol,tick.bid,slvendapadrao,tpvendapadrao,"V5");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V5") && !PossuiPosVendaComentada("V6") && (PrecoAberturaPosVenda(1)-tick.ask)*_Point>//
      (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))*_Point*prctmart/100 && VolumePos()<=500 && volnv6!=0)
     {
      if(ativahedge==true)
         slvendapadrao=PM5*(1+percentloss/100);
      trade.Sell(volnv6,_Symbol,tick.bid,slvendapadrao,tpvendapadrao,"V6");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V6") && !PossuiPosVendaComentada("V7") && (PrecoAberturaPosVenda(1)-tick.ask)*_Point>//
      (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))*_Point*prctmart/100 && VolumePos()<=500 && volnv7!=0)
     {
      if(ativahedge==true)
         slvendapadrao=PM6*(1+percentloss/100);
      trade.Sell(volnv7,_Symbol,tick.bid,slvendapadrao,tpvendapadrao,"V7");
      Sleep(500);
      return;
     }
   if(PossuiPosVendaComentada("V7") && !PossuiPosVendaComentada("V8") && (PrecoAberturaPosVenda(1)-tick.ask)*_Point>//
      (PrecoAberturaPosVenda(1)-PrecoAberturaPosVenda(2))*_Point*prctmart/100 && VolumePos()<=500 && volnv8!=0)
     {
      if(ativahedge==true)
         slvendapadrao=PM7*(1+percentloss/100);
      trade.Sell(volnv8,_Symbol,tick.bid,slvendapadrao,tpvendapadrao,"V8");
      Sleep(500);
      return;
     }
  }
//+---------------------------------------------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
