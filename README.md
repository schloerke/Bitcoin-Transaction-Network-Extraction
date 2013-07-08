# Bitcoin Transaction Network Extraction

This project is to be used solely with [schloerke's bitcointools](http://github.com/schloerke/bitcointools).


# Install

Please see the intructions on [schloerke's bitcointools](http://github.com/schloerke/bitcointools) repo to download the data.

Once your data has been downloaded, alter the file locations within ```process_bitcoin_network_runner.sh``` to point to their proper directories.  Then execute the runner

```{bash}
./process_bitcoin_network_runner.sh
```

Then wait about 18 hours.  :-(. This amount of time does not include syncing to the bitcoin network.  This amount of time only accounts for exporting the bitcoin database to a human readable format and grouping the exported data into users.
