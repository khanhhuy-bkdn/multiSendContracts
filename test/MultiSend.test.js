const { ethers } = require("hardhat");
const { expect } = require("chai");
const { add, subtract, multiply, divide } = require('js-big-decimal');

describe("MultiSend", () => {
  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    owner = accounts[0];
    admin = accounts[1];
    user1 = accounts[2];
    user2 = accounts[3];
    user3 = accounts[4];

    const NFT = await ethers.getContractFactory("NFT");
    nft = await NFT.deploy("NFT", "NFT", "");

    const MultiSend = await ethers.getContractFactory("MultiSend");
    multiSend = await upgrades.deployProxy(MultiSend, [owner.address]);

    await nft.safeMint([owner.address, owner.address, owner.address, owner.address], ["", "", "", ""]);
    await nft.connect(owner).setApprovalForAll(multiSend.address, true);
  })

  describe("multisendTokenERC721", () => {
    it('Should error The receiver list is empty', async () => {
      await expect(multiSend.multisendTokenERC721(nft.address, [], [])).to.be.revertedWith('The receiver list is empty');
      await expect(multiSend.multisendTokenERC721(nft.address, [], [1, 2])).to.be.revertedWith('The receiver list is empty');
    });

    it('Should error Inconsistent lengths', async () => {
      await expect(multiSend.multisendTokenERC721(nft.address, [user1.address, user2.address], [])).to.be.revertedWith('Inconsistent lengths');
    });

    it('Should error successfully', async () => {
      await expect(() => multiSend.multisendTokenERC721(nft.address, [user1.address, user2.address], [1, 2])).changeTokenBalances(nft, [owner, user1, user1], [-2, 1, 1]);
      const ownerOf_1 = await nft.ownerOf(1);
      const ownerOf_2 = await nft.ownerOf(2);

      expect(ownerOf_1).to.equals(user1.address);
      expect(ownerOf_2).to.equals(user2.address);
    });
  });
});
