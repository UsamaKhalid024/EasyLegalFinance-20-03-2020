({
	/**
	* @description Helper method which takes in action and creates promise around it
	* @param      action - action for which callback is set and promise is created around.
	**/
	promiseServerSideCall: function(action) {
		return new Promise(function(resolve, reject) {
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					resolve(response.getReturnValue());
				} else if (state === "ERROR") {
					var errors = response.getError();
					if (errors) {
						if (errors[0] && errors[0].message) {
							reject(Error(errors[0].message));
						}
					} else {
						reject(Error($A.get("Unknown Error")));
					}
				}
			});
			$A.enqueueAction(action);
		});
	},

	/**
	* @description  Helper method to fetch bank accounts for account
	**/
	fetchBankAccounts : function(component,event) {
		var action = component.get("c.getBankAccounts");
		action.setParams({
			accountId : component.get("v.recordId"),
			fieldSetName : component.get("v.fieldSetName")
		});
		this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
					component.set("v._recordsList",result.hasOwnProperty('records') ? result['records'] : new Array());
					var actions = [
						{ label: 'Edit', name: 'edit' },
						// { label: 'Delete', name: 'delete' } 
					]; 
					var columns = result['columns'] || [];
					columns.push({ type: 'action', typeAttributes: { rowActions: actions } });
					component.set("v._columns", columns);
					component.set("v._createNewBankAccount",false);
					component.set("v._editBankAccount",false);
					$A.util.addClass(component.find("spinner"),"slds-hide"); 
				})
			).catch(
				$A.getCallback(function(error){
					if(!$A.util.isEmpty(error)){
						var errorMessage = $A.get("e.force:showToast");
						errorMessage.setParams({
							"type" : "error",
							"message": error.message
						});
						errorMessage.fire();
						$A.util.toggleClass(component.find("spinner"),"slds-hide");
					}
			})
		);
	},

	removeBankAccount : function(component, row) {
		var action = component.get("c.removeBankAccount");
		action.setParams({
			bankAccountId : row.Id
		});
		var _this = this;
		this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
					_this.fetchBankAccounts(component);
				})
			).catch(
				$A.getCallback(function(error){
					if(!$A.util.isEmpty(error)){
						var errorMessage = $A.get("e.force:showToast");
						errorMessage.setParams({
							"type" : "error",
							"message": error.message
						});
						errorMessage.fire();
						$A.util.toggleClass(component.find("spinner"),"slds-hide");
					}
			})
		);
	},

})