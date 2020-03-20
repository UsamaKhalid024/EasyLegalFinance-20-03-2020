({
	OppoAssessHelper : function(component){
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.OpportunityAssessment');
                action.setParams({
                    LawyerRecordId : component.get('v.recordId')
                });
                action.setCallback(this,function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        var records =response.getReturnValue();
                        records.forEach(function(record){
                            record.linkName = '/'+record.Id;
                            record.Outstanding = (record.Drawdown_Total_wo_Payment__c) - record.Principal_Repaid_Roll_up__c;
                        });
                        resolve(records);
                    }else if(state === 'ERROR'){
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    },
    sortAssessmentData : function(component,fieldName,sortDirection){
        var data = component.get("v.OpportunityAssessmentdata");
        var key = function(a) { return a[fieldName]; }
        var reverse = sortDirection == 'asc' ? 1: -1;
		console.log('sortAssessmentData'+fieldName);
        
        if(fieldName == "Outstanding" || fieldName == "Drawdown_Total_wo_Payment__c" || fieldName == "Principal_Repaid_Roll_up__c"){
            
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
 
        component.set("v.OpportunityAssessmentdata",data);
    }
})