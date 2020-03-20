({
	/**
	* @description Method to handle when user click cancel button
	*/
	handleCancel: function(component,event,helper){
		component.find("overlayLib").notifyClose();
	},
})