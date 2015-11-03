    contract FactoidAnchors {
		//Original creator of the contract
		address creator;
		
		//Contract initialization
		function FactoidAnchors() {
			creator = msg.sender;
			validators[msg.sender] = 1;
		}
		
		//List of anchors
        mapping (uint32 => bytes32) public anchors;
		
		//List of validators by address and their status - approved, banned, not known
		//-1 - banned
		//0 - unknown
		//1 - approved
		mapping (address => int8) public validators;
		
		//Set Factom anchors
        function setAnchor(uint32 blockNumber, bytes32 blockID) {
			if (validators[msg.sender] == 1) {
				//only approved validators can write anchors
            	anchors[blockNumber] = blockID;
			}
        }
		
		//Approve validators
		function approveValidator(address toApprove) {
			//Only approved validators can approve other validators
			if (validators[msg.sender] == 1) {
				//Banned validators cannot be approved
				if (validators[toApprove] >= 0) {
					validators[toApprove] = 1;
				}
			}
		}
		
		//Ban misbehaving validators
		function forceValidatorState(address validator, int8 state) {
			if (msg.sender == creator) {
				validators[validator] = state;
			}
		}
    }