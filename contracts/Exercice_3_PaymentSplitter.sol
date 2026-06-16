// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PaymentSplitter {
    mapping(address => uint256) public shares;     // parts de chaque bénéficiaire
    mapping(address => uint256) public released;   // déjà retiré par bénéficiaire
    uint256 public totalShares;                    // somme de toutes les parts
    uint256 public totalReceived;                  // total ETH reçu depuis le début

    event PayeeAdded(address indexed account, uint256 shares);
    event PaymentReceived(address indexed from, uint256 amount);
    event PaymentReleased(address indexed to, uint256 amount);

    error LengthMismatch();
    error EmptyPayees();
    error ZeroAddress();
    error ZeroShares();
    error NoShares(address account);
    error NothingToRelease(address account);
    error TransferFailed();

    /**
     * @param _payees liste des bénéficiaires
     * @param _shares parts correspondantes (même index)
     */
    constructor(address[] memory _payees, uint256[] memory _shares) {
        if (_payees.length != _shares.length) revert LengthMismatch();
        if (_payees.length == 0) revert EmptyPayees();

        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    function _addPayee(address account, uint256 shares_) private {
        if (account == address(0)) revert ZeroAddress();
        if (shares_ == 0) revert ZeroShares();
        // On interdit l'ajout en double pour ne pas écraser une part existante
        if (shares[account] != 0) revert ZeroShares();

        shares[account] = shares_;
        totalShares += shares_;
        emit PayeeAdded(account, shares_);
    }

    /// Enregistre simplement les ETH reçus.
    receive() external payable {
        totalReceived += msg.value;
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * Montant que `account` peut encore retirer.
     * Formule : (totalReceived * shares[account] / totalShares) - released[account]
     */
    function pendingPayment(address account) public view returns (uint256) {
        uint256 totalDue = (totalReceived * shares[account]) / totalShares;
        return totalDue - released[account];
    }

    /// `account` (ou n'importe qui pour lui) retire la part disponible.
    function release(address payable account) external {
        if (shares[account] == 0) revert NoShares(account);

        uint256 payment = pendingPayment(account);
        if (payment == 0) revert NothingToRelease(account);

        // Effects avant interaction (protection reentrancy)
        released[account] += payment;

        (bool ok, ) = account.call{value: payment}("");
        if (!ok) revert TransferFailed();

        emit PaymentReleased(account, payment);
    }
}
