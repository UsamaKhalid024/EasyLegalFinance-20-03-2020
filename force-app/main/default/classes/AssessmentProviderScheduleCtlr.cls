public with sharing class AssessmentProviderScheduleCtlr {
    
    @AuraEnabled
    public static void createAssessmentSchedulesbyLawFirm(Id lookupId, Assessment_Provider_Schedule__c assessmentSchedule){
        
        try{
            Id lawyerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Lawyers').getRecordTypeId();
            
            List<Assessment_Provider_Schedule__c> assessmentSchedules = new List<Assessment_Provider_Schedule__c>();
            for(Contact lawyer : [SELECT Id, Name FROM Contact WHERE AccountId = :lookupId 
                                  AND RecordTypeId =:lawyerRecordTypeId]){
                                      assessmentSchedules.add(
                                          new Assessment_Provider_Schedule__c(
                                              Assessment_Provider__c = assessmentSchedule.Assessment_Provider__c,
                                              Lawyer__c = lawyer.Id,
                                              Discount__c = assessmentSchedule.Discount__c,
                                              Rebate_Period__c = assessmentSchedule.Rebate_Period__c,
                                              Rebate_Discount__c = assessmentSchedule.Rebate_Discount__c
                                          )
                                      );
                                  }
            if(!assessmentSchedules.isEmpty())
                insert assessmentSchedules;            
            
        }catch (Exception e){
            system.debug('Error : ' + e.getMessage() + ' ' + e.getLineNumber());
            system.debug(e.getStackTraceString());
            throw new AuraHandledException('Error:'+e.getMessage());
        }        
    }
    
    @AuraEnabled
    public static void createAssessmentSchedules(Id lookupId, Assessment_Provider_Schedule__c assessmentSchedule){
        
        try{
            insert assessmentSchedule;
        }catch (Exception e){
            system.debug('Error : ' + e.getMessage() );
            throw new AuraHandledException('Error:'+e.getMessage());
        }        
    }
    
    @AuraEnabled
    public static Account getAssessmentProviderInfo(Id recordId){
        return [SELECT Id, Name FROM Account WHERE Id =:recordId];
    }
    
    @AuraEnabled
    public static User getCurrentUserInfo(){
        return [SELECT Id, Can_Edit_Assessment_Schedule__c FROM User 
                WHERE Id = :UserInfo.getUserId()];
    }
    
    @AuraEnabled
    public static List<Assessment_Provider_Schedule__c> getAssessmentSchedules(Id assessmentProviderId){
        
        return [SELECT Id, Name, Assessment_Provider__c, Assessment_Provider__r.Name, Lawyer__c, 
                Lawyer__r.Name, Discount__c, CreatedDate, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                Rebate_Discount__c, Rebate_Period__c 
                FROM Assessment_Provider_Schedule__c
                WHERE Assessment_Provider__c = :assessmentProviderId];
    }
    
    @AuraEnabled
    public static List<Assessment_Provider_Schedule__c> getAssessmentSchedulesByLawyer(Id lawyerId){
        
        return [SELECT Id, Name, Assessment_Provider__c, Assessment_Provider__r.Name, Lawyer__c, 
                Lawyer__r.Name, Discount__c, CreatedDate, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
                Rebate_Discount__c, Rebate_Period__c 
                FROM Assessment_Provider_Schedule__c
                WHERE Lawyer__c = :lawyerId];
    }

    @AuraEnabled
    public static List<String> getPickListValues(String objectType, String field){
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }

    @AuraEnabled
    public static Boolean rebateIsAllowed(String lookupId, String selectedLookup){
        Boolean result = false;

        if(selectedLookup == 'Law Firm'){
            result = [SELECT Id, Rebate_Allowed__c FROM Account WHERE Id =:lookupId].Rebate_Allowed__c;
        }else if(selectedLookup == 'recordId'){
            Id lawfirmId = [SELECT Id, Lawyer__r.AccountId FROM Assessment_Provider_Schedule__c WHERE Id =: lookupId].Lawyer__r.AccountId;
            result = [SELECT Id, Rebate_Allowed__c FROM Account WHERE Id =:lawfirmId].Rebate_Allowed__c;
        }else{
            result = [SELECT Id, Account.Rebate_Allowed__c FROM Contact WHERE Id =:lookupId].Account.Rebate_Allowed__c;
        }
        return result;
    }
}