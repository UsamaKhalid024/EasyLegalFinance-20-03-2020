@isTest
public class ReportingViewComponentCtlrTest {
    
    public static testMethod void mainTest(){
        
        Test.startTest();
        
        UserRole userRole = new UserRole(DeveloperName = 'TestCustomRole', Name = 'Test Role');
        insert userRole;
        
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'ELFI - Case Management'].Id,
            LastName = 'last',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = userRole.Id,
			Lawyer_Summary__c = false, 
            Law_Firm_Summary__c = false,
            Critical_Items_Dates__c = false,
            Financial_Summary_Report__c = false           
        );
        insert testUser;
        
        system.runAs(testUser){
            User currentUser = ReportingViewComponentCtlr.getCurrentUserInfo();
            
            system.assertEquals(false, currentUser.Lawyer_Summary__c);
        }
        
        Test.stopTest();
    }
}