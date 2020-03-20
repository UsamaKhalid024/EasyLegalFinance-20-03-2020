public with sharing class LawyerLawSocietyPageTabCtlr {
    
    @AuraEnabled
    public static Contact getLawyerInfo(Id recordId){
        return [SELECT Id, Name, Upcoming_Hearings__c, Current_Proceedings__c, 
                Orders__c, Date_Reviewed__c, Next_Review_Date__c
                FROM Contact 
                WHERE RecordType.DeveloperName = 'Lawyers' 
                AND Id = :recordId LIMIT 1];
    }
    
    @AuraEnabled
    public static List<Map<String,Object>> getContentNotes(Id recordId){
        
        return LawSocietyReviewController.getContentNotes(recordId);
    }
}