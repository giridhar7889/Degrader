pragma solidity ^0.4.26;

contract Grader {
    address private admin;
    bytes32[] private courseIDList;
    mapping(bytes32 => bool) courseIds;
    address[] private instructorsList;
    mapping(address => bool) instructors;
    mapping(bytes32 => address) courseInstructor;
    uint256[8] gradeChart = [10, 9, 8, 7, 6, 5, 4, 0];

    constructor() public {
        admin = msg.sender;
    }

    function kill() public {
        require(msg.sender == admin);
        selfdestruct(admin);
    }

    struct Exam {
        bytes32 examID;
        uint256 maxMarks;
        mapping(bytes32 => uint256) marks;
    }

    struct Course {
        bytes32 courseID;
        string courseName;
        address instructor;
        bytes32[] rollList;
        bool marksExist;
        mapping(bytes32 => bool) rollNoVer;
        mapping(address => bool) TAs;
        mapping(bytes32 => address) students;
        mapping(address => bool) studentAddrVer;
    }

    struct Marks {
        bytes32[] examIDList;
        uint256[] weightageList;
        uint256[] maxMarksList;
        uint256[] gradeCutoffs;
        uint256[] gradeList;
        uint256[] totalMarksList;
        uint256[][] marksList;
        uint256[][] invMarksList;
        bool invMarksExist;
        mapping(bytes32 => bool) examIds;
        mapping(bytes32 => Exam) exams;
        mapping(bytes32 => uint256) weightage;
        mapping(bytes32 => uint256) totalMarks;
        mapping(bytes32 => uint256) grades;
    }

    mapping(bytes32 => Course) courses;
    mapping(bytes32 => Marks) courseMarks;

    function addInstructor(address[] memory instrlist)
        public
        returns (bool added)
    {
        require(msg.sender == admin, "addInstructor");
        for (uint256 i = 0; i < instrlist.length; i++) {
            if (!instructors[instrlist[i]]) {
                instructorsList.push(instrlist[i]);
                instructors[instrlist[i]] = true;
            }
        }
        added = true;
    }

    function getInstructorsList()
        public
        view
        returns (address[] memory instrList)
    {
        require(msg.sender == admin, "getInstrcutorsList");
        instrList = instructorsList;
    }

    function addCourse(
        bytes32 courseID,
        string memory courseName,
        bytes32[] memory rollList,
        address[] memory studAddr,
        address[] memory TAs
    ) public returns (bool added) {
        require(instructors[msg.sender] && (!courseIds[courseID]), "addCourse");
        require(rollList.length == studAddr.length, "addCourse");
        courseInstructor[courseID] = msg.sender;
        courseIds[courseID] = true;
        courseIDList.push(courseID);
        courses[courseID] = Course(
            courseID,
            courseName,
            msg.sender,
            rollList,
            false
        );
        for (uint256 i = 0; i < rollList.length; i++) {
            if (!courses[courseID].studentAddrVer[studAddr[i]]) {
                courses[courseID].students[rollList[i]] = studAddr[i];
                courses[courseID].studentAddrVer[studAddr[i]] = true;
            }
            if (!courses[courseID].rollNoVer[rollList[i]])
                courses[courseID].rollNoVer[rollList[i]] = true;
        }
        for (uint256 j = 0; j < TAs.length; j++)
            courses[courseID].TAs[TAs[j]] = true;
        added = true;
    }

    function addCourseMarks(bytes32 courseID) private returns (bool added) {
        require(
            courseIds[courseID] &&
                ((courseInstructor[courseID] == msg.sender) ||
                    courses[courseID].TAs[msg.sender]),
            "addCourseMarks"
        );
        bytes32[] memory examIDList;
        uint256[] memory weightageList;
        uint256[] memory maxMarksList;
        uint256[] memory gradeCutoffs;
        uint256[] memory gradeList = new uint256[](
            courses[courseID].rollList.length
        );
        uint256[] memory totalMarksList = new uint256[](
            courses[courseID].rollList.length
        );
        uint256[][] memory marksList = new uint256[][](
            courses[courseID].rollList.length
        );
        uint256[][] memory invMarksList;
        courseMarks[courseID] = Marks(
            examIDList,
            weightageList,
            maxMarksList,
            gradeCutoffs,
            gradeList,
            totalMarksList,
            marksList,
            invMarksList,
            false
        );
        courses[courseID].marksExist = true;
        added = true;
    }

    function addExam(
        bytes32 courseID,
        bytes32 examID,
        uint256 maxMarks,
        bytes32[] memory rollList,
        uint256[] memory marksList
    ) public returns (bool added) {
        require(
            courseIds[courseID] &&
                ((courseInstructor[courseID] == msg.sender) ||
                    courses[courseID].TAs[msg.sender]),
            "addExam"
        );
        require(marksList.length == rollList.length, "addExam");
        if (!courses[courseID].marksExist) addCourseMarks(courseID);
        require(!courseMarks[courseID].examIds[examID], "addExam");
        courseMarks[courseID].examIds[examID] = true;
        courseMarks[courseID].examIDList.push(examID);
        courseMarks[courseID].maxMarksList.push(maxMarks);
        courseMarks[courseID].exams[examID] = Exam(examID, maxMarks);
        for (uint256 k = 0; k < rollList.length; k++) {
            courseMarks[courseID].exams[examID].marks[rollList[k]] = marksList[
                k
            ];
        }
        for (uint256 i = 0; i < courses[courseID].rollList.length; i++) {
            courseMarks[courseID].marksList[i].push(
                courseMarks[courseID].exams[examID].marks[
                    courses[courseID].rollList[i]
                ]
            );
        }
        added = true;
    }

    function updateMarks(
        bytes32 courseID,
        bytes32 examID,
        bytes32[] memory rollList,
        uint256[] memory marksList
    ) public returns (bool added) {
        require(
            courseIds[courseID] &&
                ((courseInstructor[courseID] == msg.sender) ||
                    courses[courseID].TAs[msg.sender]) &&
                courses[courseID].marksExist &&
                courseMarks[courseID].examIds[examID],
            "updateMarks"
        );
        require(marksList.length == rollList.length, "updateMarks");
        for (uint256 k = 0; k < rollList.length; k++) {
            courseMarks[courseID].exams[examID].marks[rollList[k]] = marksList[
                k
            ];
        }
        for (uint256 i = 0; i < courses[courseID].rollList.length; i++) {
            bytes32 roll_no = courses[courseID].rollList[i];
            for (
                uint256 j = 0;
                j < courseMarks[courseID].examIDList.length;
                j++
            ) {
                if (courseMarks[courseID].examIDList[j] == examID) {
                    courseMarks[courseID].marksList[i][j] = courseMarks[
                        courseID
                    ].exams[examID].marks[roll_no];
                }
            }
        }
        added = true;
    }

    function setWeightages(bytes32 courseID, uint256[] memory weightageList)
        private
        returns (bool added)
    {
        require(
            courseIds[courseID] &&
                (courseInstructor[courseID] == msg.sender) &&
                courses[courseID].marksExist,
            "setWeightages"
        );
        require(
            courseMarks[courseID].examIDList.length == weightageList.length,
            "setWeightages"
        );
        courseMarks[courseID].weightageList = weightageList;
        for (uint256 i = 0; i < courseMarks[courseID].examIDList.length; i++)
            courseMarks[courseID].weightage[
                courseMarks[courseID].examIDList[i]
            ] = weightageList[i];
        added = true;
    }

    function setGradeCutoffs(bytes32 courseID, uint256[] memory gradeCutoffs)
        private
        returns (bool added)
    {
        require(
            courseIds[courseID] &&
                (courseInstructor[courseID] == msg.sender) &&
                courses[courseID].marksExist,
            "setGradeCutoffs"
        );
        require(
            gradeCutoffs.length == (gradeChart.length - 1),
            "setGradeCutoffs"
        );
        courseMarks[courseID].gradeCutoffs = gradeCutoffs;
        added = true;
    }

    function calculateTotal(bytes32 courseID) private returns (bool added) {
        require(
            courseIds[courseID] &&
                (courseInstructor[courseID] == msg.sender) &&
                courses[courseID].marksExist,
            "calculateTotal"
        );
        uint256 pres = 1000;
        for (uint256 p = 0; p < courses[courseID].rollList.length; p++) {
            courseMarks[courseID].totalMarks[courses[courseID].rollList[p]] = 0;
        }
        for (uint256 i = 0; i < courseMarks[courseID].examIDList.length; i++) {
            bytes32 exam_id = courseMarks[courseID].examIDList[i];
            uint256 maxmarks = courseMarks[courseID].exams[exam_id].maxMarks;
            uint256 weightage = courseMarks[courseID].weightage[exam_id];
            for (uint256 j = 0; j < courses[courseID].rollList.length; j++) {
                bytes32 roll_no = courses[courseID].rollList[j];
                courseMarks[courseID].totalMarks[roll_no] += ((courseMarks[
                    courseID
                ].exams[exam_id].marks[roll_no] *
                    pres *
                    weightage) / maxmarks);
            }
        }
        for (uint256 k = 0; k < courses[courseID].rollList.length; k++) {
            courseMarks[courseID].totalMarks[
                courses[courseID].rollList[k]
            ] /= pres;
            courseMarks[courseID].totalMarksList[k] = courseMarks[courseID]
                .totalMarks[courses[courseID].rollList[k]];
        }
        added = true;
    }

    function calculateGrades(
        bytes32 courseID,
        uint256[] memory weightageList,
        uint256[] memory gradeCutoffs
    ) public returns (bool added) {
        require(
            courseIds[courseID] &&
                (courseInstructor[courseID] == msg.sender) &&
                courses[courseID].marksExist,
            "calculateGrades"
        );
        setWeightages(courseID, weightageList);
        setGradeCutoffs(courseID, gradeCutoffs);
        calculateTotal(courseID);
        for (uint256 i = 0; i < courses[courseID].rollList.length; i++) {
            for (
                uint256 j = 0;
                j < courseMarks[courseID].gradeCutoffs.length;
                j++
            ) {
                bytes32 roll_no = courses[courseID].rollList[i];
                if (
                    courseMarks[courseID].totalMarks[roll_no] >=
                    courseMarks[courseID].gradeCutoffs[j]
                ) {
                    courseMarks[courseID].gradeList[i] = gradeChart[j];
                    courseMarks[courseID].grades[roll_no] = gradeChart[j];
                    break;
                }
            }
        }
        getInverseMarks(courseID);
        added = true;
    }

    function getProfExamWeightages(bytes32 courseID)
        public
        view
        returns (
            bytes32[] memory examslist,
            uint256[] memory maxMarkslist,
            uint256[] memory weightages
        )
    {
        require(
            courseIds[courseID] &&
                (courseInstructor[courseID] == msg.sender) &&
                courses[courseID].marksExist,
            "getProfExamWeightages"
        );
        examslist = courseMarks[courseID].examIDList;
        maxMarkslist = courseMarks[courseID].maxMarksList;
        weightages = courseMarks[courseID].weightageList;
    }

    function getInverseMarks(bytes32 courseID) private returns (bool added) {
        require(
            courseIds[courseID] &&
                (courseInstructor[courseID] == msg.sender) &&
                courses[courseID].marksExist,
            "getInverseMarks"
        );
        if (!courseMarks[courseID].invMarksExist) {
            courseMarks[courseID].invMarksList = new uint256[][](
                courseMarks[courseID].examIDList.length
            );
            for (
                uint256 j = 0;
                j < courseMarks[courseID].examIDList.length;
                j++
            )
                for (uint256 i = 0; i < courses[courseID].rollList.length; i++)
                    courseMarks[courseID].invMarksList[j].push(
                        courseMarks[courseID].marksList[i][j]
                    );
            courseMarks[courseID].invMarksExist = true;
        } else {
            for (
                uint256 q = 0;
                q < courseMarks[courseID].examIDList.length;
                q++
            )
                for (uint256 p = 0; p < courses[courseID].rollList.length; p++)
                    courseMarks[courseID].invMarksList[q][p] = courseMarks[
                        courseID
                    ].marksList[p][q];
        }
        added = true;
    }

    function getProfExamMarks(bytes32 courseID, bytes32 examID)
        public
        view
        returns (
            bytes32[] memory rolllist,
            uint256[] memory markslist,
            uint256 maxmarks,
            uint256 weightage
        )
    {
        require(
            courseIds[courseID] &&
                (courseInstructor[courseID] == msg.sender) &&
                courses[courseID].marksExist,
            "getProfGrades"
        );
        rolllist = courses[courseID].rollList;
        weightage = courseMarks[courseID].weightage[examID];
        for (uint256 i = 0; i < courseMarks[courseID].examIDList.length; i++) {
            if (courseMarks[courseID].examIDList[i] == examID) {
                maxmarks = courseMarks[courseID].maxMarksList[i];
                markslist = courseMarks[courseID].invMarksList[i];
                break;
            }
        }
    }

    function getStudentMarksGrades(bytes32 courseID, bytes32 rollNo)
        public
        view
        returns (
            bytes32[] memory examslist,
            uint256[] memory weightages,
            uint256[] memory maxMarkslist,
            uint256[] memory markslist,
            uint256 totalmarks,
            uint256 grade
        )
    {
        require(
            courseIds[courseID] &&
                ((courseInstructor[courseID] == msg.sender) ||
                    courses[courseID].studentAddrVer[msg.sender]) &&
                courses[courseID].rollNoVer[rollNo] &&
                courses[courseID].marksExist,
            "getStudentMarks"
        );
        examslist = courseMarks[courseID].examIDList;
        weightages = courseMarks[courseID].weightageList;
        maxMarkslist = courseMarks[courseID].maxMarksList;
        for (uint256 i = 0; i < courses[courseID].rollList.length; i++) {
            if (courses[courseID].rollList[i] == rollNo)
                markslist = courseMarks[courseID].marksList[i];
        }
        totalmarks = courseMarks[courseID].totalMarks[rollNo];
        grade = courseMarks[courseID].grades[rollNo];
    }

    function getProfMarksGrades(bytes32 courseID)
        public
        view
        returns (
            bytes32[] memory rolllist,
            uint256[] memory totalmarks,
            uint256[] memory gradelist
        )
    {
        require(
            courseIds[courseID] &&
                (courseInstructor[courseID] == msg.sender) &&
                courses[courseID].marksExist,
            "getProfGrades"
        );
        rolllist = courses[courseID].rollList;
        totalmarks = courseMarks[courseID].totalMarksList;
        gradelist = courseMarks[courseID].gradeList;
    }
}
