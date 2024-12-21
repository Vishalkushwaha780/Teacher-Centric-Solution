// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TeacherStreamingPlatform {
    struct Session {
        string title;
        string description;
        uint256 date;
        uint256 fee;
        address teacher;
        address[] participants;
        bool isActive;
    }

    mapping(address => bool) public registeredTeachers;
    mapping(uint256 => Session) public sessions;
    uint256 public sessionCount;

    event TeacherRegistered(address teacher);
    event SessionCreated(uint256 sessionId, address teacher, string title);
    event StudentEnrolled(uint256 sessionId, address student);
    event EarningsWithdrawn(address teacher, uint256 amount);

    // Register as a teacher
    function registerTeacher() external {
        require(!registeredTeachers[msg.sender], "Already registered as a teacher.");
        registeredTeachers[msg.sender] = true;
        emit TeacherRegistered(msg.sender);
    }

    // Create a new session
    function createSession(
        string memory _title,
        string memory _description,
        uint256 _date,
        uint256 _fee
    ) external {
        require(registeredTeachers[msg.sender], "Only registered teachers can create sessions.");
        require(_date > block.timestamp, "Session date must be in the future.");

        sessionCount++;
        sessions[sessionCount] = Session({
            title: _title,
            description: _description,
            date: _date,
            fee: _fee,
            teacher: msg.sender,
            participants: new address[](0),
            isActive: true
        });

        emit SessionCreated(sessionCount, msg.sender, _title);
    }

    // Enroll in a session
    function enrollInSession(uint256 _sessionId) external payable {
        Session storage session = sessions[_sessionId];

        require(session.isActive, "Session is no longer active.");
        require(msg.value == session.fee, "Incorrect session fee.");
        require(session.date > block.timestamp, "Session has already occurred.");

        session.participants.push(msg.sender);        

        emit StudentEnrolled(_sessionId, msg.sender);
    }

    // Withdraw earnings
    function withdrawEarnings() external {
        uint256 totalEarnings = 0;

        for (uint256 i = 1; i <= sessionCount; i++) {
            Session storage session = sessions[i];

            if (session.teacher == msg.sender && session.date < block.timestamp && session.isActive) {
                totalEarnings += session.fee * session.participants.length;
                session.isActive = false;
            }
        }

        require(totalEarnings > 0, "No earnings to withdraw.");
        payable(msg.sender).transfer(totalEarnings);

        emit EarningsWithdrawn(msg.sender, totalEarnings);
    }

    // Get participants for a session
    function getParticipants(uint256 _sessionId) external view returns (address[] memory) {
        return sessions[_sessionId].participants;
    }

    // Fallback function to accept Ether
    receive() external payable {}
}
