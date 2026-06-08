public with sharing class StudentService {

    public static List<Student__c> getStudents() {
        return [
            SELECT Id, Name, Age__c, Email__c, Course__c, IsActive__c
            FROM Student__c
            WITH USER_MODE
        ];
    }

    public static Student__c getStudentById(Id studentId) {
        if (studentId == null) {
            return null;
        }
        List<Student__c> students = [
            SELECT Id, Name, Age__c, Email__c, Course__c, IsActive__c
            FROM Student__c
            WHERE Id = :studentId
            WITH USER_MODE
            LIMIT 1
        ];
        return students.isEmpty() ? null : students[0];
    }

    public static Student__c createStudent(String name, Integer age, String email, String course, Boolean isActive) {
        Student__c newStudent = new Student__c(
            Name      = name,
            Age__c    = age,
            Email__c  = email,
            Course__c = course,
            IsActive__c = isActive
        );
        insert as user newStudent;
        return newStudent;
    }

    public static Student__c updateStudent(Student__c student) {
        if (student == null || student.Id == null) {
            throw new IllegalArgumentException('Student record or ID cannot be null');
        }
        update as user student;
        return student;
    }

    public static void deleteStudent(Id studentId) {
        if (studentId == null) {
            throw new IllegalArgumentException('Student ID cannot be null');
        }
        Student__c toDelete = new Student__c(Id = studentId);
        delete as user toDelete;
    }
}
