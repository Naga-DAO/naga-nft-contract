pragma solidity >=0.8.0 <0.9.0;

import "./NagaDaoNft.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NagaSale1 is Ownable {
  using SafeERC20 for IERC20;

  NagaDaoNft immutable public nft;
  IERC20 immutable public weth;
  uint256 immutable public mintPrice;
  uint256 immutable public mintSupply;

  uint256 public mintedAmount = 0;

  bool public isPublicSale = false;

  mapping(address => uint256) public whitelist;

  constructor(
    NagaDaoNft _nft,
    IERC20 _weth, 
    uint256 _mintPrice,
    uint256 _mintSupply
  ) {
    nft = _nft;
    weth = _weth;
    mintPrice = _mintPrice;
    mintSupply = _mintSupply;
  }

  event Mint(address indexed minter, uint256 amount, bool whitelisted);
  function mint(uint256 amount) public {
    if (!isPublicSale) {
      require(whitelist[msg.sender] >= amount, "Not whitelisted");
    }

    weth.safeTransferFrom(msg.sender, address(nft), amount * mintPrice);

    mintedAmount += amount;
    require(mintedAmount <= mintSupply, "Over supply");

    nft.mint(msg.sender, amount);

    emit Mint(msg.sender, amount, whitelist[msg.sender] >= amount);

    if (whitelist[msg.sender] >= amount) {
      whitelist[msg.sender] -= amount;
    } else {
      whitelist[msg.sender] = 0;
    }
  }

  function setWhitelist(address[] memory wallet, uint256[] memory amount) public onlyOwner {
    for (uint i = 0; i < wallet.length; i++) {
      whitelist[wallet[i]] = amount[i];
    }
  }

  event TogglePublicSale(address indexed caller, bool enabled);
  function togglePublicSale(bool enabled) public onlyOwner {
    isPublicSale = enabled;
    emit TogglePublicSale(msg.sender, enabled);
  }
}