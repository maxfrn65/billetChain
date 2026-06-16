contract Bank {
    address public owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public lastDeposit;

    uint256 public constant LOCK = 1 days; // retrait possible après 1 jour

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    error NotOwner();
    error ZeroDeposit();
    error InsufficientBalance(uint256 asked, uint256 available);
    error StillLocked(uint256 unlockAt);
    error TransferFailed();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function deposit() external payable {
        if (msg.value == 0) revert ZeroDeposit();
        balanceOf[msg.sender] += msg.value;
        lastDeposit[msg.sender] = block.timestamp;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        uint256 bal = balanceOf[msg.sender];
        if (amount > bal) revert InsufficientBalance(amount, bal);

        uint256 unlockAt = lastDeposit[msg.sender] + LOCK;
        if (block.timestamp < unlockAt) revert StillLocked(unlockAt);

        // Checks-Effects-Interactions : on décrémente AVANT d'envoyer l'ETH
        balanceOf[msg.sender] = bal - amount;

        (bool ok, ) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed();

        emit Withdrawn(msg.sender, amount);
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}