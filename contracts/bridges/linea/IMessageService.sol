pragma solidity 0.8.27;

interface IMessageService {
    function sender() external view returns (address);
}
