// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract MultiSend is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event MultisentToken(address sender, address token, uint256 total);
    event MultisentNative(address sender, uint256 total);
    event MultisentNFT(address sender, address token, uint256[] tokenIds);
    event ClaimedToken(address owner, address token, uint256 balance);
    event ClaimedNative(address owner, uint256 balance);

    function initialize(address owner_) public initializer {
        OwnableUpgradeable.__Ownable_init();
        _transferOwnership(owner_);
    }

    function multisendTokenERC20(IERC20Upgradeable _tokenERC20, address[] calldata _receivers, uint256[] calldata _balances) external {
        require(_receivers.length > 0, "The receiver list is empty");
        require(_receivers.length == _balances.length, "Inconsistent lengths");

        uint256 total = 0;
        for (uint256 i = 0; i < _receivers.length; i++) {
            total += _balances[i];
        }

        _tokenERC20.safeTransferFrom(_msgSender(), address(this), total);

        for (uint256 i = 0; i < _receivers.length; i++) {
            _tokenERC20.safeTransfer(_receivers[i], _balances[i]);
        }

        emit MultisentToken(_msgSender(), address(_tokenERC20), total);
    }

    function multisendNative(address[] calldata _receivers, uint256[] calldata _balances) external payable {
        require(_receivers.length > 0, "The receiver list is empty");
        require(_receivers.length == _balances.length, "Inconsistent lengths");

        uint256 total = 0;
        for (uint256 i = 0; i < _receivers.length; i++) {
            total += _balances[i];
            payable(_receivers[i]).transfer(_balances[i]);
        }

        require(msg.value >= total, "Insufficient funds");

        emit MultisentNative(_msgSender(), total);
    }

    function multisendTokenERC721(IERC721Upgradeable _tokenERC721, address[] calldata _receivers, uint256[] calldata _tokenIds) external {
        require(_receivers.length > 0, "The receiver list is empty");
        require(_receivers.length == _tokenIds.length, "Inconsistent lengths");
        bool isERC721 = IERC721Upgradeable(_tokenERC721).supportsInterface(
            type(IERC721Upgradeable).interfaceId
        );
        require(isERC721, "Token is not ERC721");

        for (uint256 i = 0; i < _receivers.length; i++) {
            _tokenERC721.safeTransferFrom(_msgSender(), _receivers[i], _tokenIds[i]);
        }

        emit MultisentNFT(_msgSender(), address(_tokenERC721), _tokenIds);
    }

    function claimTokenERC20(IERC20Upgradeable _tokenERC20) external {
        uint256 claimable = _tokenERC20.balanceOf(address(this));

        if (claimable > 0)
            _tokenERC20.safeTransfer(owner(), claimable);

        emit ClaimedToken(owner(), address(_tokenERC20), claimable);
    }

    function claimNative() external {
        uint256 claimable = address(this).balance;
        if (claimable > 0)
            payable(owner()).transfer(claimable);

        emit ClaimedNative(owner(), claimable);
    }
}