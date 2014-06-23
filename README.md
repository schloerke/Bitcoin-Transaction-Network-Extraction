# Bitcoin Transaction Network Extraction

The goal of this repository is to extract bitcoint transaction information from ``bitcoind``` and run the extracted data through an extension of [Ivan Brugere's work](https://github.com/ivan-brugere/Bitcoin-Transaction-Network-Extraction).

# Requirements

* bitcoind v0.9.* or higher. ([download binary](https://bitcoin.org/en/download) or [Github](https://github.com/bitcoin/bitcoin/tree/master/doc))
* node.js v0.10.*.  ([download](http://nodejs.org/download/))
* python v2.7.*
* python library bsddb3

For mac, you may use [```brew```](http://brew.sh)

```
which brew || ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
which git || brew install git
which wget || brew install wget

# install bitcoind
brew tap wysenynja/bitcoin && brew install bitcoind

# install node.js and coffeescript
brew install node
npm install coffee -g # may need sudo access

# install bsddb3 to be used with the berkeley db just installed by bitcoind
sudo BERKELEYDB_DIR="`brew --prefix`/Cellar/berkeley-db4/4.8.30/" pip install bsddb3
```

# Initial Processing

[Download the almost current blockchain](https://github.com/bitcoin/bitcoin/blob/master/doc/bootstrap.md) by torrenting the current ```bootstrap.dat``` file.  By importing the bootstrap.dat file, you will save days of downloading from the bitcoin network.

```
mkdir bitcoin_data
cd bitcoin_data
wget https://bitcoin.org/bin/blockchain/bootstrap.dat.torrent
## open bootstrap.dat.torrent
## download bootstrap.dat into bitcoin_data folder
cd ../
```

When the 15+ GB ```.dat``` file has finished downloading, import it into ```bitcoind```

```
echo -e "server=1\nrpcthreads=32\nrpctimeout=120\ntxindex=1\nrpcuser=bitcoinrpc\nrpcpassword=$(xxd -l 16 -p /dev/urandom)" > bitcoin_data/bitcoin.conf
bitcoind -datadir="./bitcoin_data"
```

To follow the progress of ```bitcoind``` use

```
tail -f bitcoin_data/debug.log
```

Once ```bitcoind``` has finished processing the ```bootstrap.dat``` file, ```bitcoind``` will change the bootstrap.dat to ```bootstrap.dat.old```. You may delete this file once ".old" has been appended.

# Extraction

Run ```bitcoind``` as explained above in the background or another tab.  This process is needed to extract all of the transactions.

To get all of the transactions per block:

```
coffee nodejs/extract_all_transactions.coffee
```

This will write a file for every block.  Each file will contain all transaction information needed for the user network code.  All files will be combined before being sent to the user network code.  By keeping each file separate, debugging and extending the exported transactions is MUCH faster.

If a connection error occurs during extraction, delete the last 5 files created, and restart the extraction coffee code.

# Prep for Networking

All of the transaction files are currently separated by blocks.  Next we will combine these block files into one with the command below.

```
./bitcoin_transactions_combine
```

This will create a file called ```./bitcoin_transactions.txt```.


# Bitcoin Transaction Network Extraction

The code inside the ```network``` forlder is an extension of [Ivan Brugere's work](https://github.com/ivan-brugere/Bitcoin-Transaction-Network-Extraction).

Given the amount of changes made to the code, this network code is to be used solely with the node.js transaction exporter above.

Once the transaction block files are combined, execute the runner:

```{bash}
./network/process_bitcoin_network_runner.sh
```



# File Structures

Notes on raw text files

## ./bitcoin_transactions.txt

* each row is an input or output of a transaction
* variable number of columns
* "\t" delimited
* row types:
** input coinbase: ["in","(transaction key)", "coinbase" "(time)", "(block height)"]
** input non-coinbase: ["in", "(transaction key)", "(previous transaction key)", "(previous transaction index)", "(public key)", "(time)", "(block_height)"]
** output: ["(out)", "(transaction key)", "(output index)", "(public key)", "(value)", "(time)", "(block_height)"]
* example:



## ./network_output/user_edges.txt
* each row is an edge in a transaction
* "," delimited
* 8 columns
* columns:
** transaction_id : int
** sender_id : int
** receiver_id : int
** time : int
** value : numeric
** output_pubkey: numeric
** output index: numeric
** block height: numeric
* example:
```
1,2,2,20130630180102,25.15211271,2,0
2,3,8,20130515191318,1.0,1821963,0
2,3,3,20130515191318,121.9565,3,1
3,3,1131722,20130630180102,20.0,4,0
3,3,3,20130630180102,101.9564,3,1
```


## ./network_output/user_edge_inputs.txt
* each row is transaction_ids used as input in "this" transaction
* "," delimited
* columns:
** transaction_id : int
** transaction_ids : int[], "," delimited
* -- example:
```
2,14050764,14050762,14050763,14050765
3,2,4
4,11993563,11965181,11985289
5,2431288
6,5
```


## ./network_output/user_edge_input_public_keys.txt
* each row is public_keys used as input in "this" transaction
* variable number of columns
* "," delimited
* columns:
** transaction_id : int
** public_keys : int[], "," delimited
* -- example:
```
2,9246231,9246229,9246230,9246232
3,4,4
4,7648160,3164019,2909333
5,1643221
6,7
```


## ./network_output/userkey_list.txt
* each row is public_keys belonging to the same user
* line number is the user_id
* variable number of columns
* columns:
** public_keys : int[], "," delimited
* example:
```
15,16,17,18,19,20,21,2516763,4641741
27,4899098,5218449,5709778,5803635
29,30
8388604
8388605
8388606
```

## pubkey_list.txt
* each row is the lengthy "public key hash"
* line number is the "public key id" (starting at 1)
* example:
```
1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa
12c6DSiU4Rq3P4ZxziKxzrL5LmMBrzjrJX
1HLoD9E4SDFFPDiYfNYnkBLQ85Y51J3Zb1
```


## transactionkey_list.txt
* each row is the lengthy "transaction hash"
* line number is the transaction_id (starting at 1)
* example:
```
4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b
0e3e2357e806b6cdb1f70b54c3a3a17b6714ee1f0e68bebb44a74b1efd512098
9b0fc92260312ce44e74ef369f5c66bbb85848f2eddd5a7a1cde251e54ccfdd5
```



