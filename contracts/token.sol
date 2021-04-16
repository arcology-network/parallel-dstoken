/// token.sol -- ERC20 implementation with minting and burning

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

import "./math.sol";
import "./auth.sol";
import "./ConcurrentLibInterface.sol";

contract DSToken is DSMath, DSAuth {
    bool                                              public  stopped;
    uint256                                           public  totalSupply;
    bytes32                                           public  symbol;
    uint256                                           public  decimals = 18; // standard token precision. override to customize
    bytes32                                           public  name = "";     // Optional token name
    ConcurrentHashMap constant hashmap = ConcurrentHashMap(0x81);
    ConcurrentQueue constant queue = ConcurrentQueue(0x82);
    System constant system = System(0xa1);

    constructor(bytes32 symbol_) public {
        symbol = symbol_;
        hashmap.create("balanceOf", int32(ConcurrentLib.DataType.ADDRESS), int32(ConcurrentLib.DataType.UINT256));
        hashmap.create("allowance", int32(ConcurrentLib.DataType.UINT256), int32(ConcurrentLib.DataType.UINT256));
        queue.create("totalSupplyAdd", uint256(ConcurrentLib.DataType.UINT256));
        queue.create("totalSupplySub", uint256(ConcurrentLib.DataType.UINT256));
        system.createDefer("updateTotalSupply", "updateTotalSupply(string)");
    }

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);
    event Stop();
    event Start();
    event TotalSupply(uint256);

    modifier stoppable {
        require(!stopped, "ds-stop-is-stopped");
        _;
    }

    function approve(address guy) external returns (bool) {
        return approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        hashmap.set("allowance", getAllowanceKey(msg.sender, guy), wad);

        emit Approval(msg.sender, guy, wad);

        return true;
    }

    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool)
    {
        if (src != msg.sender) {
            uint256 allowanceKey = getAllowanceKey(src, msg.sender);
            uint allowance = hashmap.getUint256("allowance", allowanceKey);
            if (allowance != uint(-1)) {
                require(allowance >= wad, "ds-token-insufficient-approval");
                hashmap.set("allowance", allowanceKey, sub(allowance, wad));
            }
        }

        uint256 balanceOfSrc = hashmap.getUint256("balanceOf", src);
        require(balanceOfSrc >= wad, "ds-token-insufficient-balance");
        hashmap.set("balanceOf", src, sub(balanceOfSrc, wad));
        hashmap.set("balanceOf", dst, add(hashmap.getUint256("balanceOf", dst), wad));

        emit Transfer(src, dst, wad);

        return true;
    }

    function push(address dst, uint wad) external {
        transferFrom(msg.sender, dst, wad);
    }

    function pull(address src, uint wad) external {
        transferFrom(src, msg.sender, wad);
    }

    function move(address src, address dst, uint wad) external {
        transferFrom(src, dst, wad);
    }


    function mint(uint wad) external {
        mint(msg.sender, wad);
    }

    function burn(uint wad) external {
        burn(msg.sender, wad);
    }

    function mint(address guy, uint wad) public auth stoppable {
        hashmap.set("balanceOf", guy, add(hashmap.getUint256("balanceOf", guy), wad));
        queue.pushUint256("totalSupplyAdd", wad);
        system.callDefer("updateTotalSupply");
        emit Mint(guy, wad);
    }

    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender) {
            uint256 allowanceKey = getAllowanceKey(guy, msg.sender);
            uint allowance = hashmap.getUint256("allowance", allowanceKey);
            if (allowance != uint(-1)) {
                require(allowance >= wad, "ds-token-insufficient-approval");
                hashmap.set("allowance", allowanceKey, sub(allowance, wad));
            }
        }

        uint256 balance = hashmap.getUint256("balanceOf", guy);
        require(balance >= wad, "ds-token-insufficient-balance");
        hashmap.set("balanceOf", guy, sub(balance, wad));
        queue.pushUint256("totalSupplySub", wad);
        system.callDefer("updateTotalSupply");
        emit Burn(guy, wad);
    }

    function stop() public auth {
        stopped = true;
        emit Stop();
    }

    function start() public auth {
        stopped = false;
        emit Start();
    }

    function setName(bytes32 name_) external auth {
        name = name_;
    }

    function updateTotalSupply(string memory) public {
        uint256 length = queue.size("totalSupplyAdd");
        for (uint256 i = 0; i < length; i++) {
            uint256 value = queue.popUint256("totalSupplyAdd");
            totalSupply = add(totalSupply, value);
        }
        length = queue.size("totalSupplySub");
        for (uint256 i = 0; i < length; i++) {
            uint256 value = queue.popUint256("totalSupplySub");
            totalSupply = sub(totalSupply, value);
        }
        emit TotalSupply(totalSupply);
    }

    function getAllowanceKey(address a1, address a2) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(a1, a2)));
    }
}
