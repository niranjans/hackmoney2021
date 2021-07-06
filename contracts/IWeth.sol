pragma solidity ^0.8.0;

interface IWeth {
    function deposit() external payable;
    function withdraw(uint amount) external;
    function approve(address guy, uint amount) external returns (bool);
    function balanceOf(address owner) external view returns(uint);
}