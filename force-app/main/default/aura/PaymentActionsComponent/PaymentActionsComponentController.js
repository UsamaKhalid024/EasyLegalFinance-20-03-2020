({
	doInit : function(component, event, helper) {        
		helper.getOpportunityActions(component);
        var oppId = component.get('v.oppId');
        helper.handleChange(component, '');
        helper.selectSingleOption(component);
	},
    handleChange : function(component, event, helper){
    	helper.handleChange(component, event.getParam('value'));
	},
    
})