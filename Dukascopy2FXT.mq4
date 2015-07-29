//+------------------------------------------------------------------+
//|                                               simple_csv2fxt.mq4 |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property show_inputs

#include <FXTHeader.mqh>
extern string ExtCsvFile="";
extern bool   ExtCreateHst=false;
string ExtDelimiter=",";

int      ExtPeriods[9] = { 1, 5, 15, 30, 60, 240, 1440, 10080, 43200 };
int      ExtPeriodCount = 9;
int      ExtPeriodSeconds[9];
int      ExtHstHandle[9];

int      ExtTicks;
int      ExtBars[9];
int      ExtCsvHandle=-1;
int      ExtHandle=-1;
string   ExtFileName;
datetime ExtLastTime;
datetime ExtLastBarTime[9];
double   ExtLastOpen[9];
double   ExtLastLow[9];
double   ExtLastHigh[9];
double   ExtLastClose[9];
double   ExtLastVolume[9];

int      ExtPeriodId = 0;
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
   datetime cur_time,cur_open;
   double   tick_price;
   double   tick_volume;
   int      delimiter=';';
//----
   ExtTicks = 0;
   ExtLastTime=0;
//---- open input csv-file
   if(StringLen(ExtDelimiter)>0) delimiter=StringGetChar(ExtDelimiter,0);
   if(delimiter==' ')  delimiter=';';
   if(delimiter=='\\') delimiter='\t';
   ExtCsvHandle=FileOpen(ExtCsvFile,FILE_CSV|FILE_READ,delimiter);
   if(ExtCsvHandle<0) {
      Alert("Can\'t open input file");
      return(-1);
   }
//---- open output fxt-file
   ExtFileName=Symbol()+Period()+"_0.fxt";
   ExtHandle=FileOpen(ExtFileName,FILE_BIN|FILE_WRITE);
   if(ExtHandle<0) return(-1);
//----
   for (int i = 0; i < ExtPeriodCount; i++) {
      ExtPeriodSeconds[i] = ExtPeriods[i] * 60;
      ExtBars[i]=0;
      ExtLastBarTime[i]=0;
      if (Period() == ExtPeriods[i]) {
        ExtPeriodId = i;
      }
   }
   WriteHeader(ExtHandle,Symbol(),Period(),0);
//---- open hst-files and write it's header
   if(ExtCreateHst) WriteHstHeaders();
//---- csv read loop
   while(!IsStopped())
     {
      //---- if end of file reached exit from loop
      if(!ReadNextTick(cur_time,tick_price,tick_volume)) break;
      for (i = 0; i < ExtPeriodCount; i++) {
       //---- calculate bar open time from tick time
       cur_open=cur_time/ExtPeriodSeconds[i];
       cur_open*=ExtPeriodSeconds[i];
       //---- new bar?
       if(ExtLastBarTime[i]!=cur_open)
         {
          if(ExtBars[i]>0) WriteBar(i);
          ExtLastBarTime[i]=cur_open;
          ExtLastOpen[i]=tick_price;
          ExtLastLow[i]=tick_price;
          ExtLastHigh[i]=tick_price;
          ExtLastClose[i]=tick_price;
          if (tick_volume > 0) {
            ExtLastVolume[i]=tick_volume;
          }
          else {
            ExtLastVolume[i]=1;
          }
          ExtBars[i]++;
         }
       else
         {
          //---- check for minimum and maximum
          if(ExtLastLow[i]>tick_price)  ExtLastLow[i]=tick_price;
          if(ExtLastHigh[i]<tick_price) ExtLastHigh[i]=tick_price;
          ExtLastClose[i]=tick_price;
          ExtLastVolume[i]+=tick_volume;
         }
      }
      WriteTick();
     }
//---- finalize
   for (i = 0; i < ExtPeriodCount; i++) {
    WriteBar(i);
    if(ExtHstHandle[i]>0) FileClose(ExtHstHandle[i]);
   }
   FileClose(ExtCsvHandle);
//---- store processed bars amount
   FileFlush(ExtHandle);
   FileSeek(ExtHandle,216,SEEK_SET);
   FileWriteInteger(ExtHandle,ExtBars[ExtPeriodId],LONG_VALUE);
   FileClose(ExtHandle);
   Print(ExtTicks," ticks added. ",ExtBars[ExtPeriodId]," bars finalized in the header");
//----
   return(0);
  }

// Dukascopy custom exported data format:
// yyyy.mm.dd hh:mm:ss,bid,ask,bid_volume,ask_volume
bool ReadNextTick(datetime& cur_time, double& tick_price, double& tick_volume)
  {
  tick_volume = 0;
//----
   while(!IsStopped())
	{
		// yyyy.mm.dd hh:mm:ss
     	string date_time = FileReadString(ExtCsvHandle);
      if(FileIsEnding(ExtCsvHandle)) return(false);
      cur_time=StrToTime(date_time);
      //---- read tick price (bid)
      tick_price=FileReadNumber(ExtCsvHandle);
      // discard Ask
      double dblAsk = FileReadNumber(ExtCsvHandle);
      // add bid volume (divided by standard lotsize)
      tick_volume += FileReadNumber(ExtCsvHandle) / 100000;
      // add ask volume (divided by standard lotsize)
      tick_volume += FileReadNumber(ExtCsvHandle) / 100000;
      
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
   FileWriteInteger(ExtHandle, ExtLastBarTime[ExtPeriodId], LONG_VALUE);
   FileWriteDouble(ExtHandle, ExtLastOpen[ExtPeriodId], DOUBLE_VALUE);
   FileWriteDouble(ExtHandle, ExtLastLow[ExtPeriodId], DOUBLE_VALUE);
   FileWriteDouble(ExtHandle, ExtLastHigh[ExtPeriodId], DOUBLE_VALUE);
   FileWriteDouble(ExtHandle, ExtLastClose[ExtPeriodId], DOUBLE_VALUE);
   FileWriteDouble(ExtHandle, ExtLastVolume[ExtPeriodId], DOUBLE_VALUE);
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
void WriteHstHeaders()
  {
//---- History header
   for (int i = 0; i < ExtPeriodCount; i++) {
      int    i_version=400;
      string c_copyright;
      string c_symbol=Symbol();
      int    i_period=ExtPeriods[i];
      int    i_digits=Digits;
      int    i_unused[15];
//----  
      ExtHstHandle[i]=FileOpen(c_symbol+i_period+".hst", FILE_BIN|FILE_WRITE);
      if(ExtHstHandle[i] < 0) Print("Error opening " + c_symbol + i_period);
//---- write history file header
      c_copyright="(C)opyright 2003, MetaQuotes Software Corp.";
      FileWriteInteger(ExtHstHandle[i], i_version, LONG_VALUE);
      FileWriteString(ExtHstHandle[i], c_copyright, 64);
      FileWriteString(ExtHstHandle[i], c_symbol, 12);
      FileWriteInteger(ExtHstHandle[i], i_period, LONG_VALUE);
      FileWriteInteger(ExtHstHandle[i], i_digits, LONG_VALUE);
      FileWriteArray(ExtHstHandle[i], i_unused, 0, 15);
   }
  }
//+------------------------------------------------------------------+
//| write corresponding hst-file                                     |
//+------------------------------------------------------------------+
void WriteBar(int i)
  {
   if(ExtHstHandle[i]>0)
     {
      FileWriteInteger(ExtHstHandle[i], ExtLastBarTime[i], LONG_VALUE);
      FileWriteDouble(ExtHstHandle[i], ExtLastOpen[i], DOUBLE_VALUE);
      FileWriteDouble(ExtHstHandle[i], ExtLastLow[i], DOUBLE_VALUE);
      FileWriteDouble(ExtHstHandle[i], ExtLastHigh[i], DOUBLE_VALUE);
      FileWriteDouble(ExtHstHandle[i], ExtLastClose[i], DOUBLE_VALUE);
      FileWriteDouble(ExtHstHandle[i], ExtLastVolume[i], DOUBLE_VALUE);
     }
  }
//+------------------------------------------------------------------+
