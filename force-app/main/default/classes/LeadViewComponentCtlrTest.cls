@isTest
public class LeadViewComponentCtlrTest {
    
    @TestSetup
    static void initailizeTestData(){
        RecordType customerRTLead = [SELECT Id FROM RecordType Where SobjectType = 'Lead' AND Name = 'Customer Record Type'];
        Map<String,List<String>> leadPicklistMap = NewLeadComponentCtlr.getLeadPicklistData();
        
        Lead testLead = new Lead(RecordTypeId = customerRTLead.Id);        
        testLead.FirstName = 'Test';
        testLead.LastName = 'Lead';
        testLead.Company = 'TEST COMPANY';
        testLead.Business_Unit__c = leadPicklistMap.get('Business_Unit__c')[0];
        
        insert testLead;
    }
    
    public static testMethod void getLeadInfoTest(){
        
        Test.startTest();
        
        Lead testLead = [SELECT Id, FirstName, LastName FROM LEAD LIMIT 1];
        Lead result = LeadViewComponentCtlr.getLeadInfo(testLead.Id);
        
        system.assertEquals(testLead.FirstName, result.FirstName);
        
        Test.stopTest();        
    }
    
    public static testMethod void getLeadPicklistDataTest(){
        
        Test.startTest();
        
        Lead testLead = [SELECT Id, FirstName, LastName FROM LEAD LIMIT 1];
        Map<String,List<String>> picklistMap = new Map<String,List<String>>();
        picklistMap = LeadViewComponentCtlr.getLeadPicklistData();
        
        system.assert(picklistMap.size() > 0);
        
        Test.stopTest();
    }
    
    public static testMethod void mainTest(){
        Test.startTest();
        
        List<Lead> leadList = new List<Lead>();
        
        Lead testLead = [SELECT Id, FirstName, LastName FROM LEAD LIMIT 1];
        Map<String,String> fieldsMap = LeadViewComponentCtlr.getLeadFieldsMap(testLead.id);
        system.assert(fieldsMap.size() > 0);    
        
        String clonedLeadId = LeadViewComponentCtlr.cloneLead(testLead.Id);        
        leadList = [SELECT Id, FirstName, LastName FROM LEAD];
        system.assert(String.isNotEmpty(clonedLeadId));        
        system.assertEquals(2, leadList.size());
        
        LeadViewComponentCtlr.deleteLead(clonedLeadId);
        leadList = [SELECT Id, FirstName, LastName FROM LEAD];              
        system.assertEquals(1, leadList.size());
        
        testLead.FirstName = 'Name Changed';
        LeadViewComponentCtlr.saveLead(testLead);
        
        Test.stopTest();
        
    }
}