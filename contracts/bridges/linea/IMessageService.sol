pragma solidity 0.8.20;

interface IMessageService {
    function sender() external view returns (address);
}
