bitcoin = require('bitcoin')
grewpy = require('grewpy')
fs = require('fs')

outputDir = "./bitcoin_transactions"

rpcPass = fs
  .readFileSync("./bitcoin_data/bitcoin.conf", encode = "utf8")
  .split("\n")
  .filter((x) -> return x.indexOf("rpcpassword") >= 0)[0].substring(12)

client = new bitcoin.Client({
  host: 'localhost',
  port: 8332,
  user: 'bitcoinrpc',
  pass: rpcPass,
  timeout: 1000 * 60 * 2
})

# client.getDifficulty (err, difficulty) ->
#   if err
#     return console.error(err)

#   console.log('Difficulty: ' + difficulty)
#   return


get_transaction_info = (txnHash, callback) ->
  client.getRawTransaction txnHash, (err, txnInfo) ->
    if err
      console.error("ERROR: get_transaction_info: ", txnHash, ". ", err)
      callback(err, null)
      return

    client.cmd 'decoderawtransaction', txnInfo, (err, dtInfo, valueHeader) ->
      if err
        console.error("ERROR: decoderawtransaction: ", txnInfo, ". ", err)
        callback(err, null)
        return

      # console.log("Value: ", dtInfo)
      callback(null, dtInfo)
      return
    return
  return


# print 'in\t' + txn['hash'] + '\t' + str(txnPrevHash) + '\t' + str(txnPrevOutN) + '\t' + pk + '\t' + dt + '\t' + str(blockHeight)
transaction_in_output = ({txnObj, vInObj, i}, callback) ->
  # if print 'in\t' + txn['hash'] + '\tcoinbase\t' + dt + '\t' + str(blockHeight)
  if vInObj.coinbase?
    callback null, {
      coinbase: true
      txnHash: txnObj.txid
    }
    return

  prevTxnHash = vInObj.txid

  get_transaction_info prevTxnHash, (err, inTxnObj) ->
    if err
      console.error("ERROR: transaction_in_i_addresses vin info: ", prevTxnHash, ". Error: ", err)
      callback(err, null)
      return

    voutN = vInObj.vout

    callback null, {
      txnHash:     txnObj.txid
      prevTxnHash: prevTxnHash
      prevN:       voutN
      pk:          transaction_out_address(inTxnObj, inTxnObj.vout[voutN])
    }
    return
  return


# transaction_out_i_addresses = (txnObj, i) ->
#   return transaction_out_address(txnObj.vout[i])

transaction_out_address = (txnObj, vOutObj) ->
  # console.log(txnObj.txid, vOutObj) if txnObj.txid is "ab7dbedcd5ec319985e8fea1ce6f6d48158deb560f897cf08aab73fa8d69ce78"
  if vOutObj.scriptPubKey.type is "multisig"
    sig = vOutObj.scriptPubKey.asm
    sig = sig.substr(2)
    sigLen = sig.length
    # 19 = length("3 OP_CHECKMULTISIG")

    sig = sig.substr(0, sigLen - 19)
    return sig.split(" ").join(",")

  if vOutObj.scriptPubKey.addresses?
    return vOutObj.scriptPubKey.addresses.join(",") or ("None_" + txnObj.txid + "_" + vOutObj.n)

  return ("None_" + txnObj.txid + "_" + vOutObj.n)

## output of transaction
# print 'out\t' + txnHash + '\t' + str(txnOutN) + '\t' + pk + '\t' + str(txOut['value']/1.0e8) + '\t' + dt + '\t' + str(blockHeight)
transaction_out_output = (txnObj, vOutObj) ->
  return {
    txnHash: txnObj.txid
    n:       vOutObj.n
    pk:      transaction_out_address(txnObj, vOutObj)
    value:   vOutObj.value
  }


# pk = make_none_public_key_from_txn(txnPrevHash, txnPrevOutN)
# def make_none_public_key_from_txn(txnHash, n):
#   return "None_" + str(txnHash) + "_" + str(n)


get_transaction_output = (txnHash, callback) ->
  get_transaction_info txnHash, (err, txnObj) ->
    if err
      console.error("ERROR: get_transaction_output: ", txnHash, ". Error: ", err)
      callback(err, null)
      return

    # console.error(txnObj)
    groupIn = grewpy.worker(3)

    for vInObj, vI in txnObj.vin
      do (vInObj, vI) ->
        groupIn.add (done)->
          transaction_in_output({txnObj, vInObj, i: vI}, done)
          return
        return

    groupIn.finalize (err, vInOutputArr) ->
      if err
        console.error("ERROR: get_transaction_output transaction_in_output: ", txnHash, ". Error: ", err)
        callback(err, null)
        return

      vOutOutputArr = []
      for vOutObj in txnObj.vout
        vOutOutputArr.push(transaction_out_output(txnObj, vOutObj))

      callback null, {
        inArr:  vInOutputArr
        outArr: vOutOutputArr
      }
      return
    return
  return

get_block_info = (blockN, callback) ->
  client.getBlockHash blockN, (err, blockHash) ->
    if err
      console.error("ERROR get_block_info: getBlockHash: ", blockN, ". Error: ", err)
      callback(err, null)
      return

    client.getBlock blockHash, (err, blockInfo) ->
      if err
        console.error("ERROR: get_block_info: getBlock: ", blockN, ". Error: ", err)
        callback(err, null)
        return

      callback(null, blockInfo)
      return
    return
  return



pad_left_two_zeros = (number) ->
  str = "" + number
  strLen = str.length
  if strLen >= 2
    return str
  if strLen is 1
    return "0" + str
  return "00"

pad_left_three_zeros = (number) ->
  str = "" + number
  strLen = str.length
  if strLen >= 3
    return str
  if strLen is 2
    return "0" + str
  if strLen is 1
    return "00" + str
  return "000"

pad_left_four_zeros = (number) ->
  str = "" + number
  strLen = str.length
  if strLen >= 4
    return str
  if strLen is 3
    return "0" + str
  if strLen is 2
    return "00" + str
  if strLen is 1
    return "000" + str
  return "0000"


get_block_date = (blockSeconds) ->
  dt = new Date(0)
  dt.setUTCSeconds(blockSeconds)

  return dt.getUTCFullYear() + "-" +
    pad_left_two_zeros(dt.getUTCMonth() + 1) + "-" +
    pad_left_two_zeros(dt.getUTCDate()) + "-" +
    pad_left_two_zeros(dt.getUTCHours()) + "-" +
    pad_left_two_zeros(dt.getUTCMinutes()) + "-" +
    pad_left_two_zeros(dt.getUTCSeconds())


get_block_output = (blockN, callback) ->
  get_block_info blockN, (err, blockInfo) ->
    if err
      console.error("ERROR: get_block_output: get_block_info: ", blockN, ". Error: ", err)
      callback(err, null)
      return

    groupTxn = grewpy.worker(3)

    for txnHash in blockInfo.tx
      do (txnHash) ->
        groupTxn.add (done) ->
          get_transaction_output(txnHash, done)
          return
        return

    groupTxn.finalize (err, txnOutputArr) ->
      if err
        console.error("ERROR: get_block_output: ", blockN, ". groupTxn Error: ", err)
        callback(err, null)
        return

      blockDate = get_block_date(blockInfo.time)

      callback null, {
        height:       blockInfo.height
        time:         blockDate
        transactions: txnOutputArr
      }
      return
    return
  return

make_dirs_for_block_number = (n, callback) ->
  outputExists = fs.existsSync(outputDir)
  if not outputExists
    fs.mkdirSync(outputDir)

  nThousandStr = pad_left_three_zeros((n - n % 1000) / 1000)
  nThousandDir = outputDir + "/" + nThousandStr
  thousandDoesExist = fs.existsSync(nThousandDir)
  if not thousandDoesExist
    fs.mkdirSync(nThousandDir)

  callback(null, true)
  return


block_file_path = (n) ->
  return outputDir + "/" + pad_left_three_zeros((n - n % 1000) / 1000) + "/" + pad_left_four_zeros(n) + ".txt"

block_file_path2 = (n, nThousandDir) ->
  return nThousandDir + "/" + pad_left_four_zeros(n) + ".txt"

does_block_output_exist = (n, callback) ->
  fs.exists outputDir, (doesExist) ->
    if not doesExist
      callback(null, false)
      return

    nThousandStr = pad_left_three_zeros((n - n % 1000) / 1000)
    nThousandDir = outputDir + "/" + nThousandStr
    fs.exists nThousandDir, (thousandDoesExist) ->
      if not thousandDoesExist
        callback(null, false)
        return

      fs.exists block_file_path2(n, nThousandDir), (fileDoesExist) ->
        if not fileDoesExist
          callback(null, false)
          return

        callback(null, true)
        return
      return
    return
  return


process_block = (n, callback) ->

  does_block_output_exist n, (err, blockDoesExist) ->
    if err
      console.error("ERROR: process_block: ", n, ". Error: ", err)
      callback(err, null)
      return

    if blockDoesExist
      callback(null, false)
      return

    make_dirs_for_block_number n, (err, ignore) ->
      if err
        console.error("ERROR: process_block: make_dirs_for_block_number: ", n, ". Error: ", err)
        callback(err, null)
        return

      if n is 0
        # has troubles getting gensis info, so writing by hand
        genisisInfo = "in\t4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b\tcoinbase\t2009-01-03-18-15-05\t1\nout\t4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b\t0\t1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa\t50\t2009-01-03-18-15-05\t1\n"
        fs.writeFileSync(block_file_path(n), genisisInfo)
        console.log("wrote " + n)
        callback(null, true)
        return

      get_block_output n, (err, blockObj) ->
        if err
          console.error("ERROR: process_block: get_block_output:", n, ". Error: ", err)
          callback(err, null)
          return


        # print 'in\t' + txn['hash'] + '\t' + str(txnPrevHash) + '\t' + str(txnPrevOutN) + '\t' + pk + '\t' + dt + '\t' + str(blockHeight)
        # print 'out\t' + txnHash + '\t' + str(txnOutN) + '\t' + pk + '\t' + str(txOut['value']/1.0e8) + '\t' + dt + '\t' + str(blockHeight)

        fd = fs.openSync(block_file_path(n), 'w')

        chain = grewpy.chain()

        tab = "\t"
        blockDate = blockObj.time
        lineEnding = tab + blockDate + tab + n + "\n"

        for transactionObj in blockObj.transactions
          for txnIn in transactionObj.inArr
            do (txnIn) ->
              chain.add (done) ->
                # {
                #   txnHash:     txnObj.txid
                #   prevTxnHash: prevTxnHash
                #   prevN:       voutN
                #   pk:          transaction_out_address(inTxnObj, inTxnObj.vout[voutN])
                # }
                # print 'in\t' + txn['hash'] + '\t' + str(txnPrevHash) + '\t' + str(txnPrevOutN) + '\t' + pk + '\t' + dt + '\t' + str(blockHeight)

                txtLine = if txnIn.coinbase
                  # if print 'in\t' + txn['hash'] + '\tcoinbase\t' + dt + '\t' + str(blockHeight)
                  "in\t" + txnIn.txnHash + '\tcoinbase' + lineEnding
                else
                  "in\t" + txnIn.txnHash + tab + txnIn.prevTxnHash + tab + txnIn.prevN + tab + txnIn.pk + lineEnding
                txtBuffer = new Buffer(txtLine)
                fs.write fd, txtBuffer, 0, txtBuffer.length, null, (err) ->
                  done(err, null)
                  return
                return
              return

          for txnOut in transactionObj.outArr
            do (txnOut) ->
              chain.add (done) ->
                # {
                #   txnHash: txnObj.txid
                #   n:       vOutObj.n
                #   pk:      transaction_out_address(txnObj, vOutObj)
                #   value:   vOutObj.value
                # }
                # print 'out\t' + txnHash + '\t' + str(txnOutN) + '\t' + pk + '\t' + str(txOut['value']/1.0e8) + '\t' + dt + '\t' + str(blockHeight)
                txtLine = "out\t" + txnOut.txnHash + tab + txnOut.n + tab + txnOut.pk + tab + txnOut.value + tab + blockDate + tab + n + "\n"
                txtBuffer = new Buffer(txtLine)
                fs.write fd, txtBuffer, 0, txtBuffer.length, null, (err) ->
                  done(err, null)
                  return
                return
              return

        chain.finalize (err, ignore) ->


          fs.closeSync(fd)

          if err
            console.error("ERROR: process_block: write_file: ", n, ". Error: ", err)
            callback(err, null)
            return

          console.log("wrote " + n)
          callback(null, true)
          return
        return
      return
    return
  return







client.cmd 'getblockcount', (err, maxBlockHeight, valueHeader) ->
  if err
    console.error("ERROR: getblockcount. Error: ", err)
    return

  console.log("Max block Height: ", maxBlockHeight, "\n")

  blockChain = grewpy.worker(3)
  for n in [0..maxBlockHeight]
  # for n in [0..50000]
    do (n) ->
      blockChain.add (done) ->
        process_block(n, done)
        return
      return

  blockChain.finalize (err, results) ->
    if err
      console.error("ERROR: blockChain.finalize: . Error: ", err)
      return

    console.log("DONE!")
    return







