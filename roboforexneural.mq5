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
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "ENVIO P/ REDE NEURAL"
input bool               ativaenvioneural    = true;       // ATIVA ENVIO DE DADOS
input bool               ativaenviomedia     = false;      // ATIVA ENVIO DE MÉDIA MÓVEL
input ENUM_MA_METHOD     tipomedia           = MODE_SMA;   // TIPO DE MÉDIA
input int                periodomedia        = 200;        // QTDE DE CANDLES P/ MÉDIA
input bool               ativaenviorsi       = false;      // ATIVA ENVIO DE RSI
input int                periodorsi          = 10;         // QTDE DE CANDLES P/ RSI
//input double             rsicompra           = 30;         // VALOR DO RSI P/ COMPRA
//input double             rsivenda            = 70;         // VALOR DO RSI P/ VENDA
input string             endereco            = "localhost";// IP/SITE DO SERVIDOR NEURAL
input uint               porta               = 8000;       // PORTA DO SERVIDOR NEURAL
input bool               ExtTLS              = false;      // ATIVA ENVIO POR HTTPS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input ulong              magicrobo           = 940;        // MAGIC NUMBER DO ROBÔ
input group              "ABERTURA DE POSIÇÕES"
input bool               ativaentradaea      = true;       // ATIVA ENTRADA PELO ROBÔ
input double             lotecompra          = 0.01;       // TAMANHO DO LOTE PADRÃO P/ COMPRA
input double             lotevenda           = 0.01;       // TAMANHO DO LOTE PADRÃO P/ VENDA
input double             nivelcompra         = 2000;       // % MINIMO P/ NOVAS ORDENS
input int                multiplicador       = 2;          // MULTIPLICADOR MARTINGALE
input double             pontosmart          = 3000;       // DISTÂNCIA EM PONTOS P/ NOVAS ORDENS(MARTINGALE)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "BREAKEVEN E TRAILING STOP"
input bool               ativaBE             = false;      // ATIVA BREAKEVEN
input double             recuoBE             = 1000;       // PONTOS PARA RECUO NO BREAKEVEN
input bool               ativaTS             = false;      // ATIVA TRAILING STOP
input double             pontosTS            = 2000;       // PONTOS P/ ATIVAÇÃO TS
input double             avancoTS            = 1000;       // AVANÇO DO STOP EM PONTOS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "FECHAMENTO DE POSIÇÕES"
input bool               ativasaidaea        = false;      // ATIVA SAÍDA PELO ROBÔ
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input group              "HORáRIO DE FUNCIONAMENTO DO EA"
input string             inicio              = "01:10";    // Horário de Início (entradas)
input string             termino             = "23:50";    // Horário de Término (entradas)
//input string             fechamento          = "23:45";     // Horário de Fechamento (posições)
input string             pausainicio1        = "";         // Horário de Início da Pausa 1(Notícias)
input string             pausatermino1       = "";         // Horário de Término da Pausa 1(Notícias)
input string             pausainicio2        = "";         // Horário de Início da Pausa 2(Notícias)
input string             pausatermino2       = "";         // Horário de Término da Pausa 2(Notícias)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//input group              "Gerenciamento de risco"
//input double             maxganhodiario      = 250.00;      // Máx ganho diário p/ ativar modo seguro
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
string                   shortname;

//--- Variáveis temporárias e de carater geral
double                   volumecompra        = 0.0;
double                   volumevenda         = 0.0;
double                   stopcompra          = 0.0;
double                   stopvenda           = 0.0;
double                   takecompra          = 0.0;
double                   takevenda           = 0.0;

double                   percent_margem, saldo, capital;

//--- Variáveis p/ envio de dados à rede neural
int                      socketneural        = SocketCreate();
string                   recebido            = "";
string                   open1               = "";
string                   open2               = "";
string                   close1              = "";
string                   close2              = "";
string                   low1                = "";
string                   low2                = "";
string                   high1               = "";
string                   high2               = "";
string                   envioneural         = "";
bool                     enviado;

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

//--- Criação das structs de tempo
   TimeToStruct(StringToTime(inicio),horario_inicio);
   TimeToStruct(StringToTime(termino),horario_termino);
//   TimeToStruct(StringToTime(fechamento),horario_fechamento);
   TimeToStruct(StringToTime(pausainicio1),horario_inicio_pausa1);
   TimeToStruct(StringToTime(pausatermino1),horario_termino_pausa1);
   TimeToStruct(StringToTime(pausainicio2),horario_inicio_pausa2);
   TimeToStruct(StringToTime(pausatermino2),horario_termino_pausa2);

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
   CopyRates(_Symbol,_Period,0,30,candle);
   if(CopyRates(_Symbol,_Period,0,30,candle)<0)
     {
      Alert("Erro ao obter informações de Mqlrates: ", GetLastError());
      return;
     }
   if(!SymbolInfoTick(_Symbol,tick))
     {
      Alert("Erro ao obter informações de Mqlticks: ", GetLastError());
      return;
     }

   static CIsNewBar NB1,NB2/*,NB3,NB4,NB5,NB6,NB7,NB8,NB9,NB10,NB11,NB12,NB13,NB14,NB15,NB16,NB17,NB18,NB19,NB20,NB21,NB22*/;

   saldo = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
//   double lucro_prejuizo = NormalizeDouble(AccountInfoDouble(ACCOUNT_PROFIT),2);
   capital = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY),2);
//   double margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN),2);
//   double margem_livre = NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN),2);
   percent_margem = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),2);
//   Comment("Nível de Margem: ","\n",percent_margem);

//+------------------------------------------------------------------+
//| ENVIO DE SINAIS P/ REDE NEURAL                                   |
//+------------------------------------------------------------------+
   if(ativaenvioneural==true)
     {
      if(NB1.IsNewBar(_Symbol,_Period)) //VERIFICA SE É UM NOVO CANDLE
        {
         open1 = DoubleToString(candle[1].open,5);
         open2 = DoubleToString(candle[2].open,5);
         low1 = DoubleToString(candle[1].low,5);
         low2 = DoubleToString(candle[2].low,5);
         close1 = DoubleToString(candle[1].close,5);
         close2 = DoubleToString(candle[2].close,5);
         high1 = DoubleToString(candle[1].high,5);
         high2 = DoubleToString(candle[2].high,5);
         envioneural = open1+","+high1+","+low1+","+close1+","+open2+","+high2+","+low2+","+close2;
         Comment("open1: ",open1,"\n","high1: ",high1,"\n","low1: ",low1,"\n","close1: ",close1,"\n","open2: ",open2,"\n","high2: ",high2,"\n"//
                 ,"low2: ",low2,"\n","close2: ",close2,"\n",envioneural);

         if(socketneural!=INVALID_HANDLE)
           {
            SocketConnect(socketneural,endereco,porta,1000);
            Print("Conectado a ",endereco,":",porta);
            enviado = socksend(socketneural,envioneural);
            SocketConnect(socketneural,endereco,porta,1000);
            Print("Conectado a ",endereco,":",porta);
            recebido = socketreceive(socketneural,1000);
            Print(recebido);
            SocketClose(socketneural);
           }

         //Comment("Open1 = %G\nHigh1 = %G\nLow1 = %G\nClose1 = %G\nOpen2 = %G\nHigh2 = %G\nLow2 = %G\nClose2 = %G",open1,high1,low1,close1,open2,high2,low2,close2);
         /*double Ask,Bid;
         int Spread;
         Ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         Bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         Spread=SymbolInfoInteger(Symbol(),SYMBOL_SPREAD);
         //--- Exibe valores em 3 linhas
         Comment(StringFormat("Mostrar preços\nAsk = %G\nBid = %G\nSpread = %d",Ask,Bid,Spread));*/


        }
     }
//+------------------------------------------------------------------+
//| OPERAÇÃO DO EA DENTRO DO HORÁRIO PRÉ DEFINIDO                    |
//+------------------------------------------------------------------+
   if(HorarioEntrada()) //VERIFICAÇÃO DE HORÁRIO PARA FUNCIONAMENTO DO EA
     {
      if(!(HorarioPausa1() || HorarioPausa2()))
        {
         if(ativaentradaea==true) //ATIVA AS COMPRAS PELO EA DENTRO DO HORARIO DO FUNCIONAMENTO
           {
            if(percent_margem>nivelcompra||saldo==capital) //PERMITE OU NÃO A OPERAÇÃO EM FUNÇÃO DO NÍVEL DE MARGEM DE MARGEM LIVRE
              {
              }
           }
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
//| Enviando comandos para o servidor                                |
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
//| Lendo a resposta do servidor                                     |
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
            result+=CharArrayToString(rsp,0,rsp_len);
        }
     }
   while(GetTickCount()<timeout_check && !IsStopped());
   return(result);
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
//+------------------------------------------------------------------------------------------+
