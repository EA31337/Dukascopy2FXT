1) Insert the csv file to the [directory MT4] \ experts \ files \
2) To facilitate to make sure that it has a name in the format: [pair] .csv example. EURUSD.csv. It must play with the format symbol used by the broker. Some add prefixes or suffixes and must be included in the name. How can we not then you will have to enter the file name in the following steps.
3) Open the graph of interest to us steam and run on the script JForex2FXT. If the name of the game csv file with the name of steam on the chart you can skip entering the file name. How not to copy & paste ... CsvFile = ...
4) CreateHst must be true (the default) if they arise hst files. Ew. enter the date from-to, as is to be expected spreads and what is to be the target zone. The latter is very important - in your case must play with the broker.
5) Press OK and do something else. After 15 minutes, see if done.
6) How it ended up in ... \ experts \ files will be ready hst files for each time frame separately. M1 will be called such. EURUSD1.hst. There will be also a large file FXT - this is the file for the tester. If there is anything you need, you can simply delete it.
7) Files HST should be moved to a folder [directory MT4] \ history \ [server name broker for the account] \ to MT4 able to use them.
Eg. G: \ Program Files \ MetaTrader 4 at FOREX.com \ history \ Forex.com-Demo (R) \
