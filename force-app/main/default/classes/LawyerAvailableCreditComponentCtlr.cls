public with sharing class LawyerAvailableCreditComponentCtlr {
    
    @AuraEnabled
    public static User getCurrentUserInfo(){
        User currentUser = [SELECT Id, isActive, ProfileId, 
                            Can_Edit_Approved_Credit_Limit__c 
                            FROM User 
                            WHERE Id =: UserInfo.getUserId()];
        return currentUser;
    }
    
    @AuraEnabled
    public static Contact getLawyerRecordData(String recordId){
        Contact lawyerContact = [SELECT Id, Approved_Credit_Limit__c, 
                                 Utilized_Credit_Limit__c, Available_Credit__c,
                                 Pre_approved_Amount_Roll_Up__c
                                 FROM Contact 
                                 WHERE Id =: recordId];
        return lawyerContact;
    }
    
    @AuraEnabled 
    public static void updateLawyerRecord(Contact lawyerContact){
        try{
            update lawyerContact;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage() + ' ' + e.getLineNumber());
        }
    }
    
    @auraEnabled
    public static List<Opportunity> OpportunityAssessment(String LawyerRecordId){
        List<Opportunity> LawyerOpportunityAssessmentData = [SELECT Id, Name, Principal_Repaid_Roll_up__c,
                                                             Admin_Fee_Roll_up__c, Drawdown_Total_wo_Payment__c 
                                                             FROM Opportunity 
                                                             WHERE Type_of_Loan__c = 'Assessment' 
                                                             AND lawyer__c =:LawyerRecordId];
        return LawyerOpportunityAssessmentData;
    }
    
    @auraEnabled
    public static  List<ContactHistory> CreditHistory(String recordId){
 		

        List<ContactHistory> historyList = [SELECT Field, OldValue, NewValue, 
                                            CreatedBy.Name, CreatedDate 
                                            FROM ContactHistory 
                                            WHERE Field = 'Approved_Credit_Limit__c' 
                                            AND contactId =: recordId];
        return historyList;
    }
}