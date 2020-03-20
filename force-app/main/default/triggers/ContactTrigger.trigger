trigger ContactTrigger on Contact (after update) {

	if(trigger.isAfter && trigger.isUpdate)
		contactTriggerHandler.createActivityHistory(trigger.newMap);

}