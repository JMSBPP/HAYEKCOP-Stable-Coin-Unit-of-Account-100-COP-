// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../lib/_external/SafeMath.sol";
import "../lib/_external/Ownable.sol";
import "../lib/_external/ERC20Detailed.sol";
import "../lib/_external/SafeMathInt.sol";

/** 
 *@title HAYEKCOP ERC20 token
 *
 *@dev  This is part of the implementation of a money protocol. 
 *      It is still in beta version but it intends to be resistant to inflation. 
 *      It intends to serve as a unit of account for the Colombian economy.

*       HAYEKCOP is an ERC20 token, but its supply can be adjusted by contracting 
*       and expanding it proportionally among holders according to market conditions, 
*       so that the token price is worth 100 COP adjusted by the Colombian IPC.

*       The token name is a combination of the last name of Austrian School economist
*       Friedrich Hayek and the Colombian peso ticker COP, in honor of the deceased economist
*       for his significant contributions to decentralization in money markets.
*/

contract HAYEKCOP is ERC20Detailed, Ownable {
    //--=========README==============
    // 1) The target price in this version is 100 COP expressed
    //    based on the average historical COP/USD exchange rate.
    // 2) The monetaryPolicy address will have all the logic
    //     for contraction and expansion of the supply
    using SafeMath for uint256;
    using SafeMathInt for int256;

    uint public constant TARGET_PRICE_USD = 25 * 10 ** 16;
    uint256 public constant INITIAL_SUPPLY = 1 * 10 ** 24;
    uint256 public _totalSupply;
    address public monetaryPolicy;

    uint256 private constant DECIMALS = 9;
    uint256 private _price;

    mapping(address _address => uint256 numTokens) public holders;
    mapping(address => mapping(address => uint256)) private _allowed;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    modifier onlyMonetaryPolicy() {
        require(msg.sender == monetaryPolicy);
        _;
    }

    function initialize(address _owner) public override initializer {
        ERC20Detailed.initialize("HAYEKCOP", "HAYEKCOP", uint8(DECIMALS));
        Ownable.initialize(_owner);

        _totalSupply = INITIAL_SUPPLY;
        monetaryPolicy = address(1);
        // _price = getPrice();
    }

    /**
     * @dev Expands the supply of tokens
     * @param _value: the value to be minted
     * @param _minter: the address of the minter(only monetaryPolicy contract)
     * . bool: true if successful
     */
    function mint(
        address _minter,
        uint256 _value
    ) external onlyMonetaryPolicy returns (bool) {
        require(_minter == monetaryPolicy);
        _totalSupply = _totalSupply.add(_value);
        holders[_minter] = holders[_minter].add(_value);
        emit Transfer(address(0), _minter, _value);
    }
    /**
     * @dev Contracts the supply of tokens
     * @param _value: the value to be burned
     * @param _minter: the address of the minter(only monetaryPolicy contract)
     * .:  bool: true if successful

     *  The only affected holder is the monetaryPolicy
     *          The other holders are unaffected by these functions 
     */

    function burn(
        address _minter,
        uint256 _value
    ) external onlyMonetaryPolicy returns (bool) {
        require(_minter == monetaryPolicy && _value <= holders[_minter]);
        _totalSupply = _totalSupply.sub(_value);
        holders[_minter] = holders[_minter].sub(_value);
        emit Transfer(_minter, address(0), _value);
    }

    /**
     * .: The total number of fragments.
     */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @param _address The address to query.
     * .: The balance of the specified address.
     */

    function balanceOf(
        address _address
    ) external view override returns (uint256) {
        return holders[_address];
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * . True on success, false otherwise.
     */

    function transfer(
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        require(holders[msg.sender] >= value);

        holders[msg.sender] = holders[msg.sender].sub(value);
        holders[to] = holders[to].add(value);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Transfer all of the sender's wallet balance to a specified address.
     * @param _to The address to transfer to.
     * .: on success, false otherwise.
     */
    function transferAll(
        address _to
    ) external validRecipient(_to) returns (bool) {
        uint256 balance = holders[msg.sender];

        delete holders[msg.sender];
        holders[_to] = holders[_to].add(balance);
        emit Transfer(msg.sender, _to, balance);
        return true;
    }
    /**
     *   @dev Checks the amount of tokens that a holder
     *   has allowed to a spender.
     *   @param spender The address which will spend the funds
     *   @param owner_ The address of the tokens holder
     *   .: The amount of tokens that owner_ has allowed to spender.
     */

    function allowance(
        address owner_,
        address spender
    ) external view override returns (uint256) {
        return _allowed[owner_][spender];
    }
    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(
            addedValue
        );

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool) {
        uint256 oldValue = _allowed[msg.sender][spender];
        _allowed[msg.sender][spender] = (subtractedValue >= oldValue)
            ? 0
            : oldValue.sub(subtractedValue);

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    /**
     *   @dev Transfer tokens from one address to another
     *   @param from The address which sends the funds
     *   @param to The address which receives the funds
     *   @param value The amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        holders[from] = holders[from].sub(value);
        holders[to] = holders[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

    /**
     *   @dev Approve the passed address to spend the specified amount of tokens on behalf of
     *   msg.sender. This method is included for ERC20 compatibility.
     *   @param spender: The address which will spend the funds
     *   @param value: The amount of tokens to be spent
     */

    function approve(
        address spender,
        uint256 value
    ) external override returns (bool) {
        require(holders[msg.sender] >= value);
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer all balance tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     */

    function transferAllFrom(
        address from,
        address to
    ) external validRecipient(to) returns (bool) {
        uint256 balance = holders[from];

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(balance);

        delete holders[from];
        holders[to] = holders[to].add(balance);

        emit Transfer(from, to, balance);
        return true;
    }
}
