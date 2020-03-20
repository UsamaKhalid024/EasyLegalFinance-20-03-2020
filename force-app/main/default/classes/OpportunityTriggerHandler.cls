public with sharing class OpportunityTriggerHandler {
    
    
    public static void setDiscountschedule(List<Opportunity> newOpps, Map<Id,Opportunity> oldMap, Boolean isInsert){
        
        List<Opportunity> selOpportunities = new List<Opportunity>();
        List<Assessment_Provider_Schedule__c> assessmentScheduleToInsert = new List<Assessment_Provider_Schedule__c>();
        Set<Id> assessmentProviderIds = new Set<Id>();
        Set<Id> lawyerIds = new Set<Id>();
        
        for(Opportunity opp : newOpps){
            if(opp.Type_of_Loan__c == 'Assessment' &&
               (isInsert || (!isInsert && (opp.Assessment_Provider__c != oldMap.get(opp.Id).Assessment_Provider__c ||
                                           opp.Lawyer__c != oldMap.get(opp.Id).Lawyer__c)))){
                                               
                                               selOpportunities.add(opp);
                                               assessmentProviderIds.add(opp.Assessment_Provider__c);
                                               lawyerIds.add(opp.Lawyer__c);
                                           }
        }
        
        if(!selOpportunities.isEmpty()){
            Map<String,Assessment_Provider_Schedule__c> discountscheduleMap = new Map<String, Assessment_Provider_Schedule__c>();
            for(Assessment_Provider_Schedule__c aps : [Select Id, Lawyer__c, Assessment_Provider__c, Discount__c, Rebate_Discount__c, Rebate_Period__c
                                                       FROM Assessment_Provider_Schedule__c 
                                                       WHERE Assessment_Provider__c in :assessmentProviderIds
                                                       AND Lawyer__c in :lawyerIds order by CreatedDate asc]){
                                                           discountscheduleMap.put(aps.Assessment_Provider__c + '-' + aps.Lawyer__c, aps);
                                                       }
            
            
            for(Opportunity opp : selOpportunities){
                opp.Discount_Rate__c = 0;
                opp.Rebate_Discount__c = 0;
                opp.Rebate_Period__c = null;
                
                String key = opp.Assessment_Provider__c + '-' + opp.Lawyer__c;
                if(discountscheduleMap.containsKey(key)){
                    opp.Discount_Rate__c = discountscheduleMap.get(key).Discount__c;
                    opp.Rebate_Discount__c = discountscheduleMap.get(key).Rebate_Discount__c;
                    string periodStr = discountscheduleMap.get(key).Rebate_Period__c;
                    List<String> splited = periodStr != null? periodStr.split(' ') : new List<String>();
                    opp.Rebate_Period__c = !splited.isEmpty()? Integer.valueOf(splited[0]): null;
                    
                }else if(opp.Assessment_Provider__c != null && opp.Law_Firm__c != null && opp.Lawyer__c != null){
                    assessmentScheduleToInsert.add(
                        new Assessment_Provider_Schedule__c(
                            Assessment_Provider__c = opp.Assessment_Provider__c,
                            Lawyer__c = opp.Lawyer__c,
                            Discount__c = 0
                        )
                    );
                } 
            }
        }

        if(!assessmentScheduleToInsert.isEmpty())
            insert assessmentScheduleToInsert;
    }
    
    public static void LawyerAvailableCreditRollUps(List<Opportunity> oppList, Map<Id,Opportunity> oldMap, Boolean isInsert){
        
        Set<Id> lawyerPrincipalRepaidRollUp = new Set<Id>();
        Set<Id> lawyerAmountWoPaymentRollUp = new Set<Id>();
        Set<Id> lawyerPreApprovedAmountRollUp = new Set<Id>();
        
        for(Opportunity opp : oppList){
            
            //Roll-up Amount without Payment from drawdown to lawyer.            
            if((opp.Lawyer__c != null || (!isInsert && oldMap.get(opp.Id).Lawyer__c != null)) && 
               (opp.Type_of_Loan__c == 'Assessment' || (!isInsert && oldMap.get(opp.Id).Type_of_Loan__c == 'Assessment')) &&
               (opp.Stage_Status__c == 'Active' || opp.Stage_Status__c == 'Invoice Pre-Approved' || (!isInsert && (oldMap.get(opp.Id).Stage_Status__c == 'Active' ||
                                                                                                                   oldMap.get(opp.Id).Stage_Status__c == 'Invoice Pre-Approved'))) &&
               (isInsert || (!isInsert && (opp.Type_of_Loan__c != oldMap.get(opp.Id).Type_of_Loan__c || 
                                           opp.Drawdown_Total_wo_Payment__c != oldMap.get(opp.Id).Drawdown_Total_wo_Payment__c ||
                                           opp.Lawyer__c != oldMap.get(opp.Id).Lawyer__c || opp.StageName != oldMap.get(opp.Id).StageName ||
                                           opp.Principal_Repaid_Roll_up__c != oldMap.get(opp.Id).Principal_Repaid_Roll_up__c ||
                                           opp.Stage_Status__c != oldMap.get(opp.Id).Stage_Status__c)))){
                                               
                                               
                                               if(!isInsert && opp.Lawyer__c != oldMap.get(opp.Id).Lawyer__c){
                                                   lawyerAmountWoPaymentRollUp.add(oldMap.get(opp.Id).Lawyer__c);
                                                   lawyerPrincipalRepaidRollUp.add(oldMap.get(opp.Id).Lawyer__c);
                                                   lawyerPreApprovedAmountRollUp.add(oldMap.get(opp.Id).Lawyer__c);
                                               }
                                               
                                               if(opp.Stage_Status__c == 'Invoice Pre-Approved' || (!isInsert && oldMap.get(opp.Id).Stage_Status__c == 'Invoice Pre-Approved')){
                                                   lawyerPreApprovedAmountRollUp.add(opp.Lawyer__c);
                                               }
                                               if(opp.Stage_Status__c == 'Active' || (!isInsert && oldMap.get(opp.Id).Stage_Status__c == 'Active')){
                                                   lawyerAmountWoPaymentRollUp.add(opp.Lawyer__c);
                                                   lawyerPrincipalRepaidRollUp.add(opp.Lawyer__c);
                                               }
                                           }
        }
        
        if(!lawyerPrincipalRepaidRollUp.isEmpty())
            CalPrincipalRepaidRollUpForLawyer(lawyerPrincipalRepaidRollUp);
        
        if(!lawyerAmountWoPaymentRollUp.isEmpty())
            CalAmountWoPaymentRollUpForLawyer(lawyerAmountWoPaymentRollUp);
        
        if(!lawyerPreApprovedAmountRollUp.isEmpty())
            CalPreApprovedAmountRollUpForLawyer(lawyerPreApprovedAmountRollUp);
    }
    
    private static void CalPrincipalRepaidRollUpForLawyer(Set<Id> lawyerIds){
        
        List<Contact> lawyersToUpdate = new List<Contact>();
        
        for(AggregateResult aggrResult : [SELECT Lawyer__c lawyerId, SUM(Principal_Repaid_Roll_up__c) amnt 
                                          FROM Opportunity 
                                          WHERE Type_of_Loan__c = 'Assessment'
                                          AND StageName = 'Closed With Loan'
                                          AND Stage_Status__c = 'Active'
                                          AND Lawyer__c in :lawyerIds
                                          GROUP By Lawyer__c]){
                                              lawyersToUpdate.add(
                                                  new Contact(
                                                      Id = (Id)aggrResult.get('lawyerId'),
                                                      Principal_Repaid_Roll_up__c = (Decimal) aggrResult.get('amnt')
                                                  )
                                              );
                                          }
        if(!lawyersToUpdate.isEmpty())
            update lawyersToUpdate;
    }
    
    private static void CalAmountWoPaymentRollUpForLawyer(Set<Id> lawyerIds){
        
        List<Contact> lawyersToUpdate = new List<Contact>();
        
        for(AggregateResult aggrResult : [SELECT Lawyer__c lawyerId, SUM(Drawdown_Total_wo_Payment__c) amnt 
                                          FROM Opportunity 
                                          WHERE Type_of_Loan__c = 'Assessment'
                                          AND Stage_Status__c != 'Invoice Pre-Approved'
                                          AND Stage_Status__c = 'Active'
                                          AND StageName = 'Closed With Loan'
                                          AND Lawyer__c in :lawyerIds
                                          GROUP By Lawyer__c]){
                                              lawyersToUpdate.add(
                                                  new Contact(
                                                      Id = (Id)aggrResult.get('lawyerId'),
                                                      Amount_wo_Payment_Roll_up__c = (Decimal) aggrResult.get('amnt')
                                                  )
                                              );
                                          }
        if(!lawyersToUpdate.isEmpty())
            update lawyersToUpdate;
        
    }
    
    private static void CalPreApprovedAmountRollUpForLawyer(Set<Id> lawyerIds){
        
        List<Contact> lawyersToUpdate = new List<Contact>();
                
        for(AggregateResult aggrResult : [SELECT Lawyer__c lawyerId, SUM(Drawdown_Total_wo_Payment__c) amnt 
                                          FROM Opportunity 
                                          WHERE Type_of_Loan__c = 'Assessment'
                                          AND Stage_Status__c = 'Invoice Pre-Approved'
                                          AND Lawyer__c in :lawyerIds
                                          GROUP By Lawyer__c]){
                                              lawyersToUpdate.add(
                                                  new Contact(
                                                      Id = (Id)aggrResult.get('lawyerId'),
                                                      Pre_approved_Amount_Roll_Up__c = (Decimal) aggrResult.get('amnt')
                                                  )
                                              );
                                          }
        if(!lawyersToUpdate.isEmpty())
            update lawyersToUpdate;
    }
}