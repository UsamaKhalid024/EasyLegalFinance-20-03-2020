global class Batch_UpdatePayoutDateOnOppty implements Database.Batchable<Opportunity>, Database.stateful {
    private Set<Id> oppIds;
    private Date pDate;
    global Batch_UpdatePayoutDateOnOppty(Set<Id> opptyIds, Date payoutDate)
    {
        oppIds = opptyIds;
        pDate = payoutDate;
    }
	global Iterable<Opportunity> start(Database.BatchableContext BC)
    {
        return [Select id from opportunity where id in :oppIds];
    }
    
    global void execute(Database.BatchableContext BC,List<Opportunity> opportunities)
    {
        for(Opportunity opp : opportunities){
            opp.Payout_Date__c = pDate;
        }
        if(!opportunities.isEmpty())
                update opportunities;
    }
    
    global void finish(Database.BatchableContext BC)
    {
    }
}