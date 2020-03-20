global class Batch_MergeAdminFeeWithOpptyDrawdown implements Database.Batchable<Opportunity>
{
    global Iterable<Opportunity> start(Database.BatchableContext BC)
    {
        return [Select id from opportunity];
    }
    
    global void execute(Database.BatchableContext BC,List<Opportunity> scope)
    {
        DrawdownTriggerHandler.mergeAdminFees(new Map<Id,Opportunity>(scope).keySet());
    }
    
    global void finish(Database.BatchableContext BC)
    {
    }
    global static void ProcessAll( Integer batchSize)
    {
        Database.executeBatch(new Batch_MergeAdminFeeWithOpptyDrawdown(), batchSize);
    }
}
