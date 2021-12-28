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
#include <Dictionary.mqh>

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
input int                porta               = 8082;       // PORTA DA REDE NEURAL
//input bool               ExtTLS              = false;      // ATIVA ENVIO POR HTTPS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "ABERTURA DE POSIÇÕES"
input bool               ativaentradaea      = true;       // ATIVA ABERTURA
input double             loteinicial         = 0.01;       // TAMANHO DO LOTE INICIAL
input double             valoraumento        = 1000.00;    // VALOR PARA AUMENTO DE LOTE
input int                volumetick          = 150;        // VOLUME DE TICK ANTERIOR MIN. P/ ORDENS
input group              "MARTINGALE"
input ENUM_TP_MART       tipomartingale      = mart1;      // TIPO DE VOLUME MARTINGALE
input int                multiplicador       = 2;          // MULTIPLICADOR P/ MARTINGALE
input double             pontosmart          = 100;        // PONTOS DISTANTES P/ PX OPER
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "BREAKEVEN/TRAILING STOP"
input bool               ativbreak           = false;      // ATIVA BREAKEVEN/TRAILING STOP
input double             pontosbreak         = 5;          // PTOS PROX AO TP PARA ATIV BREAKEVEN
input double             pontosbreak2        = 5;          // PTOS P/ MOVER TP PARA FRENTE BREAKEVEN
input double             pontosbesl          = 10;         // PTOS A MENOS PARA SL NOVO
input double             pontosts            = 5;          // PTOS DO SL NOVO PARA ATIV TS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "GERENCIAMENTO DE RISCO - STOP"
input bool               ativastop           = false;      // ATIVA STOP FORÇADO
input double             stoppercent         = 10.00;      // % DO CAPITAL LIQUIDO PARA "STOPAR"
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "GERENCIAMENTO DE RISCO - CONTROLE DE MARGEM"
input double             prctniveloper       = 3000;       // MARGEM MINIMA P/ ABRIR POSIÇÕES
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "GERENCIAMENTO DAS VARIÁVEIS QUE UTILIZAM HORÁRIO"
input double             pontosprev1         = 25;         // PONTOS DE TP P/ PERÍODOS DE BAIXO MOVIMENTO
input double             pontosprev2         = 50;         // PONTOS DE TP P/ PERÍODOS DE ALTO MOVIMENTO

string                   shortname;

//--- Variáveis temporárias e de carater geral
double                   stopcompra          = 0.0;
double                   stopvenda           = 0.0;
double                   takecompra          = 0.0;
double                   takevenda           = 0.0;

double                   percent_margem, saldo, capital, lucro_prejuizo, volumemaximo, volumeoper, slcomprapadrao, slvendapadrao, previsao;

//--- Definição das variáveis dos volumes para compra e venda quando utilizar martingale
double                   volnv2,volnv3,volnv4,volnv5,volnv6,volnv7,volnv8,volnv9;
double                   volnv_2,volnv_3,volnv_4,volnv_5,volnv_6,volnv_7,volnv_8,volnv_9;

//--- Definição das variáveis dos preços médios para compra e venda quando utilizar martingale
double                   PM1, PM2, PM3, PM4, PM5, PM6, PM7;

//--- Variáveis p/ ticks e candles
MqlTick                  tick;
MqlRates                 candle[];

//--- Usa a classe responsável pela execução das ordens - Ctrade
CTrade                   trade;

//--- Usa a classe responsável pela leitura dos dados do arquivo contendo as previsões
CDictionary *dict = new CDictionary();

//+--------------------------------+
//| Expert initialization function |
//+--------------------------------+
int OnInit()
  {

//--- Seta o magic number do robô
   trade.SetExpertMagicNumber(magicrobo);

   ArraySetAsSeries(candle,true);

   ReadFileToDictCSV("previsoes.csv");

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

//--- Definição dos preços médios para quando houver 2 ou mais compras/vendas

   if(PositionsTotal()==1)

     {
      if(PossuiPosCompraComentada("C1") && !PossuiPosCompraComentada("C2"))
         PM1 = (tick.ask*volnv2 + PrecoAberturaPosCompra()*volumeoper)/(volnv2+volumeoper);
      if(PossuiPosCompraComentada("C2") && !PossuiPosCompraComentada("C3"))
         PM2 = (tick.ask*volnv3 + PrecoAberturaPosCompra()*VolumePos())/(volnv3+VolumePos());
      if(PossuiPosCompraComentada("C3") && !PossuiPosCompraComentada("C4"))
         PM3 = (tick.ask*volnv4 + PrecoAberturaPosCompra()*VolumePos())/(volnv4+VolumePos());
      if(PossuiPosCompraComentada("C4") && !PossuiPosCompraComentada("C5"))
         PM4 = (tick.ask*volnv5 + PrecoAberturaPosCompra()*VolumePos())/(volnv5+VolumePos());
      if(PossuiPosCompraComentada("C5") && !PossuiPosCompraComentada("C6"))
         PM5 = (tick.ask*volnv6 + PrecoAberturaPosCompra()*VolumePos())/(volnv6+VolumePos());
      if(PossuiPosCompraComentada("C6") && !PossuiPosCompraComentada("C7"))
         PM6 = (tick.ask*volnv7 + PrecoAberturaPosCompra()*VolumePos())/(volnv7+VolumePos());
      if(PossuiPosCompraComentada("C7") && !PossuiPosCompraComentada("C8"))
         PM7 = (tick.ask*volnv8 + PrecoAberturaPosCompra()*VolumePos())/(volnv8+VolumePos());

      if(PossuiPosVendaComentada("C1") && !PossuiPosVendaComentada("C2"))
         PM1 = (tick.bid*volnv2 + PrecoAberturaPosVenda()*volumeoper)/(volnv2+volumeoper);
      if(PossuiPosVendaComentada("C2") && !PossuiPosVendaComentada("C3"))
         PM2 = (tick.bid*volnv3 + PrecoAberturaPosVenda()*VolumePos())/(volnv3+VolumePos());
      if(PossuiPosVendaComentada("C3") && !PossuiPosVendaComentada("C4"))
         PM3 = (tick.bid*volnv4 + PrecoAberturaPosVenda()*VolumePos())/(volnv4+VolumePos());
      if(PossuiPosVendaComentada("C4") && !PossuiPosVendaComentada("C5"))
         PM4 = (tick.bid*volnv5 + PrecoAberturaPosVenda()*VolumePos())/(volnv5+VolumePos());
      if(PossuiPosVendaComentada("C5") && !PossuiPosVendaComentada("C6"))
         PM5 = (tick.bid*volnv6 + PrecoAberturaPosVenda()*VolumePos())/(volnv6+VolumePos());
      if(PossuiPosVendaComentada("C6") && !PossuiPosVendaComentada("C7"))
         PM6 = (tick.bid*volnv7 + PrecoAberturaPosVenda()*VolumePos())/(volnv7+VolumePos());
      if(PossuiPosVendaComentada("C7") && !PossuiPosVendaComentada("C8"))
         PM7 = (tick.bid*volnv8 + PrecoAberturaPosVenda()*VolumePos())/(volnv8+VolumePos());
     }

//+------------------------------------------------------------------------------------------+
//| APÓS PREVISÃO RECEBIDA DO ARQUIVO DE PREVISÕES EFETUAR AS OPERAÇÕES DENTRO DA ESTRATÉGIA |
//+------------------------------------------------------------------------------------------+

   previsao = NormalizeDouble(StringToDouble(dict.Get<string>(TimeCurrent())),5);

//+------------------------------------------------------------------+
//| APÓS PREVISÃO RECEBIDA EFETUAR AS OPERAÇÕES DENTRO DA ESTRATÉGIA |
//+------------------------------------------------------------------+

   double Ask = NormalizeDouble(tick.ask,5);
   double Bid = NormalizeDouble(tick.bid,5);

   if(ativaentradaea==true &&  !PossuiPosAbertaOutroAtivo())
     {
      if(NB2.IsNewBar(_Symbol,_Period)) //VERIFICA SE É UM NOVO CANDLE
        {
         if(previsao > Ask + 20*_Point && previsao!=0.0 && (percent_margem>prctniveloper||saldo==capital))
           {
            /////////////////////////////////////
            //---|VIRADA DE MÃO PARA VENDAS|---//
            /////////////////////////////////////
            if(PossuiPosVenda())
              {
               if(PossuiPosVendaComentada("V1"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv2,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C2");
                  return;
                 }
               if(PossuiPosVendaComentada("V2"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv3,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C3");
                  return;
                 }
               if(PossuiPosVendaComentada("V3"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv4,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C4");
                  return;
                 }
               if(PossuiPosVendaComentada("V4"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv5,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C5");
                  return;
                 }
               if(PossuiPosVendaComentada("V5"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv6,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C6");
                  return;
                 }
               if(PossuiPosVendaComentada("V6"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv7,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C7");
                  return;
                 }
               if(PossuiPosVendaComentada("V7"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Buy(volnv8,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C8");
                  return;
                 }
              }
            ////////////////////////////////////////
            //---|COMPRAS NORMAIS E MARTINGALE|---//
            ////////////////////////////////////////
            else
              {
               if(PositionsTotal()==0 && tick.ask>candle[1].open && candle[1].tick_volume>=volumetick)
                 {
                  trade.Buy(volumeoper,_Symbol,tick.ask,slcomprapadrao,tick.bid+pontosprev2*_Point,"C1");
                  return;
                 }
               if(PossuiPosCompraComentada("C1") && !PossuiPosCompraComentada("C2") && Ask<PrecoAberturaPosCompra()-pontosmart*_Point /*&& previsao>PrecoPosCompra()+5*_Point*/ && VolumePos()<=500 && volnv2!=0)
                 {
                  trade.Buy(volnv2,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C2");
                  return;
                 }
               if(PossuiPosCompraComentada("C2") && !PossuiPosCompraComentada("C3") && Ask<PrecoAberturaPosCompra()-pontosmart*_Point && previsao>PrecoPosCompra()+5*_Point && VolumePos()<=500 && volnv3!=0)
                 {
                  trade.Buy(volnv3,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C3");
                  return;
                 }
               if(PossuiPosCompraComentada("C3") && !PossuiPosCompraComentada("C4") && Ask<PrecoAberturaPosCompra()-pontosmart*_Point && previsao>PrecoPosCompra()+5*_Point && VolumePos()<=500 && volnv4!=0)
                 {
                  trade.Buy(volnv4,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C4");
                  return;
                 }
               if(PossuiPosCompraComentada("C4") && !PossuiPosCompraComentada("C5") && Ask<PrecoAberturaPosCompra()-pontosmart*_Point && previsao>PrecoPosCompra()+5*_Point && VolumePos()<=500 && volnv5!=0)
                 {
                  trade.Buy(volnv5,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C5");
                  return;
                 }
               if(PossuiPosCompraComentada("C5") && !PossuiPosCompraComentada("C6") && Ask<PrecoAberturaPosCompra()-pontosmart*_Point && previsao>PrecoPosCompra()+5*_Point && VolumePos()<=500 && volnv6!=0)
                 {
                  trade.Buy(volnv6,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C6");
                  return;
                 }
               if(PossuiPosCompraComentada("C6") && !PossuiPosCompraComentada("C7") && Ask<PrecoAberturaPosCompra()-pontosmart*_Point && previsao>PrecoPosCompra()+5*_Point && VolumePos()<=500 && volnv7!=0)
                 {
                  trade.Buy(volnv7,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C7");
                  return;
                 }
               if(PossuiPosCompraComentada("C7") && !PossuiPosCompraComentada("C8") && Ask<PrecoAberturaPosCompra()-pontosmart*_Point && previsao>PrecoPosCompra()+5*_Point && VolumePos()<=500 && volnv8!=0)
                 {
                  trade.Buy(volnv8,_Symbol,tick.ask,slcomprapadrao,tick.bid+(pontosprev2/2)*_Point,"C8");
                  return;
                 }
              }
           }

         if(previsao < Bid - 20*_Point && previsao!=0.0 && (percent_margem>prctniveloper||saldo==capital))
           {
            //////////////////////////////////////
            //---|VIRADA DE MÃO PARA COMPRAS|---//
            //////////////////////////////////////

            if(PossuiPosCompra())
              {
               if(PossuiPosCompraComentada("C1"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv2,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V2");
                  return;
                 }
               if(PossuiPosCompraComentada("C2"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv3,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V3");
                  return;
                 }
               if(PossuiPosCompraComentada("C3"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv4,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V4");
                  return;
                 }
               if(PossuiPosCompraComentada("C4"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv5,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V5");
                  return;
                 }
               if(PossuiPosCompraComentada("C5"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv6,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V6");
                  return;
                 }
               if(PossuiPosCompraComentada("C6"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv7,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V7");
                  return;
                 }
               if(PossuiPosCompraComentada("C7"))
                 {
                  FechaTodasPosicoesAbertas();
                  Sleep(200);
                  trade.Sell(volnv8,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V8");
                  return;
                 }
              }
            ///////////////////////////////////////
            //---|VENDAS NORMAIS E MARTINGALE|---//
            ///////////////////////////////////////
            else
              {
               if(PositionsTotal()==0 && tick.bid<candle[1].open && candle[1].tick_volume>=volumetick)
                 {
                  trade.Sell(volumeoper,_Symbol,tick.bid,slvendapadrao,tick.bid-pontosprev2*_Point,"V1");
                  return;
                 }
               if(PossuiPosVendaComentada("V1") && !PossuiPosVendaComentada("V2") && Bid>PrecoAberturaPosVenda()+pontosmart*_Point && previsao<PrecoPosCompra()-5*_Point && VolumePos()<=500 && volnv2!=0)
                 {
                  trade.Sell(volnv2,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V2");
                  return;
                 }
               if(PossuiPosVendaComentada("V2") && !PossuiPosVendaComentada("V3") && Bid>PrecoAberturaPosVenda()+pontosmart*_Point && previsao<PrecoPosCompra()-5*_Point && VolumePos()<=500 && volnv3!=0)
                 {
                  trade.Sell(volnv3,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V3");
                  return;
                 }
               if(PossuiPosVendaComentada("V3") && !PossuiPosVendaComentada("V4") && Bid>PrecoAberturaPosVenda()+pontosmart*_Point && previsao<PrecoPosCompra()-5*_Point && VolumePos()<=500 && volnv4!=0)
                 {
                  trade.Sell(volnv4,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V4");
                  return;
                 }
               if(PossuiPosVendaComentada("V4") && !PossuiPosVendaComentada("V5") && Bid>PrecoAberturaPosVenda()+pontosmart*_Point && previsao<PrecoPosCompra()-5*_Point && VolumePos()<=500 && volnv5!=0)
                 {
                  trade.Sell(volnv5,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V5");
                  return;
                 }
               if(PossuiPosVendaComentada("V5") && !PossuiPosVendaComentada("V6") && Bid>PrecoAberturaPosVenda()+pontosmart*_Point && previsao<PrecoPosCompra()-5*_Point && VolumePos()<=500 && volnv6!=0)
                 {
                  trade.Sell(volnv6,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V6");
                  return;
                 }
               if(PossuiPosVendaComentada("V6") && !PossuiPosVendaComentada("V7") && Bid>PrecoAberturaPosVenda()+pontosmart*_Point && previsao<PrecoPosCompra()-5*_Point && VolumePos()<=500 && volnv7!=0)
                 {
                  trade.Sell(volnv7,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V7");
                  return;
                 }
               if(PossuiPosVendaComentada("V7") && !PossuiPosVendaComentada("V8") && Bid>PrecoAberturaPosVenda()+pontosmart*_Point && previsao<PrecoPosCompra()-5*_Point && VolumePos()<=500 && volnv8!=0)
                 {
                  trade.Sell(volnv8,_Symbol,tick.bid,slvendapadrao,tick.bid-(pontosprev2/2)*_Point,"V8");
                  return;
                 }
              }
           }

         //////////////////////////
         //---|AJUSTE DE TAKE|---//
         //////////////////////////
/*         if(TPUltimaPosAberta() != previsao && (StopUltimaPosAberta()==slcomprapadrao||StopUltimaPosAberta()==slvendapadrao) && ((PossuiPosCompra() && previsao > PrecoPosCompra()+5*_Point)||(PossuiPosVenda() && previsao < PrecoPosCompra()-5*_Point)))
           {
            if(PossuiPosCompra())
              {

               trade.PositionModify(_Symbol,slcomprapadrao,previsao);
               return;
              }
            if(PossuiPosVenda())
              {

               trade.PositionModify(_Symbol,slvendapadrao,previsao);
               return;
              }
           }
*/        }
     }

//////////////////////////
//---|STOP FORÇADO |----//
//////////////////////////
   if(ativastop==true)
      if(MathAbs((LucroPrejuizoPosAberta()/capital)*100)>=stoppercent && LucroPrejuizoPosAberta()<0 && saldo!=capital)
        {
         FechaTodasPosicoesAbertas();
         Sleep(100);
         return;
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
