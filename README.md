# Bitcoin Transaction Network Extraction

The goal of this repository is to extract bitcoint transaction information from ``bitcoind``` and run the extracted data through an extension of [Ivan Brugere's work](https://github.com/ivan-brugere/Bitcoin-Transaction-Network-Extraction).

# Requirements

* ```bitcoind``` v0.9.* or higher. ([download binary](https://bitcoin.org/en/download) or [Github](https://github.com/bitcoin/bitcoin/tree/master/doc))
* node.js v0.10.*.  ([download](http://nodejs.org/download/))

For mac, you may use ```brew```

```
brew tap wysenynja/bitcoin && brew install bitcoind
brew install node
npm install coffee -g # may need sudo access
```

# Initial Processing

[Download the almost current blockchain](https://github.com/bitcoin/bitcoin/blob/master/doc/bootstrap.md) by torrenting the current ```bootstrap.dat``` file.  By importing the bootstrap.dat file, you will save days of processing time.

```
wget https://bitcoin.org/bin/blockchain/bootstrap.dat.torrent
open bootstrap.dat.torrent
## download bootstrap.dat into ./ folder
```

When the 15+ GB file has finished downloading we will import it into ```bitcoind```

```
mkdir bitcoin_data
echo -e "server=1\nrpcuser=bitcoinrpc\nrpcpassword=$(xxd -l 16 -p /dev/urandom)" > bitcoin_data/bitcoin.conf
bitcoind -detachdb -datadir="./bitcoin_data" -txindex=1 -loadblock="./bootstrap.dat"
```

To follow the progress of ```bitcoind``` use

```
tail -f bitcoin_data/debug.log
```

Once ```bitcoind``` has finished processing the file and caught up to the current block, the regular execution of the ``bitcoind`` should not include the ```-loadblock``` arguement.

```
bitcoind -detachdb -datadir="./bitcoin_data" -txindex=1
```

```bitcoind``` should be running while extrating transactions with node.js.

# Extraction

Run ```bitcoind``` as explained above in the background or another tab.

While that is running, execute the node.js extraction

```
coffee nodejs/extract_all_transactions.coffee
```

This will write a file for every block.  Each file will contain all transaction information needed for the user network code.  All files will be combined before being sent to the user network code.  By keeping each file separate, debugging and extending the exported transactions is MUCH faster.

If a connection error occurs during extraction, delete the last 5 files created, and restart the extraction.

# Prep for Networking

All of the transaction files are currently separated by blocks.  Combine these block files into one with the command below.

```
./bitcoin_transactions_combine
```

## Mac Install of bsddb3

Do the script below if you having trouble loading the pythong library ```bsddb3```

```
sudo BERKELEYDB_DIR=/usr/local/Cellar/berkeley-db4/4.8.30/ pip install bsddb3
```


# Bitcoin Transaction Network Extraction

This fork is an extension of [Ivan Brugere's work](https://github.com/ivan-brugere/Bitcoin-Transaction-Network-Extraction).

Given the amount of changes made to the code, this fork is to be used solely with node.js transaction exporter above.

Once the transaction block files are combined, alter the file locations within ```network/process_bitcoin_network_runner.sh``` to point to their proper directories.  Then execute the runner

```{bash}
./network/process_bitcoin_network_runner.sh
```



