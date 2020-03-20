({
	getAssessmentSchedules : function(component) {
		return new Promise($A.getCallback(
            function(resolve, reject){
                let action = component.get("c.getAssessmentSchedulesByLawyer");
                
                action.setParams({
                    lawyerId : component.get("v.recordId")
                });
                
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state == 'SUCCESS'){
                        var records =response.getReturnValue();
                        records.forEach(function(record){
                            record.linkName = '/'+record.Id;
                            record.linkProvider = '/' + record.Assessment_Provider__c;
                            record.Assessment_ProviderName = record.Assessment_Provider__r.Name;
                            record.discount = record.Discount__c / 100;
                            record.LastModifiedByName = record.LastModifiedBy.Name;
                            record.CreatedByName = record.CreatedBy.Name;
                            record.rebateDiscount = record.Rebate_Discount__c/100;
                        });
                        resolve(records);
                    }else if(state == 'ERROR'){
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
	},
    errorsHandler : function(component, errors){
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast(component, 'Error', errors[0].message);
        }
    },
    
    showToast : function(component, title, message, type) {
        component.find('notifLib').showToast({
            "variant": type,
            "title": title,
            "message": message
        });
    },
    sortData : function(component,fieldName,sortDirection){
        var data = component.get("v.data");
        var key = function(a) { return a[fieldName]; }
        var reverse = sortDirection == 'asc' ? 1: -1;
        
        if(fieldName == "discount" || fieldName == "rebateDiscount"){
            
            data.sort(function(a,b){ 
                var a = key(a);
                var b = key(b);
                return reverse * ((a>b) - (b>a));
            });
            
        } else {
            data.sort(function(a,b){ 
                var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
                var b = key(b) ? key(b).toLowerCase() : '';
                return reverse * ((a>b) - (b>a));
            });
        }
        
        component.set("v.data",data);
    }
})