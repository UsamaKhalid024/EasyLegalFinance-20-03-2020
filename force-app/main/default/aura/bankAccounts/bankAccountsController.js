({
	/**
	* @description Method to be called during component initalisation
	*/
	doInit: function(component,event,helper){
		helper.fetchBankAccounts(component,event);
		if (!component.get('v.historyFilters')) { // Don't override set filters
			component.set('v.historyFilters',  [ {'column': 'AccountId', 'operator': 'equals', 'value': component.get('v.recordId') } ])
		}
		component.set('v._historyUrl', `/lightning/r/Report/00O56000000eDESEA2/view?fv0=${component.get('v.recordId')}`)
    },
	
	/**
	* @description Method to handle when user click cancel button
	*/
	handleCancel: function(component,event,helper){
		component.find("overlayLib").notifyClose();
	},

	/**
	* @description Method to handle when user click New Button
	*/
	handleNewBankAccountForm : function(component,event,helper){
		component.set("v._createNewBankAccount",true);
	},

	/**
	* @description Method to handle when user clicks cancel Button
	*/
	handleNewBankAccountCancel : function(component,event,helper){
		component.set("v._createNewBankAccount",false);
		component.set("v._editBankAccount",false);
	},

	/**
	* @description Method to handle when the record submitted sucessfully
	*/
	handleCreateSubmit : function(component,event,helper){
		event.getParam("fields")['Client__c'] = component.get("v.recordId");
		component.find('createForm').submit(event.getParam("fields"));
		$A.util.addClass(component.find("spinner"),"slds-show"); 
	},

	/**
	* @description Method to handle when the record submitted sucessfully
	*/
	handleEditSubmit : function(component,event,helper){
		component.find('editForm').submit(event.getParam("fields"));
		$A.util.addClass(component.find("spinner"),"slds-show"); 
	},

	/**
	* @description Method to handle when the record saved sucessfully
	*/
	handleSuccess : function(component,event,helper){
		helper.fetchBankAccounts(component,event);
	},

    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');

        switch (action.name) {
            case 'edit':
				component.set('v._selectedId', row.Id)
				component.set('v._editBankAccount', true)
                break;
			case 'delete':
				if (confirm("Are you sure you want to delete this Bank Account?")) {
					helper.removeBankAccount(component, row);
				}
                break;
        }
	}

})