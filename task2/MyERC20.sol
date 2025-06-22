// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract MyERC20 {
    // 代币基本信息
    string _name;  // 代币名称（如"MyToken"）
    string _symbol; // 代币符号（如"MTK"）
    
    uint256 totalSupply; // 总发行量

    // 合约管理员地址
    address public owner;

    constructor(string memory name_, string memory symbol_, uint256 _initialSupply) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender; // 部署者设为管理员
        _mint(msg.sender, _initialSupply); // 初始发行代币
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    // 余额映射：地址=>持有量
    mapping(address account => uint256) private _balances;

    // 授权映射：所有者=>(被授权人=>额度)
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    // 事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // 所有者权限修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "OnlyOwner: Only the contract owner can call this method");
        _;
    }

    // 查询余额
    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    // 转账
    function transfer(address to, uint256 amount) public returns(bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal{
        require(from != address(0), "From: address is not valid");
        require(to != address(0), "To: address is not valid");
        require(_balances[from] >= amount, "Insufficient Balance");
 
        _balances[from] -= amount; // update balances
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
    
    // 授权额度
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    // 代扣转账(需先approve）
    function transferFrom(address from, address to, uint256 amount) public returns (bool){
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }
    // 查询授权额度
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender]; // 读取嵌套映射
    }
    // 额度消费逻辑
    function _spendAllowance(address owner_, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner_, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");
            _approve(owner_, spender, currentAllowance - amount);
        }
    }
    
    // 增发代币（仅owner可调用）
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    // 铸币
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");
        totalSupply += amount;// 更新总发行量
        _balances[account] += amount; // 更新余额
        emit Transfer(address(0), account, amount); // 铸币事件from是零地址
    }

}