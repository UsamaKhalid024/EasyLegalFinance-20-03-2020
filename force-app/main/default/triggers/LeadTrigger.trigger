trigger LeadTrigger on Lead (after update) 
{
	if(Trigger.isAfter && Trigger.isUpdate)
    {
        LeadTriggerHandler.renameNewlyCreatedOppty(Trigger.new, Trigger.oldMap);
    }
}