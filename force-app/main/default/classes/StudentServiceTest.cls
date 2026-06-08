@isTest
private class StudentServiceTest {
    
    @isTest
    static void testCreateStudent() {
        Test.startTest();
        Student__c s = StudentService.createStudent('Test Student', 20, 'test@example.com', 'Science', true);
        Test.stopTest();
        
        System.assertNotEquals(null, s.Id, 'Student ID should not be null after creation');
        Student__c retrieved = StudentService.getStudentById(s.Id);
        System.assertEquals('Test Student', retrieved.Name, 'Student name should match');
        System.assertEquals(20, retrieved.Age__c, 'Age should match');
        System.assertEquals('test@example.com', retrieved.Email__c, 'Email should match');
        System.assertEquals('Science', retrieved.Course__c, 'Course should match');
        System.assertEquals(true, retrieved.IsActive__c, 'IsActive should be true');
    }
    
    @isTest
    static void testGetStudents() {
        Student__c s1 = StudentService.createStudent('Student One', 21, 'one@example.com', 'Commerce', false);
        Student__c s2 = StudentService.createStudent('Student Two', 22, 'two@example.com', 'Arts', true);
        
        Test.startTest();
        List<Student__c> students = StudentService.getStudents();
        Test.stopTest();
        
        System.assert(students.size() >= 2, 'Should retrieve at least 2 students');
    }
    
    @isTest
    static void testUpdateStudent() {
        Student__c s = StudentService.createStudent('Original Student', 19, 'orig@example.com', 'Science', true);
        s.Name = 'Updated Student';
        s.Age__c = 25;
        
        Test.startTest();
        Student__c updated = StudentService.updateStudent(s);
        Test.stopTest();
        
        Student__c retrieved = StudentService.getStudentById(s.Id);
        System.assertEquals('Updated Student', retrieved.Name, 'Name should have updated');
        System.assertEquals(25, retrieved.Age__c, 'Age should have updated');
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
    static void testExceptions() {
        try {
            StudentService.updateStudent(null);
            System.assert(false, 'Exception should have been thrown for null student in update');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Student record or ID cannot be null', e.getMessage());
        }
        
        try {
            StudentService.deleteStudent(null);
            System.assert(false, 'Exception should have been thrown for null ID in delete');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Student ID cannot be null', e.getMessage());
        }
    }
}
