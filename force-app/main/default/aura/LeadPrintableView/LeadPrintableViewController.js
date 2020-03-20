({
	doInit : function(component, event, helper) {
		component.set("v.spinner", true);		        
		helper.getLeadInfo(component);		
	},
    
    doPrint : function(component, event, helper){
        window.print();
    }
})