const { expect } = require("chai");
const { ethers } = require("hardhat");

const whitelistMerkleRoot = '0xb0b31d36008af7f899492a8cb1511d63e982d85f372db074ba36bdbb7859ccf3'

const hexProof1 = [
  '0x029c3b8640876c4398266344a06b3f125caff4e9c46f2757e530c7b5f1d7473b',
  '0xe72d09a05473eb71b9198fc5d751d950484d0bc8d28d989da886221de1710e68',
  '0xe6ad72a88a37a4b3a5582fbd55c2dab1deae6fd3d512c3ad23d66275b5eb639d',
  '0x4fd78b05d65dd11ba35b245cb2fbe200b3c4fde8199e30340570aff29e795fd6',
  '0xc0d69bf475fdc8aba8c92789670e650f7eb5a4b640ef0671ec765602d1cbc8f9',
  '0xe9a8981920950b1200bb979cbd7f49fe0bb3158f44caa0ae912f362d1d9672a4'
]

describe("Equity Coin", function () {

  let equityCoin
  let owner
  let acc2
  let acc3
  let acc4
  let unverifiedAdd
  let balanceSheet
  let allowanceSheet

  before(async () => {
    [owner, acc2, acc3, acc4, unverifiedAdd] = await ethers.getSigners()

    const BalanceSheet = await ethers.getContractFactory('BalanceSheet')
    const AllowanceSheet = await ethers.getContractFactory('AllowanceSheet')
    const EquityCoin = await ethers.getContractFactory('EquityCoin')


    balanceSheet = await BalanceSheet.deploy()
    await balanceSheet.deployed()
    allowanceSheet = await AllowanceSheet.deploy()
    await allowanceSheet.deployed()

    equityCoin = await EquityCoin.deploy()
    await equityCoin.deployed()

    
  })
  
  it("should set balance/allowance sheet", async function () {

    let tx = await equityCoin.transferOwnership(owner.address)
    await tx.wait()

    console.log(await equityCoin.pendingOwner())

    // need to transfer ownership to equity coin
    await allowanceSheet.transferOwnership(equityCoin.address)
    await equityCoin.setAllowanceSheet(allowanceSheet.address)

    await balanceSheet.transferOwnership(equityCoin.address)
    await equityCoin.setBalanceSheet(balanceSheet.address)


    expect(await equityCoin.allowances()).to.eq(allowanceSheet.address)
    expect(await equityCoin.balances()).to.eq(balanceSheet.address)

  })


  it("should add verified and mint", async function () {

    await equityCoin.addVerified(owner.address, '0x807911e6ef955f187909f26400c529ea6c0f604cd590ac8db4a6225cb3625cea')

    expect(await equityCoin.isVerified(owner.address)).to.be.eq(true)

    // MINT

    await equityCoin.mint(owner.address, 50000)

    expect(await equityCoin.balanceOf(owner.address)).to.be.eq(50000)

    expect(await balanceSheet.balanceOf(owner.address)).to.be.eq(50000)

    // expect(await equityCoin.shareholders(0)).to.be.eq(owner.address)



  })

  it('should transfer and update balances', async () => {

    await equityCoin.addVerified(acc2.address, `0x807911e6ef955f187909f26400c529ea6c0f604cd590ac8db4a6225cb3625cea`)

    await equityCoin.transfer(acc2.address, 100)

    expect(await equityCoin.balanceOf(owner.address)).to.be.eq(49900)
    expect(await balanceSheet.balanceOf(owner.address)).to.be.eq(49900)

    expect(await equityCoin.balanceOf(acc2.address)).to.be.eq(100)
    expect(await balanceSheet.balanceOf(acc2.address)).to.be.eq(100)
  })



  it('should update locking period', async () => {
    await equityCoin.setLockingPeriod(100)

    console.log(await equityCoin.lockingPeriod())

  })

  it('should transfer when lock period is over', async () => {

    const lockingPeriodIsOver = await equityCoin.lockingPeriod()

    await ethers.provider.send('evm_setNextBlockTimestamp', [lockingPeriodIsOver.toNumber() + 60]);
    await equityCoin.connect(acc2).transfer(owner.address, 10)


  })

  it('should remove from hodler list if balance is 0 ', async () => {

    // console.log(await equityCoin.holderIndices(acc2.address))

    

    // console.log(await equityCoin.shareholders(1))

    await equityCoin.connect(acc2).transfer(owner.address, 90)

    expect(await balanceSheet.balanceOf(acc2.address)).to.be.eq(0)

    console.log(await equityCoin.isHolder(acc2.address))
    // console.log(await equityCoin.shareholders(1))

    console.log(await equityCoin.holderCount())


  })

  it ('Cancel and reissue', async () => {

    await equityCoin.addVerified(acc3.address, '0x807911e6ef955f187909f26400c529ea6c0f604cd590ac8db4a6225cb362dcea')
    console.log(await equityCoin.balanceOf(owner.address))

    await equityCoin.transfer(acc3.address, 500)


    expect(await equityCoin.balanceOf(acc3.address)).to.be.eq(500)
    expect(await balanceSheet.balanceOf(acc3.address)).to.be.eq(500)

    expect(await equityCoin.balanceOf(owner.address)).to.be.eq(49500)
    expect(await balanceSheet.balanceOf(owner.address)).to.be.eq(49500)
    await equityCoin.addVerified(acc4.address, '0x807911e6ef955f187909f26400c529ea6c0f604cd590ac8db4a6225cb362dcea')

    await equityCoin.cancelAndReissue(acc3.address, acc4.address)
    expect(await equityCoin.balanceOf(acc4.address)).to.be.eq(500)
    expect(await balanceSheet.balanceOf(acc4.address)).to.be.eq(500)

    expect(await equityCoin.balanceOf(acc3.address)).to.be.eq(0)
    expect(await balanceSheet.balanceOf(acc3.address)).to.be.eq(0)

    console.log(await equityCoin.isHolder(acc4.address))

    expect(await equityCoin.balanceOf(owner.address)).to.be.eq(49500)
    expect(await balanceSheet.balanceOf(owner.address)).to.be.eq(49500)

    console.log(await equityCoin.hasHash(acc3.address, '0x807911e6ef955f187909f26400c529ea6c0f604cd590ac8db4a6225cb362dcea'))

    console.log(await equityCoin.holderCount())

    expect(await equityCoin.getCurrentFor(acc3.address)).to.eq(acc4.address)
  })

  
})