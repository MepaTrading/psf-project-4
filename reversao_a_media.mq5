//+--------------------------------------------------------------------------------+
//|Atividade 04 - Prototipo de EA Metatrader Melhorado                             |
//|Universidade de Brasília - UnB                                                  |
//|Campus UnB Gama                                                                 |
//|Disciplina: Processamento Digital de Sinais Financeiros                         |
//|Lucas Malta, Romeu Carvalho e Victor Moura                                      |
//+--------------------------------------------------------------------------------+
#property script_show_inputs
#property copyright "Marcelino Andrade, Lucas Malta, Romeu Carvalho e Victor Moura"
#property version   "1.002"
#property description "The real trial version - 31/12/2019"
#resource "vwap.ex5"
#include <Trade\Trade.mqh>
CTrade Trade;
//+------------------------------------------------------------------+
//| Variáveis de Entradas e Outros Detalhes                          |
//+------------------------------------------------------------------+
input group                  "PROTÓTIPO FUNCIONAL DE REVERSÃO À MÉDIA:"
sinput string                 Name0; // Universidade de Brasília - Campus UnB Gama - Engenharias
sinput string                 Name1; // Atividade 04: Processamento Digital de Sinais Financeiros - UnB
sinput string                 Name2; // Autores: Marcelino Andrade, Lucas Malta, Romeu Carvalho e Victor Moura
input group                   "ASPECTOS GERAIS:"
sinput ulong                 MagicNumber=1111;// Magic Number:
input double                 FixedVolume = 1;// Volume Operacional;
input group                   "LÓGICA DE ENTRADA:"
input int                        Periodovwap=12;// Periodo da Media VWAP;
input double                 Distanciavwap=700;// Distância da Media VWAP;
input group                   "ASPECTOS DA ORDEM:"
enum Operacao
  {
   Comprado=0, // Somente Comprado
   Vendido=1, //  Somente Vendido
   Comprado_Vendido=2, // Comprado e Vendido
  };
input Operacao            Tipo_de_Operacao=Comprado_Vendido; // Natureza da Operação;

enum Ordem
  {
   Mercado = 0, // A Mercado
   PendenteA=1, // Pendente Limit (ATIVIDADE 01)
   PendenteB=2, // Pendente Stop (ATIVIDADE 02)
  };
input Ordem                Tipo_de_Ordem=Mercado;// Natureza da Ordem (ATIVIDADES 01 E 02):
input double                DistanciaPEN = 0;// Distancia da Ordem Pendente (ATIVIDADES 01 E 02);
input int                       DuracaoPEN = 0;// Duraçao da Ordem Pendente (ATIVIDADES 01 E 02);
input group                  "LUCRO E PROTEÇÃO:"
enum  StopGain
  {
   Sem_StopGain=0, // Desabilitado
   Com_StopGainA=1, // StopGain [Pts]
  };
input StopGain           Tipo_de_Profit=Com_StopGainA; // Estratégia de Lucro:
input int                      TakeProfit = 1000; // Distancia StopGain [pts];
enum  Stop
  {
   Sem_StopLoss=0, // Desabilitado
   Com_StopLossA=1, // StopLoss [Pts]
   Retorno_Media=2, // Retorno a Média
   StopLoss_Media=3, // Retorno a Média e StopLoss [Pts]
  };
input Stop                   Tipo_de_Stop=StopLoss_Media;  // Estratégia de Proteção:
input int               TakeLoss = 800; // Distancia StopLoss [pts];
input group                 "DEFINIÇÕES TEMPORAIS:"
enum horas
  {
   h09=9, //09 horas
   h10=10, //10 horas
   h11=11, //11 horas
   h12=12, //12 horas
   h13=13, //13 horas
   h14=14, //14 horas
   h15=15, //15 horas
   h16=16, //16 horas
   h17=17, //17 horas
  };
enum minutos
  {
   m00=0, //00 minuto
   m05=5, //05 minutos
   m10=10, //10 minutos
   m15=15, //15 minutos
   m20=20, //20 minutos
   m25=25, //25 minutos
   m30=30, //30 minutos
   m35=35, //35 minutos
   m40=40, //40 minutos
   m45=45, //45 minutos
   m50=50, //50 minutos
   m55=55, //55 minutos
  };


enum ENUM_MA_TIMEFRAME
  {
   M1,
   M5,
   M15,
   M30,
   H1,
   H4,
   Diario,
   Semanal,
  };
input ENUM_MA_TIMEFRAME  MA_Chart_Timeframe = M15; // Tempo Gráfico:
enum Modo
  {
   Continuo = 0, // SwingTrade
   DayTrade=1, // DayTrade
   DayTradeO=1, // DayTrade One  (ATIVIDADE 03)
  };
input Modo                  Tipo_de_Modos=DayTrade;// Modos Operacionais  (ATIVIDADE 03);


input horas                  horaInicio=h09; // Hora Inicial para Abrir Posiçoes;
input minutos              minutoInicio=m15; // Minuto Inicial para Abrir Posiçoes;
input horas                  horaFim=h10; // Hora Final para Abrir Posicoes;
input minutos              minutoFim=m30; // Minuto Final para Abrir Posicoes
input horas                  horaTerm=h11; // Hora de Fechamento DayTrade;
input minutos              minutoTerm=m00; // Minuto de Fechamento DayTrade;
input int            timeframeMinutes=1440; // Janela de operação DayTrade;

input group                  "ASPECTOS AUXILIARES:"

enum fill
  {
   FOK = 0, // FOK
   IOC  = 1, // IOC
   RETURN = 2, // RETURN
  };
input fill                      Tipo_de_Fill=RETURN; // Modos de Preenchimento;
enum avaliar
  {
   Fun_01 = 0, // Função 01
   Fun_02 = 0, // Função 02
   Fun_03 = 0, // Função 03
  };
input avaliar               Fun_OnTester=Fun_01; // Funções de Avaliação  (ATIVIDADE 04);
ENUM_TIMEFRAMES  MA_Timeframe;
int VWAP;
double vwap[];
double close[];
bool Buy_Condition = false;
bool Sell_Condition = false;
MqlDateTime horario_inicio,horario_termino,horario_fechamento,horario_atual;
string inicio="";
string termino="";
string fechamento="";
static int bars=0;
//+------------------------------------------------------------------+
//| Variáveis do Painel                                               |
//+------------------------------------------------------------------+
#include <Comment.mqh>
//---
#define EXPERT_NAME           "Reversão à Média"
#define EXPERT_VERSION      "1.0"
//--- custom colors
#define COLOR_BACK              clrRed
#define COLOR_BORDER         clrDimGray
#define COLOR_CAPTION        clrDodgerBlue
#define COLOR_TEXT               clrLightGray
#define COLOR_WIN                 clrLimeGreen
#define COLOR_LOSS              clrCrimson
//--- input parameters
input bool                                   InpAutoColors=true;//Auto Colors
input string                                 title_ea_options="=== EA Options ===";//EA Options
//--- global variables
CComment comment;
int tester;
int visual_mode;
int remainingSeconds;
string operando = "Sim";


//+------------------------------------------------------------------+
//| Atividades de Inicialização                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//+------------------------------------------------------------------+
//| Condições de erros nas entradas de horario        |
//+------------------------------------------------------------------+
   StringConcatenate(inicio,horaInicio,":",minutoInicio);
   StringConcatenate(termino,horaFim,":",minutoFim);
   StringConcatenate(fechamento,horaTerm,":",minutoTerm);
   TimeToStruct(StringToTime(inicio),horario_inicio);
   TimeToStruct(StringToTime(termino),horario_termino);
   TimeToStruct(StringToTime(fechamento),horario_fechamento);
   bool cond01 = (horario_inicio.hour>horario_termino.hour);
   bool cond02 = (horario_inicio.hour==horario_termino.hour && horario_inicio.min>horario_termino.min);
   bool cond03 = (horario_termino.hour>horario_fechamento.hour);
   bool cond04 = (horario_termino.hour==horario_fechamento.hour && horario_termino.min>horario_fechamento.min);
   bool cond05 = (timeframeMinutes <= 0);
   remainingSeconds = timeframeMinutes*60;
   if(cond01 || cond02 || cond03 || cond04 || cond05)
     {
      printf("Erro nos Parametros de Horários!");
      return INIT_FAILED;
     }

//+------------------------------------------------------------------+
// Típos de Preenchimentos                                     |
//+------------------------------------------------------------------+
   switch(Tipo_de_Fill)
     {
      case FOK:
         Trade.SetTypeFilling(ORDER_FILLING_RETURN);  ;
         break;
      case IOC:
         Trade.SetTypeFilling(ORDER_FILLING_RETURN);  ;
         break;
      case RETURN:
         Trade.SetTypeFilling(ORDER_FILLING_RETURN);  ;
         break;
     }
//+------------------------------------------------------------------+
// Time Frames Operacionais                                   |
//+------------------------------------------------------------------+
   switch(MA_Chart_Timeframe)
     {
      case M1:
         MA_Timeframe = PERIOD_M1;
         break;
      case M5:
         MA_Timeframe = PERIOD_M5;
         break;
      case M15:
         MA_Timeframe = PERIOD_M15;
         break;
      case M30:
         MA_Timeframe = PERIOD_M30;
         break;
      case H1:
         MA_Timeframe = PERIOD_H1;
         break;
      case H4:
         MA_Timeframe = PERIOD_H4;
         break;
      case Diario:
         MA_Timeframe = PERIOD_D1;
         break;
      case Semanal:
         MA_Timeframe = PERIOD_W1;
         break;
     }
//+--------------------------------------------------------------------------+
// Indicador Customizado e criação de Séries Temporais  |
//+--------------------------------------------------------------------------+
   VWAP=iCustom(_Symbol,MA_Timeframe,"vwap.ex5",Periodovwap);
   if(VWAP<0)
     {
      Alert(" Erro ao Criar Indicador VWAP - error: ",GetLastError(),"!!");
      return INIT_FAILED;
     }
   ArraySetAsSeries(vwap,true);

   ArraySetAsSeries(close,true);
//+--------------------------------------------------------------------------+
// Configuração do Gráfico Inicial                                       |
//+--------------------------------------------------------------------------+
   long handle=ChartID();
   if(handle>0)
     {
      ChartSetInteger(handle,CHART_SHIFT,true);
      ChartSetInteger(handle,CHART_MODE,CHART_CANDLES);
      ChartNavigate(handle,CHART_CURRENT_POS,100);
      ChartSetInteger(handle,CHART_SHOW_VOLUMES,CHART_VOLUME_TICK);
      ChartSetInteger(handle,CHART_SHOW_GRID,false);
      ChartSetInteger(handle,CHART_COLOR_BACKGROUND,Black);
     }

//+------------------------------------------------------------------+
//| Inicializando Painel      |
//+------------------------------------------------------------------+
   tester=MQLInfoInteger(MQL_TESTER);
   visual_mode=MQLInfoInteger(MQL_VISUAL_MODE);
//--- panel position
   int y=30;
   if(ChartGetInteger(0,CHART_SHOW_ONE_CLICK))
      y=120;
//--- panel name
   srand(GetTickCount());
   string name="panel_"+IntegerToString(rand());
   comment.Create(name,20,y);
//--- panel style
   comment.SetAutoColors(InpAutoColors);
   comment.SetColor(COLOR_BORDER,COLOR_BACK,255);
   comment.SetFont("Lucida Console",16,false,1.7);
//---
#ifdef __MQL5__
   comment.SetGraphMode(!tester);
#endif
//--- not updated strings
   comment.SetText(0,StringFormat("Expert: %s v.%s",EXPERT_NAME,EXPERT_VERSION),COLOR_CAPTION);
   comment.SetText(1,"Timeframe: "+StringSubstr(EnumToString(MA_Timeframe),7),COLOR_TEXT);
   comment.SetText(2,StringFormat("Volume: %.2f",FixedVolume),COLOR_TEXT);
   comment.SetText(3,StringFormat("Stop Loss: %d pts",TakeLoss),COLOR_LOSS);
   comment.SetText(4,StringFormat("Take Profit: %d pts",TakeProfit),COLOR_WIN);
   comment.SetText(5,"Time: "+TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS),COLOR_TEXT);
   comment.SetText(6,"Price: "+DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits),COLOR_TEXT);
   comment.SetText(7,"Ativo: "+Symbol(),COLOR_TEXT);
   comment.SetText(8,StringFormat("Magic: %d",MagicNumber),COLOR_TEXT);
   comment.SetText(9, StringFormat("Timeframe restante: %d h(s) %d min(s) %d sec(s)", remainingSeconds/3600 , (remainingSeconds%3600)/60, (remainingSeconds%3600)%60), COLOR_TEXT);
   comment.SetText(10,StringFormat("Operando: %s", operando),COLOR_TEXT);
   comment.SetText(11,"Autor: Prof. Marcelino Andrade e alunos",COLOR_TEXT);
   comment.Show();
//--- run timer
   if(!tester)
      EventSetTimer(1);
   OnTimer();
//--- done
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(VWAP);
   ArrayFree(vwap);
   ArrayFree(close);
   comment.Destroy();
  }
//+------------------------------------------------------------------+
//| OnTimer                                                          |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(!tester || visual_mode)
     {
       int horas = remainingSeconds/3600;
       int mins = (remainingSeconds%3600)/60;
       int secs = (remainingSeconds%3600)%60;
      remainingSeconds-=1;
      
      if(remainingSeconds < 0) remainingSeconds = 0; // Preventing remainingSeconds from assuming negative values

      if(remainingSeconds <= 0) operando = "Não";

      comment.SetText(10,StringFormat("Operando: %s", operando),COLOR_TEXT);
      comment.SetText(5,"Time: "+TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS),COLOR_TEXT);
      comment.SetText(9, StringFormat("Timeframe restante: %d h(s) %d min(s) %d sec(s)", horas, mins, secs), COLOR_TEXT);
      comment.Show();

     }
  }
//+------------------------------------------------------------------+
//| Atividades a Cada Tick                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//+------------------------------------------------------------------+
// Painel Execução         |
//+------------------------------------------------------------------+
   if(!tester || visual_mode)
     {
      comment.SetText(6,"Price: "+DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits),COLOR_TEXT);
      comment.Show();
     }

//+------------------------------------------------------------------+
// Copiando e Testando Valores em Variáveis         |
//+------------------------------------------------------------------+
   if(CopyClose(_Symbol,0,0,3,close)<0)
     {
      Alert("Erro Copiando o Preço - error:",GetLastError(),"!!");
      ResetLastError();
      return;
     }

   if(CopyBuffer(VWAP,0,0,4,vwap)<0)
     {
      Alert("Erro Copiando o VWAP - error:",GetLastError());
      ResetLastError();
      return;
     }
//+------------------------------------------------------------------+
// Verificando o Status de Posições                          |
//+------------------------------------------------------------------+
   bool Buy_opened=false;
   bool Sell_opened=false;
   if(PositionSelect(_Symbol)==true)
     {
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         Buy_opened=true;
        }
      else
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
           {
            Sell_opened=true;
           }
     }
//+------------------------------------------------------------------+
// Logica de Entradas e Horários Válidos                  |
//+------------------------------------------------------------------+
   Buy_Condition = false;
   Sell_Condition = false;

   if(IsNewBarMin() && HorarioEntrada())
     {
      Buy_Condition = (vwap[0]-close[0]>Distanciavwap);
      Sell_Condition = (close[0]-vwap[0]>Distanciavwap);
     }

//+------------------------------------------------------------------+
// Operações Compradas                                          |
//+------------------------------------------------------------------+
   if(Tipo_de_Operacao == Comprado || Tipo_de_Operacao == Comprado_Vendido)
     {
      if(!Buy_opened && !Sell_opened && Buy_Condition)
        {
         Market_Buy();
        }
     }
//+------------------------------------------------------------------+
// Operações Vendidas                                             |
//+------------------------------------------------------------------+
   if(Tipo_de_Operacao==Vendido || Tipo_de_Operacao==Comprado_Vendido)
     {
      if(!Buy_opened && !Sell_opened && Sell_Condition)
        {
         Market_Sell();
        }
     }
//+------------------------------------------------------------------+
//| Condição de Saida na Média                                |
//+------------------------------------------------------------------+
   if(Tipo_de_Stop == Retorno_Media || Tipo_de_Stop == StopLoss_Media)
     {
      if(Buy_opened && close[0]-vwap[0]>0)
        {
         ClosePositionByMagic(MagicNumber,"Média");
        }
      if(Sell_opened && vwap[0]-close[0]>0)
        {
         ClosePositionByMagic(MagicNumber,"Média");
        }
     }
//+------------------------------------------------------------------+
//| Condição de Saida no Tempo                               |
//+------------------------------------------------------------------+
   if((Tipo_de_Modos==DayTrade) && (HorarioFechamento()))
      ClosePositionByMagic(MagicNumber,"Tempo");
  }
//+------------------------------------------------------------------+
// Ordem a Mercado de Compra                                |
//+------------------------------------------------------------------+
void Market_Buy()
  {
   double positionPriceASK = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double positionPriceBID = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   double TakeProfitPoint = 0;
   double StopLossPoint = 0;
   bool M_Buy = false;

   if(Tipo_de_Profit==Sem_StopGain)
      TakeProfitPoint = 0;
   if(Tipo_de_Profit==Com_StopGainA)
      TakeProfitPoint = NormalizeDouble(positionPriceASK + TakeProfit,2);

   if(Tipo_de_Stop==Sem_StopLoss)
      StopLossPoint = 0;
   if(Tipo_de_Stop==Com_StopLossA)
      StopLossPoint = NormalizeDouble(positionPriceBID - TakeLoss,2);
   if(Tipo_de_Stop==StopLoss_Media)
      StopLossPoint = NormalizeDouble(positionPriceBID - TakeLoss,2);

   Trade.SetExpertMagicNumber(MagicNumber);
   M_Buy = Trade.Buy(FixedVolume,_Symbol,positionPriceASK,StopLossPoint,TakeProfitPoint);
//+------------------------------------------------------------------+
// Verificação da Ordem de Compra                         |
//+------------------------------------------------------------------+
   if(!M_Buy)
     {
      Print(__FUNCTION__,"::Método Falhou. Return code=",Trade.ResultRetcode(),
            ". Descrição do código: ",Trade.ResultRetcodeDescription(),", Magic=",MagicNumber);
     }
   else
     {
      Print(__FUNCTION__,"::Metodo Executado com Sucesso. Return code=",Trade.ResultRetcode(),
            " (",Trade.ResultRetcodeDescription(),")",", Magic=",MagicNumber);
     }
  }
//+------------------------------------------------------------------+
// Ordem a Mercado de Venda                                 |
//+------------------------------------------------------------------+
void Market_Sell()
  {
   double positionPriceASK = SymbolInfoDouble(_Symbol,SYMBOL_ASK);//AdjustAboveStopLevel(_Symbol,PositionGetDouble(POSITION_PRICE_OPEN));
   double positionPriceBID = SymbolInfoDouble(_Symbol,SYMBOL_BID);//AdjustAboveStopLevel(_Symbol,PositionGetDouble(POSITION_PRICE_OPEN));

   double TakeProfitPoint = 0;
   double StopLossPoint = 0;
   bool M_Sell = false;

   if(Tipo_de_Profit==Sem_StopGain)
      TakeProfitPoint = 0;
   if(Tipo_de_Profit==Com_StopGainA)
      TakeProfitPoint = NormalizeDouble(positionPriceBID - TakeProfit,2);

   if(Tipo_de_Stop==Sem_StopLoss)
      StopLossPoint = 0;
   if(Tipo_de_Stop==Com_StopLossA)
      StopLossPoint = NormalizeDouble(positionPriceASK + TakeLoss,2);
   if(Tipo_de_Stop==StopLoss_Media)
      StopLossPoint = NormalizeDouble(positionPriceASK + TakeLoss,2);

   Trade.SetExpertMagicNumber(MagicNumber);
   M_Sell = Trade.Sell(FixedVolume,_Symbol,positionPriceBID,StopLossPoint,TakeProfitPoint);
//+------------------------------------------------------------------+
// Verificação da Ordem de Compra                         |
//+------------------------------------------------------------------+
   if(!M_Sell)
     {
      Print(__FUNCTION__,"::Método Falhou. Return code=",Trade.ResultRetcode(),
            ". Descrição do código: ",Trade.ResultRetcodeDescription(),", Magic=",MagicNumber);
     }
   else
     {
      Print(__FUNCTION__,"::Método Executado com Sucesso. Return code=",Trade.ResultRetcode(),
            " (",Trade.ResultRetcodeDescription(),")",", Magic=",MagicNumber);
     }
  }
//+------------------------------------------------------------------+
// Fechamento de Ordem by Magic                          |
//+------------------------------------------------------------------+
void ClosePositionByMagic(long const magic_number, string comment)
  {
   ulong ticket;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if((ticket=PositionGetTicket(i))>0)
         if(magic_number==PositionGetInteger(POSITION_MAGIC))
           {
            double ticket_volume=PositionGetDouble(POSITION_VOLUME);
            if(ticket_volume>0)
              {
               Trade.PositionClose(ticket);
               Print(__FUNCTION__,"::Magic = ",
                     magic_number," Ticket = ",ticket," Volume = ",ticket_volume," Close by = ", comment);
              }
           }
  }
//+------------------------------------------------------------------+
// Condições Horárias de Operação                          |
//+------------------------------------------------------------------+
bool HorarioEntrada()
  {
   TimeToStruct(TimeCurrent(),horario_atual);

   bool cond0  = (horario_atual.hour > horario_inicio.hour);
   bool cond1  = (horario_atual.hour < horario_termino.hour);
   bool cond2  = (horario_atual.hour == horario_inicio.hour && horario_atual.min >= horario_inicio.min);
   bool cond3  = (horario_atual.hour == horario_termino.hour && horario_atual.min <= horario_termino.min);
   bool cond4 = (remainingSeconds > 0);

   if(cond4){
     if((cond0 && cond1) || cond2 || cond3){
        return true;
     }
   }
    
    return false;
  }
//+------------------------------------------------------------------+
// Condições Horárias de Fechamento                      |
//+------------------------------------------------------------------+
bool HorarioFechamento()
  {
   TimeToStruct(TimeCurrent(),horario_atual);

   bool cond0 = (horario_atual.hour > horario_fechamento.hour);
   bool cond1 = (horario_atual.hour == horario_fechamento.hour) && (horario_atual.min >= horario_fechamento.min);
   bool cond2 = (remainingSeconds <= 0);

   if(cond0 || cond1 || cond2)
      return true;
   else
      return false;
  }
//+------------------------------------------------------------------+
//| Nova Barra de Minuto                                                  |
//+------------------------------------------------------------------+
bool IsNewBarMin()
  {
   if(bars!=Bars(_Symbol,PERIOD_M1))
     {
      bars=Bars(_Symbol,PERIOD_M1);
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
