pragma solidity ^0.4.15;

import "./AbstractImporter.sol";

contract Importer6 is AbstractImporter {
    function _import() internal {
        ico.importTokens(0xd29ba5f94fb91eefc5e3aaf69f181febed73930e);
        ico.importTokens(0xd8d80210106e2a431c9c43ac133ec22a008a2f07);
    }
}