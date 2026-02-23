pragma solidity 0.8.26;

interface IMessageService {
    function sender() external view returns (address);
}
