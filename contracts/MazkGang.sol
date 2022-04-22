// SPDX-License-Identifier: MIT

// Amended by HashLips
/**
    !Disclaimer!
    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    HashLips will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MazkGang is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";

  uint256 public constant maxSupply = 10000;

  uint256 public constant freeSupply = 100;

  uint256 public constant whitelistCost = 0.1 ether;
  uint256 public constant whitelistSupply = 3000;
  uint256 public constant whitelistPerWallet = 2;
  uint256 public whitelistMinted = 0;
  
  uint256 public constant salePerWallet = 5;
  uint256 public constant saleCost = 0.55 ether;
  uint256 public constant saleMinCost = 0.15 ether;
  uint256 public constant saleReducePrice = 0.1 ether;
  uint256 public constant saleReduceDuration = 1200;

  uint256 public whitelistStartTimestamp = 1e36; // infinity
  uint256 public saleStartTimestamp = 1e36; // infinity

  mapping(address => uint256) whitelistAddressMinted;
  mapping(address => uint256) saleAddressMinted;

  bytes32 public whitelistRoot;

  bool public revealed = false;
  string public notRevealedUri;
  uint256 public seed = 0;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setWhitelistStartTimestamp(uint256 startTimestamp) public onlyOwner {
    whitelistStartTimestamp = startTimestamp;
  }

  function setSaleStartTimestamp(uint256 startTimestamp) public onlyOwner {
    saleStartTimestamp = startTimestamp;
  }

  function setSeed(uint256 _seed) public onlyOwner {
    seed = _seed;
  }

  function setWhitelistRoot(bytes32 _whitelistRoot) public onlyOwner {
    whitelistRoot = _whitelistRoot;
  }

  // whitelist
  function mintWhitelist(uint256 _mintAmount, bytes32[] memory proof) public payable {
    MerkleProof.verify(proof, whitelistRoot, bytes32(uint256(uint160(msg.sender))));

    require(block.timestamp >= whitelistStartTimestamp, "Wait");
    require(msg.value == whitelistCost * _mintAmount, "Pay");

    uint256 supply = totalSupply();
    whitelistMinted += _mintAmount;
    whitelistAddressMinted[msg.sender] += _mintAmount;
    
    require(whitelistMinted <= whitelistSupply && supply + _mintAmount <= maxSupply && whitelistAddressMinted[msg.sender] <= whitelistPerWallet, "Limited");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  // public
  function getSaleCost() public view returns(uint256) {
    uint256 ab = saleReducePrice * (block.timestamp - saleStartTimestamp) / saleReduceDuration;
    return ab + saleMinCost < saleCost ? saleCost - ab : saleMinCost;
  }

  function mint(uint256 _mintAmount) public payable {
    require(block.timestamp >= saleStartTimestamp, "Wait");
    require(msg.value >= getSaleCost() * _mintAmount, "Pay");

    uint256 supply = totalSupply();
    saleAddressMinted[msg.sender] += _mintAmount;

    require(supply + _mintAmount <= maxSupply && saleAddressMinted[msg.sender] <= salePerWallet, "Limited");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}