    contract FactoidAnchors {
        //Original creator of the contract
        address creator;
        
        //Contract initialization
        function FactoidAnchors() {
            creator = msg.sender;
            validators[msg.sender] = 1;
            validatorCount = 1;
            quorum = 6000;
            supermajority = 9000;
        }
        
        //List of anchors
        mapping (uint32 => bytes32) public anchors;
        
        //List of validators by address and their status - approved, banned, not known
        //-1 - banned
        //0 - unknown
        //1 - approved
        mapping (address => int8) public validators;
        uint public validatorCount;
        
        //Minimal number of votes to perform important actions. Out of 10'000
        uint public quorum;
        //Minimal number of votes to overwrite the contract creator. Out of 10'000
        uint public supermajority;
        
        
        /*******************************Modifiers*******************************/
        
        modifier onlyApproved {
            //only approved validators can write anchors, approve other validators, etc.
            if (validators[msg.sender] != 1) throw;
        }
        
        modifier onlyCrator {
            //only crator can perform some actions until it disables itself
            if (msg.sender != creator) throw;
        }
        
        /*********************************Events********************************/
        
        event ValidatorStateChanged(address validator, int8 previousState, int8 newState);
        
        /*********************************Voting********************************/
        
        mapping(uint=>Vote) public votes;
        uint public nextVoteID;
        
        struct Vote {
            uint ID;
            address votedOn;
            int8 newState;
            mapping (address=>bool) voted;
            uint approvalTally;
        }
        
        function voteOn(uint index, bool voteFor) onlyApproved {
            if (votes[index].voted[msg.sender] == true) return;
            votes[index].voted[msg.sender] = true;
            if (voteFor==true) votes[index].approvalTally++;
            checkAndExecuteVote(index);
        }
        
        function checkAndExecuteVote(uint index) private {
            uint minQuorum;
            if (votes[index].newState >=0) minQuorum = validatorCount * quorum / 10000;
            else minQuorum = supermajority * quorum / 10000;
            if (votes[index].approvalTally > minQuorum) {
                setValidatorState(votes[index].votedOn, votes[index].newState, false);
                delete votes[index];
            }
        }
        
        function setValidatorState(address validator, int8 state, bool force) private {
            int8 previousState = validators[validator];
            if ((previousState == -1) && (force==false)) return;
            if (validators[validator] == 1) validatorCount--;
            validators[validator] = state;
            if (state == 1) validatorCount++;
            ValidatorStateChanged(validator, previousState, state);
        }
        
        /*******************************Functions*******************************/
        
        //Ban oneself in case private key is compromised
        function banSelf() {
            if (validators[msg.sender] == 1) validatorCount--;
            validators[msg.sender] = -1;
        }
        
        //Set Factom anchors
        function setAnchor(uint32 blockNumber, bytes32 blockID) onlyApproved {
            anchors[blockNumber] = blockID;
        }
        
        //Approve validators
        function approveValidator(address toApprove) onlyApproved {
            voteOnValidatorState(toApprove, 1);
        }
        
        function removeValidator(address toRemove) onlyApproved {
            voteOnValidatorState(toRemove, -1);
        }
        
        function voteOnValidatorState(address toVoteOn, int8 newState) {
            if (validators[toVoteOn] == -1) return;
            if (validators[toVoteOn] == newState) return;
            Vote v = votes[nextVoteID];
            
            v.ID = nextVoteID;
            nextVoteID++;
            v.votedOn = toVoteOn;
            v.newState = newState;
            
            votes[v.ID] = v;
        }
        
        /***************************Creator functions***************************/
        
        //Ban misbehaving validators
        function forceValidatorState(address validator, int8 state) onlyCrator {
            setValidatorState(validator, state, true);
        }
        
        //Remove central point of control
        function removeCreator() onlyCrator {
            delete creator;
        }
    }
 