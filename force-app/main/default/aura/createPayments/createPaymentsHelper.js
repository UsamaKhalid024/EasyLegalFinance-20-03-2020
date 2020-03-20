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
	* @description Helper method to set the payment schedule mode from the input field
	**/
	paymentSchedulerModeChange : function(component,event) {
		component.set("v._paymentScheduleMode",component.find("paymentSchedulerMode").get("v.value"));
	},

	/**
	* @description Helper method to create payment schedule
	**/
	getBankAccountOptions: function(component) {
		var action = component.get("c.getBankAccountOptions");
		action.setParams({
			oppId: component.get("v.recordId")
		});
		this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
					var bankAccountOptions = result.map(ba => {
						return { value: ba.Id, label: ba.Name }
					});
					component.find("bankSelector").set("v.options", bankAccountOptions);
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
					}
			})
		);
	},

	/**
	* @description Helper method to create payment schedule
	**/
	calculatePayments : function(component,event) {
		var action = component.get("c.calculatePayments");
		action.setParams({
			opportunityId : component.get("v.recordId")
		});
		this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
					component.set("v._recordsList",result);
					component.set("v._columns",[
						{label:'Payment Date',fieldName:'Scheduled_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'}},
						{label:'Amount',fieldName:'Amount__c',type:'currency'}
					]);
					$A.util.toggleClass(component.find("spinner"),"slds-hide");
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
	
	/**
	* @description Helper method to create payment schedule
	**/
	createPayments : function(component,event) {
		var action = component.get("c.createPayments");
        var _this = this;
		action.setParams({
			opportunityId : component.get("v.recordId"),
			paymentsList : component.get("v._recordsList")
		});
		this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
					_this.firePaymentsChangedEvent(component);
					$A.util.toggleClass(component.find("spinner"),"slds-hide");
					component.find("overlayLib").notifyClose();
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

	firePaymentsChangedEvent: function (component) {
        component.find('pubsub').fireEvent(`scheduledpaymentschanged-${component.get('v.recordId')}`);
	}
})