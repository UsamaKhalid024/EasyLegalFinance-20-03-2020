public class ApprovelProcessUnlock {
    
    @InvocableMethod(label='Unlock Records And Create Approval History')
    public static void unlockRecordAndCreateCustomApprovalHistory(List<ID> ids) {
        
        List<Id> recordIdsToUnlock = new List<Id>();
        
        for(Id accId : Ids){
            if(Approval.isLocked(accId))
                recordIdsToUnlock.add(accId);
        }
        
        If(!recordIdsToUnlock.isEmpty())
            List<Approval.UnlockResult> unlockList = Approval.unlock(recordIdsToUnlock);
        
        createCustomApprovalHistoryRecords(ids);
    }
    
    public static void createCustomApprovalHistoryRecords(List<ID> ids){
        
        Map<Id, ProcessInstance> accountToPIMap = new Map<Id,ProcessInstance >();
        List<Custom_Approval_History__c> toInsert = new List<Custom_Approval_History__c>();
        
        for(ProcessInstance pi : [SELECT Id, createdDate,
                                  TargetObjectId
                                  FROM ProcessInstance
                                  WHERE TargetObjectId in :ids 
                                  AND Status = 'Pending'
                                  order by createdDate]){
                                      if(!accountToPIMap.containsKey(pi.TargetObjectId))
                                          accountToPIMap.put(pi.TargetObjectId, pi);
                                  }
        
        for(Account acc : [Select Id, Projected_Loan_Value__c, Loan_To_Value__c
                           FROM Account
                           WHERE Id in :ids]){
                               toInsert.add(
                                   new Custom_Approval_History__c(
                                       Account__c = acc.Id,
                                       Process_Instance_Id__c = accountToPIMap.containsKey(acc.Id)? accountToPIMap.get(acc.Id).Id : null,
                                       Value_to_Approve__c = '' + acc.Projected_Loan_Value__c,
                                       Loan_To_Value__c = acc.Loan_To_Value__c
                                   )
                               );
                           }
        
        if(!toInsert.isEmpty()){
            insert toInsert;
        }
        
    }
}