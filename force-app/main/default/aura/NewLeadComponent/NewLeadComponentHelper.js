({
    getLeadInfo : function(component) {
        ///////////////////getting filed label maps///////////////////////////
        var fieldsMapAction = component.get('c.getLeadFieldsMap');
        
        component.set("v.spinner", true);
        fieldsMapAction.setCallback(this, function (response){
            component.set("v.spinner", false);
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
            component.set("v.spinner", false);
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
        /*
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
                
                component.set("v.selectedLookUpLawyer.Id",component.get("v.leadObj").Lawyer_Name_new__c);
                component.set("v.selectedLookUpLawyer.Name",(component.get("v.leadObj").Lawyer_Name_new__c ? 
                                                           component.get("v.leadObj").Lawyer_Name_new__r.Name : ''));
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
        */
        
    },
    
    
    errorsHandler : function(errors){
        alert('error'+errors[0].message);
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
    /*errorHandlingController.js*/
    
    validateRequired : function(component, Id) {
        var inputCmp = component.find(Id);
        var value = inputCmp.get("v.value");
        if (!value || value === "") {
            // Set error
            this.showToast('ERROR', 'Check errors on respective fields!', 'ERROR');
            inputCmp.showHelpMessageIfInvalid();
            //inputCmp.set("v.errors", [{message:"Field is required."}]);
            return false;
        } else {
            // Clear error
            //inputCmp.set("v.errors", null);
            return true;
        }
    },
    validateCheckboxes : function(component, Id) {
        var inputCmp = component.find(Id);
        var value = component.get("v.leadObj."+Id);
        if (!value || value === "") {
            // Set error
            this.showToast('ERROR', component.get('v.fieldLabels.'+Id)+' is required', 'ERROR');
            return false;
        } else {
            // Clear error
            return true;
        }
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
    getRecordTypes: function(component) {
        var getRecordTypeMapAction = component.get('c.getRecordTypeMap');
        component.set("v.spinner", true);
        getRecordTypeMapAction.setCallback(this, function (response){
            component.set("v.spinner", false);
            var state = response.getState();
            if(state === 'SUCCESS')
            {
                //component.set("v.spinner", false);
                //console.log('RecordType Start');
                //console.log(response.getReturnValue());
                //console.log('RecordType End');
                //console.log('Map Triverse');
                var myMap = response.getReturnValue()
                var value;
                var arr = [];
				Object.keys(myMap).forEach(function(key) {
    				value = myMap[key];
    				console.log(key + ' -- ' + value);
                    arr.push({'label' : value, 'value': key});
                    
				});
                console.log(arr);
                component.set('v.RecordTypeOptions',arr);
                component.set('v.selectedRecordTypeValue',arr[0].value);
                component.set('v.leadRecordTypes',response.getReturnValue());
                component.set('v.showRecordTypePopup', true);
                if(arr.length == 0)
                {
                    component.set('v.showRecordTypePopup', false);
                }
            }
            else if (state ==='ERROR')
            {
                component.set('v.showRecordTypePopup', false);
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
        $A.enqueueAction(getRecordTypeMapAction); 
    },
    
    getPickListValuesHelper: function(component, object, field, attributeId)
    {
        console.log("here");
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