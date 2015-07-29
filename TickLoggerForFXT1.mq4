//+------------------------------------------------------------------+
//|                                             TickLoggerForFXT.mq4 |
//|                                               Paul Hampton-Smith |
//+------------------------------------------------------------------+

int handle;

int init()
{
   Comment("Waiting for tick");
   handle = FileOpen(Symbol() + TimeToStr(CurTime(),TIME_DATE) + "_tick_log.csv", FILE_CSV|FILE_READ|FILE_WRITE, ';' );
   FileSeek(handle,0,SEEK_END);
}

int deinit()
{
   FileClose(handle);
}

int start()
{
   Comment("Logging ticks");
   FileWrite(handle,TimeToStr(CurTime()),Bid);
   return(0);
}


