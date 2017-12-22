pragma solidity ^0.4.15;

import "./ImmlaToken.sol";

contract DistributionIco {

address public tKoreec = 0x7831775357Af2D779dCD6c25C2e383B0C94b4866;
address public tImmlaTokenDepository = 0x64075eef64d9e105a61227cccd5fa9f6b54db278;

function distribution(address[] tImmlaTokenDepository, uint256[] balancesValues)
{
   for (uint i = 0; i < tImmlaTokenDepository.length; i++) {
      uint amount = balancesValues[i];
      address tKoreec = tImmlaTokenDepository[i];
      if(amount > 0){
         balances[tKoreec] += amount;
         totalSupply += amount;
      }
   }
}

}