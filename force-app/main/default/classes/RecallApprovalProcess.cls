public class RecallApprovalProcess {
    
    @InvocableMethod(label='Remove Pending Approvals')
    public static void recallPendingApprovals(List<ID> ids) {
        
        List<Id> ProcessInstanceIds = new List<Id>();
        for(ProcessInstance pi : [SELECT Id, Status 
                                  FROM ProcessInstance 
                                  Where TargetObjectId in :ids
                                  AND Status = 'Pending']){
                                      ProcessInstanceIds.add(pi.Id);
                                  }
        
        if(!ProcessInstanceIds.isEmpty()){
            List<Approval.ProcessWorkitemRequest> reqList = new List<Approval.ProcessWorkitemRequest>();
            for(ProcessInstanceWorkitem piwItem : [SELECT Id FROM ProcessInstanceWorkitem 
                                                   WHERE ProcessInstanceId in :ProcessInstanceIds]){
                                                       
                                                       Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
                                                       pwr.setAction('Removed');
                                                       pwr.setWorkItemId(piwItem.id);
                                                       reqList.add(pwr);
                                                   }            
            
            List<Approval.ProcessResult> result = Approval.process(reqList);
        }
    }
}