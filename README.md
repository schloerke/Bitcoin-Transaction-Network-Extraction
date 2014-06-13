# Bitcoin Transaction Network Extraction

The goal of this repository is to extract bitcoint transaction information from ``bitcoind``` and run the extracted data through an extension of [Ivan Brugere's work](https://github.com/ivan-brugere/Bitcoin-Transaction-Network-Extraction).

# Requirements

* bitcoind v0.9.* or higher. ([download binary](https://bitcoin.org/en/download) or [Github](https://github.com/bitcoin/bitcoin/tree/master/doc))
* node.js v0.10.*.  ([download](http://nodejs.org/download/))
* python v2.7.*
* python library bsddb3

For mac, you may use ```brew```

```
# install bitcoind
brew tap wysenynja/bitcoin && brew install bitcoind

# install node.js and coffeescript
brew install node
npm install coffee -g # may need sudo access

# install bsddb3 to be used with the berkeley db just installed by bitcoind
sudo BERKELEYDB_DIR="`brew --prefix`/Cellar/berkeley-db4/4.8.30/" pip install bsddb3
```

# Initial Processing

[Download the almost current blockchain](https://github.com/bitcoin/bitcoin/blob/master/doc/bootstrap.md) by torrenting the current ```bootstrap.dat``` file.  By importing the bootstrap.dat file, you will save days of processing time.

```
wget https://bitcoin.org/bin/blockchain/bootstrap.dat.torrent
## open bootstrap.dat.torrent
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

Once ```bitcoind``` has finished processing the ```bootstrap.dat``` file and caught up to the current block, ```bitcoind``` may be shut down and restarted without the ```-loadblock``` arguement.

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

All of the transaction files are currently separated by blocks.  Next we will combine these block files into one with the command below.

```
./bitcoin_transactions_combine
```


# Bitcoin Transaction Network Extraction

The code inside the ```network``` forlder is an extension of [Ivan Brugere's work](https://github.com/ivan-brugere/Bitcoin-Transaction-Network-Extraction).

Given the amount of changes made to the code, this network code is to be used solely with the node.js transaction exporter above.

Once the transaction block files are combined, execute the runner:

```{bash}
./network/process_bitcoin_network_runner.sh
```



