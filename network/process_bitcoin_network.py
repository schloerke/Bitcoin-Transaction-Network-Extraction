
from   operator import itemgetter
import bsddb3 as bsddb
import sys

from write_user_public_keys import *
from fix_missing_public_keys import *
from write_network_dictionaries import *
from write_user_edges import *

#paths and filenames defined in shell script runner
transactions_in          = sys.argv[1]
transaction_keys         = sys.argv[2]
pub_keys                 = sys.argv[3]
users_out                = sys.argv[4]
referents_out            = sys.argv[5]
referent_public_keys_out = sys.argv[6]
edges_out                = sys.argv[7]
db_path                  = sys.argv[8]

#index and write out long key strings, use numeric data instead (scalability consideration). Also build main data rows.
print "Starting: writing network dictionaries"
rows = write_network_dictionaries(db_path, transactions_in, transaction_keys, pub_keys)
print "Completed: writing network dictionaries"

#preprocessing: input pubkeys from 'coinbase' are sometimes given in raw data as (None), these can be fixed by using the output pubkey
print "Starting: fixing missing public keys"
rows = fix_missing_public_keys(rows)
print "Completed: fixing missing public keys"

#group public keys used as shared inputs to a transaction (i.e. a "user" owns the private key to each address).
print "Starting: writing user public keys"
user_hash = write_user_public_keys(users_out, rows)
print "Completed: writing user public keys"

#write main data file
print "Starting: writing user edges"
write_user_edges(referents_out, referent_public_keys_out, edges_out, rows, user_hash)
print "Completed: writing user edges"
