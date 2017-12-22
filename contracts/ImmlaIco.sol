pragma solidity ^0.4.15;

import "./ImmlaToken.sol";

contract ImmlaIco is SafeMath {
    /*
     * ICO meta data
     */
    ImmlaToken public immlaToken;
    AbstractToken public preIcoToken;

    // Address of account to which ethers will be tranfered in case of successful ICO
    address public escrow;
    // Address of manager
    address public icoManager;
    // Address of a account, that will transfer tokens from pre-ICO
    address public tokenImporter = 0x0;
    // Addresses of founders, team and bountyOwner
    address public founder1;
    address public founder2;
    address public founder3;
    address public team;
    address public bountyOwner;

   

    address public preicocontract = 0xd29ba5f94fb91eefc5e3aaf69f181febed73930e;
    address public preico2contract = 0xd8d80210106e2a431c9c43ac133ec22a008a2f07;
    address public icocontract = 0x39de38ba63d172b962db2fc2ee5e4376287c50bf; 
    address public icocontractsecond = 0x0c4911ba2A7EF0a82E7bfce61B7e358121196Ba1;
    address public tKOREEC = 0x7831775357Af2D779dCD6c25C2e383B0C94b4866;
    address public tImmlaTokenDepository = 0x64075eef64d9e105a61227cccd5fa9f6b54db278;
    address public tImmlaTokenDepository2 = 0x2faaf371af6392fdd3016e111fb4b3b551ee46ab;   
    address public tImmlaBountyTokenDepository = 0x5AB08C5Dfd53b8f6f6C3e3bbFDb521170C3863B0;
    address public tAndrey = 0x027810A9C17cb0E739a33769A9E794AAF40D2338;
    address public tMichail = 0x00af06cF0Ae6BD83fC36b6Ae092bb4F669B6dbF0; 
    address public tSlava = 0x00c11E5B0b5db0234DfF9a357F56077c9a7A83D0;
    address public tAndrey2 = 0xC7e788FeaE61503136021cC48a0c95bB66d0B9f2;
    address public tMichail2 = 0xb6f4ED2CE19A08c164790419D5d87D3074D4Bd92;
    address public tSlava2 = 0x00ded30026135fBC460c2A9bf7beC06c7F31101a;



    
    // 38548226,7 IML is reward for team
    uint public constant teamsReward = 38548226701232220000000000;
    //  9361712,2 IML is token for bountyOwner
    uint public constant bountyOwnersTokens = 9361712198870680000000000;
    
    // BASE = 10^18
    uint constant BASE = 1000000000000000000;
    
    // 2017.09.14 21:00 UTC or 2017.09.15 0:00 MSK
    uint public constant defaultIcoStart = 1505422800;
    // ICO start time
    uint public icoStart = defaultIcoStart;
    
    // 2017.10.15 21:00 UTC or 2017.10.16 0:00 MSK
    uint public constant defaultIcoDeadline = 1508101200;
    // ICO end time
    uint public  icoDeadline = defaultIcoDeadline;
    
    // 2018.03.14 21:00 UTC or 2018.03.15 0:00 MSK
    uint public constant defaultFoundersRewardTime = 1521061200;
    // founders' reward time
    uint public foundersRewardTime = defaultFoundersRewardTime;
    
    // Min limit of tokens is 18 000 000 IML
    uint public constant minIcoTokenLimit = 18000000 * BASE;
    // Max limit of tokens is 434 477 177 IML
    uint public constant maxIcoTokenLimit = 434477177 * BASE;
    
    // Amount of imported tokens from pre-ICO
    uint public importedTokens = 0;
    // Amount of sold tokens on ICO
    uint public soldTokensOnIco = 0;
    // Amount of issued tokens on pre-ICO = 13232941,7 IML
    uint public constant soldTokensOnPreIco = 13232941687168431951684000;
    
    // There are 170053520 tokens in stage 1
    // 1 ETH = 3640 IML
    uint tokenPrice1 = 3640;
    uint tokenSupply1 = 170053520 * BASE;
    
    // There are 103725856 tokens in stage 2
    // 1 ETH = 3549 IML
    uint tokenPrice2 = 3549;
    uint tokenSupply2 = 103725856 * BASE;
    
    // There are 100319718 tokens in stage 3
    // 1 ETH = 3458 IML
    uint tokenPrice3 = 3458;
    uint tokenSupply3 = 100319718 * BASE;
    
    // There are 60378083 tokens in stage 4
    // 1 ETH = 3367 IML
    uint tokenPrice4 = 3367;
    uint tokenSupply4 = 60378083 * BASE;
    
    // Token's prices in stages in array
    uint[] public tokenPrices;
    // Token's remaining amounts in stages in array
    uint[] public tokenSupplies;
    
    // Check if manager can be setted
    bool public initialized = false;
    // If flag migrated=false, token can be burned
    bool public migrated = false;
    // Tokens to founders can be sent only if sentTokensToFounders == false and time > foundersRewardTime
    bool public sentTokensToFounders = false;
    // If stopICO is called, then ICO 
    bool public icoStoppedManually = false;
    
    // mapping of ether balances info
    mapping (address => uint) public balances;
    
    /*
     * Events
     */
    
    event BuyTokens(address buyer, uint value, uint amount);
    event WithdrawEther();
    event StopIcoManually();
    event SendTokensToFounders(uint founder1Reward, uint founder2Reward, uint founder3Reward);
    event ReturnFundsFor(address account);
    
    /*
     * Modifiers
     */
    
    modifier whenInitialized() {
        // only when contract is initialized
        require(initialized);
        _;
    } 
    
    modifier onlyManager() {
        // only ICO manager can do this action
        require(msg.sender == icoManager);
        _;
    }
    
    modifier onIcoRunning() {
        // Checks, if ICO is running and has not been stopped
        require(!icoStoppedManually && now >= icoStart && now <= icoDeadline);
        _;
    }
    
    modifier onGoalAchievedOrDeadline() {
        // Checks if amount of sold tokens >= min limit or deadline is reached
        require(soldTokensOnIco >= minIcoTokenLimit || now > icoDeadline || icoStoppedManually);
        _;
    }
    
    modifier onIcoStopped() {
        // Checks if ICO was stopped or deadline is reached
        require(icoStoppedManually || now > icoDeadline);
        _;
    }
    
    modifier notMigrated() {
        // Checks if base can be migrated
        require(!migrated);
        _;
    }
    
    /// @dev Constructor of ICO. Requires address of icoManager,
    /// address of preIcoToken, time of start ICO (or zero),
    /// time of ICO deadline (or zero), founders' reward time (or zero)
    /// @param _icoManager Address of ICO manager
    /// @param _preIcoToken Address of pre-ICO contract
    /// @param _icoStart Timestamp of ICO start (if equals 0, sets defaultIcoStart)
    /// @param _icoDeadline Timestamp of ICO deadline (if equals 0, sets defaultIcoDeadline)
    /// @param _foundersRewardTime Timestamp of founders rewarding time 
    /// (if equals 0, sets defaultFoundersRewardTime)
    function ImmlaIco(address _icoManager, address _preIcoToken, 
        uint _icoStart, uint _icoDeadline, uint _foundersRewardTime) {
        assert(_preIcoToken != 0x0);
        assert(_icoManager != 0x0);
        
        immlaToken = new ImmlaToken(this);
        icoManager = _icoManager;
        preIcoToken = AbstractToken(_preIcoToken);
        
        if (_icoStart != 0) {
            icoStart = _icoStart;
        }
        if (_icoDeadline != 0) {
            icoDeadline = _icoDeadline;
        }
        if (_foundersRewardTime != 0) {
            foundersRewardTime = _foundersRewardTime;
        }
        
        // tokenPrices and tokenSupplies arrays initialisation
        tokenPrices.push(tokenPrice1);
        tokenPrices.push(tokenPrice2);
        tokenPrices.push(tokenPrice3);
        tokenPrices.push(tokenPrice4);
        
        tokenSupplies.push(tokenSupply1);
        tokenSupplies.push(tokenSupply2);
        tokenSupplies.push(tokenSupply3);
        tokenSupplies.push(tokenSupply4);
    }
    
    /// @dev Initialises addresses of team, founders, tokens owner, escrow.
    /// Initialises balances of team and tokens owner
    /// @param _founder1 Address of founder 1
    /// @param _founder2 Address of founder 2
    /// @param _founder3 Address of founder 3
    /// @param _team Address of team
    /// @param _bountyOwner Address of bounty owner
    /// @param _escrow Address of escrow
    function init(
        address _founder1, address _founder2, address _founder3, 
        address _team, address _bountyOwner, address _escrow) onlyManager {
        assert(!initialized);
        assert(_founder1 != 0x0);
        assert(_founder2 != 0x0);
        assert(_founder3 != 0x0);
        assert(_team != 0x0);
        assert(_bountyOwner != 0x0);
        assert(_escrow != 0x0);
        
        founder1 = _founder1;
        founder2 = _founder2;
        founder3 = _founder3;
        team = _team;
        bountyOwner = _bountyOwner;
        escrow = _escrow;
        
        immlaToken.emitTokens(team, teamsReward);
        immlaToken.emitTokens(bountyOwner, bountyOwnersTokens);
        
        initialized = true;
    }
    
    /// @dev Sets new manager. Only manager can do it
    /// @param _newIcoManager Address of new ICO manager
    function setNewManager(address _newIcoManager) onlyManager {
        assert(_newIcoManager != 0x0);
        
        icoManager = _newIcoManager;
    }
    
    /// @dev Sets new token importer. Only manager can do it
    /// @param _newTokenImporter Address of token importer
    function setNewTokenImporter(address _newTokenImporter) onlyManager {
        tokenImporter = _newTokenImporter;
    } 
    
    // saves info if account's tokens were imported from pre-ICO
    mapping (address => bool) private importedFromPreIco;
    /// @dev Imports account's tokens from pre-ICO. It can be done only by user, ICO manager or token importer
    /// @param _account Address of account which tokens will be imported
    function importTokens(address _account) {
        // only tokens holder or manager or tokenImporter can do migration
        require(msg.sender == tokenImporter || msg.sender == icoManager || msg.sender == _account);
        require(!importedFromPreIco[_account]);
        
        uint preIcoBalance = preIcoToken.balanceOf(_account);
        if (preIcoBalance > 0) {
            immlaToken.emitTokens(_account, preIcoBalance);
            importedTokens = add(importedTokens, preIcoBalance);
        }
        
        importedFromPreIco[_account] = true;
    }
    
    /// @dev Stops ICO manually. Only manager can do it
    function stopIco() onlyManager /* onGoalAchievedOrDeadline */ {
        icoStoppedManually = true;
        StopIcoManually();
    }
    
    /// @dev If ICO is successful, sends funds to escrow (Only manager can do it). If ICO is failed, sends funds to caller (Anyone can do it)
    function withdrawEther() onGoalAchievedOrDeadline {
        if (soldTokensOnIco >= minIcoTokenLimit) {
            assert(initialized);
            assert(this.balance > 0);
            assert(msg.sender == icoManager);
            
            escrow.transfer(this.balance);
            WithdrawEther();
        } 
        else {
            returnFundsFor(msg.sender);
        }
    }
    
    /// @dev Returns funds to funder if ICO is unsuccessful. Dont removes IMMLA balance. Can be called only by manager or contract 
    /// or user for himself
    /// @param _account Address of funder
    function returnFundsFor(address _account) onGoalAchievedOrDeadline {
        assert(msg.sender == address(this) || msg.sender == icoManager || msg.sender == _account);
        assert(soldTokensOnIco < minIcoTokenLimit);
        assert(balances[_account] > 0);
        
        _account.transfer(balances[_account]);
        balances[_account] = 0;
        
        ReturnFundsFor(_account);
    }
    
    /// @dev count tokens that can be sold with amount of money. Can be called only by contract
    /// @param _weis Amount of weis
    function countTokens(uint _weis) private returns(uint) { 
        uint result = 0;
        uint stage;
        for (stage = 0; stage < 4; stage++) {
            if (_weis == 0) {
                break;
            }
            if (tokenSupplies[stage] == 0) {
                continue;
            }
            uint maxTokenAmount = tokenPrices[stage] * _weis;
            if (maxTokenAmount <= tokenSupplies[stage]) {
                result = add(result, maxTokenAmount);
                break;
            }
            result = add(result, tokenSupplies[stage]);
            _weis = sub(_weis, div(tokenSupplies[stage], tokenPrices[stage]));
        }
        
        if (stage == 4) {
            result = add(result, tokenPrices[3] * _weis);
        }
        
        return result;
    }
    
    /// @dev Invalidates _amount tokens. Can be called only by contract
    /// @param _amount Amount of tokens
    function removeTokens(uint _amount) private {
        for (uint i = 0; i < 4; i++) {
            if (_amount == 0) {
                break;
            }
            if (tokenSupplies[i] > _amount) {
                tokenSupplies[i] = sub(tokenSupplies[i], _amount);
                break;
            }
            _amount = sub(_amount, tokenSupplies[i]);
            tokenSupplies[i] = 0;
        }
    }
    
    /// @dev Buys quantity of tokens for the amount of sent ethers.
    /// @param _buyer Address of account which will receive tokens
    function buyTokens(address _buyer) private {
        assert(_buyer != 0x0);
        require(msg.value > 0);
        require(soldTokensOnIco < maxIcoTokenLimit);
        
        uint boughtTokens = countTokens(msg.value);
        assert(add(soldTokensOnIco, boughtTokens) <= maxIcoTokenLimit);
        
        removeTokens(boughtTokens);
        soldTokensOnIco = add(soldTokensOnIco, boughtTokens);
        immlaToken.emitTokens(_buyer, boughtTokens);
        
        balances[_buyer] = add(balances[_buyer], msg.value);
        
        BuyTokens(_buyer, msg.value, boughtTokens);
    }
    
    /// @dev Fall back function ~50k-100k gas
    function () payable onIcoRunning {
        buyTokens(msg.sender);
    }
    
    /// @dev Burn tokens from accounts only in state "not migrated". Only manager can do it
    /// @param _from Address of account 
    function burnTokens(address _from, uint _value) onlyManager notMigrated {
        immlaToken.burnTokens(_from, _value);
    }
    
    /// @dev Set state "migrated". Only manager can do it 
    function setStateMigrated() onlyManager {
        migrated = true;
    }
    
    /// @dev Send tokens to founders. Can be sent only after immlaToken.rewardTime() (2018.03.15 0:00 UTC)
    /// Sends 40% * 10% of all tokens to founder 1
    /// Sends 30% * 10% of all tokens to founder 2
    /// Sends 30% * 10% of all tokens to founder 3
    function sendTokensToFounders() onlyManager whenInitialized {
        require(!sentTokensToFounders && now >= foundersRewardTime);
        
        // soldTokensOnPreIco + soldTokensOnIco is ~81.3% of tokens 
        uint totalCountOfTokens = mulByFraction(add(soldTokensOnIco, soldTokensOnPreIco), 1000, 813);
        uint totalRewardToFounders = mulByFraction(totalCountOfTokens, 1, 10);
        
        uint founder1Reward = mulByFraction(totalRewardToFounders, 40, 100);
        uint founder2Reward = mulByFraction(totalRewardToFounders, 30, 100);
        uint founder3Reward = mulByFraction(totalRewardToFounders, 30, 100);
        immlaToken.emitTokens(founder1, founder1Reward);
        immlaToken.emitTokens(founder2, founder2Reward);
        immlaToken.emitTokens(founder3, founder3Reward);
        SendTokensToFounders(founder1Reward, founder2Reward, founder3Reward);
        sentTokensToFounders = true;
    }
}
