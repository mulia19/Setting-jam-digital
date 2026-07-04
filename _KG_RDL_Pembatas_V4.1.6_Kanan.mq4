//+------------------------------------------------------------------+
//|												 Copyright © 2010, JACreative |
//|																 KGForexWorld.com |
//|															  Update:26-Nov-2010 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, KGForexWorld.com"
#property link      "http://www.kgforexworld.com"

#property indicator_chart_window
#property indicator_buffers 0



extern   int      Update.Tiap_N_Tick      = 20;
extern	bool		BellCurve.Di.Kanan 		= true;
extern   int      Maju.Brp.BlokData          = 5;
extern	int		BarAwal  		= 33,
                  BarAkhir       = 0,
						Sinkron			= 0;
//extern   int      CurveLine      = 30;
extern   bool     Show_AVGRDL    = true,
                  ShowSD1RDL     = false,
                  Show_FDBalance = false,
                  Show_FD_SDp1   = false,
                  Show_FD_SDn1   = false,
                  Show_FD_SDp2   = false,
                  Show_FD_SDn2   = false,
                  Show_Shape     = false,   
                  Show_POC       = false,
                  Show_BSB       = false,
                  Show_AVG       = false,
                  Show_REG       = false,
                  Show_SSP       = false,
                  Show_BSP       = false,
                  Show_VA        = false,
                  Show_SD2       = false;
extern	color		WarnaRDL			= DarkGreen;
extern   int      Shift          = 0,
						FD_Sinkron		= PERIOD_M30;	// FD Sinkron tidak berkerja pada chart biasa
extern	bool		BellCurve 		= true,
						ShowID 			= true,
						ShowPrice		= true;
extern   color    color1         = C'55,100,135';
extern   color    color2         = C'45,90,125';
extern	color		RDLColor			= Gray;
extern   color    ShapeColor     = Maroon;
extern   color    SD1RDLColor    = Red;
extern   color    POCShapeColor  = Blue;
extern   color    FDBalanceColor = Green;
extern	int		LabelDistance	= 0;
extern   int      Tebal_Garis    = 2;


int		Per,FDPer,PerPNow,PerPEnd,PerPNowScale,SAVEPER,SAVE_LINETIME,save_end,handle,COUNT[],TMP_COUNT[],CountMax,PeriodeSinkron,Geser,ENDTIME,Akhir,tmpKa,tmpKa2;

double	HIGHER,LOWER,LOWEST,HIGHEST,HIGH,LOW,MAXPrice;

string	LabelName,NamaFile;

bool		FIRST	= true,
			ERROR = false,
			ChartPT	= true;
int      tick=0;
datetime	LINETIME,LINETIMEn,SAVETIME,TSearch,TMP_TIME;

//+------------------------------------------------------------------+
//| init()                     												   |
//+------------------------------------------------------------------+
int init(){
	int i;
LINETIMEn = Maju.Brp.BlokData;
	LabelName	= "RDL_Pembatas"+BarAwal+BarAkhir+WarnaRDL;
	NamaFile		= "Pembatas\\"+LabelName+Symbol();

	handle	= FileOpen(NamaFile, FILE_BIN|FILE_READ);
	if(handle>=1){
		LINETIME			= FileReadInteger(handle, LONG_VALUE);
		ENDTIME			= FileReadInteger(handle, LONG_VALUE);
		FileClose(handle);
	}
	else if(LINETIME == 0){
		LINETIME = Time[BarAwal];
   ENDTIME = Time[BarAkhir];
	}
	SAVE_LINETIME	= LINETIME;
   save_end       = ENDTIME;
	//
	if((LINETIME < Time[Bars-1]) || (iBarShift(NULL, 0, LINETIME) >= 20000))
		ERROR = true;

if(BellCurve.Di.Kanan)  	LabelName	= "RDL_Pembatas"+BarAwal+BarAkhir+WarnaRDL+" Ka";
else		LabelName	= "RDL_Pembatas"+BarAwal+BarAkhir+WarnaRDL;

}


//+-------------------------------------------------------------------+
//| deinit													                      |
//+-------------------------------------------------------------------+
int deinit(){
	int i,strlen,obj_total;
	string name;
	obj_total	= ObjectsTotal();
	strlen		= StringLen(LabelName);
	for(i=obj_total;i>=0;i--){
		name	= ObjectName(i);
		if(StringSubstr(name, 0, strlen) == LabelName)
			ObjectDelete(name);
	}
}


//+-------------------------------------------------------------------+
//| deinit													                      |
//+-------------------------------------------------------------------+
int DELOBJ(){
	int i,strlen,obj_total;
	string name;
	obj_total	= ObjectsTotal();
	strlen		= StringLen(LabelName+"OBJ");
	for(i=obj_total;i>=0;i--){
		name	= ObjectName(i);
		if(StringSubstr(name, 0, strlen) == LabelName+"OBJ")
			ObjectDelete(name);
	}
}

//+------------------------------------------------------------------+
//| start()                     												   |
//+------------------------------------------------------------------+
int start(){
   if(BellCurve.Di.Kanan)
   start2();
   else
   start1();

   tick+=1;
}
//+------------------------------------------------------------------+
//| start1()                     												   |
//+------------------------------------------------------------------+
int start1(){
	if(ERROR)
		return(0);
	
	int			SinkronPer,i,k,Jarak,COUNTER,ARRAYCount[],TMP,TMPCount,SumRDL=0,AVGRDL;
	double		j,ArraySinkronHigh[5],ArraySinkronLow[5];
	datetime		ArraySinkronTime[5];

	if(ObjectFind(LabelName) == -1){
		ObjectCreate(LabelName, OBJ_VLINE, 0, LINETIME, 0);
		ObjectSet(LabelName, OBJPROP_COLOR, WarnaRDL);
		ObjectSet(LabelName, OBJPROP_STYLE, STYLE_DOT);
		ObjectSet(LabelName, OBJPROP_BACK, true);
	}

	if(ObjectFind(LabelName+"end") == -1){
		ObjectCreate(LabelName+"end", OBJ_VLINE, 0, ENDTIME, 0);
		ObjectSet(LabelName+"end", OBJPROP_COLOR, WarnaRDL);
		ObjectSet(LabelName+"end", OBJPROP_STYLE, STYLE_DOT);
		ObjectSet(LabelName+"end", OBJPROP_BACK, true);
	}

	LINETIME		= ObjectGet(LabelName, OBJPROP_TIME1);
	Per			= iBarShift(NULL, Sinkron, LINETIME);
	ENDTIME		= ObjectGet(LabelName+"end", OBJPROP_TIME1);
   Akhir       = iBarShift(NULL, Sinkron, ENDTIME);

/*	if(BellCurve){
		if(ObjectFind(LabelName) == -1){
			ObjectCreate(LabelName, OBJ_VLINE, 0, LINETIME, 0);
			ObjectSet(LabelName, OBJPROP_COLOR, WarnaRDL);
			ObjectSet(LabelName, OBJPROP_STYLE, STYLE_DOT);
			ObjectSet(LabelName, OBJPROP_BACK, true);
		}
	}	
   ObjectSet(LabelName, OBJPROP_TIME1, LINETIME);*/

	if((SAVE_LINETIME != LINETIME) || (SAVEPER != Per) || (IndicatorCounted() == 0)){
		if(save_end != ENDTIME || SAVE_LINETIME != LINETIME) {DELOBJ();FIRST			= true;}
		if(ENDTIME>Time[0] && tick>=Update.Tiap_N_Tick)   {DELOBJ(); tick=0; FIRST=true;}
		// SIMPAN POSISI KE FILE
		handle	= FileOpen(NamaFile, FILE_BIN|FILE_WRITE);
		if(handle>=1){
			FileWriteInteger(handle, LINETIME, LONG_VALUE);
			FileWriteInteger(handle, ENDTIME, LONG_VALUE);
			FileClose(handle);
		}
	}

	if(FIRST){
		FIRST		= false;
		LOWEST	= Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))]-(100*Point);
		HIGHEST	= High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))]+(100*Point);
		Jarak		= (HIGHEST - LOWEST)/Point;

		ArrayResize(COUNT, Jarak);
		ArrayResize(TMP_COUNT, Jarak);
		ArrayInitialize(COUNT, 0);
		ArrayInitialize(TMP_COUNT, 0);

		ArrayCopySeries(ArraySinkronHigh, MODE_HIGH, 0, Sinkron);
		ArrayCopySeries(ArraySinkronLow, MODE_LOW, 0, Sinkron);
		ArrayCopySeries(ArraySinkronTime, MODE_TIME, 0, Sinkron);

		for(i=Per;i>=Akhir;i--){
			for(j=ArraySinkronLow[i];j<=ArraySinkronHigh[i];j+=Point){
				TMP	= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				COUNT[TMP] ++;
			}
		}// END FOR
		MAXPrice	= (JA_ArrayMaximum(COUNT)*Point)+LOWEST;

		for(j=ArraySinkronLow[0];j<=ArraySinkronHigh[0];j+=Point){
			TMP	= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
			COUNT[TMP] --;
		}
		JA_ArrayCopy(TMP_COUNT, COUNT);
		SAVEPER			= Bars;
		CountMax			= COUNT[JA_ArrayMaximum(COUNT)];
		PerPNow			= iBarShift(NULL, 0, LINETIME);
		PerPEnd			= iBarShift(NULL, 0, ENDTIME);
		PerPNowScale 	= CountMax	;//(PerPNow-PerPEnd);
//		if(CurveLine>0 && PerPNowScale>CurveLine)PerPNowScale=CurveLine;
		//if(PerPNowScale > 150)PerPNowScale = 150;
			
      //PerPNowScale=30;
		//Print(PerPNowScale);
		int clr = 0;
		if(BellCurve){
			for(j=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j<=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j+=Point){
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0){
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
					if(TMPCount > 0)	
					       if(MathMod(clr,2)==0){
   						    SET_Rectangle("OBJR"+DoubleToStr(j,Digits)+Shift, LINETIME, j, Time[PerPNow-TMPCount], j+Point, color1);
                      }
                      else{
   						    SET_Rectangle("OBJR"+DoubleToStr(j,Digits)+Shift, LINETIME, j, Time[PerPNow-TMPCount], j+Point, color2);                  
                      }
                  SumRDL+=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
                  clr++;
				}
			}
		}
      AVGRDL = SumRDL/((High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))]-Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))])/Point);
      double VAH = iBands(NULL,Sinkron,Per-Akhir+1,1,0,PRICE_TYPICAL,MODE_UPPER,Akhir);//
      double VAL = iBands(NULL,Sinkron,Per-Akhir+1,1,0,PRICE_TYPICAL,MODE_LOWER,Akhir);
      double VAH2 = iBands(NULL,Sinkron,Per-Akhir+1,2,0,PRICE_TYPICAL,MODE_UPPER,Akhir);//iMA(0,Sinkron,1,Per,0,1,0);
      double VAL2 = iBands(NULL,Sinkron,Per-Akhir+1,2,0,PRICE_TYPICAL,MODE_LOWER,Akhir);
      double AVG = iMA(0,Sinkron,Per-Akhir+1,0,0,PRICE_TYPICAL,Akhir);
      double REG = 3*iMA(0,Sinkron,Per-Akhir+1,0,3,PRICE_TYPICAL,Akhir)-2*iMA(0,Sinkron,Per-Akhir+1,0,0,PRICE_TYPICAL,Akhir);
      double BSB = ( (iHigh(NULL, Sinkron, iHighest(NULL, Sinkron, MODE_HIGH, Per-Akhir+1, Akhir)) + iLow(NULL, 0, iLowest(NULL, Sinkron, MODE_LOW, Per-Akhir+1, Akhir)) )/2);
      double SSP = iHigh(NULL, Sinkron, iHighest(NULL, Sinkron, MODE_HIGH, Per-Akhir+1, Akhir));
      double BSP = iLow(NULL, 0, iLowest(NULL, Sinkron, MODE_LOW, Per-Akhir+1, Akhir));
      
		if(ShowSD1RDL){
		   int pembagi = 0;
			int RDLsq = 0;
			for(j=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j<=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j+=Point){
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0){
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
               //SumRDL+=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
               RDLsq += MathPow(iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount])-AVGRDL,2);
               pembagi++;
				}
		}
		pembagi=((High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))]-Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))])/Point);
		//Alert(RDLsq + "     " + pembagi);
	   RDLsq=MathSqrt(RDLsq/SumRDL);
      SET_VLINE("RDLsq", Time[iBarShift(NULL,0,LINETIME)-RDLsq], Time[iBarShift(NULL,0,LINETIME)-RDLsq], High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))], Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))],SD1RDLColor, 2, STYLE_SOLID);
		}

      if (Show_Shape == True)
      {
         int awalShape=0,akhirShape=0,POCShape=0;
			for(j=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j<=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j+=Point){
   			TMP	= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);   
				if(COUNT[TMP] > 0){
               if(COUNT[TMP-1]<AVGRDL && COUNT[TMP]>=AVGRDL){
                  awalShape=TMP;
                  POCShape=TMP;
               }
               if(POCShape > 0){
                  if(COUNT[TMP]>COUNT[POCShape])POCShape=TMP;
               }
               if(awalShape != 0 && COUNT[TMP+1]<AVGRDL && COUNT[TMP]>=AVGRDL){
                  akhirShape=TMP;
               }
               if(awalShape !=0 && akhirShape != 0){
                  SET_Rectangle("OBJAREA" + TMP, LINETIME, awalShape*Point + LOWEST,ENDTIME, akhirShape*Point + LOWEST, ShapeColor);
                  //SET_LINE("OBJPOCShape " + TMP, LINETIME, ENDTIME, POCShape*Point + LOWEST, POCShapeColor, 1, STYLE_DASHDOT);
                  awalShape=0;
                  akhirShape=0;
                  POCShape=0;
               } 
	         }
			}
      }

		if(Show_FDBalance){
		   double Sum = 0, tmpProc,Proc;
		   int FDB;
			for(j=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j<=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j+=Point){
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0){
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
               Sum +=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
               Proc=(Sum/SumRDL)*100;
               if(Proc==50){
                  FDB=TMP;
                  break;
               }
               if(tmpProc<50 && Proc>50){
                  if(MathAbs(tmpProc-50)<MathAbs(Proc-50)){
                     FDB=TMP-1;
                  }
                  else{
                     FDB=TMP;
                  }
                  break;
               }
               tmpProc=Proc;
				}
		}
      SET_LINE("50% FTD ", LINETIME, ENDTIME, FDB*Point + LOWEST, FDBalanceColor, Tebal_Garis, STYLE_SOLID);
      SET_LABEL("FDBLabel", "50%   ", ENDTIME, FDB*Point + LOWEST, FDBalanceColor);
		}

		if(Show_FD_SDp1)
		{
		   Sum = 0;
		   Proc=0;
		   tmpProc=0;
			for(j=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j<=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j+=Point)
			{
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0)
				{
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
               Sum +=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
               Proc=(Sum/SumRDL)*100;
               if(Proc==84)
               {
                  FDB=TMP;
                  break;
               }
               if(tmpProc<84 && Proc>84)
               {
                  if(MathAbs(tmpProc-84)<MathAbs(Proc-84))
                  {
                     FDB=TMP-1;
                  }
                  else{
                     FDB=TMP;
                  }
                  break;
               }
               tmpProc=Proc;
				}
		   }
            SET_LINE("FDSD+1 ", LINETIME, ENDTIME, FDB*Point + LOWEST, FDBalanceColor, 1, STYLE_DOT);
            SET_LABEL("FDSD+1Label", "+sd1   ", ENDTIME, FDB*Point + LOWEST, FDBalanceColor);
      }
      
      if(Show_FD_SDn1)
      {
		   Sum = 0;
		   Proc=0;
		   tmpProc=0;
			for(j=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j>=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j-=Point){
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0){
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
               Sum +=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
               Proc=(Sum/SumRDL)*100;
               if(Proc==84){
                  FDB=TMP;
                  break;
               }
               if(tmpProc<84 && Proc>84){
                  if(MathAbs(tmpProc-84)<MathAbs(Proc-84)){
                     FDB=TMP-1;
                  }
                  else{
                     FDB=TMP;
                  }
                  break;
               }
               tmpProc=Proc;
				}
		}
      SET_LINE("FDSD-1 ", LINETIME, ENDTIME, FDB*Point + LOWEST, FDBalanceColor, 1, STYLE_DOT);
      SET_LABEL("FDSD-1Label", "-sd1   ", ENDTIME, FDB*Point + LOWEST, FDBalanceColor);

		}

      if(Show_FD_SDp2)
		{
		   Sum = 0;
		   Proc=0;
		   tmpProc=0;
			for(j=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j<=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j+=Point)
			{
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0)
				{
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
               Sum +=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
               Proc=(Sum/SumRDL)*100;
               if(Proc==97.5)
               {
                  FDB=TMP;
                  break;
               }
               if(tmpProc<97.5 && Proc>97.5)
               {
                  if(MathAbs(tmpProc-97.5)<MathAbs(Proc-97.5))
                  {
                     FDB=TMP-1;
                  }
                  else{
                     FDB=TMP;
                  }
                  break;
               }
               tmpProc=Proc;
				}
		   }
            SET_LINE("FDSD+2 ", LINETIME, ENDTIME, FDB*Point + LOWEST, FDBalanceColor, 1, STYLE_DOT);
            SET_LABEL("FDSD+2Label", "+sd2   ", ENDTIME, FDB*Point + LOWEST, FDBalanceColor);
      }
      
      if(Show_FD_SDn2)
      {
		   Sum = 0;
		   Proc=0;
		   tmpProc=0;
			for(j=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j>=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j-=Point){
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0){
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
               Sum +=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
               Proc=(Sum/SumRDL)*100;
               if(Proc==97.5){
                  FDB=TMP;
                  break;
               }
               if(tmpProc<97.5 && Proc>97.5){
                  if(MathAbs(tmpProc-97.5)<MathAbs(Proc-97.5)){
                     FDB=TMP-1;
                  }
                  else{
                     FDB=TMP;
                  }
                  break;
               }
               tmpProc=Proc;
				}
		}
      SET_LINE("FDSD-2 ", LINETIME, ENDTIME, FDB*Point + LOWEST, FDBalanceColor, 1, STYLE_DOT);
      SET_LABEL("FDSD-2Label", "-sd2   ", ENDTIME, FDB*Point + LOWEST, FDBalanceColor);

		}
      
      if (Show_AVGRDL == True)
      {
            SET_VLINE("AVGRDL", Time[iBarShift(NULL,0,LINETIME)-AVGRDL], Time[iBarShift(NULL,0,LINETIME)-AVGRDL], High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))], Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))],WarnaRDL, 2, STYLE_SOLID);
      }
      
      if (Show_POC == True)
      {
      SET_LINE("OBJLine", LINETIME, ENDTIME, MAXPrice, RDLColor, 1, STYLE_SOLID);
      SET_LABEL("OBJLabel", "POC   ", ENDTIME, MAXPrice, RDLColor);
      }
      if (Show_VA == True)
      {
      SET_LINE("OBJLine2", LINETIME, ENDTIME, VAH, RDLColor, 1, STYLE_DOT);
      SET_LABEL("OBJLabe2", "VAH   ", ENDTIME, VAH, RDLColor);
 
      SET_LINE("OBJLine3", LINETIME, ENDTIME, VAL, RDLColor, 1, STYLE_DOT);
      SET_LABEL("OBJLabe3", "VAL   ", ENDTIME, VAL, RDLColor);
      }
 
      if (Show_AVG == True)
      {
      SET_LINE("OBJLine4", LINETIME, ENDTIME, AVG, RDLColor, 1, STYLE_SOLID);
      SET_LABEL("OBJLabe4", "AVG   ", ENDTIME, AVG, RDLColor);
      }
      if (Show_REG == True)
      {
      SET_LINE("OBJLine5", LINETIME, ENDTIME, REG, RDLColor, 1, STYLE_DASHDOTDOT);
      SET_LABEL("OBJLabe5", "REG   ", ENDTIME, REG, RDLColor);
      }
      if (Show_SD2 == True)
      {
      SET_LINE("OBJLine6", LINETIME, ENDTIME, VAH2, RDLColor, 1, STYLE_DOT);
      SET_LABEL("OBJLabe6", "+2  ", ENDTIME, VAH2, RDLColor);
 
      SET_LINE("OBJLine7", LINETIME, ENDTIME, VAL2, RDLColor, 1, STYLE_DOT);
      SET_LABEL("OBJLabe7", "-2  ", ENDTIME, VAL2, RDLColor);
      }
      if (Show_BSB == True)
      {
      SET_LINE("OBJLine8", LINETIME, ENDTIME, BSB, RDLColor, 1, STYLE_SOLID);
      SET_LABEL("OBJLabe8", "Balance       ", ENDTIME, BSB, RDLColor);
      }
      if (Show_SSP == True)
      {
      SET_LINE("OBJLine9", LINETIME, ENDTIME, SSP, RDLColor, 1, STYLE_DOT);
      SET_LABEL("OBJLabe9", "Hi   ", ENDTIME, SSP, RDLColor);
      }
      if (Show_BSP == True)
      {
      SET_LINE("OBJLine10", LINETIME, ENDTIME, BSP, RDLColor, 1, STYLE_DOT);
      SET_LABEL("OBJLabe10", "Lo   ", ENDTIME, BSP, RDLColor);
      }
	}// END IF
	else{
		for(i=Per-SAVEPER; i>=Akhir; i--){
			for(j=iLow(0,Sinkron,i);j<=iHigh(0,Sinkron,i);j+=Point){
				TMP	= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				COUNT[TMP] ++;
			}
			if(BellCurve){
				for(j=Low[Akhir];j<=High[Akhir];j+=Point){
					TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
					if(COUNT[TMP] > 0){
						TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
					if(TMPCount > 0)	
						if(MathMod(clr,2)==0){
   						SET_Rectangle("OBJR"+DoubleToStr(j,Digits)+Shift, LINETIME, j, Time[PerPNow-TMPCount], j+Point, color1);
                  }
                  else{
   						SET_Rectangle("OBJR"+DoubleToStr(j,Digits)+Shift, LINETIME, j, Time[PerPNow-TMPCount], j+Point, color2);                  
                  }
                  clr++;
					}
				}
			}
		}


		// UPDATE RDL LINE SETIAP setengah Sinkron detik
		if((TimeCurrent()-TSearch) > (Sinkron*60)/2){
			MAXPrice	= (JA_ArrayMaximum(COUNT)*Point)+LOWEST;
			TSearch	= TimeCurrent();
		}
		
		for(j=iLow(0,Sinkron,Akhir);j<=iHigh(0,Sinkron,Akhir);j+=Point){
			TMP	= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
			COUNT[TMP] --;
		}
	}// END ELSE
	
	//SET_LINE("OBJLine", LINETIME, ENDTIME, MAXPrice, WarnaRDL, 1, STYLE_DOT);
	//SET_LABEL("OBJLabel", "RDL", ENDTIME, MAXPrice, WarnaRDL);

	SAVE_LINETIME	= LINETIME;
   save_end       = ENDTIME;
	SAVEPER			= Per;
//   FIRST = true;
}


//+------------------------------------------------------------------+
//|  JA_ArrayMaximum                                                    |
//+------------------------------------------------------------------+
int JA_ArrayMaximum(int &ARY[]){
	int i,TOTAL,CATAT=0;
	TOTAL = ArraySize(ARY);

	for(i=0;i<TOTAL;i++){
		if(ARY[i] > ARY[CATAT]){
			CATAT 	= i;
		}
	}
	return(CATAT);
}



//+------------------------------------------------------------------+
//|  JA_ArrayCopy                                                    |
//+------------------------------------------------------------------+
void JA_ArrayCopy(int &ARY_DEST[], int &ARY_SOURCE[]){
	int i,TOTAL,CATAT=0;
	TOTAL = ArraySize(ARY_DEST);

	for(i=0;i<TOTAL;i++){
		ARY_DEST[i] = ARY_SOURCE[i];
	}

}


//+------------------------------------------------------------------+
//|  ScaleValue                                                    |
//+------------------------------------------------------------------+
int ScaleValue(double x, double in_min, double in_max, double out_min, double out_max) {
	return(MathFloor((x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min));
}


//+------------------------------------------------------------------+
//|  SET_Rectangle                                                    |
//+------------------------------------------------------------------+
void SET_Rectangle(string name, datetime Tm1, double Prc1, datetime Tm2, double Prc2, color clr){
	if(ObjectFind(LabelName+name) == -1){
		ObjectCreate(LabelName+name, OBJ_RECTANGLE,0, Tm1, Prc1, Tm2, Prc2);
		ObjectSet(LabelName+name, OBJPROP_COLOR, clr);
		ObjectSet(LabelName+name, OBJPROP_BACK, true);
	}
	ObjectSet(LabelName+name, OBJPROP_TIME2, Tm2);
	ObjectSet(LabelName+name, OBJPROP_PRICE2, Prc2);
}

//+------------------------------------------------------------------+
//|  SET_LINE                                                        |
//+------------------------------------------------------------------+
void SET_LINE(string name, datetime OpenTm, datetime CloseTm, double Prc, color clr, int WIDTH, int MYSTYLE=STYLE_SOLID){

	if(ObjectFind(LabelName+name) == -1){
		ObjectCreate(LabelName+name, OBJ_TREND, 0, OpenTm, Prc, CloseTm, Prc);
		ObjectSet(LabelName+name, OBJPROP_STYLE, MYSTYLE);
		ObjectSet(LabelName+name, OBJPROP_WIDTH, WIDTH);
		ObjectSet(LabelName+name, OBJPROP_COLOR, clr);
		ObjectSet(LabelName+name, OBJPROP_RAY, false);
		ObjectSet(LabelName+name, OBJPROP_BACK, true);

	}

	ObjectSet(LabelName+name, OBJPROP_TIME1, OpenTm);
	ObjectSet(LabelName+name, OBJPROP_TIME2, CloseTm);
	ObjectSet(LabelName+name, OBJPROP_PRICE1, Prc);
	ObjectSet(LabelName+name, OBJPROP_PRICE2, Prc);
}




//+------------------------------------------------------------------+
//|  SET_LABEL                                                       |
//+------------------------------------------------------------------+
void SET_LABEL(string NAMA, string TEXT, datetime WAKTU, double HARGA, color WARNA){
	if(ShowPrice){
		if(ObjectFind(LabelName+NAMA) == -1)
			ObjectCreate(LabelName+NAMA, OBJ_ARROW, 0, WAKTU, HARGA);

		ObjectSet(LabelName+NAMA, OBJPROP_TIME1, WAKTU);
		ObjectSet(LabelName+NAMA, OBJPROP_PRICE1, HARGA);
		ObjectSet(LabelName+NAMA, OBJPROP_COLOR, WARNA);
		ObjectSet(LabelName+NAMA, OBJPROP_ARROWCODE, SYMBOL_RIGHTPRICE);
	}

	if(ShowID){
		NAMA = NAMA+" TXT";
   	if(ObjectFind(LabelName+NAMA) == -1)
			ObjectCreate(LabelName+NAMA, OBJ_TEXT, 0, WAKTU, HARGA);

		ObjectSet(LabelName+NAMA, OBJPROP_TIME1, WAKTU);
		ObjectSet(LabelName+NAMA, OBJPROP_PRICE1, HARGA);
		ObjectSetText(LabelName+NAMA, TEXT, 8, "Verdana", WARNA);
		ObjectSetText(LabelName+NAMA, TEXT, 8, "Verdana", WARNA);
	}
}// END SET_LABEL

//+------------------------------------------------------------------+
//|  SET_LINE                                                        |
//+------------------------------------------------------------------+
void SET_VLINE(string name, datetime OpenTm, datetime CloseTm, double Prc1, double Prc2, color clr, int WIDTH, int MYSTYLE=STYLE_SOLID){

	if(ObjectFind(LabelName+name) == -1){
		ObjectCreate(LabelName+name, OBJ_VLINE, 0, OpenTm, Prc1, CloseTm, Prc2);
		ObjectSet(LabelName+name, OBJPROP_STYLE, MYSTYLE);
		ObjectSet(LabelName+name, OBJPROP_WIDTH, WIDTH);
		ObjectSet(LabelName+name, OBJPROP_COLOR, clr);
		ObjectSet(LabelName+name, OBJPROP_RAY, false);
		ObjectSet(LabelName+name, OBJPROP_BACK, true);

	}

	ObjectSet(LabelName+name, OBJPROP_TIME1, OpenTm);
	ObjectSet(LabelName+name, OBJPROP_TIME2, CloseTm);
	ObjectSet(LabelName+name, OBJPROP_PRICE1, Prc1);
	ObjectSet(LabelName+name, OBJPROP_PRICE2, Prc2);
}
















//+------------------------------------------------------------------+
//| start2()                     											   |
//+------------------------------------------------------------------+
int start2(){
	if(ERROR)
		return(0);
	
	int			SinkronPer,i,k,Jarak,COUNTER,ARRAYCount[],TMP,TMPCount,SumRDL=0,AVGRDL;
	double		j,ArraySinkronHigh[5],ArraySinkronLow[5];
	datetime		ArraySinkronTime[5];

	if(ObjectFind(LabelName) == -1){
		ObjectCreate(LabelName, OBJ_VLINE, 0, LINETIME, 0);
		ObjectSet(LabelName, OBJPROP_COLOR, WarnaRDL);
		ObjectSet(LabelName, OBJPROP_STYLE, STYLE_DOT);
		ObjectSet(LabelName, OBJPROP_BACK, true);
	}

	if(ObjectFind(LabelName+"end") == -1){
		ObjectCreate(LabelName+"end", OBJ_VLINE, 0, ENDTIME, 0);
		ObjectSet(LabelName+"end", OBJPROP_COLOR, WarnaRDL);
		ObjectSet(LabelName+"end", OBJPROP_STYLE, STYLE_DOT);
		ObjectSet(LabelName+"end", OBJPROP_BACK, true);
	}

	LINETIME		= ObjectGet(LabelName, OBJPROP_TIME1);
	Per			= iBarShift(NULL, Sinkron, LINETIME);
	ENDTIME		= ObjectGet(LabelName+"end", OBJPROP_TIME1);
   Akhir       = iBarShift(NULL, Sinkron, ENDTIME);

/*	if(BellCurve){
		if(ObjectFind(LabelName) == -1){
			ObjectCreate(LabelName, OBJ_VLINE, 0, LINETIME, 0);
			ObjectSet(LabelName, OBJPROP_COLOR, WarnaRDL);
			ObjectSet(LabelName, OBJPROP_STYLE, STYLE_DOT);
			ObjectSet(LabelName, OBJPROP_BACK, true);
		}
	}	
   ObjectSet(LabelName, OBJPROP_TIME1, LINETIME);*/

	if((SAVE_LINETIME != LINETIME) || (SAVEPER != Per) || (IndicatorCounted() == 0)){
		
		if(save_end != ENDTIME || SAVE_LINETIME != LINETIME) {DELOBJ();FIRST			= true;}
		if(ENDTIME>Time[0] && tick>=Update.Tiap_N_Tick)   {DELOBJ(); tick=0; FIRST=true;}
		// SIMPAN POSISI KE FILE
		handle	= FileOpen(NamaFile, FILE_BIN|FILE_WRITE);
		if(handle>=1){
			FileWriteInteger(handle, LINETIME, LONG_VALUE);
			FileWriteInteger(handle, ENDTIME, LONG_VALUE);
			FileClose(handle);
		}
	}

	if(FIRST){
		FIRST		= false;
		LOWEST	= Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))]-(100*Point);
		HIGHEST	= High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))]+(100*Point);
		Jarak		= (HIGHEST - LOWEST)/Point;

		ArrayResize(COUNT, Jarak);
		ArrayResize(TMP_COUNT, Jarak);
		ArrayInitialize(COUNT, 0);
		ArrayInitialize(TMP_COUNT, 0);

		ArrayCopySeries(ArraySinkronHigh, MODE_HIGH, 0, Sinkron);
		ArrayCopySeries(ArraySinkronLow, MODE_LOW, 0, Sinkron);
		ArrayCopySeries(ArraySinkronTime, MODE_TIME, 0, Sinkron);

		for(i=Per;i>=Akhir;i--){
			for(j=ArraySinkronLow[i];j<=ArraySinkronHigh[i];j+=Point){
				TMP	= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				COUNT[TMP] ++;
			}
		}// END FOR
		MAXPrice	= (JA_ArrayMaximum(COUNT)*Point)+LOWEST;

		for(j=ArraySinkronLow[0];j<=ArraySinkronHigh[0];j+=Point){
			TMP	= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
			COUNT[TMP] --;
		}
		JA_ArrayCopy(TMP_COUNT, COUNT);
		SAVEPER			= Bars;
		CountMax			= COUNT[JA_ArrayMaximum(COUNT)];
		PerPNow			= iBarShift(NULL, 0, LINETIME);
		PerPEnd			= iBarShift(NULL, 0, ENDTIME);
		PerPNowScale 	= CountMax	;//(PerPNow-PerPEnd);
		//if(CurveLine>0 && PerPNowScale>CurveLine)PerPNowScale=CurveLine;
		//if(PerPNowScale > 150)PerPNowScale = 150;
			
      //PerPNowScale=30;
		//Print(PerPNowScale);
		int clr = 0;
		if(BellCurve){
			for(j=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j<=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j+=Point){
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0){
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
					if(TMPCount > 0)
					{
					      tmpKa = Time[0]+(Period()*60*(LINETIMEn+PerPNowScale));
					      tmpKa2= Time[0]+(Period()*60*(LINETIMEn+PerPNowScale-TMPCount));
						   if(MathMod(clr,2)==0){
   						   SET_Rectangle("OBJR"+DoubleToStr(j,Digits)+Shift, tmpKa, j, tmpKa2, j+Point, color1);
                     }
                     else{
   						   SET_Rectangle("OBJR"+DoubleToStr(j,Digits)+Shift, tmpKa, j, tmpKa2, j+Point, color2);                  
                     }
               }
                  SumRDL+=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
                  clr++;
				}
			}
		}
      AVGRDL = SumRDL/((High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))]-Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))])/Point);
      double VAH = iBands(NULL,Sinkron,Per-Akhir+1,1,0,PRICE_TYPICAL,MODE_UPPER,Akhir);//
      double VAL = iBands(NULL,Sinkron,Per-Akhir+1,1,0,PRICE_TYPICAL,MODE_LOWER,Akhir);
      double VAH2 = iBands(NULL,Sinkron,Per-Akhir+1,2,0,PRICE_TYPICAL,MODE_UPPER,Akhir);//iMA(0,Sinkron,1,Per,0,1,0);
      double VAL2 = iBands(NULL,Sinkron,Per-Akhir+1,2,0,PRICE_TYPICAL,MODE_LOWER,Akhir);
      double AVG = iMA(0,Sinkron,Per-Akhir+1,0,0,PRICE_TYPICAL,Akhir);
      double REG = 3*iMA(0,Sinkron,Per-Akhir+1,0,3,PRICE_TYPICAL,Akhir)-2*iMA(0,Sinkron,Per-Akhir+1,0,0,PRICE_TYPICAL,Akhir);
      double BSB = ( (iHigh(NULL, Sinkron, iHighest(NULL, Sinkron, MODE_HIGH, Per-Akhir+1, Akhir)) + iLow(NULL, 0, iLowest(NULL, Sinkron, MODE_LOW, Per-Akhir+1, Akhir)) )/2);
      double SSP = iHigh(NULL, Sinkron, iHighest(NULL, Sinkron, MODE_HIGH, Per-Akhir+1, Akhir));
      double BSP = iLow(NULL, 0, iLowest(NULL, Sinkron, MODE_LOW, Per-Akhir+1, Akhir));
      
		if(ShowSD1RDL){
		   int pembagi = 0;
			int RDLsq = 0;
			for(j=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j<=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j+=Point){
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0){
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
               //SumRDL+=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
               RDLsq += MathPow(iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount])-AVGRDL,2);
               pembagi++;
				}
		}
		pembagi=((High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))]-Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))])/Point);
		//Alert(RDLsq + "     " + pembagi);
	   RDLsq=MathSqrt(RDLsq/SumRDL);
      SET_VLINE("RDLsq", 
      Time[0]+(Period()*60*(LINETIMEn+PerPNowScale-RDLsq)), 
      Time[0]+(Period()*60*(LINETIMEn+PerPNowScale-RDLsq)), 
      High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))], 
      Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))],
      SD1RDLColor, 2, STYLE_SOLID);
		}

      if (Show_Shape == True)
      {
         int awalShape=0,akhirShape=0,POCShape=0;
			for(j=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j<=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j+=Point){
   			TMP	= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);   
				if(COUNT[TMP] > 0){
               if(COUNT[TMP-1]<AVGRDL && COUNT[TMP]>=AVGRDL){
                  awalShape=TMP;
                  POCShape=TMP;
               }
               if(POCShape > 0){
                  if(COUNT[TMP]>COUNT[POCShape])POCShape=TMP;
               }
               if(awalShape != 0 && COUNT[TMP+1]<AVGRDL && COUNT[TMP]>=AVGRDL){
                  akhirShape=TMP;
               }
               if(awalShape !=0 && akhirShape != 0){
                  //SET_Rectangle("OBJAREA" + TMP, LINETIME, awalShape*Point + LOWEST,ENDTIME, akhirShape*Point + LOWEST, ShapeColor);
                  SET_Rectangle("OBJAREA" + TMP, LINETIME, awalShape*Point + LOWEST,Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), akhirShape*Point + LOWEST, ShapeColor);
                  //SET_LINE("OBJPOCShape " + TMP, LINETIME, ENDTIME, POCShape*Point + LOWEST, POCShapeColor, 1, STYLE_DASHDOT);
                  awalShape=0;
                  akhirShape=0;
                  POCShape=0;
               } 
	         }
			}
      }

		if(Show_FDBalance){
		   double Sum = 0, tmpProc,Proc;
		   int FDB;
			for(j=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j<=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j+=Point){
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0){
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
               Sum +=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
               Proc=(Sum/SumRDL)*100;
               if(Proc==50){
                  FDB=TMP;
                  break;
               }
               if(tmpProc<50 && Proc>50){
                  if(MathAbs(tmpProc-50)<MathAbs(Proc-50)){
                     FDB=TMP-1;
                  }
                  else{
                     FDB=TMP;
                  }
                  break;
               }
               tmpProc=Proc;
				}
		}
      SET_LINE("50% FTD ", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), FDB*Point + LOWEST, FDBalanceColor, Tebal_Garis, STYLE_SOLID);
      SET_LABEL("FDBLabel", "50%   ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), FDB*Point + LOWEST, FDBalanceColor);
		}

		if(Show_FD_SDp1)
		{
		   Sum = 0;
		   Proc=0;
		   tmpProc=0;
			for(j=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j<=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j+=Point)
			{
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0)
				{
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
               Sum +=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
               Proc=(Sum/SumRDL)*100;
               if(Proc==84)
               {
                  FDB=TMP;
                  break;
               }
               if(tmpProc<84 && Proc>84)
               {
                  if(MathAbs(tmpProc-84)<MathAbs(Proc-84))
                  {
                     FDB=TMP-1;
                  }
                  else{
                     FDB=TMP;
                  }
                  break;
               }
               tmpProc=Proc;
				}
		   }
            SET_LINE("FDSD+1 ", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), FDB*Point + LOWEST, FDBalanceColor, 1, STYLE_DOT);
            SET_LABEL("FDSD+1Label", "+sd1   ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), FDB*Point + LOWEST, FDBalanceColor);
      }
      
      if(Show_FD_SDn1)
      {
		   Sum = 0;
		   Proc=0;
		   tmpProc=0;
			for(j=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j>=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j-=Point){
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0){
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
               Sum +=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
               Proc=(Sum/SumRDL)*100;
               if(Proc==84){
                  FDB=TMP;
                  break;
               }
               if(tmpProc<84 && Proc>84){
                  if(MathAbs(tmpProc-84)<MathAbs(Proc-84)){
                     FDB=TMP-1;
                  }
                  else{
                     FDB=TMP;
                  }
                  break;
               }
               tmpProc=Proc;
				}
		}
      SET_LINE("FDSD-1 ", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), FDB*Point + LOWEST, FDBalanceColor, 1, STYLE_DOT);
      SET_LABEL("FDSD-1Label", "-sd1   ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), FDB*Point + LOWEST, FDBalanceColor);

		}

      if(Show_FD_SDp2)
		{
		   Sum = 0;
		   Proc=0;
		   tmpProc=0;
			for(j=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j<=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j+=Point)
			{
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0)
				{
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
               Sum +=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
               Proc=(Sum/SumRDL)*100;
               if(Proc==97.5)
               {
                  FDB=TMP;
                  break;
               }
               if(tmpProc<97.5 && Proc>97.5)
               {
                  if(MathAbs(tmpProc-97.5)<MathAbs(Proc-97.5))
                  {
                     FDB=TMP-1;
                  }
                  else{
                     FDB=TMP;
                  }
                  break;
               }
               tmpProc=Proc;
				}
		   }
            SET_LINE("FDSD+2 ", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), FDB*Point + LOWEST, FDBalanceColor, 1, STYLE_DOT);
            SET_LABEL("FDSD+2Label", "+sd2   ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), FDB*Point + LOWEST, FDBalanceColor);
      }
      
      if(Show_FD_SDn2)
      {
		   Sum = 0;
		   Proc=0;
		   tmpProc=0;
			for(j=High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j>=Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))];j-=Point){
				TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				if(COUNT[TMP] > 0){
					TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
               Sum +=iBarShift(NULL,0,LINETIME)-iBarShift(NULL,0,Time[PerPNow-TMPCount]);
               Proc=(Sum/SumRDL)*100;
               if(Proc==97.5){
                  FDB=TMP;
                  break;
               }
               if(tmpProc<97.5 && Proc>97.5){
                  if(MathAbs(tmpProc-97.5)<MathAbs(Proc-97.5)){
                     FDB=TMP-1;
                  }
                  else{
                     FDB=TMP;
                  }
                  break;
               }
               tmpProc=Proc;
				}
		}
      SET_LINE("FDSD-2 ", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), FDB*Point + LOWEST, FDBalanceColor, 1, STYLE_DOT);
      SET_LABEL("FDSD-2Label", "-sd2   ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), FDB*Point + LOWEST, FDBalanceColor);

		}
      
      if (Show_AVGRDL == True)
      {
         
            SET_VLINE("AVGRDL", tmpKa-(AVGRDL)*Period()*60, tmpKa-(AVGRDL)*Period()*60, High[iHighest(0,0,MODE_HIGH,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))], Low[iLowest(0,0,MODE_LOW,iBarShift(NULL, 0, LINETIME),iBarShift(NULL, 0, ENDTIME))],WarnaRDL, 2, STYLE_SOLID);   
         
      }
      
      if (Show_POC == True)
      {
      SET_LINE("OBJLine", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), MAXPrice, RDLColor, 1, STYLE_SOLID);
      SET_LABEL("OBJLabel", "POC   ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), MAXPrice, RDLColor);
      }
      if (Show_VA == True)
      {
      SET_LINE("OBJLine2", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), VAH, RDLColor, 1, STYLE_DOT);
      SET_LABEL("OBJLabe2", "VAH   ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), VAH, RDLColor);
 
      SET_LINE("OBJLine3", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), VAL, RDLColor, 1, STYLE_DOT);
      SET_LABEL("OBJLabe3", "VAL   ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), VAL, RDLColor);
      }
 
      if (Show_AVG == True)
      {
      SET_LINE("OBJLine4", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), AVG, RDLColor, 1, STYLE_SOLID);
      SET_LABEL("OBJLabe4", "AVG   ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), AVG, RDLColor);
      }
      if (Show_REG == True)
      {
      SET_LINE("OBJLine5", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), REG, RDLColor, 1, STYLE_DASHDOTDOT);
      SET_LABEL("OBJLabe5", "REG   ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), REG, RDLColor);
      }
      if (Show_SD2 == True)
      {
      SET_LINE("OBJLine6", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), VAH2, RDLColor, 1, STYLE_DOT);
      SET_LABEL("OBJLabe6", "+2  ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), VAH2, RDLColor);
 
      SET_LINE("OBJLine7", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), VAL2, RDLColor, 1, STYLE_DOT);
      SET_LABEL("OBJLabe7", "-2  ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), VAL2, RDLColor);
      }
      if (Show_BSB == True)
      {
      SET_LINE("OBJLine8", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), BSB, RDLColor, 1, STYLE_SOLID);
      SET_LABEL("OBJLabe8", "Balance       ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), BSB, RDLColor);
      }
      if (Show_SSP == True)
      {
      SET_LINE("OBJLine9", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), SSP, RDLColor, 1, STYLE_DOT);
      SET_LABEL("OBJLabe9", "Hi   ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), SSP, RDLColor);
      }
      if (Show_BSP == True)
      {
      SET_LINE("OBJLine10", LINETIME, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), BSP, RDLColor, 1, STYLE_DOT);
      SET_LABEL("OBJLabe10", "Lo   ", Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), BSP, RDLColor);
      }
	}// END IF
	else
	{
		for(i=Akhir+Per-SAVEPER; i>=Akhir; i--)
		{
			for(j=iLow(0,Sinkron,i);j<=iHigh(0,Sinkron,i);j+=Point)
			{
				TMP	= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
				COUNT[TMP] ++;
			}
			if(BellCurve)
			{
            if(i-Akhir==1 && ENDTIME<Time[0])
            {
	              for(int o=ObjectsTotal();o>=0;o--){
		              string name	= ObjectName(o);
		              if(StringSubstr(name, 0, StringLen(LabelName)) == LabelName)
		              {
		                 if(name!=LabelName && name!=LabelName+"end")
		                 {
		                 datetime t=ObjectGet(name,OBJPROP_TIME1);
			              ObjectSet(name, OBJPROP_TIME1, t+60*Period());
			              t=ObjectGet(name,OBJPROP_TIME2);
	                    ObjectSet(name, OBJPROP_TIME2, t+60*Period());
	                    }
	                 }
	                    
	              }
            }
            else
            {
              if(ENDTIME>Time[0])
				  for(j=Low[Akhir];j<=High[Akhir];j+=Point){
					  TMP		= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
					  if(COUNT[TMP] > 0)
					  {
						  TMPCount = ScaleValue(COUNT[TMP],0,CountMax,0,PerPNowScale);
					      if(TMPCount > 0)	
						      if(MathMod(clr,2)==0)
						      {
   						      SET_Rectangle("OBJR"+DoubleToStr(j,Digits)+Shift, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), j, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale-TMPCount)), j+Point, color1);
                        }
                        else{
   						      SET_Rectangle("OBJR"+DoubleToStr(j,Digits)+Shift, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale)), j, Time[0]+(Period()*60*(LINETIMEn+PerPNowScale-TMPCount)), j+Point, color2);                  
                        }
                        clr++;
					  }
				  }
				}
			}
		}


		// UPDATE RDL LINE SETIAP setengah Sinkron detik
		if((TimeCurrent()-TSearch) > (Sinkron*60)/2){
			MAXPrice	= (JA_ArrayMaximum(COUNT)*Point)+LOWEST;
			TSearch	= TimeCurrent();
		}
		
		for(j=iLow(0,Sinkron,Akhir);j<=iHigh(0,Sinkron,Akhir);j+=Point){
			TMP	= NormalizeDouble(j/Point,0)-NormalizeDouble(LOWEST/Point,0);
			COUNT[TMP] --;
		}
	}// END ELSE
	
	//SET_LINE("OBJLine", LINETIME, ENDTIME, MAXPrice, WarnaRDL, 1, STYLE_DOT);
	//SET_LABEL("OBJLabel", "RDL", ENDTIME, MAXPrice, WarnaRDL);

	SAVE_LINETIME	= LINETIME;
   save_end       = ENDTIME;
	SAVEPER			= Per;
//   FIRST = true;
}