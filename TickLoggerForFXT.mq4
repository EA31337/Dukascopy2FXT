//+---------------------------------------------------------------------+
//|                                                TickLoggerForFXT.mq4 |
//|                                                  Paul Hampton-Smith |
//| Version 2 with seconds recorded and additional comments on the chart|
//+---------------------------------------------------------------------+

int handle;
string strFilename;
int nTickCount;

int init()
{
   Comment("\nWaiting for first tick");
   string strMonthPad = "";
   string strDayPad = "";
   if (Month()<10) strMonthPad = "0";
   if (Day()<10) strDayPad = "0";
   
   strFilename = StringConcatenate(Symbol(),"_",Year(),strMonthPad,Month(),strDayPad,Day(),"_ticks.csv");
   nTickCount = 0;
   handle = FileOpen(strFilename, FILE_CSV|FILE_READ|FILE_WRITE, ';' );
   FileSeek(handle,0,SEEK_END);
}

int deinit()
{
   FileClose(handle);
}

int start()
{
	nTickCount++;
   Comment("\nLogging tick #",nTickCount," to ",strFilename);
   FileWrite(handle,TimeToStr(CurTime(),TIME_DATE|TIME_MINUTES|TIME_SECONDS),Bid);
   return(0);
}


