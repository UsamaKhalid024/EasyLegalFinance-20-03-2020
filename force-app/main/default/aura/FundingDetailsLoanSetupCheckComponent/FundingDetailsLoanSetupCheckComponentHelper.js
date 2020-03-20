({
    setDisabled : function(component) {
        var fields = component.get('v.fields');
        var disabled = {};
        var selectedOpportunity = component.get('v.selectedOpportunity');
        for (var i = 0; i < fields.length; i++) {
            // Allow edits when field value is blank, null, etc... otherwise mark as readonly
            disabled[fields[i]] = !!selectedOpportunity[fields[i]];
        }
        return disabled;
        //component.set('v.disabled', disabled);
    },

    saveOpportunity : function(component, opp) {
        var action = component.get('c.updateOpportunity');             
        action.setParams({ opp : opp})
                        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.selectedOpportunity", response.getReturnValue());
                this.showToast('Success', "The loan information was successfully updated", "success");
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);        
    },

    showToast : function(title, message, type, mode) {
        mode = mode || 'dismissible';
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "mode": mode
        });
        toastEvent.fire();
    },    
    
    errorsHandler : function(errors){
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message);
        }
    },
    
    unknownErrorsHandler : function(){
        console.log('Unknown error');
        this.showToast('Error', 'Unknown error'); 
    }
})