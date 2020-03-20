@isTest
public class NewLeadComponentCtlrTest {
    
    public static testMethod void mainTest(){
        
        Test.startTest();
        RecordType customerRTLead = [SELECT Id FROM RecordType Where SobjectType = 'Lead' AND Name = 'Customer Record Type'];        
        
        Map<String,List<String>> leadPicklistMap = NewLeadComponentCtlr.getLeadPicklistData();
        Map<String,String> leadFieldsMap = NewLeadComponentCtlr.getLeadFieldsMap('');
        
        Map<String,String> leadRTypes = NewLeadComponentCtlr.getRecordTypeMap();
        
        Lead testLead = new Lead(RecordTypeId = customerRTLead.Id);
        
        try{
            NewLeadComponentCtlr.saveLead(testLead);
        }catch(Exception e){
            
        }
        testLead.FirstName = 'Test';
        testLead.LastName = 'Lead';
        testLead.Company = 'TEST COMPANY';
        testLead.Business_Unit__c = leadPicklistMap.get('Business_Unit__c')[0];
        
        try{
            NewLeadComponentCtlr.saveLead(testLead);
        }catch(Exception e){
            
        }
        
        NewLeadComponentCtlr.leadInfo = testLead;
        
        Test.stopTest();        
    }
}