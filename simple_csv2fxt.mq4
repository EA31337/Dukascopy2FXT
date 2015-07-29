//+------------------------------------------------------------------+
//|                                               simple_csv2fxt.mq4 |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property show_inputs

#include <FXTHeader.mqh>
extern string ExtCsvFile="";
extern string ExtDelimiter=";";
extern bool   ExtCreateHst=true;

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
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
   datetime cur_time,cur_open;
   double   tick_price;
   int      delimiter=';';
//----
   ExtTicks=0;
   ExtBars=0;
   ExtLastTime=0;
   ExtLastBarTime=0;
//---- open input csv-file
   if(StringLen(ExtCsvFile)<=0)  ExtCsvFile=Symbol()+"_ticks.csv";
   if(StringLen(ExtDelimiter)>0) delimiter=StringGetChar(ExtDelimiter,0);
   if(delimiter==' ')  delimiter=';';
   if(delimiter=='\\') delimiter='\t';
   ExtCsvHandle=FileOpen(ExtCsvFile,FILE_CSV|FILE_READ,delimiter);
   if(ExtCsvHandle<0) return(-1);
//---- open output fxt-file
   ExtFileName=Symbol()+Period()+"_0.fxt";
   ExtHandle=FileOpen(ExtFileName,FILE_BIN|FILE_WRITE);
   if(ExtHandle<0) return(-1);
//----
   ExtPeriodSeconds=Period()*60;
   WriteHeader(ExtHandle,Symbol(),Period(),0);
//---- open hst-file and write it's header
   if(ExtCreateHst) WriteHstHeader();
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
   return(0);
  }
//+------------------------------------------------------------------+
//| YYYY.MM.DD HH:MI:SS;1.2345                                       |
//+------------------------------------------------------------------+
bool ReadNextTick(datetime& cur_time, double& tick_price)
  {
//----
   while(!IsStopped())
     {
      //---- first read date and time
      string date_time=FileReadString(ExtCsvHandle);
      if(FileIsEnding(ExtCsvHandle)) return(false);
      cur_time=StrToTime(date_time);
      //---- read tick price
      tick_price=FileReadNumber(ExtCsvHandle);
      if(FileIsEnding(ExtCsvHandle)) return(false);
      //---- time must go forward. if no then read further
      if(cur_time>ExtLastTime) break;
     }
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
   int    i_period=Period();
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
   FileWriteArray(ExtHstHandle, i_unused, 0, 16);
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
