//+------------------------------------------------------------------+
//|                                                       DAX-40.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Informacion del Asesor                                 
//+------------------------------------------------------------------+





#property copyright "Copyright 2024, MetaQuotes Ltd."
#property  description "Asesor experto que aplica la estrategia dax 40 v 1.0, esta consiste en tres señales, en esta version la suma de dos señales seran suficientes para entrar, una señal sera la tendencia que entregue el cruce de dos medias moviles, la segunda señal sera una diferencia menor o igual de 150 puntos entre un 0 o un 00 con el 30, 50, 60 de fibonacci, la tercera señal sera un fibonacci 30,50,60 que coincida con la tendencia del cruce de las medias moviles"
#property link      ""
#property version   "1.00"



//+------------------------------------------------------------------+
//| Notas del Asesor                                
//+------------------------------------------------------------------+
//
//+------------------------------------------------------------------+
//| AE Enumeraciones                                 
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Variables Input y globales                                
//+------------------------------------------------------------------+

sinput group                                          "### AJUSTES GENERALES ###"
input ulong                                           MagicNumberFIBOMA                    = 101;
input ulong                                           MagicNumberFIBONi                    = 102;
input ulong                                           MagicNumberREBFIBO                   = 103;

sinput group                                          "### AJUSTES MEDIA MOVIL ###"
input int                                             PeriodoMALenta                      = 21; 
input int                                             PeriodoMARapida                     = 10;
input ENUM_MA_METHOD                                  MetodoMALenta                       = MODE_EMA;
input ENUM_MA_METHOD                                  MetodoMARapida                      = MODE_EMA;
input int                                             ShiftMALenta                        = 0;
input int                                             ShiftMARapida                       = 0;
input ENUM_APPLIED_PRICE                              PrecioMALenta                       = PRICE_CLOSE;
input ENUM_APPLIED_PRICE                              PrecioMARapida                      = PRICE_HIGH;

sinput group "### GESTION ESTRATEGIA ###"
input int                                             DeltaMASignal                       = 10;
input double                                          DeltaFiboNivelPsico                 = 1.5;


sinput group "### GESTION MONETARIA ###"
input double                                          VolumenFijo                         = 0.1;

sinput group "### GESTION DE POSICIONES ###"
input ushort                                          SLPuntosFijos                       = 15;
input ushort                                          SLPuntosFijosMA                     = 0;
input ushort                                          TPPuntosFijos                       = 30;
input ushort                                          TSPuntosFijos                       = 0;
input ushort                                          BEPuntosFijos                       = 0;

sinput group "### GESTION DE variables globales ###"
datetime glTiempoBarraApertura;
datetime glTiempoBarraAperturaBase;
int ManejadorMARapida;
int ManejadorMALenta;
int SumSignal;
   double cierre1;        
   double cierre2;
   double high1;
   double high2; 
   double low1; 
   double low2; 
double altoMasAlto;
double bajoMasBajo;
double altoMasAltoRetroceso;
double bajoMasBajoRetroceso;



double serieFibonacci[3];
double serieFibonacciRetrocesoLargo[3];
double serieFibonacciRetrocesoCorto[3];
double nivelesPsicologicos[4];
string tendenciaImpulsoFibo;
datetime expirationTimeOrder;
double verificacionFiboMA;
double verificacionFiboPsico;
double verificacionfiboRebote;



//+------------------------------------------------------------------+
//| Procesador de eventos                                
//+------------------------------------------------------------------+








int OnInit()
{
   glTiempoBarraApertura = D'1971.01.01 00:00';
 /*  
// verificando entre la vela 1 y 2 cual tiene el valor de alto mas alto y bajo mas bajo
   high1 = High(1);
   high2 = High(2);
   low1 = Low(1);
   low2 = Low(2);
   
   altoMasAlto = Retornar_Magnitud_Mayor(high1, high2);
   bajoMasBajo = Retornar_Magnitud_Menor(low1, low2);
*/
 
//inicializando los manejadores de las MA

   ManejadorMALenta = MA_Init(PeriodoMALenta,ShiftMALenta,MetodoMALenta,PrecioMALenta);
   ManejadorMARapida = MA_Init(PeriodoMARapida,ShiftMARapida,MetodoMARapida,PrecioMARapida);

// manejo de errores, si hay algun error con la inizalizacion de las MA que retorne un error que detenga la ejecucion del bot  
   if(ManejadorMALenta == -1 || ManejadorMARapida == -1)
     {
      return (INIT_FAILED);
     }// if
      else
         {
          return (INIT_SUCCEEDED);
         }// else
   SumSignal = 0;
   return(INIT_SUCCEEDED);       
   
}//oninit

void OnDeinit(const int reason)
{

   Print("Asesor Eliminado");
   
}//ondeinit

void OnTick()
{




         //------------------------//
         // control de nueva barra //
         //------------------------//

   bool nuevaBarra = false;
   
// comprobacion de nueva barra
   if(glTiempoBarraApertura != iTime(_Symbol,PERIOD_CURRENT,0))
     {
         //nuevaBarra = true;  
         glTiempoBarraApertura = iTime(_Symbol,PERIOD_CURRENT,0); 
         
// preguntando si en el servidor estoy en la hora 10
   MqlDateTime aperturaMercado;
   TimeToStruct (glTiempoBarraApertura,aperturaMercado); 
   if((aperturaMercado.hour == 9 && aperturaMercado.min >= 47) || aperturaMercado.hour == 10 || (aperturaMercado.hour == 16 && aperturaMercado.min >= 17) || (aperturaMercado.hour == 17 && aperturaMercado.min <= 30))
     {

      nuevaBarra = true;
     }//if  
     else
       {
// en el momento en que esto ya no se cumpla es porque cerro el tiempo de apertura por lo tanto hay nulizar todas las variables que se relacionan con dar las señales
// perro, gato, bueno =0;
         altoMasAlto=0.0;
         bajoMasBajo=1000000.0;
               
Print("alto mas alto: ", altoMasAlto);
Print("bajo mas bajo: ", bajoMasBajo);   

                        
                            
                            
                          
                 
         
             
       }         
            
     }//if  
   if(nuevaBarra == true)
     {
   
//////////////////determinando el time para el vencimiento de las ordenes//////////////////////////
  glTiempoBarraAperturaBase = TimeCurrent();
  MqlDateTime aperturaMercadoBase;
  TimeToStruct (glTiempoBarraAperturaBase,aperturaMercadoBase); 
if((aperturaMercadoBase.hour == 9 && aperturaMercadoBase.min == 47) || (aperturaMercadoBase.hour == 16 && aperturaMercadoBase.min == 17)) 
  {
      expirationTimeOrder = TimeCurrent() + 4500;  
      Print("expiration: ", expirationTimeOrder);   
  }   

      Print("expiration: ", expirationTimeOrder);  

   
         //---------------------------------------------------------------------------------------//
         // variables locales que si no me equivoco se resetean sola en cada apertura de barra    //
         //---------------------------------------------------------------------------------------// 
//altoMasAlto=0.0;
//bajoMasBajo=100000;  
string signalFibo;
string signalFiboRetrocesoLargo;
string signalFiboRetrocesoCorto;

serieFibonacci[0]=0;
serieFibonacci[1]=0;
serieFibonacci[2]=0;






 







   
   
   
   
   
     
         //------------------------//
         // Precio e Inicadores    //
         //------------------------//
// ejecutando funcion que llama al valor de los precios relacionados con cada barra segun su shift
   
   cierre1 = Close(1);        
   cierre2 = Close(2);
   high1 = High(1);
   high2 = High(2);
   low1 = Low(1);
   low2 = Low(2);

   
// ejecutando funcion que compara alto mas alto y el bajo mas bajo
   
   altoMasAlto = Retornar_Magnitud_Mayor(high1, altoMasAlto);
   bajoMasBajo = Retornar_Magnitud_Menor(low1, bajoMasBajo);
Print("alto mas alto: ", altoMasAlto);
Print("bajo mas bajo: ", bajoMasBajo);
double deltaPrecios = altoMasAlto-bajoMasBajo; 
Print("Delta Precio: ", deltaPrecios);  

///////////////////// FIBONACHI////////////////////////////////////////////////////////


// ejecutnado funcion que compara las diferencia de puntos entre el alto mas alto y el bajo mas bajo del impulso, dando señal "OPERAR" cuando sea mayor o igual a 3000 puntos

   signalFibo = Signal_Magnitud_Fibo(altoMasAlto, bajoMasBajo);
   
// ejecuntado funcion que retorna la serie de fibonacci de nuestro impulso si cumple la señal de entrada del fibonacci

   Serie_Fibo(serieFibonacci,signalFibo,tendenciaImpulsoFibo,altoMasAlto,bajoMasBajo);
      

// ejecutando funcion que compara el retroceso de nuestra onda alcista, este compara el alto mas alto con el bajo actual, de cumplir el delta ejecuta la serie de fibonacci

   signalFiboRetrocesoLargo = Signal_Magnitud_Fibo(altoMasAlto, low1);
   Serie_Fibo(serieFibonacciRetrocesoLargo, signalFiboRetrocesoLargo ,"CORTO", altoMasAlto, low1);
   
   
// ejecutando funcion que compara el retroceso de nuestra onda bajista, este compara el bajo mas bajo con el alto actual, de cumplir el delta ejecuta la serie de fibonacci

   signalFiboRetrocesoCorto = Signal_Magnitud_Fibo(bajoMasBajo, high1);
   Serie_Fibo(serieFibonacciRetrocesoCorto, signalFiboRetrocesoCorto, "LARGO", bajoMasBajo, high1);   
   
// ejecuntando funcion que me da la tendendia del fibonacci///////////////////// 

   tendenciaImpulsoFibo = Tendencia_Fibo(altoMasAlto,high1);
   



   
   


 
 
///////////////////// FIBONACHI////////////////////////////////////////////////////////
 
   
 //////////////////////// barrera psicologica multiplo de 50///////////////////////////  
   
 //// llamando a la funcion que introduce en un array los niveles psicologicos multiplos de 50
 
 Niveles_psicologicos(nivelesPsicologicos, altoMasAlto, bajoMasBajo);
 

   
 ///////////////////////////////////////////////////////////////////////////////////////////////////   
       
// media movil MA

   double MALenta1= ma(ManejadorMALenta,1); 
   double MARapida1= ma(ManejadorMARapida, 1);
// controlando si el cruce de medias moviles esta en largo o en corto //
   string tendenciaMA = tendencia_Cruce_MA(MALenta1, MARapida1);
// verificando si el delta ma cumple para dar señal de "OPERAR" //   
   string signalMA = Signal_MA(MALenta1, MARapida1, DeltaMASignal);
  
    
   
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
 ///     llamando a la funcion que da la señal para entrar al mecado, compara fibo con niveles psicologicos, retorna el precio para entrar o 0 para no entrar        ///
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    
 double entradaOperarFiboPsico = signal_PriceReturn_Fibo_Psico(signalFibo, serieFibonacci, nivelesPsicologicos, DeltaFiboNivelPsico);
 
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
 ///     llamando a la funcion que da la señal para entrar al mecado, compara la señal del deltaMA y la tendencia fibo, de coincidir retorna el nivel 61 del fibo        ///
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////   
  
  double entradaOperarFiboMA = signal_PriceReturn_fibo_MA(signalMA, tendenciaMA, signalFibo, tendenciaImpulsoFibo, serieFibonacci);
      
         
         //------------------------//
         // colocacion de ordenes  //
         //------------------------//
         
         
/*         
 if((entradaOperarFiboMA != 0) && (Revision_Posicion_Colocada(MagicNumberFIBOMA)==false) && (Revision_Orden_Colocada(MagicNumberFIBOMA)==false))
   {
    double stopLossMA = Calcular_Stop_Loss(tendenciaMA,entradaOperarFiboMA,SLPuntosFijos);
    
    double takeProfitMA = Calcular_Take_Profit(tendenciaMA,entradaOperarFiboMA,TPPuntosFijos);
    
    ulong ticket = Apertura_Trades(tendenciaMA, MagicNumberFIBOMA , VolumenFijo, entradaOperarFiboMA, stopLossMA, takeProfitMA, expirationTimeOrder);
    
    Print("entrada fibo-MA: ", entradaOperarFiboMA, " stoploss: ", stopLossMA, " tprofit: ", takeProfitMA);     
   }     
  
  if((entradaOperarFiboPsico != 0) && (Revision_Posicion_Colocada(MagicNumberFIBONi)==false) && (Revision_Orden_Colocada(MagicNumberFIBONi)==false))
   {
    double stopLossFi = Calcular_Stop_Loss(tendenciaImpulsoFibo, entradaOperarFiboPsico, SLPuntosFijos);
    
    double takeProfitFi = Calcular_Take_Profit(tendenciaImpulsoFibo, entradaOperarFiboPsico, TPPuntosFijos); 
      
    ulong ticket = Apertura_Trades(tendenciaImpulsoFibo, MagicNumberFIBONi, VolumenFijo, entradaOperarFiboPsico, stopLossFi, takeProfitFi, expirationTimeOrder);
    
    Print("entrada fibo-psico: ", entradaOperarFiboPsico,  " stoploss: ", stopLossFi, " tprofit: ", takeProfitFi);      
   }   
 */        
 
 ////////////////////////colocacion orden con la estrategia FIBOMA ////////////////////////////////////
 ///////////// existe una posicion colocada?, de ser falso procedemos a colocar una orden/////////////
   
   if((entradaOperarFiboMA != 0) && (Revision_Posicion_Colocada(MagicNumberFIBOMA)==false))
     {   
         ///// primero verificamos que no existan ordenes////////////
         if(Revision_Orden_Colocada(MagicNumberFIBOMA)==false)
           {
                
                double stopLossMA = Calcular_Stop_Loss(tendenciaMA,entradaOperarFiboMA,SLPuntosFijos);
    
                double takeProfitMA = Calcular_Take_Profit(tendenciaMA,entradaOperarFiboMA,TPPuntosFijos);
                
                Print("entrando fibo-MA: ", entradaOperarFiboMA, " stoploss: ", stopLossMA, " tprofit: ", takeProfitMA);                   
    
                ulong ticket = Apertura_Trades(tendenciaMA, MagicNumberFIBOMA , VolumenFijo, entradaOperarFiboMA, stopLossMA, takeProfitMA, expirationTimeOrder);
                
                verificacionFiboMA = entradaOperarFiboMA;
    
 

           ///// en caso de exister una orden la modificamos//////////////            
           }
            if( (Revision_Orden_Colocada(MagicNumberFIBOMA) == true) && entradaOperarFiboMA != verificacionFiboMA )                              
                   
              {
                  double stopLossMAN = Calcular_Stop_Loss(tendenciaMA,entradaOperarFiboMA,SLPuntosFijos);
    
                  double takeProfitMAN = Calcular_Take_Profit(tendenciaMA,entradaOperarFiboMA,TPPuntosFijos); 
                  
                  Print(" Modificando entrada fibo-MA: ", entradaOperarFiboMA, " stoploss: ", stopLossMAN, " tprofit: ", takeProfitMAN);                                   
               
                  Modificacion_orden_precioEntrada (entradaOperarFiboMA,stopLossMAN,takeProfitMAN,MagicNumberFIBOMA, VolumenFijo, expirationTimeOrder); 

                  verificacionFiboMA = entradaOperarFiboMA;  
                  
                                                                   
              }
      } 
     
     /////////consultamos si no hay entradas, para eliminar alguna orden puesta por el numero magico en cuestion////////////// 
     
   if((entradaOperarFiboMA == 0) && (Revision_Posicion_Colocada(MagicNumberFIBOMA)==false) && (Revision_Orden_Colocada(MagicNumberFIBOMA)==true)) {
   
   Print("Eliminando orden de FIBOMA ");
   
   Eliminacion_Orden(MagicNumberFIBOMA);  
   
   }     
  //////////////////////// FIN colocacion orden con la estrategia FIBOMA ////////////////////////////////////   
  
////////////////////////colocacion orden con la estrategia FIBOPSICO ////////////////////////////////////
 ///////////// existe una posicion colocada?, de ser falso procedemos a colocar una orden/////////////
   /* 
   if((entradaOperarFiboPsico != 0) && (Revision_Posicion_Colocada(MagicNumberFIBONi)==false))
     {   
         ///// primero verificamos que no existan ordenes////////////
         if(Revision_Orden_Colocada(MagicNumberFIBONi)==false)
           {
                double stopLossFi = Calcular_Stop_Loss(tendenciaImpulsoFibo, entradaOperarFiboPsico, SLPuntosFijos);
                
                double takeProfitFi = Calcular_Take_Profit(tendenciaImpulsoFibo, entradaOperarFiboPsico, TPPuntosFijos); 
                
                Print("entrando fibo-psico: ", entradaOperarFiboPsico,  " stoploss: ", stopLossFi, " tprofit: ", takeProfitFi);                   
                  
                ulong ticket = Apertura_Trades(tendenciaImpulsoFibo, MagicNumberFIBONi, VolumenFijo, entradaOperarFiboPsico, stopLossFi, takeProfitFi, expirationTimeOrder);
                
                verificacionFiboPsico = entradaOperarFiboPsico;
                
 

           ///// en caso de exister una orden la modificamos//////////////            
           }
            if( (Revision_Orden_Colocada(MagicNumberFIBONi) == true) && entradaOperarFiboPsico != verificacionFiboPsico )                              
                   
              {
                  double stopLossFiNew = Calcular_Stop_Loss(tendenciaImpulsoFibo, entradaOperarFiboPsico, SLPuntosFijos);
                
                  double takeProfitFiNew = Calcular_Take_Profit(tendenciaImpulsoFibo, entradaOperarFiboPsico, TPPuntosFijos); 
                  
                  Print("modificando orden fibo-psico: ", entradaOperarFiboPsico,  " stoploss: ", stopLossFiNew, " tprofit: ", takeProfitFiNew);                             
               
                  Modificacion_orden_precioEntrada(entradaOperarFiboPsico,stopLossFiNew,takeProfitFiNew,MagicNumberFIBONi, VolumenFijo, expirationTimeOrder); 

                  verificacionFiboPsico = entradaOperarFiboPsico;                                                   
              }
      } 
     
     /////////consultamos si no hay entradas, para eliminar alguna orden puesta por el numero magico en cuestion////////////// 
     
   if((entradaOperarFiboPsico == 0) && (Revision_Posicion_Colocada(MagicNumberFIBONi)==false) && (Revision_Orden_Colocada(MagicNumberFIBONi)==true)) {
   
   Print("Eliminando orden fibopsico");
   
   Eliminacion_Orden(MagicNumberFIBONi);  
   
   }     
  //////////////////////// FIN colocacion orden con la estrategia FIBOMA ////////////////////////////////////       
   
   */ 
        
         
         
         
         //------------------------//
         // cierre de posiciones    //
         //------------------------//
         
         
         
   
       
         
         
         //------------------------//
         // gestion de posiciones  //
         //------------------------//  
     
     
     
     
      
}//ifcomprobacion nueva barra



   
}//ontick





//+------------------------------------------------------------------+
//| Funciones                                 
//+------------------------------------------------------------------+

//+----------------------------- FUNCIONES DEL PRECIO-------------------------------------+
// creamos una funcion para crear un objeto que almacene en un array la informacion de cada barra
double Close (int pShift)
{
// la clase mqlrates genera objetos con la informacion de cada barra  
   MqlRates barra [];
// se convierte nuestra array barra en forma serial, para asi almacenar los datos de manera serial, siendo 0 la barra en curso
   ArraySetAsSeries(barra, true);
// añadimos la informacion del servido a nuestro array barra, desde la barra 0 hasta la barra 2
   CopyRates(_Symbol,PERIOD_CURRENT,0,3,barra);
// retornamos el precio de cierre con el parametro pshift, el cual seria la posicion de la barra
   double precioCierre = barra[pShift].close; 
// normalizando precio
   precioCierre = NormalizeDouble(precioCierre,_Digits);
   return precioCierre;
}//F

double High (int pShift)
{

   MqlRates barra [];

   ArraySetAsSeries(barra, true);

   CopyRates(_Symbol,PERIOD_CURRENT,0,3,barra);

   double precioHigh = barra[pShift].high; 

   precioHigh = NormalizeDouble(precioHigh,_Digits);
   
   return precioHigh;
}//F

double Low (int pShift)
{

   MqlRates barra [];

   ArraySetAsSeries(barra, true);

   CopyRates(_Symbol,PERIOD_CURRENT,0,3,barra);

   double precioLow = barra[pShift].low; 

   precioLow = NormalizeDouble(precioLow,_Digits);
   
   return precioLow;
}//F

// funcion para retornar el alto mas alto//

double Retornar_Magnitud_Mayor (double pMagnitud1, double pMagnitud2){
   double respuesta=0;
   if(pMagnitud1 >= pMagnitud2)
     {
      respuesta = pMagnitud1;
     } else if(pMagnitud2 > pMagnitud1)
              {
               respuesta = pMagnitud2;
              }
      else
        {
         Print("error al compara magnitud mayor");
        }
         
   return respuesta;
}

// funcion para retornar el bajo mas bajo//

double Retornar_Magnitud_Menor (double pMagnitud1, double pMagnitud2){
   double respuesta=0;
   if(pMagnitud1 <= pMagnitud2)
     {
      respuesta = pMagnitud1;
     } else if(pMagnitud2 < pMagnitud1)
              {
               respuesta = pMagnitud2;
              }
      else
        {
         Print("error al compara magnitud menor");
        }
         
   return respuesta;
}

// funcion para comparar el delta magnitud, si es mayor a 3000 puntos debera retornar una señal

string Signal_Magnitud_Fibo (double pMagnitud1, double pMagnitud2){
   string respuesta;
   double deltaMagnitud = pMagnitud1 - pMagnitud2;
   deltaMagnitud = MathAbs(deltaMagnitud);
   if(deltaMagnitud >= 30)//30
     {
      respuesta = "OPERAR";
     } else
         {
          respuesta = "NO OPERAR";
         }
     
     return respuesta;

}
// funcion que me retorne la tendencia del fibonacci
string Tendencia_Fibo (double pAltoMasAlto, double pAltoMasAltoVela1){
   string respuesta="nulo";
   if(pAltoMasAltoVela1 >= pAltoMasAlto)
     {
      respuesta = "LARGO";
     } else if(pAltoMasAltoVela1 < pAltoMasAlto)
              {
               respuesta = "CORTO";
              } 
     
     return respuesta;
}


// funcion que retorna un array con la serie de fibonacci

void Serie_Fibo (double &pArray[] ,string pSignalFibo, string pTendencia, double pAltoMasAlto, double pBajoMasBajo) 
{
 
   double fibo30;
   double fibo50;
   double fibo60;
      
     
   if(pSignalFibo == "OPERAR")
   
     {
         if(pTendencia == "LARGO")
           {
            fibo30 = pAltoMasAlto - (pAltoMasAlto - pBajoMasBajo)*0.382;
            fibo30 = NormalizeDouble(fibo30,_Digits);
            fibo50 = pAltoMasAlto - (pAltoMasAlto - pBajoMasBajo)*0.5;
            fibo50 = NormalizeDouble(fibo50,_Digits);
            fibo60 = pAltoMasAlto - (pAltoMasAlto - pBajoMasBajo)*0.618;
            fibo60 = NormalizeDouble(fibo60,_Digits);
            pArray[0]=fibo30;
            pArray[1]=fibo50;
            pArray[2]=fibo60;              
           } 
            if(pTendencia == "CORTO")
                    {
                        fibo30 = pBajoMasBajo + (pAltoMasAlto - pBajoMasBajo)*0.382;
                        fibo30 = NormalizeDouble(fibo30,_Digits);
                        fibo50 = pBajoMasBajo + (pAltoMasAlto - pBajoMasBajo)*0.5;
                        fibo50 = NormalizeDouble(fibo50,_Digits);               
                        fibo60 = pBajoMasBajo + (pAltoMasAlto - pBajoMasBajo)*0.618;
                        fibo60 = NormalizeDouble(fibo60,_Digits);   
                        pArray[0]=fibo30;
                        pArray[1]=fibo50;
                        pArray[2]=fibo60;                                   
                    }   
                         
     }

   //Array[0]=fibo30;
   //Array[1]=fibo50;
   //Array[2]=fibo60;
   //double serie[3]= {fibo30, fibo50, fibo60};
   //return serie;

}//f

/////////////////////////////////////// funcion para la barrera psicologica multiplo de 50 //////////////////////////////


void Niveles_psicologicos (double &pArray[], double pAltoMasAlto, double pBajoMasBajo){


double division1 = (MathFloor(pAltoMasAlto/50))*50;
double division2 = (MathCeil(pAltoMasAlto/50))*50;
double division3 = (MathFloor(pBajoMasBajo/50))*50;
double division4 = (MathCeil(pBajoMasBajo/50))*50;
pArray[0]=division1;
pArray[1]=division2;
pArray[2]=division3;
pArray[3]=division4;

}//f

////////////////////////////////////// funcion para la barrera psicologica multiplo de 50 //////////////////////////////




//+----------------------------- FUNCIONES DE LA MEDIA MOVIL-------------------------------------+

//************************************************//
// funcion para inizializar el manejador de las MA
//************************************************//

   int MA_Init(int pPeriodoMA, int pShiftMA, ENUM_MA_METHOD pMetodoMA, ENUM_APPLIED_PRICE pPrecioMA)
   {
// reseteando last error a 0, lo hacemos para resetear los errores de tal manera que si esta funcion genera error podremos retornar el error actual
   ResetLastError();

// el manejador es un identificador unico para el indicador, se utiliza para todas las acciones relacionadas con este, como obtener datos o eliminarlo   
   int Manejador = iMA(_Symbol, PERIOD_CURRENT, pPeriodoMA, pShiftMA, pMetodoMA, pPrecioMA);

// comprobacion de errores
   if(Manejador == INVALID_HANDLE)
     {
      return -1;
      Print("ha habido un error creando el manejador del indicador de la media movil: ", GetLastError() );
     }// if  
      
   Print("el manejador del indicador MA se ha creado con exito");
   return Manejador;
    }//f
    
 //****************************************************//   
 // funcion para acceder a los datos de la media movil
 //****************************************************//
 
   double ma(int pManejadorMA, int pShift)
   {
 // reseteando last error a 0
   ResetLastError();
 // creando array que llenaremos con los precios del indicador
   double ma[];
 // lo convertimos en array serial
   ArraySetAsSeries(ma,true);
 // llenamos los datos del array con la informacion del servidor, vamos a llenar solo las ultimas tres velas
 // se usa la funcion del mql5 llamada copy buffer la cual nos retorna la informacion del indicador, el primer parametro es el manejador del indicador
   bool resultado = CopyBuffer(pManejadorMA, 0, 0, 3, ma);
 // comprobacion de errores ya que resultado dara verdadero de ser exitoso o falso de no serlo
   if(resultado == false)
     {
      Print("error al copiar datos del indicador MA", GetLastError());
     }//i
// preguntamos por el valor del indicador almacenado en pshift
   double valorMA= ma[pShift];
//normalizamos el valor de valorMA
   valorMA = NormalizeDouble(valorMA,_Digits);
// retornamos
   return valorMA;
   }//f
   
  //*************************************************************************//   
 // funcion para acceder indicar si el cruce de MA esta en largo o en corto
 //**************************************************************************//
 
   string tendencia_Cruce_MA(double pMALenta, double pMARapida) {
   string resultado = "";
   if(pMARapida > pMALenta)
   {
    resultado = "LARGO";
   }
   if(pMARapida < pMALenta)
     {
      resultado = "CORTO";
     }  
   return resultado; 
 
 }//f
 
 //********************************************************************************************//   
 // funcion para dar señal de "OPERAR" cuando el delta sea mayor o igual al delta parametrizado
 //********************************************************************************************//
 
 string Signal_MA (double pMa1, double pMa2, int pDeltaMASignal){
 
   string respuesta;
   double deltaMagnitud = pMa1 - pMa2;
   deltaMagnitud = MathAbs(deltaMagnitud);
   if(deltaMagnitud >= pDeltaMASignal)
     {
      respuesta = "OPERAR";
     } else
         {
          respuesta = "NO OPERAR";
         }
     
     return respuesta;
 
 }
 
 


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////// funciones finales para usarse para operar en el mercado//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// esta funcion tomara la señal de operar de fibonaccio, y cuando sea operar, va a comparar con los niveles psicologicos y cuando coincida segun el delta dado entonces retornara el valor fibo que coincide, retoranara 0 de no haber coincidencia//////


double signal_PriceReturn_Fibo_Psico (string psignalFibo, double &pArrayFibo[], double &pArrayNivelPsi[], double pDelta){

double respuesta=0.0;
int sizei= ArraySize(pArrayFibo);
int sizej = ArraySize(pArrayNivelPsi);
bool continuar=true;

if(psignalFibo == "OPERAR")
  {
   for(int i=0;i<sizei;i++)
  {
  if(continuar==true)
    {
     for(int j=0;j<sizej;j++)
    {
    if(((pArrayFibo[i]-pDelta) <= pArrayNivelPsi[j]) &&  ((pArrayFibo[i]+ pDelta) >= pArrayNivelPsi[j]))
       {
        Print("el siguiente valor coincide: ", pArrayFibo[i]);
        respuesta = pArrayFibo[i];
        continuar=false;
        break;
       }//if
    }//forj
    }//if 
  }//fori
  }


respuesta = NormalizeDouble(respuesta,_Digits);
return respuesta;

}


// esta funcion tomara la señal de entrada de el delta MA y la señal de entrada del fibo, de indicar operar y estar en la misma tendencia retornara el 60 del fibo para operar o 0 para no operar//////////////////
double signal_PriceReturn_fibo_MA (string pSignalMA,string pTendenciaMA,string pSignalFibo, string pTendenciaFibo, double &pArrayfibo[]){
double respuesta=0.0;
if(pSignalMA=="OPERAR" &&  pSignalFibo=="OPERAR" && pTendenciaFibo==pTendenciaMA)
  {
  if(pTendenciaFibo == "LARGO")
    {
     if(pArrayfibo[2] < pArrayfibo[0])
       {
        respuesta= pArrayfibo[2];
       }else
          {
           respuesta = pArrayfibo[0];
          }
    }
  if(pTendenciaFibo == "CORTO")
    {
           if(pArrayfibo[2] > pArrayfibo[0])
       {
            respuesta= pArrayfibo[2];
       }else
          {
           respuesta = pArrayfibo[0];
          }
    }
  }
return respuesta;

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////funciones para la colocacion de ordenes limit con stop loss y take profit al borker/////////

ulong Apertura_Trades (string pTendencia, ulong pMagicNumber, double pVolumenFijo, double pPrecioEntrada , double pSLPrecio, double pTPPrecio, datetime pExpirationTime){



   
   string comentario = pTendencia + " - " +_Symbol + " - " + string(pMagicNumber);
   
   
   //declaracion e inizializacon de los objetos solicitud y resultado
   
   MqlTradeRequest solicitud={};
   MqlTradeResult resultado={};
   
   
   
   if(pTendencia == "LARGO")
     {
   // parametros de la solicitud
   solicitud.action        =TRADE_ACTION_PENDING;
   solicitud.symbol        = _Symbol;
   solicitud.volume        = pVolumenFijo;
   solicitud.type          = ORDER_TYPE_BUY_LIMIT;
   solicitud.price         = pPrecioEntrada;
   solicitud.deviation     = 10;
   solicitud.magic         = pMagicNumber;
   solicitud.comment       = comentario;
   solicitud.type_filling  = ORDER_FILLING_IOC; 
   solicitud.sl            = pSLPrecio;
   solicitud.tp            = pTPPrecio;
   solicitud.expiration    = pExpirationTime;
   solicitud.type_time     = ORDER_TIME_SPECIFIED;
   

   // envio de solicitud//
   if(!OrderSend(solicitud,resultado))
     {
      Print("error en el envio de la orden: ", GetLastError());
     }
  
   //informacion de la operacion
   Print("abierta ", solicitud.symbol, " ", pTendencia, "order # ", resultado.retcode, "volumen: ", resultado.volume, ", precio: ", pPrecioEntrada);
      
     }

   
   if(pTendencia == "CORTO")
     {
   // parametros de la solicitud
   solicitud.action        =TRADE_ACTION_PENDING;
   solicitud.symbol        = _Symbol;
   solicitud.volume        = pVolumenFijo;
   solicitud.type          = ORDER_TYPE_SELL_LIMIT;
   solicitud.price         = pPrecioEntrada;
   solicitud.deviation     = 10;
   solicitud.magic         = pMagicNumber;
   solicitud.comment       = comentario;
   solicitud.type_filling  = ORDER_FILLING_IOC;
   solicitud.sl            = pSLPrecio;
   solicitud.tp            = pTPPrecio;
   solicitud.expiration    = pExpirationTime; 
   solicitud.type_time     = ORDER_TIME_SPECIFIED;
   

   // envio de solicitud//
   if(!OrderSend(solicitud,resultado))
     {
      Print("error en el envio de la orden: ", GetLastError());
     }
  
   //informacion de la operacion
   Print("abierta ", solicitud.symbol, " ", pTendencia, "order # ", resultado.retcode, "volumen: ", resultado.volume, ", precio: ", pPrecioEntrada);
      
     }

if(resultado.retcode == TRADE_RETCODE_DONE || resultado.retcode == TRADE_RETCODE_DONE_PARTIAL ||resultado.retcode == TRADE_RETCODE_PLACED ||resultado.retcode == TRADE_RETCODE_NO_CHANGES)
  {
   return resultado.order;
  }

else
  {
   return 0;
  }
}


/////////////////////////////////funcion que verifica si este bot ya tiene una posicion colocado verificando si hay alguna orden con el numero magico de este bot////////////////


bool Revision_Posicion_Colocada (ulong pMagicNumber){
bool posicionColocada = false;


   for(int i = PositionsTotal()-1 ;i>=0; i--)
     {
      ulong posicionTicket = PositionGetTicket(i);
      PositionSelectByTicket(posicionTicket);
      ulong posicionMagico = PositionGetInteger(POSITION_MAGIC);
      
      if(posicionMagico == pMagicNumber)
        {
        posicionColocada = true;
        break;       
        }
     }

return posicionColocada;
}

bool Revision_Orden_Colocada (ulong pMagicNumber){

bool ordenColocada = false;
 

   for(int i = OrdersTotal()-1 ;i>=0; i--)
     {     
      ulong orderByIndex = OrderGetTicket(i);
      ulong seleccionOrden = OrderSelect(orderByIndex);
      long magicOrder = OrderGetInteger(ORDER_MAGIC);   
         
      if(magicOrder == pMagicNumber)
        {
        ordenColocada = true;
        break;       
        }
     }

return ordenColocada;



}

 

////////////////////////// funcion para cierre de posiciones/////////////////////////////////
/*void cierrePosiciones (ulong pMagicNumber, string pExitSignal)
{
  MqlTradeRequest solicitud={};
  MqlTradeResult resultado={};


   for(int i = PositionsTotal()-1 ;i>=0; i--)
     {
// queremos resetear los valores de los objetos solicitud y resultado , lo hacemos con la funcion zeromemory
         ZeroMemory(solicitud);
         ZeroMemory(resultado);

      ulong posicionTicket = PositionGetTicket(i);
      PositionSelectByTicket(posicionTicket);         
      ulong posicionMagico = PositionGetInteger(POSITION_MAGIC);         
      ulong posicionTipo = PositionGetInteger(POSITION_TYPE);  
      
      if(posicionMagico == pMagicNumber && )
        {
         
        } 
     }

}
*/
///////////////////////////////////////funcion para la gestion de posiciones/////////////////

   double Calcular_Stop_Loss(string pTendencia, double pPrecioEntrada,int pSlPuntosFijos){
      double stopLoss=0.0;
      
      if(pTendencia == "LARGO")
        {
         stopLoss= pPrecioEntrada - pSlPuntosFijos;
        }
       else if(pTendencia == "CORTO")
         {
          stopLoss = pPrecioEntrada + pSlPuntosFijos;
         }
   
      stopLoss = NormalizeDouble(stopLoss,_Digits);
      return stopLoss;  
   
   }

/////////////////////funcion para la gestion del take profit/////////////////////

   double Calcular_Take_Profit (string pTendencia, double pPrecioEntrada, int pTPPuntosFijos){
   double takeProfit=0.0;
   
      if(pTendencia == "LARGO")
        {
         takeProfit= pPrecioEntrada + pTPPuntosFijos;
        }
       else if(pTendencia == "CORTO")
         {
          takeProfit = pPrecioEntrada - pTPPuntosFijos;
         }
   
      takeProfit = NormalizeDouble(takeProfit,_Digits);
      return takeProfit;  
   
   }


////////////////////////funcion para la modificacion de posiciones//////////////////////////////////

   void Modificacion_Posiciones (ulong pTicket, ulong pMagicNumber, double pSLPrecio, double pTPPrecio){
   
      MqlTradeRequest solicitud = {};
      MqlTradeResult resultado = {};
      
      solicitud.action = TRADE_ACTION_SLTP;
      solicitud.position = pTicket;
      solicitud.symbol = _Symbol;
      solicitud.sl = NormalizeDouble(pSLPrecio,_Digits);
      solicitud.tp = NormalizeDouble(pTPPrecio, _Digits);
      solicitud.comment = " MOD. " + " - " + _Symbol + " - " + string(pMagicNumber) + ", SL: " + DoubleToString(solicitud.sl, _Digits) + ", TP: " + DoubleToString(solicitud.tp, _Digits);
      
      if(solicitud.sl > 0 || solicitud.tp > 0)
        {
         Sleep(1000);
         bool sent = OrderSend(solicitud, resultado);
         Print(resultado.comment);
         if(!sent)
           {
            Print("error de modificacion orderSend: ", GetLastError());
            Sleep(3000);
            bool sent = OrderSend(solicitud, resultado);
            Print(resultado.comment); 
            
            if(!sent)
              {
            Print("3er intento, error de modificacion orderSend: ", GetLastError());
            Sleep(3000);
            bool sent = OrderSend(solicitud, resultado);
            Print(resultado.comment);                
              }          
            
           }
        }
        
   }
   
   //////////// modificar orden ////////////////////////
   
  void Modificacion_orden_precioEntrada (double pPrecioEntradaNuevo, double pSLNuevo, double pTPProfitNuevo, ulong pMagicNumber,double pVolumenFijo, datetime pExpirationTime){  
   
   MqlTradeRequest solicitud={};
   MqlTradeResult resultado={};
  
   
  for(int i = OrdersTotal()-1 ;i>=0; i--)
    { 
      ZeroMemory  (solicitud);
      ZeroMemory  (resultado);  
            
      ulong    orderByIndex    = OrderGetTicket(i);
      ulong    seleccionOrden  = OrderSelect(orderByIndex);
      ulong     magicOrder      = OrderGetInteger(ORDER_MAGIC); 

            
      if(magicOrder == pMagicNumber)
        {
      
              // parametros de la solicitud
      solicitud.action        =TRADE_ACTION_MODIFY;
      solicitud.order         = OrderGetTicket(i);
      solicitud.symbol        = _Symbol;
      solicitud.price         = pPrecioEntradaNuevo;
      solicitud.sl            = pSLNuevo;
      solicitud.tp            = pTPProfitNuevo;
     
     
      solicitud.volume        = pVolumenFijo;
      solicitud.deviation     = 10;
      solicitud.magic         = pMagicNumber;
      solicitud.expiration    = pExpirationTime;
      solicitud.type_time     = ORDER_TIME_SPECIFIED;
      solicitud.type_filling  = ORDER_FILLING_IOC;
      

        }
  
   // envio de solicitud//
   bool ordenEnviada = OrderSend(solicitud,resultado);
   Sleep(3000);
   if(!ordenEnviada)
     {
      Print("error en el envio de la modificacion: ", GetLastError());
      ordenEnviada = OrderSend(solicitud,resultado);
      Sleep(3000);
      if(!ordenEnviada)
        {
      Print("error en el envio de la modificacion: ", GetLastError());     
      ordenEnviada = OrderSend(solicitud,resultado);
      Sleep(3000);
      if(!ordenEnviada)
        {
      Print("error en el envio de la modificacion: ", GetLastError());
          
               
        }
     }
  
    } else
        {     
  
   //informacion de la operacion
   Print("modificada order #: ", resultado.retcode, ", precio: ", pPrecioEntradaNuevo);     
   break; 
        }
        
   }
     
 }
 
 
 /////////////// eliminar orden ///////////////////////////////////////
 
 void Eliminacion_Orden (ulong pMagicNumber){  
   
   MqlTradeRequest solicitud={};
   MqlTradeResult resultado={};
  
   
  for(int i = OrdersTotal()-1 ;i>=0; i--)
    { 
      ZeroMemory  (solicitud);
      ZeroMemory  (resultado);        
      ulong    orderByIndex    = OrderGetTicket(i);
      ulong    seleccionOrden  = OrderSelect(orderByIndex);
      ulong     magicOrder      = OrderGetInteger(ORDER_MAGIC); 

            
      if(magicOrder == pMagicNumber)
        {
      
              // parametros de la solicitud
      solicitud.action        =TRADE_ACTION_REMOVE;
      solicitud.order         = OrderGetTicket(i);
     
        }
   
   // envio de solicitud//
      bool ordenEnviada = OrderSend(solicitud,resultado);
      Sleep(3000);
      if(!ordenEnviada)
     {
      Print("error en el envio de la modificacion: ", GetLastError());
      
      ordenEnviada = OrderSend(solicitud,resultado);
      Sleep(1000);
      if(!ordenEnviada)
        {
      Print("error en el envio de la modificacion: ", GetLastError());
      
      ordenEnviada = OrderSend(solicitud,resultado);
      Sleep(1000);
      if(!ordenEnviada)
        {
      Print("error en el envio de la modificacion: ", GetLastError());
            
               
        }
     }
  
    } else
        {     
  
   //informacion de la operacion
   Print("eliminada order #: ", resultado.retcode);     
   break; 
        }
        
   }
     
 }
  