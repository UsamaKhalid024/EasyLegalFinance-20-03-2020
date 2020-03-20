trigger handleLeadTrigger on Lead (after update) {

	leadHelper.convertToContact(trigger.new, trigger.oldmap);
}