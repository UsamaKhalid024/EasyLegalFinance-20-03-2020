public with sharing class AssessmentProviderScheduleTriggerHandler {
    
    public static void updateAssessmentScheduleOnOpportunities(List<Assessment_Provider_Schedule__c> newSchedules, Map<Id, Assessment_Provider_Schedule__c> oldMap, Boolean isInsert){
        
        List<Assessment_Provider_Schedule__c> selSchedules = new List<Assessment_Provider_Schedule__c>();
        Map<String, Assessment_Provider_Schedule__c> assessmentScheduleMap = new Map<String, Assessment_Provider_Schedule__c>();
        Set<Id> aProviderIds = new Set<Id>();
        Set<Id> lawyerIds = new Set<Id>();
        
        for(Assessment_Provider_Schedule__c sch : newSchedules){
            if(sch.Assessment_Provider__c != null && sch.Lawyer__c != null && 
               (isInsert || (!isInsert && (sch.Assessment_Provider__c != oldMap.get(sch.Id).Assessment_Provider__c ||
                                           sch.Lawyer__c != oldMap.get(sch.Id).Lawyer__c || sch.Discount__c != oldMap.get(sch.Id).Discount__c ||
                                           sch.Rebate_Discount__c != oldMap.get(sch.Id).Rebate_Discount__c || 
                                           sch.Rebate_Period__c != oldMap.get(sch.Id).Rebate_Period__c)))){
                                               selSchedules.add(sch);
                                               aProviderIds.add(sch.Assessment_Provider__c);
                                               lawyerIds.add(sch.Lawyer__c);
                                           }
               }
        
        
        if(!selSchedules.isEmpty()){
            String key = '';
            for(Assessment_Provider_Schedule__c sch : [SELECT Id, Discount__c, Assessment_Provider__c, Lawyer__c, CreatedDate,
                                                                          Rebate_Discount__c, Rebate_Period__c
                                                                          FROM Assessment_Provider_Schedule__c
                                                                          WHERE Assessment_Provider__c in :aProviderIds
                                                                          AND Lawyer__c in :lawyerIds order by CreatedDate desc]){
                                                                              key = sch.Assessment_Provider__c + '-' + sch.Lawyer__c;
                                                                              if(!assessmentScheduleMap.containsKey(key))
                                                                                    assessmentScheduleMap.put(key, sch);

            }

            List<Opportunity> opportunities = [SELECT Id, Discount_Rate__c, Rebate_Discount__c, 
                                              Rebate_Period__c, Assessment_Provider__c, Lawyer__c
                                              FROM Opportunity 
                                              WHERE Lawyer__c in :lawyerIds AND Assessment_Provider__c in :aProviderIds
                                              AND StageName != 'Closed With Loan'
                                              AND StageName != 'Closed No Loan' AND StageName != 'TESTING'
                                              AND Type_of_Loan__c = 'Assessment'];

            for(Opportunity opp : opportunities){
                
                if(assessmentScheduleMap.containsKey(opp.Assessment_Provider__c + '-' + opp.Lawyer__c)){
                    Assessment_Provider_Schedule__c apsch = assessmentScheduleMap.get(opp.Assessment_Provider__c + '-' + opp.Lawyer__c);
                    opp.Discount_Rate__c = apsch.Discount__c;
                    opp.Rebate_Discount__c = apsch.Rebate_Discount__c;
                    String periodStr = apsch.Rebate_Period__c;
                    List<String> splited = periodStr != null? periodStr.split(' ') : new List<String>();
                    opp.Rebate_Period__c = !splited.isEmpty()? Integer.valueOf(splited[0]): null;
                }
                    
            }  
            if(!opportunities.isEmpty())    
                update opportunities;
        }
    }
}