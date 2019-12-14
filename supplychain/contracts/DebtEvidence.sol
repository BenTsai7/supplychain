pragma solidity ^0.4.24;

import "./Table.sol";

//DebtEvidenceABI用于回调接口
contract DebtEvidenceABI{
    function EvidenceTransferConfirm(uint amount) public returns(bool){}
}

contract DebtEvidence{
    //事件类型
    event AcceptedEvent(address _addr);
    event ConfirmEvent(address _addr);
    event TransferConfirmEvent(uint _amount,address _to);
    event PaidEvent();

    //用户类型，分别为核心企业，银行，小微企业，可信机构
    enum UserType{
        CoreEnterprise,Bank,MicroEnterprise,CertifyingAuthority
    }
    //凭证类型，分别为采购，债权转让，和融资凭证
    enum EvidenceType{
        Purchasing,
        EvidenceTransfer,
        Financing
    }
    //证据状态
    enum EvidenceState{
        UnAccepted,
        Accepted,
        Confirmed,
        Paid
    }
    address owner;//Supply Chain合约的地址
    /*-----------------------------------------------*/
    //债权相关信息
    /*------------------------------------------------*/
    EvidenceType evidencetype;  //债务类型
    address debtor; //名义债务人地址
    address creditor;   //债权人地址
    uint signed_time;   //债权签订时间
    uint due_time;  //债权应还时间
    address raw_debtor; //原始债权人地址
    address parent_evidence;   //父债权地址
    address[] sub_evidence;    //子债权地址
    uint initial_amount;    //原始债权额度
    uint current_amount;    //当前债权额度
    EvidenceState state; //债权状态

    /*-----------------------------------------------*/
    //交易相关信息
    /*-----------------------------------------------*/
    bytes32 Tx_hash;   //交易哈希
    string commodity;   //商品名(也可以改为商品ID)，用于标识采购交易
    uint funds; //如果是融资交易，则是现金数量
    string info; //交易具体描述
    address certifier; //交易证明人
    //双方对交易哈希值的数字签名
    uint8 v1;
    bytes32 r1;
    bytes32 s1;
    uint8 v2;
    bytes32 r2;
    bytes32 s2;
    //第三方可信机构对交易的数字签名，确保交易真实存在
    uint8 v3;
    bytes32 r3;
    bytes32 s3;
    
    /*-----------------------------------------------*/
    //兑付相关
    /*-----------------------------------------------*/
    //双方对该凭证的地址的数字签名，表示已被支付
    bool isDebtorPaid; //Debtor是否调用支付签名
    bytes32 PaidHash; //双方确认支付时的哈希值
    uint8 pay_v1;
    bytes32 pay_r1;
    bytes32 pay_s1;
    uint8 pay_v2;
    bytes32 pay_r2;
    bytes32 pay_s2;
    
    constructor(uint _evidencetype,address _debtor,uint _due_time,address _raw_debtor,address _parent_evidence,uint _initial_amount
        ,bytes32 _Tx_hash,string _commodity,uint _funds,string _info,uint8 _v1,bytes32 _r1,bytes32 _s1) public {
        //此时该凭证的状态未未被确认
        owner = msg.sender;
        evidencetype = EvidenceType(_evidencetype);
        debtor = _debtor;
        signed_time = now;
        due_time = _due_time;
        raw_debtor = _raw_debtor;
        parent_evidence = _parent_evidence;
        initial_amount = _initial_amount;
        current_amount = _initial_amount;
        state = EvidenceState.UnAccepted;
        Tx_hash = _Tx_hash;
        commodity = _commodity;
        funds = _funds;
        info = _info;
        v1 = _v1;
        r1 = _r1;
        s1 = _s1;
        isDebtorPaid = false;
    }
    //交易接受方对该交易及其凭证进行确认
    function AcceptTransaction(string account,uint8 _v2,bytes32 _r2,bytes32 _s2) public returns(bool,string){
        if (checkUser(account,msg.sender)==false) return (false,"illegal access");//不是合法用户
        if (state!=EvidenceState.UnAccepted) return (false,"transaction has been accpeted");//已被签名
        creditor = msg.sender;
        v2 = _v2;
        r2 = _r2;
        s2 = _s2;
        state = EvidenceState.Accepted;
        emit AcceptedEvent(msg.sender);
        return (true,"transaction accepted");
    }
    //第三方可信结构对该交易及其凭证进行确认
    function ConfirmTransaction(string account,uint8 _v3,bytes32 _r3,bytes32 _s3) public returns(bool,string){
        if(checkUser(account,msg.sender)==false) return (false,"illegal access");//不是合法用户
        if(UserType(getUserType(account))!=UserType.CertifyingAuthority) return (false,"not certifying authority");//不是可信机构，不能证明
        if(state==EvidenceState.UnAccepted) return (false,"transaction not accpeted"); //交易还没被接受
        if(state!=EvidenceState.Accepted) return (false,"transaction is already confirmed");
        certifier = msg.sender;
        v3 = _v3;
        r3 = _r3;
        s3 = _s3;
        state = EvidenceState.Confirmed;
        //如果是债权转让，则需要通知SupplyChain更新其父债权
        if(evidencetype==EvidenceType.EvidenceTransfer && parent_evidence!=0){
            //bytes4 method = bytes4(keccak256("EvidenceTransferConfirm(uint)"));
            //require(parent_evidence.call(method,initial_amount));
            require(DebtEvidenceABI(parent_evidence).EvidenceTransferConfirm(current_amount));
        }
        emit ConfirmEvent(msg.sender);
        return (true,"transaction confirmed");
    }

    //债权的支付确认，双方对该交易地址进行数字签名
    function PaidTransaction(uint8 v,bytes32 r,bytes32 s,bytes32 _PaidHash) public returns(bool,string) {
        if(state==EvidenceState.Paid) return (false,"transaction has already been paid");
        if(state!=EvidenceState.Confirmed) return (false,"transaction has not been confirmed");
        if(msg.sender == raw_debtor){
            if(isDebtorPaid){
                return(false,"already paid");
            }
            isDebtorPaid = true;
            pay_v1 = v;
            pay_r1 = r;
            pay_s1 = s;
            PaidHash = _PaidHash;
            return (true,"wait to be confirmed");
        }
        else if(msg.sender == creditor){
            if(!isDebtorPaid){
                return (false,"debtor has not paid.");
            }
            pay_v2 = v;
            pay_r2 = r;
            pay_s2 = s;
            state = EvidenceState.Paid;
            emit PaidEvent();
            return (true,'transaction paid confirmed');
        }
        else{
            return (false,"illegal access");
        }
    }
    
    //该函数用于被SupplyChain调用已检测其是否可以被转让
    function EvidenceTransferVerify(address _address,uint amount) public returns(bool){
        if(msg.sender!=owner) return false;
        if(_address!=creditor) return false;
        if(state!=EvidenceState.Confirmed) return false;
        if(funds!=0) return false;
        if(amount>current_amount) return false;
        return true;
    }
    //该函数用于添加子债权，只能被SupplyChain调用
    function AddSubEvidence(address _address) public returns(bool){
        if(msg.sender!=owner) return false;
        sub_evidence.push(_address);
        return true;
    }

    //只有子债权真实性被证明后，这个债权的额度才会减少
    function EvidenceTransferConfirm(uint amount) public returns(bool){
        for(uint i=0;i<sub_evidence.length;i++){
            if(sub_evidence[i]== msg.sender){
                if(current_amount<amount) return false; //防止大量生成子债权产生的攻击
                current_amount -= amount;
                emit TransferConfirmEvent(amount,msg.sender);
                return true;
            }
        }
        //revert();
        return false;
    }

    function getDebtor() public view returns(address){
        return raw_debtor;
    }

    function getDebtAmount() public view returns(uint){
        return current_amount;
    }
    function getDueTime() public view returns(uint){
        return due_time;
    }

    //获得债权相关信息
    function getEvidenceInfo() public view returns(address,uint,address,address,uint,uint,address,address,uint,uint,uint){
       return (owner,uint(evidencetype),debtor,creditor,signed_time,due_time,raw_debtor,parent_evidence,initial_amount,current_amount,uint(state));
    }

    //获得交易相关信息
    function getTxInfo() public view returns(bytes32,string,uint,string,address){
        return (Tx_hash,commodity,funds,info,certifier);
    }

    //获得兑付相关信息
    function getPaymentInfo() public view returns(bool,bytes32,uint8,bytes32,bytes32,uint8,bytes32,bytes32){
        return (isDebtorPaid,PaidHash,pay_v1,pay_r1,pay_s1,pay_v2,pay_r2,pay_s2);
    }

    //获得三方签名
    function getSignature() public view returns(address,uint8,bytes32,bytes32,address,uint8,bytes32,bytes32,address,uint8,bytes32,bytes32){
        return (debtor,v1,r1,s1,creditor,v2,r2,s2,certifier,v3,r3,s3);
    }
    //获得子凭证
    function getSubEvidence() public view returns(address[]){
        return sub_evidence;
    }
    /****************************************************************************
   * 内部接口getUserType用于获得对应User的身份类型
   ****************************************************************************/
    function getUserType(string account) private view returns(int){
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("User");
        Entries entries = table.select(account,table.newCondition());
        return entries.get(0).getInt("user_type");
    }
    /****************************************************************************
   * 内部接口checkUser用于检查调用函数的User是否合法
   ****************************************************************************/
    function checkUser(string account,address _address) private view returns(bool){
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("User");
        Entries entries = table.select(account,table.newCondition());
        if(entries.size()!=1) return false;
        if(entries.get(0).getAddress("address")!=_address) return false;
        return true;
    }

}