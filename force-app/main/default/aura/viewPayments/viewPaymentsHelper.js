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
	* @description  Helper method to fetch payments for opportunity
	**/
	fetchPayments : function(component,event) {
		var action = component.get("c.getPayments");
		action.setParams({
			opportunityId : component.get("v.recordId"),
			fieldSetName : component.get("v.fieldSetName")
		});
		this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
					component.set("v._recordsList",result.hasOwnProperty('records') ? result['records'] : new Array());
					component.set("v._columns",result.hasOwnProperty('columns') ? result['columns'] : new Array());
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