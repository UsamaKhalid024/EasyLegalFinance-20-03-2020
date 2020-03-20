@isTest(seeAllData=false)
public class PermissionAssignerTest {

    @isTest
    static void test_add_permission() {
        User u = [Select Id From User Where Id = :UserInfo.getUserId()][0];
        Permission_Assignment__mdt pa = [Select User_Field_Name__c, Permission_Set_Name__c From Permission_Assignment__mdt Where Permission_Set_Name__c = 'Schedule_Payments'];
        PermissionSet ps = [Select Id, Name From PermissionSet Where Name = :pa.Permission_Set_Name__c];

        test.startTest();
        u.put(pa.User_Field_Name__c, true);
        update u;
        test.stopTest();

        PermissionSetAssignment psa = [Select Id From PermissionSetAssignment Where AssigneeId=:u.Id AND PermissionSetId=:ps.Id];
        system.assertNotEquals(null, psa, 'PermissionSetAssignment should have been created');
    }

    @isTest
    static void test_add_multiple() {
        User u = [Select Id From User Where Id = :UserInfo.getUserId()][0];
        Permission_Assignment__mdt[] paList = [Select User_Field_Name__c, Permission_Set_Name__c From Permission_Assignment__mdt];
        system.debug(paList);
        Set<String> psNames = new Set<String>();
        for (Permission_Assignment__mdt pa : paList) {
            psNames.add(pa.Permission_Set_Name__c);
            u.put(pa.User_Field_Name__c, true);
        }
        system.debug(psNames);
        Map<Id, PermissionSet> psMap = new Map<Id, PermissionSet>([Select Id, Name From PermissionSet Where Name in :psNames]);
        system.debug(psMap);

        test.startTest();
        update u;
        test.stopTest();

        PermissionSetAssignment[] psaList = [Select Id From PermissionSetAssignment Where AssigneeId=:u.Id AND PermissionSetId in :psMap.keySet()];
        system.debug(psaList);
        system.assertEquals(psNames.size(), psaList.size(), 'PermissionSetAssignments should have been created');
    }

    @isTest
    static void test_remove_permission() {
        Permission_Assignment__mdt pa = [Select User_Field_Name__c, Permission_Set_Name__c From Permission_Assignment__mdt Where Permission_Set_Name__c = 'Schedule_Payments'];
        PermissionSet ps = [Select Id, Name From PermissionSet Where Name = :pa.Permission_Set_Name__c];

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorgsldkfjlskjf390skldjfos9udfklj.com');
        u.put(pa.User_Field_Name__c, true);
        insert u;

        //User u = [Select Id From User Where Id = :UserInfo.getUserId()][0];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=u.Id, PermissionSetId=ps.Id);
        database.insert(psa, false);

        test.startTest();
        u.put(pa.User_Field_Name__c, false);
        update u;
        test.stopTest();

        PermissionSetAssignment[] psaList = [Select Id From PermissionSetAssignment Where AssigneeId=:u.Id AND PermissionSetId=:ps.Id];
        system.assertEquals(0, psaList.size(), 'PermissionSetAssignments should have been deleted');
    }
}