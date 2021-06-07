pragma solidity 0.8.4;

contract StakeToDo {
    address owner;
    struct task {
        uint dateCreated;
        uint dateCompleted; // 0 is not completed
        address stakeholder;
        uint amountStaked;
        string taskName;
        uint deadline; // optional, 0 is no deadline
    }
    
    mapping(address => uint) public taskCount;
    mapping(address => mapping (uint => task)) public tasks;
    
    event TaskCreated(address indexed _creator, string indexed _taskName, uint _taskNumber);
    event TaskCompleted(address indexed _creator, string indexed _taskName, uint _taskNumber);

    constructor() {
        owner = msg.sender;
    }
    
    function createTask(address _stakeholder, string memory _taskName, uint _deadline) public payable {
        require(msg.value > 0, "task stake can't be 0");
        require(_deadline == 0 || _deadline > block.timestamp, "deadline must be in the future or 0 for no deadline");

        // set the taskCount
        taskCount[msg.sender] += 1;

        // create the task
        task memory newTask = task({
            dateCreated: block.timestamp,
            dateCompleted: 0,
            stakeholder: _stakeholder,
            amountStaked: msg.value,
            taskName: _taskName,
            deadline: _deadline
        });
        tasks[msg.sender][taskCount[msg.sender]] = newTask;

        emit TaskCreated(msg.sender, _taskName, taskCount[msg.sender]);
    }
    
    function validateTask(address payable _creator, uint _taskNumber) public {
        // can't if not validator
        require(tasks[_creator][_taskNumber].stakeholder == msg.sender, "You are not the validator");
        // can't if task already dateCompleted
        require(tasks[_creator][_taskNumber].dateCompleted == 0, "Task was already completed");
        // can't if after deadline
        require(tasks[_creator][_taskNumber].deadline == 0 || tasks[_creator][_taskNumber].deadline > block.timestamp, "deadline is passed, funds lost");
        
        // validator validates a task (and refund owner)
        tasks[_creator][_taskNumber].dateCompleted = block.timestamp;
        _creator.transfer(tasks[_creator][_taskNumber].amountStaked);
        
        emit TaskCreated(_creator, tasks[_creator][_taskNumber].taskName, _taskNumber);
        
        // mainnet signing to avoid gas?
    }
    
    // a way to burn the unused funds
    function burnOverdue(address _creator, uint _taskNumber) public {
        address burn = 0x0000000000000000000000000000000000000000;
        require(msg.sender == owner, "you are not the owner");
        // task must be uncompleted
        require(tasks[_creator][_taskNumber].dateCompleted == 0, "can't burn stake for completed tasks");
        // task must be overdue
        require(tasks[_creator][_taskNumber].deadline != 0 && tasks[_creator][_taskNumber].deadline < block.timestamp, "can't burn if no deadline or deadline not reached");
        
        // burn and donate to the owner
        // math issue with /2 ?
        payable(burn).transfer(tasks[_creator][_taskNumber].amountStaked / 2 );
        payable(owner).transfer(tasks[_creator][_taskNumber].amountStaked / 2 );
    }
    
}