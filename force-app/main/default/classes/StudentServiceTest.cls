@isTest
private class StudentServiceTest {

    @isTest
    static void testCreateStudent() {
        Test.startTest();
        Student__c s = StudentService.createStudent('Test Student', 20, 'test@example.com', 'Science', true);
        Test.stopTest();

        System.assertNotEquals(null, s.Id, 'Student ID should not be null after creation');
        Student__c retrieved = StudentService.getStudentById(s.Id);
        System.assertEquals('Test Student', retrieved.Name,    'Name should match');
        System.assertEquals(20,             retrieved.Age__c,  'Age should match');
        System.assertEquals('test@example.com', retrieved.Email__c,  'Email should match');
        System.assertEquals('Science',      retrieved.Course__c, 'Course should match');
        System.assertEquals(true,           retrieved.IsActive__c, 'IsActive should be true');
    }

    @isTest
    static void testGetStudents() {
        StudentService.createStudent('Student One', 21, 'one@example.com', 'Commerce', false);
        StudentService.createStudent('Student Two', 22, 'two@example.com', 'Arts',     true);

        Test.startTest();
        List<Student__c> students = StudentService.getStudents();
        Test.stopTest();

        System.assert(students.size() >= 2, 'Should retrieve at least 2 students');
    }

    @isTest
    static void testGetStudentById_NullId() {
        Test.startTest();
        Student__c result = StudentService.getStudentById(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Null ID should return null');
    }

    @isTest
    static void testUpdateStudent() {
        Student__c s = StudentService.createStudent('Original Student', 19, 'orig@example.com', 'Science', true);
        s.Name  = 'Updated Student';
        s.Age__c = 25;

        Test.startTest();
        StudentService.updateStudent(s);
        Test.stopTest();

        Student__c retrieved = StudentService.getStudentById(s.Id);
        System.assertEquals('Updated Student', retrieved.Name,   'Name should have updated');
        System.assertEquals(25,                retrieved.Age__c, 'Age should have updated');
    }

    @isTest
    static void testDeleteStudent() {
        Student__c s = StudentService.createStudent('Student to Delete', 18, 'del@example.com', 'Arts', false);
        Id sId = s.Id;

        Test.startTest();
        StudentService.deleteStudent(sId);
        Test.stopTest();

        Student__c retrieved = StudentService.getStudentById(sId);
        System.assertEquals(null, retrieved, 'Student should be deleted');
    }

    @isTest
    static void testUpdateStudent_NullThrows() {
        Test.startTest();
        try {
            StudentService.updateStudent(null);
            System.assert(false, 'Exception expected for null student');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Student record or ID cannot be null', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateStudent_NoIdThrows() {
        Test.startTest();
        try {
            StudentService.updateStudent(new Student__c());
            System.assert(false, 'Exception expected for student with no ID');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Student record or ID cannot be null', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteStudent_NullThrows() {
        Test.startTest();
        try {
            StudentService.deleteStudent(null);
            System.assert(false, 'Exception expected for null ID');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Student ID cannot be null', e.getMessage());
        }
        Test.stopTest();
    }
}
