//+------------------------------------------------------------------+
//|Aula 6 - Indicadores VWAP                                         |
//|Universidade de Brasília - UnB                                    |
//|Campus UnB Gama                                                   |
//|Disciplina: Processamento Digital de Sinais Financeiros           |
//|Prof. Marcelino Monteiro de Andrade Dr.                           |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Indicator information                                            |
//+------------------------------------------------------------------+
#property copyright "Marcelino Andrade / mrclnndrd@gmail.com"
#property version   "2.00" 
#property description "Implementa o indicador 'VWAP'"
#property description "The real trial version - 31/12/2019"

//+------------------------------------------------------------------+
//| Indicator #property                                            |
//+------------------------------------------------------------------+

// Gráfico do indicador sobreposto ao preço
#property indicator_chart_window             

// Quatro buffers operacionais,sendo um de cor
#property indicator_buffers 4               

// Quantidade de gráficos
#property indicator_plots   1               

// Nome do indicador no gráfico
#property indicator_label1  "VWAP"          

// Exemplos: DRAW_HISTOGRAM, DRAW_LINE
#property indicator_type1   DRAW_COLOR_LINE

// Exemplos: clrGreen,clrOrange,clrDeepPink   
#property indicator_color1  clrRed,clrBlue    

// Exemplos: STYLE_SOLID, STYLE_DOT
#property indicator_style1  STYLE_DASHDOT    

// Espessura do indicador
#property indicator_width1  2                

//#include <Math\Stat\Math.mqh>

// Período VWAP
input uint VWAPPeriod=5; 

// Array dinâmico do Preço 
double         PriceBuffer[];         

// Array dinâmico do Volume        
double         VolumeBuffer[];  

// Array dinâmico de Saída              
double         VWAPBuffer[];   

// Array dinâmico de Cores do Indicador               
double         VWAPColor[];                  

//Permissões
const string allowed_names[] = {"Tester","MONTEIRO DE ANDRADE Marcelino","XXXXXX"}; 
int password_status = -1;	

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
// vinculando buffer 0 ao array dinâmico VWAPBuffer como saida para o gŕafico
   SetIndexBuffer(0,VWAPBuffer,INDICATOR_DATA); 

// vinculando buffer 0 ao array dinâmico PriceBuffer para calculo intermediário   
   SetIndexBuffer(2,PriceBuffer,INDICATOR_CALCULATIONS); 

// vinculando buffer 0 ao array dinâmico VolumeBuffer para calculo intermediário   
   SetIndexBuffer(3,VolumeBuffer,INDICATOR_CALCULATIONS); 

// vinculando buffer 0 ao array dinâmico VWAPColor para cores   
   SetIndexBuffer(1,VWAPColor,INDICATOR_COLOR_INDEX); 

//Precisão de desenho de valores do indicador   
   IndicatorSetInteger(INDICATOR_DIGITS,4); 


// Autenticação do Indicador   
   datetime expire_date = D'31.12.2019'; //<-- hard coded datetime
   if (TimeCurrent() >= expire_date)   
   {
   Alert ("The real trial version has been expired!");
   return INIT_FAILED;
   }
   string name = AccountInfoString(ACCOUNT_NAME);
   string account = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));  
   for (int i=0; i<ArraySize(allowed_names); i++)
   if (name == allowed_names[i] || account == allowed_names[i] || 1) 
       { 
         password_status = 1;
         Comment(StringFormat("Autenticado: %s",name)); 
         break;
       }  
   if (password_status == -1) 
      {
      Alert ("Nome não autenticado."); 
      return INIT_FAILED;
      } 
   if(VWAPPeriod==0)
   {
      return INIT_FAILED;
   }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(prev_calculated==0)
     {
      // Inicia Array/Buffer Vazio
      ArrayInitialize(VWAPBuffer,EMPTY_VALUE); 
      ArrayInitialize(PriceBuffer,EMPTY_VALUE); 
      ArrayInitialize(VolumeBuffer,EMPTY_VALUE); 
     }

   PriceBuffer[0]=0.0;
   VolumeBuffer[0]=1.0;


  //Atualiza a cada barra o buffer de preço e volumne   
   for(int i=MathMax(1,prev_calculated); i<rates_total && !IsStopped(); i++) 
     {
      PriceBuffer[i]=NormalizeDouble((close[i]+high[i]+low[i])/3,2);
      VolumeBuffer[i]=tick_volume[i];
  //    Print("A=",i, "    B=",PriceBuffer[i], "    C=",VolumeBuffer[i]);
     }
     
 // Iniciando o intervalo de varredura acima do periodo do indicador      
   for(int p=MathMax(VWAPPeriod+1,prev_calculated); p<rates_total && !IsStopped(); p++) 
     {
//      Print("A=",p, "    B=",prev_calculated, "    C=",rates_total);
      double sumPrice=0,sumVol=0;
 
// Calculando o Indicador      
       for(int q=0; q<VWAPPeriod && p-q>=0; q++)
        {
         sumPrice += PriceBuffer[p-q]*VolumeBuffer[p-q];
         sumVol   += VolumeBuffer[p-q];
        } 
        
// Resultado do Indicador e cores no Gráfico          
       VWAPBuffer[p]= sumPrice/sumVol;   
       VWAPColor[p]=(VWAPBuffer[p]-VWAPBuffer[p-1]>0 ? 1: 0);
     }
   return(rates_total-1);
  }
//+------------------------------------------------------------------+