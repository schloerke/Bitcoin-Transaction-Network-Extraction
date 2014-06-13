##
#
#   arr[][] fix_missing_public_keys(arr[][])
#   @var rows the matrix of data values to process
#   @return the preprocessed main data matrix

#   preprocessing: input pubkeys from 'coinbase' are sometimes given in raw data as (None), these can be fixed by using the output pubkey
#   We've indexed these pubkeys to 0 (see below: prev_row[3] == 0), so we are filling 0 values.
#

from operator import itemgetter
import array as ar
def fix_missing_public_keys(rows):

    #handle missing pubkeys
    rows.sort(key=itemgetter(1,2,0))
    prev_row = rows[0]

    for i in range(1, len(rows)):
        row = rows[i]
        thirdItem = 0
        if (prev_row[3] == 0) and (row[0] == 1) and (row[1] == prev_row[1]) and (row[2] == prev_row[2]): # if missing, type==output and matching input key
            thirdItem = row[3]
        else:
            thirdItem = prev_row[3]

        rows[i-1] = [prev_row[0], prev_row[6], prev_row[2], thirdItem, prev_row[4], prev_row[5], prev_row[7]]

        prev_row = row
        if i % 1000000 == 0:
            print "Progress: fix public keys, percent complete: " + str(float(i)/len(rows))

    ##### row specification:
    # row: [<"i"/"o">, transaction_key, index, pubkey, date_time, <i:referent transaction, o:outputvalue >]
    rows[i] = [prev_row[0], prev_row[6], prev_row[2], prev_row[3], prev_row[4], prev_row[5], prev_row[7]]
    return rows;
