({
    getLeadInfo : function(component) {
        ///////////////////getting filed label maps///////////////////////////
        var fieldsMapAction = component.get('c.getLeadFieldsMap');
        component.set("v.spinner", true);
        fieldsMapAction.setCallback(this, function (response){
            var state = response.getState();
            if(state === 'SUCCESS')
            {
                //component.set("v.spinner", false);
                component.set('v.fieldLabels',response.getReturnValue());
            }
            else if (state ==='ERROR')
            {
                //component.set("v.spinner", false);
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
        $A.enqueueAction(fieldsMapAction); 
        
        ///////////////////////get picklist values////////////////////////////
        var picklistMapAction = component.get('c.getLeadPicklistData');
        component.set("v.spinner", true);
        picklistMapAction.setCallback(this, function (response){
            var state = response.getState();
            if(state === 'SUCCESS')
            {
                //component.set("v.spinner", false);
                component.set('v.pickListMap',response.getReturnValue());
            }
            else if (state ==='ERROR')
            {
                //component.set("v.spinner", false);
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
        $A.enqueueAction(picklistMapAction); 
        
        ///////////////////////get lead record data///////////////////////////
        
        var recordId = component.get("v.recordId");
        var action = component.get('c.getLeadInfo');             
        action.setParams({ leadId : recordId})
                        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
				component.set("v.leadObj", response.getReturnValue());                
                
                //setting lookups
				component.set("v.selectedLookUpFirm.Id",component.get("v.leadObj").Law_Firm_Name_new__c);
                component.set("v.selectedLookUpFirm.Name",(component.get("v.leadObj").Law_Firm_Name_new__c ? 
                                                           component.get("v.leadObj").Law_Firm_Name_new__r.Name : ''));
                component.set("v.selectedLookUpFirm.BillingCity",(component.get("v.leadObj").Law_Firm_Name_new__c ? 
                                                                  component.get("v.leadObj").Law_Firm_Name_new__r.BillingCity : ''));
                component.set("v.selectedLookUpFirm.BillingState",(component.get("v.leadObj").Law_Firm_Name_new__c ? 
                                                                   component.get("v.leadObj").Law_Firm_Name_new__r.BillingState : ''));
                
                component.set("v.selectedLookUpLawyer.Id",component.get("v.leadObj").Lawyer_Name_new__c);
                component.set("v.selectedLookUpLawyer.Name",(component.get("v.leadObj").Lawyer_Name_new__c ? 
                                                           component.get("v.leadObj").Lawyer_Name_new__r.Name : ''));
                component.set("v.selectedLookUpLawyer.Phone",(component.get("v.leadObj").Law_Phone__c));
                component.set("v.selectedLookUpLawyer.Email",(component.get("v.leadObj").Law_Email__c));
                
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
    
    deleteLead : function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.deleteLead');             
        action.setParams({ leadId : recordId})
                        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
				component.set("v.leadObj", response.getReturnValue());                
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
    
    getCalendarMin : function(component){
        var year = new Date().getFullYear() - 10;
        var min = year+'-01-01';
        component.set("v.calendarMin", min);                
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 10;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
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
    formatPhone: function(component, event, field){
        var obj = event.getParam("value");
        if(!obj)	return;
        if(typeof(obj) === 'object'){
            obj = obj[field];
        }
        if(typeof(obj) === 'string')
        {
            obj = obj.replace(/[^\d]+/g, '')
            .replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
            component.set("v.leadObj."+field, obj);
        }
    },
    getPickListValuesHelper: function(component, object, field, attributeId)
    {
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
 
                if (allValues != undefined && allValues.length > 0) {
                    opts.push({
                        class: "optionClass",
                        label: "--- None ---",
                        value: ""
                    });
                }
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
                component.set('v.'+attributeId, opts);
            }
        });
        $A.enqueueAction(picklistgetter);
    },
})