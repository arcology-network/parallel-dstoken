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

/*  ============================================================================================================== */

// The original contract is modified to use the U256Cum library to parallelize the mint and burn functions.
// This is demonstration for the use of Arcology's concurrent library to parallelize the ERC20 token contract.
// The original contract can be found here: https://github.com/dapphub/ds-token
// This is demo only and not for production use.

pragma solidity >=0.4.23;

import "../ds-auth/src/auth.sol";
import "../ds-math/src/math.sol";
import "@arcologynetwork/concurrentlib/lib/commutative/U256Cum.sol";

contract DSToken is DSMath, DSAuth {
    bool                                                     public  stopped;
    // uint256                                               public  totalSupply;
    U256Cumulative                                           public  totalSupply;
    // mapping (address => uint256)                          public  balanceOf;
    mapping (address => U256Cumulative)                      public  balanceOf;
    // mapping (address => mapping (address => uint256)) public  allowance;
    mapping (address => mapping (address => U256Cumulative)) public  allowance;

    string                                                   public  symbol;
    uint8                                                    public  decimals = 18; // standard token precision. override to customize
    string                                                   public  name = "";     // Optional token name

    constructor(string memory symbol_) public {
        symbol = symbol_;
        totalSupply = new U256Cumulative(0, type(uint256).max);
    }

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);
    event Stop();
    event Start();
    event Step(uint step);
    event Balance(uint256 bal);

    modifier stoppable {
        require(!stopped, "ds-stop-is-stopped");
        _;
    }

    function approves(address guy) external returns (bool) {
        return approve(guy, type(uint256).max);
        
    }

    function approve(address guy, uint256 wad) public stoppable returns (bool) {
        
        if (address(allowance[msg.sender][guy]) == address(0)) {
            allowance[msg.sender][guy] = new U256Cumulative(0, type(uint256).max);
        }
        allowance[msg.sender][guy].add(wad);

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
        // if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
        //     require(allowance[src][msg.sender] >= wad, "ds-token-insufficient-approval");
        //     allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        // }
        if (src != msg.sender && address(allowance[src][msg.sender]) != address(0)) {
            // require(allowance[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[src][msg.sender].sub(wad);
        }


        require(address(balanceOf[src]) != address(0) , "ds-token-insufficient-balance");
        // balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[src].sub(wad);
        // balanceOf[dst] = add(balanceOf[dst], wad);
        if (address(balanceOf[dst]) == address(0)) {
            balanceOf[dst] = new U256Cumulative(0, type(uint256).max);
        } 
        balanceOf[dst].add(wad);
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

    function balance(address src) external {
        //return balanceOf[src].get();
        emit Balance(balanceOf[src].get());
    }

    function mints(uint wad) external {
        mint(msg.sender, wad);
    }

    function burns(uint wad) external {
        burn(msg.sender, wad);
    }

    function mint(address guy, uint wad) public auth stoppable {
        // balanceOf[guy] = add(balanceOf[guy], wad);
        if (address(balanceOf[guy]) == address(0)) {
            balanceOf[guy] = new U256Cumulative(0, type(uint256).max);
        } 
        balanceOf[guy].add(wad);
        // totalSupply = add(totalSupply, wad);
        totalSupply.add(wad);
        emit Mint(guy, wad);
    }

    function burn(address guy, uint256 wad) public auth stoppable {

        // if (guy != msg.sender && allowance[guy][msg.sender] != type(uint256).max) {
        //     require(allowance[guy][msg.sender] >= wad, "ds-token-insufficient-approval");
        //     allowance[guy][msg.sender] = sub(allowance[guy][msg.sender], wad);
        // }
        if (guy != msg.sender && address(allowance[guy][msg.sender]) != address(0)) {
            allowance[guy][msg.sender].sub(wad);
        }

        require(address(balanceOf[guy]) != address(0) , "ds-token-insufficient-balance");
        // balanceOf[guy] = sub(balanceOf[guy], wad);
        balanceOf[guy].sub(wad);
        // totalSupply = sub(totalSupply, wad);
        totalSupply.sub(wad);
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


    function setName(string memory name_) public auth {
        name = name_;
    }
}