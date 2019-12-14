pragma solidity ^0.4.24;

import "./DebtEvidence.sol";

contract SupplyChain{
    /****************************************************************************
    事件定义
    ***************************************************************************/
    event newDebtEvidenceEvent(address _addr,address evidence_address);
    event newEvidenceTransferEvent(address _addr,address evidence_address,address parent_evidence_address);
    /****************************************************************************
   * 数据结构定义
   ****************************************************************************/
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
    /****************************************************************************
   ****************************************************************************/

    /****************************************************************************
   * 合约数据
   ****************************************************************************/
    uint nonexistentid = 0; //0 id用于表示该交易或凭证不存在
    int errorcode = -1; //错误码
    mapping (address => bool) allEvidence;//用于保存所有创建过的合约，并防止攻击
    /****************************************************************************
   ****************************************************************************/

    constructor() public {
        //各参数初始化
        //从1开始标识
        nonexistentid = 0; //0 id用于表示该交易或凭证不存在
        //构造函数中创建user表
        //获得生产Table的TableFactory工厂
        TableFactory tf = TableFactory(0x1001);
        // 创建表
        // 用户管理表, key : account, field : address, user_type
        // |  用户账号(主键)      |    用户账号地址    |     用户类型       |
        // |-------------------- |-------------------|-------------------|
        // |      account        |    address        |    user_type      |     
        // |---------------------|-------------------|-------------------|
        //user_type 0,1,2分别表示核心企业，银行，小微企业
        tf.createTable("User", "account","address,user_type");
    }

    /****************************************************************************
   * 发起采购交易请求
   ****************************************************************************/
    function createPurchasingTx(string account,bytes32 Tx_hash,uint due_time,uint amount,string commodity,string info,uint8 v1,bytes32 r1,bytes32 s1) public returns(address){
        //检验用户是否合法
        if (!checkUser(account,msg.sender)) {revert();}
        DebtEvidence debtEvidence = new DebtEvidence(uint(EvidenceType.Purchasing),msg.sender,due_time,msg.sender,0x0,amount,Tx_hash,commodity,0,info,v1,r1,s1);
        allEvidence[debtEvidence] = true;
        emit newDebtEvidenceEvent(msg.sender,debtEvidence);
        return debtEvidence;
    }
    /****************************************************************************
   * 发起融资交易请求(无债权转让)
   ****************************************************************************/
    function createFinancing(string account,bytes32 Tx_hash,uint due_time,uint amount,uint funds,string info,uint8 v1,bytes32 r1,bytes32 s1) public returns(address){
        //检验用户是否合法
        if (!checkUser(account,msg.sender)) {revert();}
        DebtEvidence debtEvidence = new DebtEvidence(uint(EvidenceType.Financing),msg.sender,due_time,msg.sender,0x0,amount,Tx_hash,"",funds,info,v1,r1,s1);
        allEvidence[debtEvidence] = true;
        emit newDebtEvidenceEvent(msg.sender,debtEvidence);
        return debtEvidence;
    }
    /****************************************************************************
   * 发起债权转让请求(无债权转让)
   ****************************************************************************/
    function EvidenceTransfer(string account,address parent_evidence,bytes32 _Tx_hash,uint amount,string _commodity,uint _funds,string _info,uint8 _v1,bytes32 _r1,bytes32 _s1) public returns(address){
        //检验用户是否合法
        if (!checkUser(account,msg.sender)) {revert();}
        if (allEvidence[parent_evidence]==false) {revert();}//防止攻击
        if(DebtEvidence(parent_evidence).EvidenceTransferVerify(msg.sender,amount)==false) {revert();}
        DebtEvidence debtEvidence = new DebtEvidence(uint(EvidenceType.EvidenceTransfer),msg.sender,DebtEvidence(parent_evidence).getDueTime(),DebtEvidence(parent_evidence).getDebtor(),parent_evidence,amount,_Tx_hash,_commodity,_funds,_info,_v1,_r1,_s1);
        allEvidence[debtEvidence] = true;
        require(DebtEvidence(parent_evidence).AddSubEvidence(debtEvidence));
        emit newEvidenceTransferEvent(msg.sender,debtEvidence,parent_evidence);
        return debtEvidence;
    }
    /****************************************************************************
   * 外部接口getUserType用于获得对应User的身份类型
   ****************************************************************************/
    function getUserType(string account) public view returns(int){
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("User");
        Entries entries = table.select(account,table.newCondition());
        if(entries.size()!=1) return errorcode;//error
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
   /****************************************************************************
   Function:用于增加用户或修改用户
   以下接口仅限有写User表权限的管理员调用，虽然接口是public的其它人也可以调用，但无User表写权限会导致调用失败
   可以使用console控制台的CRUD SQL命令代替这些接口修改用户表
   ****************************************************************************/
    function updateUser(string account,address _address,int user_type) public returns(int){
        //检查用户是否已经存在
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("User");
        Entries entries = table.select(account,table.newCondition());
        int count;
        Entry entry = table.newEntry();
        //用户不存在
        if(entries.size()==0){
            entry.set("account",account);
            entry.set("address",_address);
            entry.set("user_type",user_type);
            count = table.insert(account,entry);
        }
        //用户已经存在,更新用户属性
        else{
            entry.set("address",_address);
            entry.set("user_type",user_type);
            count = table.update(account,entry,table.newCondition());
        }
        return count;
    }
    function removeUser(string account) public returns(int){
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("User");
        int count = table.remove(account,table.newCondition());
        return count;
    }
    /****************************************************************************
   ****************************************************************************/
   function getUserAddress(string account) public returns(address){
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("User");
        Entries entries = table.select(account,table.newCondition());
        if(entries.size()==0){
            return 0x0;
        }else{
            return entries.get(0).getAddress("address");
        }
   }
}