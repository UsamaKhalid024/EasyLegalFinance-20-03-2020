({
	doInit : function(component, event, helper) {
        component.set('v.selectedFilterDate', new Date().toISOString());
        helper.getScheduledPaymentsWithOpportunities(component, component.get('v.selectedFilterDate'), component.get('v.selectedWorkflowStage'));        
        helper.getPickListValues(component, 'Opportunity', 'Interest_Compounding_Period__c','interestCompoundingPeriod');
        helper.getPickListValues(component, 'Opportunity', 'Compounding_Interest__c','compoundingInterest');
        helper.getPickListValues(component, 'Opportunity', 'Fee_Calculation_Method__c','feeCalculationMethod');
        helper.getPickListValues(component, 'Opportunity', 'Minimum_Interest_Period__c','minimumInterestPeriod');
        helper.getPickListValues(component, 'Opportunity', 'Fixed_Amount__c','fixedAmount');   
        helper.getPickListValues(component, 'Opportunity', 'Interest_Deferral_Period__c', 'interestDeferralOptions');
        helper.getPickListValues(component, 'Opportunity', 'Funding_Details_Status__c','fundingDetailStatus');
        helper.getPickListValues(component, 'Drawdown__c', 'Reference_Notes__c','refNotesOptions');
        helper.getPickListValues(component, 'Drawdown__c', 'Payment_Method__c','paymentMethod');
    },

    removeAutocomplete: function(component, event, helper) {
        var elem = event.target; // Doesn't seem to actually resolve to focused input...
        elem.setAttribute("autocomplete", "off");

        /*
        var removeAutocompleteNames = ['FilterDate'];
        var inputs, input;
        for (var i = 0; i < removeAutocompleteNames.length; i++) {
            inputs = document.getElementsByName(removeAutocompleteNames[i]);
            for (var x = 0; i < inputs.length; i++) {
                input = inputs[x];
                if (input) {
                    input.setAttribute("autocomplete", "off");
                }
            }
        }
        */
    },
    
    refreshOpportunityList: function(component, event, helper){
        var filterStage = component.get("v.selectedWorkflowStage");
        var filterDate = component.get('v.selectedFilterDate');
        component.set("v.spinner", true);
        helper.getScheduledPaymentsWithOpportunities(component, filterDate, filterStage);
    },

    changeScheduledPaymentSelected : function(component, event, helper) {
        var index = event.currentTarget.dataset.idx;
        var selectedScheduledPayment = component.get("v.spList")[index]; // Use it retrieve the store record
        component.set("v.selectedScheduledPayment", selectedScheduledPayment);
    },

    saveOpportunity : function(component, event, helper) {
        component.set("v.spinner", true);
        helper.saveOpportunity(component, component.get("v.selectedOpportunity"));
    },
    
    markStatusAsComplete : function(component, event, helper){
        component.set("v.spinner", true);
        var selectedOpportunity = component.get("v.selectedOpportunity");
        var currentStage = selectedOpportunity.Funding_Details_Status__c;
        var nextStage = '';
        
        if(currentStage == 'EFT Set-Up'){
            nextStage = 'Loan Set-up Check'
        } else if(currentStage === 'Loan Set-up Check'){
            nextStage = 'Process Drawdowns';
        } else if(currentStage === 'Process Drawdowns'){
            nextStage = 'Populate PPSA';
        } else if(currentStage === 'Populate PPSA'){
            nextStage = 'Final Review';
        } else if(currentStage === 'Final Review'){
            nextStage = 'Closed';
        }
        
        if(nextStage != ''){
        	helper.changeFundingStatus(component, selectedOpportunity.Id, nextStage);
        } else {
            component.set("v.spinner", false);
        }
    },

    addNewDrawdown : function(component, event, helper){
        component.set("v.spinner", true);
        helper.addNewDrawdown(component);  
    }
})