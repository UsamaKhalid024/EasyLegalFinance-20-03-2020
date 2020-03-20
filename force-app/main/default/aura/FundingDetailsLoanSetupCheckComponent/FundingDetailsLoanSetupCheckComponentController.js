({
    doInit : function(component, event, helper) {

        // Set fields that will be edited in form
        var fields = [
            'Interest_Rate__c',
            'Interest_Compounding_Period__c',
            'Compounding_Interest__c',
            'Fee_Calculation_Method__c',
            'Fixed_Amount__c',
            'Percent_Amount__c',
            'Custommized_Amount__c',
            'Minimum_Interest_Period__c',
            'Interest_Deferral_Period__c'
        ];
        component.set('v.fields', fields);
        component.set('v.disabled', helper.setDisabled(component));
    },

    setDisabled : function(component, event, helper) {
        if (component.get("v.selectedOpportunity").Id !== component.get("v.selectedOpportunityId")) {
            component.set('v.disabled', helper.setDisabled(component));
            component.set("v.selectedOpportunityId", component.get("v.selectedOpportunity").Id);
        }
    },

    saveOpportunity : function(component, event, helper) {
		$A.util.toggleClass(component.find("spinner"),"slds-hide");
        helper.saveOpportunity(component, component.get("v.selectedOpportunity"));
    }
})