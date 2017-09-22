import json
from inspect import getmembers
from pprint import pprint
from time import sleep
from web3 import Web3, HTTPProvider
web3 = Web3(HTTPProvider('http://dev.papyrus.global:80'))


# Read necessary ABIs
abiPrePapyrusToken = json.load(open('bin/contracts/PrePapyrusToken.abi', 'r'))
abiPapyrusWallet = json.load(open('bin/contracts/PapyrusWallet.abi', 'r'))

# Addresses of wallet holders
walletHolderA = '0x3dcd8ee9ac88a4ba0636b12cb7176569a8b9dc4c'
walletHolderB = '0xd1f0b9d541a1b3d7498b26e1146247bed6bb55da'
walletHolderC = '0xe6bc63eac7be24f5e873d2993f6317dff067d37b'
walletHolderD = '0x2242936ea02b5c029172faaee8d6066755a32394'
walletHolderE = '0xe9827cac7edbec62e30e45d4f5d5baefef76d376'
web3.personal.unlockAccount(walletHolderA, 'Jsag8712bdu1s')
web3.personal.unlockAccount(walletHolderB, 'Kjcbnva9sch12')
web3.personal.unlockAccount(walletHolderC, 'KLZHfcfa97ylk')
web3.personal.unlockAccount(walletHolderD, 'KjsahiKJ7891a')
web3.personal.unlockAccount(walletHolderE, 'Aj8asjda8a9AB')

# Addresses of existing smart contracts
prePapyrusTokenAddress = '0x0c06ba38df7537e25ded9b3d1fdfeb90dff05f15'
walletAddress = '0x3ebb35533aeb4e435997a9c3f6be8cdc78576cbf'

# Preparing contracts
prePapyrusToken = web3.eth.contract(abiPrePapyrusToken, prePapyrusTokenAddress)
wallet = web3.eth.contract(abiPapyrusWallet, walletAddress)

#print(prePapyrusToken.call().balanceOf(walletAddress))

class InvestmentApproval:
    address: str
    amountToken: int
    amountEther: int
    def __init__(self, address, amountToken, amountEther):
        self.address = address
        self.amountToken = amountToken
        self.amountEther = amountEther

class InvestmentRejection:
    address: str
    amountEther: int
    def __init__(self, address, amountEther):
        self.address = address
        self.amountEther = amountEther


def waitForNextBlock():
    blockStart = web3.eth.blockNumber
    while blockStart == web3.eth.blockNumber:
        sleep(0.1)

def makeTokensTransferable():
    if prePapyrusToken.call().transferable() == False:
        data = prePapyrusToken.encodeABI('setTransferable', [True])
        web3.eth.sendTransaction({'from': web3.eth.coinbase, 'to': prePapyrusTokenAddress, 'data': data})
        waitForNextBlock()

def submitTransactionToWallet(addressFrom, addressTo, txValue, txData):
    data = wallet.encodeABI('submitTransaction', [addressTo, 0, bytearray.fromhex(txData[2:])])
    web3.eth.sendTransaction({'from': addressFrom, 'to': walletAddress, 'data': data})
    waitForNextBlock()

def submitTransactionsToWallet(addressFrom, addressesTo=[], txValues=[], txDatas=[]):
    txDataTotal = bytearray()
    txDataOffsets = []
    txDataLength = []
    txDataCurrentOffset = 0
    i = 0
    while i < len(addressesTo):
        txData = bytearray.fromhex(txDatas[i][2:])
        txDataTotal.extend(txData)
        txDataOffsets.append(txDataCurrentOffset)
        txDataLength.append(len(txData))
        txDataCurrentOffset += len(txData)
        i += 1
    data = wallet.encodeABI('submitTransactions', [addressesTo, txValues, txDataOffsets, txDataLength, txDataTotal])
    web3.eth.sendTransaction({'from': addressFrom, 'to': walletAddress, 'data': data})
    waitForNextBlock()

def confirmTransactionOnWallet(transactionId):
    data = wallet.encodeABI('confirmTransaction', [transactionId])
    web3.eth.sendTransaction({'from': walletHolderB, 'to': walletAddress, 'data': data})
    web3.eth.sendTransaction({'from': walletHolderD, 'to': walletAddress, 'data': data})
    waitForNextBlock()

def confirmTransactionsOnWallet(transactionIds=[]):
    data = wallet.encodeABI('confirmTransactions', [transactionIds])
    web3.eth.sendTransaction({'from': walletHolderB, 'to': walletAddress, 'data': data})
    web3.eth.sendTransaction({'from': walletHolderD, 'to': walletAddress, 'data': data})
    waitForNextBlock()

# Before starting tests make sure PRP are transferable
makeTokensTransferable()

dataSendToD = prePapyrusToken.encodeABI('transfer', [walletHolderD, web3.toWei(1, 'ether')])
dataSendToE = prePapyrusToken.encodeABI('transfer', [walletHolderE, web3.toWei(1, 'ether')])

print('Submitting single transaction to Papyrus Wallet:')

balance = web3.eth.getBalance(walletHolderA)
#print(wallet.call().transactionCount())
submitTransactionToWallet(walletHolderA, prePapyrusTokenAddress, 0, dataSendToD)
print(balance - web3.eth.getBalance(walletHolderA))
#print(wallet.call().transactionCount())

print('Submitting batched transaction to Papyrus Wallet:')

balance = web3.eth.getBalance(walletHolderA)
#print(wallet.call().transactionCount())
submitTransactionsToWallet(walletHolderA, [prePapyrusTokenAddress, prePapyrusTokenAddress], [0, 0], [dataSendToD, dataSendToE])
print(balance - web3.eth.getBalance(walletHolderA))
#print(wallet.call().transactionCount())

print('Confirming single transaction on Papyrus Wallet:')

#print(prePapyrusToken.call().balanceOf(walletHolderD))
#print(prePapyrusToken.call().balanceOf(walletHolderE))
confirmTransactionOnWallet(15)
#print(prePapyrusToken.call().balanceOf(walletHolderD))
#print(prePapyrusToken.call().balanceOf(walletHolderE))

print('Confirming complex transaction on Papyrus Wallet:')

#print(prePapyrusToken.call().balanceOf(walletHolderD))
#print(prePapyrusToken.call().balanceOf(walletHolderE))
confirmTransactionsOnWallet([16, 17])
#print(prePapyrusToken.call().balanceOf(walletHolderD))
#print(prePapyrusToken.call().balanceOf(walletHolderE))
