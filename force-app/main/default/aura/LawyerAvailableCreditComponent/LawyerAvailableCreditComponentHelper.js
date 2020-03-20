({
    getCurrentUserInfo : function(component) {
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get("c.getCurrentUserInfo");
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        resolve(response.getReturnValue());
                    }else if(state === 'ERROR'){
                        reject(response.getError());
                    }                   
                });
                $A.enqueueAction(action);
            }
        ));
    },
    getLawyerRecordData : function(component){
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get("c.getLawyerRecordData");
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
    updateLawyerRecord : function(component){
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get("c.updateLawyerRecord");
                action.setParams({
                    lawyerContact : component.get("v.Lawyer")
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