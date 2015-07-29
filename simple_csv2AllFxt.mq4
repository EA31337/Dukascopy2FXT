//+------------------------------------------------------------------+
//|                                            simple_csv2Allfxt.mq4 |
//|   with mods by Paul Hampton-Smith                                |
//|    - fixed hst header error                                      |
//|    - output selected fxt files with one pass							|
//|    - handle logfiles with no seconds         							|
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property show_inputs

#include <FXTHeader.mqh>
extern string ExtCsvFile="";
extern bool MakeM1 = true;
extern bool MakeM5 = true;
extern bool MakeM15 = true;
extern bool MakeM30 = true;
extern bool MakeH1 = true;
extern bool MakeH4 = true;
extern bool MakeD1 = true;
extern bool MakeW1 = true;

int      ExtTicks;
int      ExtBars;
int      ExtCsvHandle=-1;
int      ExtHstHandle=-1;
int      ExtHandle=-1;
string   ExtFileName;
int      ExtPeriodSeconds;
datetime ExtLastTime;
datetime ExtLastBarTime;
double   ExtLastOpen;
double   ExtLastLow;
double   ExtLastHigh;
double   ExtLastClose;
double   ExtLastVolume;
int nHourPrev, nMinutePrev, nSeconds;

int nPeriod;
bool bDebug = false;

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
{
	if (MakeM1) MakeFXT(PERIOD_M1);
	if (MakeM5)	MakeFXT(PERIOD_M5);
	if (MakeM15)MakeFXT(PERIOD_M15);
	if (MakeM30)MakeFXT(PERIOD_M30);
	if (MakeH1)	MakeFXT(PERIOD_H1);
	if (MakeH4)	MakeFXT(PERIOD_H4);
	if (MakeD1)	MakeFXT(PERIOD_D1);
	if (MakeW1)	MakeFXT(PERIOD_W1);
	Comment("simple_csv2AllFxt completed");
}

//+------------------------------------------------------------------+
//| YYYY.MM.DD HH:MI:SS;1.2345                                       |
//+------------------------------------------------------------------+
bool ReadNextTick(datetime& cur_time, double& tick_price)
  {
//----
      //---- first read date and time
      string date_time=FileReadString(ExtCsvHandle);
      if(FileIsEnding(ExtCsvHandle)) return(false);
      cur_time=StrToTime(date_time);
      
      if (TimeSeconds(cur_time) == 0)
      {
      	// may have a record without seconds
	      if ( nHourPrev == TimeHour(cur_time) &&
	      	nMinutePrev == TimeMinute(cur_time) )
      	{
				// same minute - add 1 second
     			if (nSeconds < 59) nSeconds++;
     		}
     		else
     		{
     			nSeconds = 0;
     		}
     		cur_time = cur_time + nSeconds;
     	}
     	nHourPrev = TimeHour(cur_time);
     	nMinutePrev = TimeMinute(cur_time);
      	
      //---- read tick price
      tick_price=FileReadNumber(ExtCsvHandle);
      if(FileIsEnding(ExtCsvHandle)) return(false);
//---- price must be normalized
   tick_price=NormalizeDouble(tick_price,Digits);
   ExtLastTime=cur_time;
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void WriteTick()
{
//---- current bar state
   FileWriteInteger(ExtHandle, ExtLastBarTime, LONG_VALUE);
   FileWriteDouble(ExtHandle, ExtLastOpen, DOUBLE_VALUE);
   FileWriteDouble(ExtHandle, ExtLastLow, DOUBLE_VALUE);
   FileWriteDouble(ExtHandle, ExtLastHigh, DOUBLE_VALUE);
   FileWriteDouble(ExtHandle, ExtLastClose, DOUBLE_VALUE);
   FileWriteDouble(ExtHandle, ExtLastVolume, DOUBLE_VALUE);
//---- incoming tick time
   FileWriteInteger(ExtHandle, ExtLastTime, LONG_VALUE);
//---- flag 4 (it must be not equal to 0)
   FileWriteInteger(ExtHandle, 4, LONG_VALUE);
//---- ticks counter
   ExtTicks++;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void WriteHstHeader()
  {
//---- History header
   int    i_version=400;
   string c_copyright;
   string c_symbol=Symbol();
   int    i_period=nPeriod;
   int    i_digits=Digits;
   int    i_unused[16];
//----  
   ExtHstHandle=FileOpen(c_symbol+i_period+".hst", FILE_BIN|FILE_WRITE);
   if(ExtHstHandle < 0) return;
//---- write history file header
   c_copyright="(C)opyright 2003, MetaQuotes Software Corp.";
   FileWriteInteger(ExtHstHandle, i_version, LONG_VALUE);
   FileWriteString(ExtHstHandle, c_copyright, 64);
   FileWriteString(ExtHstHandle, c_symbol, 12);
   FileWriteInteger(ExtHstHandle, i_period, LONG_VALUE);
   FileWriteInteger(ExtHstHandle, i_digits, LONG_VALUE);
  	FileWriteInteger(ExtHstHandle, 0, LONG_VALUE);       //timesign
   FileWriteInteger(ExtHstHandle, 0, LONG_VALUE);       //last_sync
   FileWriteArray(ExtHstHandle, i_unused, 0, 13);  
  }
//+------------------------------------------------------------------+
//| write corresponding hst-file                                     |
//+------------------------------------------------------------------+
void WriteBar()
  {
   if(ExtHstHandle>0)
     {
      FileWriteInteger(ExtHstHandle, ExtLastBarTime, LONG_VALUE);
      FileWriteDouble(ExtHstHandle, ExtLastOpen, DOUBLE_VALUE);
      FileWriteDouble(ExtHstHandle, ExtLastLow, DOUBLE_VALUE);
      FileWriteDouble(ExtHstHandle, ExtLastHigh, DOUBLE_VALUE);
      FileWriteDouble(ExtHstHandle, ExtLastClose, DOUBLE_VALUE);
      FileWriteDouble(ExtHstHandle, ExtLastVolume, DOUBLE_VALUE);
     }
  }
//+------------------------------------------------------------------+

void MakeFXT(int period)
{
	nPeriod = period;
   datetime cur_time,cur_open;
   double   tick_price;
   int      delimiter=';';
//----
   ExtTicks=0;
   ExtBars=0;
   ExtLastTime=0;
   ExtLastBarTime=0;
//---- open input csv-file
//   if(StringLen(ExtCsvFile)<=0)  ExtCsvFile=Symbol()+"_ticks.csv";
//   if(StringLen(ExtDelimiter)>0) delimiter=StringGetChar(ExtDelimiter,0);
//   if(delimiter==' ')  delimiter=';';
//   if(delimiter=='\\') delimiter='\t';
   ExtCsvHandle=FileOpen(ExtCsvFile,FILE_CSV|FILE_READ,';');
   if(ExtCsvHandle<0) return(-1);
   int nCsvStartPos = FileTell(ExtCsvHandle);
   // get start time
   ReadNextTick(t_fromdate,tick_price);
   // go back to read again
   FileSeek(ExtCsvHandle,nCsvStartPos,SEEK_SET);

//---- open output fxt-file
   ExtFileName=Symbol()+nPeriod+"_0.fxt";
   ExtHandle=FileOpen(ExtFileName,FILE_BIN|FILE_WRITE);
   if(ExtHandle<0) return(-1);
   Print("Creating ",Symbol(),nPeriod,"_0.fxt");
   Comment("Creating ",Symbol(),nPeriod,"_0.fxt");
//----
   ExtPeriodSeconds=nPeriod*60;
   WriteHeader(ExtHandle,Symbol(),nPeriod,0);
//---- open hst-file and write it's header
   WriteHstHeader();
//---- csv read loop
   while(!IsStopped())
     {
      //---- if end of file reached exit from loop
      if(!ReadNextTick(cur_time,tick_price)) break;
      //---- calculate bar open time from tick time
      cur_open=cur_time/ExtPeriodSeconds;
      cur_open*=ExtPeriodSeconds;
      //---- new bar?
      if(ExtLastBarTime!=cur_open)
        {
         if(ExtBars>0) WriteBar();
         ExtLastBarTime=cur_open;
         ExtLastOpen=tick_price;
         ExtLastLow=tick_price;
         ExtLastHigh=tick_price;
         ExtLastClose=tick_price;
         ExtLastVolume=1;
         WriteTick();
         ExtBars++;
         // progress info
         if (MathMod(ExtBars,MathMax(120/nPeriod,1)) < 1) Comment("Writing bar ",ExtBars," to ",Symbol(),nPeriod,"_0.fxt");
        }
      else
        {
         //---- check for minimum and maximum
         if(ExtLastLow>tick_price)  ExtLastLow=tick_price;
         if(ExtLastHigh<tick_price) ExtLastHigh=tick_price;
         ExtLastClose=tick_price;
         ExtLastVolume++;
         WriteTick();
        }
     }
//---- finalize
   WriteBar();
   if(ExtHstHandle>0) FileClose(ExtHstHandle);
   FileClose(ExtCsvHandle);
//---- store processed bars amount
   FileFlush(ExtHandle);
   FileSeek(ExtHandle,88,SEEK_SET);
   FileWriteInteger(ExtHandle,ExtBars,LONG_VALUE);
   FileClose(ExtHandle);
   Print(ExtTicks," ticks added. ",ExtBars," bars finalized in the header");
//----
   return;
}
