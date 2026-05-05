// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AddressBook {
    enum Category { Family, Friend, Work, Other }
    struct Contact {
        string name;
        string email;
        uint256 phone;
        Category category;
        uint64 createdAt;     
        bool exists;          
    }

    mapping(address => mapping(uint256 => Contact)) private contacts;
    mapping(address => uint256) public contactCount;
    mapping(address => uint256[]) private contactIds;

    event ContactAdded(address indexed user, uint256 indexed id, string name);
    event ContactDeleted(address indexed user, uint256 indexed id);

    function addContact(
        string calldata _name,
        string calldata _email,
        uint256 _phone,
        Category _category
    ) external returns (uint256 id) {
        require(bytes(_name).length > 0, "Nom requis");
        require(bytes(_name).length <= 64, "Nom trop long");

        // L'id est le compteur + 1 (donc on commence à 1, pas à 0)
        id = contactCount[msg.sender] + 1;

        // Création du contact dans MA boîte aux lettres uniquement
        contacts[msg.sender][id] = Contact({
            name: _name,
            email: _email,
            phone: _phone,
            category: _category,
            createdAt: uint64(block.timestamp),
            exists: true
        });

        // Mise à jour du compteur et de la liste
        contactCount[msg.sender] = id;
        contactIds[msg.sender].push(id);

        emit ContactAdded(msg.sender, id, _name);
    }

    function getContact(uint256 _id) external view returns (Contact memory) {
        require(contacts[msg.sender][_id].exists, "Contact inexistant");
        return contacts[msg.sender][_id];
    }

    function getMyContactIds() external view returns (uint256[] memory) {
        return contactIds[msg.sender];
    }

    function deleteContact(uint256 _id) external {
        require(contacts[msg.sender][_id].exists, "Contact inexistant");


        delete contacts[msg.sender][_id];

        
        uint256[] storage ids = contactIds[msg.sender];
        uint256 len = ids.length;
        for (uint256 i = 0; i < len; i++) {
            if (ids[i] == _id) {
                ids[i] = ids[len - 1];
                ids.pop();
                break;
            }
        }

        emit ContactDeleted(msg.sender, _id);
    }

    function countByCategory(Category _category) external view returns (uint256 total) {
        uint256[] memory ids = contactIds[msg.sender];
        for (uint256 i = 0; i < ids.length; i++) {
            if (contacts[msg.sender][ids[i]].category == _category) {
                total++;
            }
        }
    }


}