({
	doinit : function(component, event, helper) {
        component.set('v.OpportunityAssessmentColumns', [
            {label: 'Opportunity Name', fieldName: 'linkName', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}, sortable: true},
            {label: 'Paid', fieldName: 'Principal_Repaid_Roll_up__c', type: 'currency', sortable: true},
            {label: 'Invoice Total', fieldName: 'Drawdown_Total_wo_Payment__c', type: 'currency', sortable: true},            
            {label: 'Outstanding', fieldName: 'Outstanding', type: 'currency', sortable: true}
        ]);
        helper.OppoAssessHelper(component).then($A.getCallback(
            function(result){
                component.set("v.OpportunityAssessmentdata", result);
                component.set("v.spinner", false);
                component.set("v.setdatatable", true);
            }
        )).catch(
            function(errors){
                console.log(errors);
            }
        );
	},
    handleAssessmentSort : function(component,event,helper){
        //Returns the field which has to be sorted
        var sortBy = event.getParam("fieldName");
        //returns the direction of sorting like asc or desc
        var sortDirection = event.getParam("sortDirection");
        //Set the sortBy and SortDirection attributes
        component.set("v.sortBy",sortBy);
        component.set("v.sortDirection",sortDirection);
        // call sortData helper function
        helper.sortAssessmentData(component,sortBy,sortDirection);
    }
})