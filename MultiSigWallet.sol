//SPDX-License-Identifier:MIT

pragma solidity ^0.8.17;


contract MultiSigWallet{

    address[] public owners;
    uint256 public numOfConfirmations;

    constructor(address[] memory _owners, uint256 _numOfConf){
        require(_owners.length>1,"Requires more than one owner");
        require(_numOfConf>0 && _numOfConf<=_owners.length,"Invalid number of confirmations");
        for(uint256 i=0;i<_owners.length;i++){
            require(_owners[i]!=address(0),"Invalid Address");
            owners.push(_owners[i]);
        }
        numOfConfirmations = _numOfConf;
    }

    struct Transaction{
        address to;
        uint256 value;
        bool executed;
    }

    Transaction[] private transactions;
    mapping(uint256=>mapping(address=>bool)) public isConfirmed;

    event TransactionSubmitted(
        uint256 id,
        address sender,
        address receiver
    );

    event TransactionConfirmed(
        uint256 id,
        address owner
    );

    event TransactionExecuted(
        uint256 id,
        address to
    );

    function isOwner(address _address) private view returns(bool){
        for(uint256 i=0;i<owners.length;i++){
            if(_address==owners[i]){
                return true;
            }
        }
        return false;
    }

    function submitTransaction(address _to) public payable{
        require(_to!=address(0),"Invalid address");
        require(msg.value>0,"Invalid amount");
        uint256 transactionId = transactions.length;
        transactions.push(Transaction(_to,msg.value,false));
        emit TransactionSubmitted(transactionId,msg.sender,_to);
    }


    function confirmTransaction(uint256 _id) public{
        require(_id>=0 && _id<transactions.length,"Invalid id");
        require(isOwner(msg.sender),"Only owner can confirm");
        require(!isConfirmed[_id][msg.sender],"Owner has already confirmed the transaction");
        isConfirmed[_id][msg.sender] = true;
        emit TransactionConfirmed(_id,msg.sender);
        if(isConfirmationsCompleted(_id)){
            executeTransaction(_id);
        }
    }

    function executeTransaction(uint256 _id) public payable{
        require(!transactions[_id].executed,"Transaction Already Executed");
        require(isOwner(msg.sender),"Only owner can call this function");
        require(_id>=0 && _id<transactions.length,"Invalid id");
        require(isConfirmationsCompleted(_id),"Does not have enough confirmations");
        (bool sent,) = transactions[_id].to.call{value:transactions[_id].value}("");
        require(sent,"Transaction failed");
        transactions[_id].executed = true;
        emit TransactionExecuted(_id,transactions[_id].to);
    }

    function isConfirmationsCompleted(uint256 _id) private view returns(bool){
        uint256 confirmations;
        for(uint256 i=0;i<owners.length;i++){
            if(isConfirmed[_id][owners[i]]){
                confirmations++;
            }
        }
        return confirmations>=numOfConfirmations;
    }
}

