// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFantomAddressRegistry {
    function tokenRegistry() external view returns (address);
}

interface IFantomTokenRegistry {
    function enabled(address) external returns (bool);
}


interface ISymbol {
    function symbol() external view returns(string memory);
    function decimals() external view returns (uint8);
}

interface IOracle {
    function getValue(bytes32 key) external view returns(int256);
}

contract FantomPriceFeed is Ownable {
    /// @notice keeps track of oracles for each tokens
    mapping(address => address) public oracles;

    /// @notice fantom address registry contract
    address public addressRegistry;

    /// @notice wrapped FTM contract
    address public wFTM;

    constructor(address _addressRegistry, address _wFTM) public {
        addressRegistry = _addressRegistry;
        wFTM = _wFTM;
    }

    /**
     @notice Register oracle contract to token
     @dev Only owner can register oracle
     @param _token ERC20 token address
     @param _oracle Oracle address
     */
    function registerOracle(address _token, address _oracle)
        external
        onlyOwner
    {
        IFantomTokenRegistry tokenRegistry = IFantomTokenRegistry(
            IFantomAddressRegistry(addressRegistry).tokenRegistry()
        );
        require(tokenRegistry.enabled(_token), "invalid token");
        require(oracles[_token] == address(0), "oracle already set");

        oracles[_token] = _oracle;
    }

    /**
     @notice Update oracle address for token
     @dev Only owner can update oracle
     @param _token ERC20 token address
     @param _oracle Oracle address
     */
    function updateOracle(address _token, address _oracle) external onlyOwner {
        require(oracles[_token] != address(0), "oracle not set");

        oracles[_token] = _oracle;
    }

    /**
     @notice Get current price for token
     @dev return current price or if oracle is not registered returns 0
     @param _token ERC20 token address
     */
    function getPrice(address _token) external view returns (int256, uint8) {
        if (oracles[_token] == address(0)) {
            return (0, 0);
        }

        string memory symbol = ISymbol(_token).symbol();

        if (keccak256(bytes(symbol)) == keccak256(bytes("WWAN"))) {
            symbol = "WAN";
        }

        IOracle oracle = IOracle(oracles[_token]);
        int256 price = IOracle(oracle).getValue(stringToBytes32(symbol));
        uint8 priceDecimals = 18;
        return (price, priceDecimals);
    }

    /**
     @notice Update address registry contract
     @dev Only admin
     */
    function updateAddressRegistry(address _addressRegistry)
        external
        onlyOwner
    {
        addressRegistry = _addressRegistry;
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}
