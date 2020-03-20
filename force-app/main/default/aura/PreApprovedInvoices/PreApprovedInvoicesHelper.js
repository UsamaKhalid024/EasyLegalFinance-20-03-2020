({
	getCalendarMin : function(component){
        var year = new Date().getFullYear() - 1;
        //var min = year+'-01-01';
        var min = '2010-01-01';
        component.set("v.calendarMin", min);                  
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 5;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    
    getPickListValues : function(component, object, field, attributeId){
        var picklistgetter = component.get('c.getPickListValues');
        picklistgetter.setParams({
            objectType: object,
            field: field
        });
        picklistgetter.setCallback(this, function(response){
            var opts = [];
            if(response.getState() == 'SUCCESS')
            {
                var allValues = response.getReturnValue();
                for (var i = 0; i < allValues.length; i++) {
                    if(allValues[i].includes('===SEPERATOR==='))
                    {
                        opts.push({
                            class: "optionClass",
                            label: allValues[i].split('===SEPERATOR===')[0],
                            value: allValues[i].split('===SEPERATOR===')[1]
                        });
                    }
                    else
                    {
                        opts.push({
                            class: "optionClass",
                            label: allValues[i],
                            value: allValues[i]
                        });
                    }
                }
                opts.push({
                    class: "optionClass",
                    label: 'Consolidated',
                    value: 'Consolidated'
                });                
                component.set('v.'+attributeId, opts);
            }
        });
        $A.enqueueAction(picklistgetter);
    },
    
    getPreApprovedInvoices : function(component){
        return new Promise($A.getCallback(
            function(resolve, reject){
                let action = component.get("c.getPreApprovedInvoices");
                action.setParams({
                    searchByName : component.get("v.searchByName"),
                    BusinessUnit : component.get("v.selectedBusinessUnitFilter"),
                    field : component.get("v.sortField"),
                    direction : component.get("v.sortOrder")
                });
                
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state == "SUCCESS"){
                        resolve(response.getReturnValue());
                    }else if(state == "ERROR"){
                        reject(response.getError());
                    }
                });
                
                $A.enqueueAction(action);
            }
        ));
    },
    
    errorsHandler : function(errors){
        if(errors){
            if (errors[0] && errors[0].message) {
                console.log('Error message: ' + errors[0].message);
                this.showToast('Error', errors[0].message, 'error');
            }else{
                this.showToast('Error', JSON.stringify(errors), 'error');
            }
        }else
            this.showToast('Error', 'Unknown Error!', 'error');
    },
    
    showToast : function(title, message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
})