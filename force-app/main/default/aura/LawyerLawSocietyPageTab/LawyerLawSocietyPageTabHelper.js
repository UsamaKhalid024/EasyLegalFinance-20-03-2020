({
	getLawyerInfo : function(component) {
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get("c.getLawyerInfo");
                action.setParams({
                    recordId : component.get("v.recordId")
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
    
    getContentNotes : function(component) {
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get("c.getContentNotes");
                action.setParams({
                    recordId : component.get("v.recordId")
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
    
    sortNotes : function(component,fieldName,sortDirection){
        var data = component.get("v.notes");
        var key = function(a) { return a[fieldName]; }
        var reverse = sortDirection == 'asc' ? 1: -1;
        
        data.sort(function(a,b){ 
            var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
            var b = key(b) ? key(b).toLowerCase() : '';
            return reverse * ((a>b) - (b>a));
        });
        
        
        component.set("v.notes",data);
    },
    
    errorsHandler : function(errors){
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message);
        }
    },
    
    showToast : function(title, message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})