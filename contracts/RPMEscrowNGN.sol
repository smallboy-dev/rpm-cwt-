// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title RPMEscrowNGN
 * @dev Escrow contract for Nigerian Naira (NGN) stablecoins (e.g., cNGN)
 */
interface IERC20 {
    function transferFrom(address sender, address recipient, uint226 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract RPMEscrowNGN {
    address public admin;
    IERC20 public ngnToken;

    struct Project {
        address client;
        address developer;
        uint256 totalBudget;
        uint256 escrowBalance;
        bool isCompleted;
    }

    mapping(string => Project) public projects;

    event ProjectFunded(string projectId, uint256 amount);
    event FundsReleased(string projectId, uint256 amount);

    constructor(address _ngnToken) {
        admin = msg.sender;
        ngnToken = IERC20(_ngnToken);
    }

    function fundProject(string memory _projectId, address _developer, uint256 _amount) external {
        require(ngnToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        projects[_projectId] = Project({
            client: msg.sender,
            developer: _developer,
            totalBudget: _amount,
            escrowBalance: _amount,
            isCompleted: false
        });

        emit ProjectFunded(_projectId, _amount);
    }

    function releaseMilestone(string memory _projectId, uint256 _amount) external {
        Project storage project = projects[_projectId];
        require(msg.sender == project.client || msg.sender == admin, "Not authorized");
        require(project.escrowBalance >= _amount, "Insufficient escrow");

        project.escrowBalance -= _amount;
        require(ngnToken.transfer(project.developer, _amount), "Transfer to dev failed");

        emit FundsReleased(_projectId, _amount);
    }
}
