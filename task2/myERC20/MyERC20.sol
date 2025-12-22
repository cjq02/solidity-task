// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MyERC20
 * @dev 代币合约框架：包含转账、授权、铸造、销毁功能
 * 
 * 主要任务：
 * 1. 定义代币基本信息（名称、符号、小数位、总供应量）
 * 2. 实现余额映射和授权映射
 * 3. 实现 transfer 函数（自己转账）
 * 4. 实现 approve 函数（授权他人花费）
 * 5. 实现 transferFrom 函数（他人代理转账）
 * 6. 实现 mint 函数（铸造代币，仅 owner）
 * 7. 实现 burn 函数（销毁代币）
 */
contract MyERC20 {
    // TODO: 代币基本信息
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    // TODO: 状态变量
    mapping(address => uint256) public balanceOf;
    // 第1层嵌套key是发起人，第2层嵌套是授权人
    mapping(address => mapping(address => uint256)) public allowance;
    
    // TODO: 所有者
    address public owner;
    
    // TODO: 事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // TODO: 修饰符
    modifier onlyOwner() {
        // TODO: 检查调用者是否为 owner
        require(msg.sender == owner, "Only onwer");
        _;
    }
    
    // TODO: 构造函数
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        // TODO: 初始化代币信息
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        // TODO: 设置 owner 为部署者
        owner = msg.sender;
        // TODO: 计算总供应量（考虑小数位）
        totalSupply = _initialSupply * 10**decimals;
        // TODO: 将初始代币分配给部署者
        balanceOf[owner] = totalSupply;
        // TODO: 触发 Transfer 事件（from = address(0)）
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    // TODO: 转账函数
    function transfer(address to, uint256 amount) public returns (bool) {
        // TODO: 检查收款地址不为零地址
        require(to != address(0), "Cannot transfer to the zero address");
        // TODO: 检查余额是否足够
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        // TODO: 更新余额（从调用者扣除，给收款人增加）
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        // TODO: 触发 Transfer 事件
        emit Transfer(msg.sender, to, amount);
        // TODO: 返回 true
        return true;
    }
    
    // TODO: 授权函数
    function approve(address spender, uint256 amount) public returns (bool) {
        // TODO: 检查被授权者地址不为零地址
        require(spender != address(0), "Cannot approve zero address");
        // TODO: 设置授权额度
        allowance[msg.sender][spender] = amount;
        // TODO: 触发 Approval 事件
        emit Approval(msg.sender, spender, amount);
        // TODO: 返回 true
        return true;
    }
    
    // TODO: 授权转账函数
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // TODO: 检查 from 和 to 都不为零地址
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        // TODO: 检查 from 的余额是否足够
        require(balanceOf[from] >= amount, "Insufficient balance in the from address");
        // TODO: 检查授权额度是否足够（allowance[from][msg.sender]）
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        // TODO: 更新余额（从 from 扣除，给 to 增加）
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        // TODO: 减少授权额度
        allowance[from][msg.sender] -= amount;
        // TODO: 触发 Transfer 事件
        emit Transfer(from, to, amount);
        // TODO: 返回 true
        return true;
    }
    
    // TODO: 铸造函数（可选，需要onlyOwner）
    function mint(address to, uint256 amount) public onlyOwner {
        // TODO: 检查接收地址不为零地址
        require(to != address(0), "Cannot mint to the zero address");
        // TODO: 增加总供应量
        totalSupply += amount;
        // TODO: 增加接收地址的余额
        balanceOf[to] += amount;
        // TODO: 触发 Transfer 事件（from = address(0)）
        emit Transfer(address(0), to, amount);
    }
    
    // TODO: 销毁函数（可选）
    function burn(uint256 amount) public {
        // TODO: 检查调用者余额是否足够
        require(balanceOf[msg.sender] >= amount, "Insufficient amount");
        // TODO: 减少总供应量
        totalSupply -= amount;
        // TODO: 减少调用者的余额
        balanceOf[msg.sender] -= amount;
        // TODO: 触发 Transfer 事件（to = address(0)）
        emit Transfer(msg.sender, address(0), amount);
    }
}

