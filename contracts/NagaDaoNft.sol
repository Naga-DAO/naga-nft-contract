// SPDX-License-Identifier: MIT

// Amended by HashLips
/**
    !Disclaimer!

    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    The developer will not be responsible or liable for all loss or 
    damage whatsoever caused by you participating in any way in the 
    experimental code, whether putting money into the contract or 
    using the code for your own project.
*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NagaDaoNft is ERC721, Ownable {
  using SafeERC20 for IERC20;
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "ipfs://__CID__";
  string public uriSuffix = ".json";
  
  uint256 public maxSupply = 10000;

  bool public paused = true;
  
  mapping(address => bool) public allowMinting;

  constructor() ERC721("Naga DAO", "NAGA") {
    _mintLoop(msg.sender, 32);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(address to, uint256 _mintAmount) public mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(allowMinting[msg.sender], "Not allowed minting");

    _mintLoop(to, _mintAmount);
  }
  
  // function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
  //   _mintLoop(_receiver, _mintAmount);
  // }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  event SetAllowMinting(address indexed caller, address indexed minter, bool allowed);
  function setAllowMinting(address minter, bool allowed) public onlyOwner {
    allowMinting[minter] = allowed;
    emit SetAllowMinting(msg.sender, minter, allowed);
  }

  event SetUriPrefix(address indexed caller, string url);
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
    emit SetUriPrefix(msg.sender, _uriPrefix);
  }

  event SetUriSuffix(address indexed caller, string url);
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
    emit SetUriSuffix(msg.sender, _uriSuffix);
  }

  event SetPaused(address indexed caller, bool paused);
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
    emit SetPaused(msg.sender, _state);
  }

  event Withdraw(address indexed caller, address indexed to, address indexed token, uint256 amount);
  function withdraw(address to, IERC20 token, uint256 amount) public onlyOwner {
    token.safeTransfer(to, amount);
    emit Withdraw(msg.sender, to, address(token), amount);
  }

  event WithdrawMatic(address indexed caller, address indexed to, uint256 amount);
  function withdrawMatic(address to, uint256 amount) public onlyOwner {
    (bool os, ) = payable(to).call{value: amount}("");
    emit WithdrawMatic(msg.sender, to, amount);
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
