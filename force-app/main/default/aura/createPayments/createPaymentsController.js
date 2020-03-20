({
	/**
	* @description Method to be called when lighting record edit form loads the records
	*/
	handleOnLoad: function(component,event,helper) {
		if(event.getParams() && $A.util.isUndefinedOrNull(component.get("v._paymentScheduleMode"))){
			$A.util.toggleClass(component.find("spinner"),"slds-hide");
			component.set("v._paymentScheduleMode", event.getParams().recordUi.record.fields.Payment_Schedule_Mode__c.value);
			component.set("v._disableBankSelection", event.getParams().recordUi.record.fields.Payment_Use_Primary_Bank_Account__c.value);
			component.set("v._selectedBankAccountId", event.getParams().recordUi.record.fields.Payment_Default_Bank_Account__c.value);
			helper.getBankAccountOptions(component);
			helper.calculatePayments(component, event);
		}
	},

	handleUsePrimaryBankAccountChanged: function(component, event, helper) {
		component.set("v._disableBankSelection", event.getParams().checked);
	},

	/**
	* @description Method handles payment scheduler mode change
	*/
	handlePaymentSchedulerModeChange: function(component,event,helper){
		helper.paymentSchedulerModeChange(component,event);
	},

	/**
	* @description Method to handle when user click cancel button
	*/
	handleCancel: function(component,event,helper){
		component.find("overlayLib").notifyClose();
	},

	/**
	* @description Method called when payment scheduler settings successfull saved
	*/
	handleSubmit: function(component, event, helper) {
		event.preventDefault();       // stop the form from submitting
		var fields = event.getParam('fields');
		fields.Payment_Default_Bank_Account__c = component.find("bankSelector").get("v.value");

		component.find('createPaymentForm').submit(fields);
		$A.util.toggleClass(component.find("spinner"),"slds-hide");
	},

	/**
	* @description Method called when payment scheduler settings successfull saved
	*/
	handleSuccess: function(component, event, helper) {
		helper.calculatePayments(component, event);
	},
	
	/**
	* @description Method called when payments created sucessfully
	*/
	handleCreatePayments : function(component, event, helper) {
		$A.util.toggleClass(component.find("spinner"),"slds-hide");
		helper.createPayments(component, event);
	},
})