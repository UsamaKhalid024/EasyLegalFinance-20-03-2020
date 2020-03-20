({
    doInit : function(component, event, helper) {
        component.set("v.spinner", true);
        
        component.set('v.columns', [
            {label: 'Assessment Provider', fieldName: 'linkProvider', type: 'url', typeAttributes: {label: { fieldName: 'Assessment_ProviderName' }, target: '_blank'}, sortable: true},
            {label: 'Invoice Discount', fieldName: 'discount', type: 'percent', typeAttributes:{minimumFractionDigits : '2'}, sortable: true},
            {label: 'Client Rebate', fieldName: 'rebateDiscount', type: 'percent', typeAttributes:{minimumFractionDigits : '2'}, sortable: true},
            {label: 'Rebate Period', fieldName: 'Rebate_Period__c', type: 'text', sortable: true},
            {label: 'Created Date', fieldName: 'CreatedDate', type: 'date', cellAttributes: { alignment: 'right' }, typeAttributes:{ year : "numeric", month: "long", day:"2-digit"} ,sortable: true},
            {label: 'Created By', fieldName: 'CreatedByName', type: 'text', sortable: true}
        ]);
        
        helper.getAssessmentSchedules(component).then(
            function(result){                
                component.set("v.data", result);
            }
        ).then(
            function(){
                helper.sortData(component,component.get("v.sortBy"),component.get("v.sortDirection"));
                component.set("v.datatableIsSet", true);
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(component, errors);
            }
        );
    },
    handleSort : function(component,event,helper){
        //Returns the field which has to be sorted
        var sortBy = event.getParam("fieldName");
        //returns the direction of sorting like asc or desc
        var sortDirection = event.getParam("sortDirection");
        //Set the sortBy and SortDirection attributes
        component.set("v.sortBy",sortBy);
        component.set("v.sortDirection",sortDirection);
        // call sortData helper function
        helper.sortData(component,sortBy,sortDirection);
    }
})