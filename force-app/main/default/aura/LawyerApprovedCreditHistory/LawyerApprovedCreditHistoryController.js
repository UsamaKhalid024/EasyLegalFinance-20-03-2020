({
	doinit : function(component, event, helper) {
        
        component.set('v.Approvedcolumns', [
            {label: 'Updated By', fieldName: 'CreatedByName', type: 'text', sortable: true},
            {label: 'Old Value', fieldName: 'OldValue', type: 'currency', sortable: true},
            {label: 'Updated Value', fieldName: 'NewValue', type: 'currency', sortable: true},
            {label: 'Updated Date', fieldName: 'CreatedDate', type: 'date',typeAttributes: {
      			day: 'numeric',
      			month: 'short',
      			year: 'numeric',
      			hour: '2-digit',
      			minute: '2-digit',
      			second: '2-digit',
      			hour12: true
    		}, sortable: true}
        ]);
        
              
		helper.CreditHistoryHelper(component).then($A.getCallback(
            function(result){
                
                for (var i = 0; i < result.length; i++) {
                    var row = result[i];
                    if (row.CreatedBy) row.CreatedByName = row.CreatedBy.Name;
                    if (row.CreatedDate){
                        var date = new Date(row.CreatedDate);
                        row.CreatedDate = date;
                    }
                }
                //console.log(result);
                component.set("v.data", result);
                component.set("v.spinner", false);
                component.set("v.setdatatable", true);
            }
        )).catch(
            function(errors){
				console.log(errors);
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
    },
})