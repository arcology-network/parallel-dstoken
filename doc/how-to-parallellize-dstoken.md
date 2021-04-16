```Solidity
pragma solidity >=0.4.23;

// math.sol is copied from github.com/dapphub/ds-math, auth.sol is copied from github.com/dapphub/ds-auth.
import "./math.sol";
import "./auth.sol";
// ConcurrentLibInterface.sol includes all the declarations we need to use Monaco's concurrent containers and other system level API.
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
        // Remove two global variables 'balanceOf' and 'allowance', replace them with ConcurrentHashMap.
        // The original definition of balanceOf is 'mapping (address => uint256)', we use ConcurrentHashMap to replace it directly.
        // The original definition of allowance is 'mapping (address => mapping (address => uint256))'. The nesting form of ConcurrentHashMap is not supported so far, so we join the outer and inner keys together and calculate a hash from it as the new key. Refer to 'getAllowanceKey' function. 
        hashmap.create("balanceOf", int32(ConcurrentLib.DataType.ADDRESS), int32(ConcurrentLib.DataType.UINT256));
        hashmap.create("allowance", int32(ConcurrentLib.DataType.UINT256), int32(ConcurrentLib.DataType.UINT256));
        // In 'mint' and 'burn', the global variable 'totalSupply' needs to be updated, which cause it's impossible to parallellize these two functions. We change the way of updating 'totalSupply' like this: In 'mint' and 'burn', we don't update 'totalSupply' directly, but push a changing request into a ConcurrentQueue, then call a defer function. In that defer function, we handle all the changing requests in a loop, which takes place after the parallel phase. 
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
    // Add a new event to check the result of the defer function.
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
        // Get the length of the ConcurrentQueue, then pop the elements one by one and update totalSupply accordingly.
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
        // Join 'a1' and 'a2' into a single byte array, calculate it's hash. The return value type of 'keccak256' is 'bytes32', we convert it to 'uint256' and use it as the key of ConcurrentHashMap.
        return uint256(keccak256(abi.encodePacked(a1, a2)));
    }
}
```

After the modifications above, All the functions in DSToken except 'stop', 'start' and 'setName' can be called parallelly.
These three functions are used by the contract's manager and they won't be called frequently.

When we say 'parallellable', we mean:
* For 'mint' and 'burn', only one account is touched in such a transaction, which is the account whose balance is increased by 'mint' or decreased by 'burn'. So calling 'mint' or 'burn' on different accounts are not conflicting. E.g. mint(addressA, wad) and mint(addressB, wad), burn(addressA, wad) and burn(addressB, wad), mint(addressA, wad) and burn(addressB, wad) are not conflicting. Although they all need to update 'totalSupply', the updating is done in defer function, which has no impact on parallellization. But, mint(addressA, wad) and mint(addressA, wad), burn(addressA, wad) and burn(addressA, wad), mint(addressA, wad) and burn(addressA, wad) are all conflicted, because the all need to touch the same key 'addressA' in the ConcurrentHashMap named 'balanceOf', which is not allowed.
* For 'approve', 'transferFrom' and all the other wrapper functions, the number of accounts they touched is two, the token's owner and the recipient. So like 'mint' and 'burn', if all the account pairs among multiple transactions have no intersection, then the transactions are not conflicting, and they can be processed parallelly.
