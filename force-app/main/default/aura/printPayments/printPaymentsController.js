({
	/**
	* @description Method to be called during component initalisation
	*/
	doInit: function(component,event,helper){
		helper.fetchPayments(component,event);
	},

	/**
	* @description Method to handle when user click cancel button
	*/
	handleCancel: function(component,event,helper){
		component.find("overlayLib").notifyClose();
	},
})