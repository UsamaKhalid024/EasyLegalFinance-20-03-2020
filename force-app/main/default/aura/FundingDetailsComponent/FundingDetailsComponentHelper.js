({
    getScheduledPaymentsWithOpportunities : function(component, filterDate, workflowStage) {
        var p = new Promise( $A.getCallback( function( resolve , reject ) { 
            var action = component.get('c.getScheduledPaymentsWithOpportunities');
            action.setParams({ filterDate: filterDate, workflowStage: workflowStage });
            
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
                    var valuesMap = response.getReturnValue();
                    var spList = valuesMap.scheduled_payments;
                    var oppMap = valuesMap.opportunities;

                    // Set opportunity reference on Scheduled Payments
                    spList.forEach(sp => {
                        sp.opportunity = oppMap[sp.Opportunity__c];
                    });

                    component.set("v.spList", spList);  
                    component.set("v.oppMap", oppMap);  
                    component.set("v.spinner", false);
                    resolve(true);
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
                    reject(false);
                }
            });
            $A.enqueueAction(action);  
            console.log('refreshing now...');
        }));
        console.log('time to exit promise');
        return p;
    },

    getOpportunitiesList : function(component, filterDate, workflowStage) {
        var p = new Promise( $A.getCallback( function( resolve , reject ) { 
            var action = component.get('c.getOpportunities');
            action.setParams({ filterDate: filterDate, workflowStage: workflowStage });
            
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
                    component.set("v.oppList", response.getReturnValue());  
                    component.set("v.spinner", false);
                    resolve(true);
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
                    reject(false);
                }
            });
            $A.enqueueAction(action);  
            console.log('refreshing now...');
        }));
        console.log('time to exit promise');
        return p;
    },   
    
    getSingleOpportunity : function(component, oppId) {
        var action = component.get('c.getSingleOpportunity');             
        action.setParams({ oppId : oppId})
                        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
				component.set("v.selectedOpportunity", response.getReturnValue());
                var currentStage = response.getReturnValue().Funding_Details_Status__c;
                this.getDrawdownList(component, oppId);
                this.controlWorkflowStages(component, currentStage);
                component.set("v.spinner", false);
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

    saveOpportunity : function(component, opp) {
        var action = component.get('c.updateOpportunity');             
        action.setParams({ opp : opp})
                        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
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

    
    getDrawdownList : function(component, oppId) {
        if (!oppId) {
            oppId = component.get('v.selectedOpportunity').Id;
        }
        var action = component.get('c.getDrawdownsByOpp');             
        action.setParams({ oppId : oppId})
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.drawDownList", response.getReturnValue());                
            } else if (state === 'ERROR') {
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

    addNewDrawdown : function(component) {
        component.set("v.spinner", true); 
        var recordId = component.get('v.selectedOpportunity').Id;
        var drawDownList = component.get('v.drawDownList');
        var action = component.get('c.insertNewDrawdown');             
        action.setParams({oppId : recordId});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {                
                this.getDrawdownList(component);
                component.set("v.spinner", false);
                /*component.set("v.drawDownList", response.getReturnValue());
                console.log('------');
                console.log(response.getReturnValue());
                console.log('------');*/
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
            // this.getRefNotesDependantPicklistMapAsync(component, 'drawDownObj', 'referenceNotesDepPicklistMap');
        });
        $A.enqueueAction(action);        
    },  
    
    changeFundingStatus : function(component, oppId, nextStage) {
        var action = component.get('c.changeFundingStatus');             
        action.setParams({ oppId : oppId, nextStage : nextStage})
                        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
				component.set("v.selectedOpportunity", response.getReturnValue());                           
                var currentStage = response.getReturnValue().Funding_Details_Status__c;
                this.controlWorkflowStages(component, currentStage);
                component.set("v.spinner", false);
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
    
    controlWorkflowStages: function(component, currentStage){
        if(currentStage == 'EFT Set-Up'){
			component.set("v.stageEFTSetUp", "slds-path__item slds-is-current slds-is-active");
            component.set("v.stageLoanSetUp", "slds-path__item slds-is-incomplete");            
            component.set("v.stageProcessDrawdowns", "slds-path__item slds-is-incomplete");            
            component.set("v.stagePopulatePPSA", "slds-path__item slds-is-incomplete");            
            component.set("v.stageCloseTransaction", "slds-path__item slds-is-incomplete");            
            component.set("v.stageClosed", "slds-path__item slds-is-incomplete");     	
        } else if(currentStage == 'Loan Set-up Check'){
            component.set("v.stageEFTSetUp", "slds-path__item slds-is-complete");
            component.set("v.stageLoanSetUp", "slds-path__item slds-is-current slds-is-active");
            component.set("v.stageProcessDrawdowns", "slds-path__item slds-is-incomplete");            
            component.set("v.stagePopulatePPSA", "slds-path__item slds-is-incomplete");            
            component.set("v.stageCloseTransaction", "slds-path__item slds-is-incomplete");            
            component.set("v.stageClosed", "slds-path__item slds-is-incomplete");            
        } else if(currentStage == 'Process Drawdowns'){
            component.set("v.stageEFTSetUp", "slds-path__item slds-is-complete");
            component.set("v.stageLoanSetUp", "slds-path__item slds-is-complete");
            component.set("v.stageProcessDrawdowns", "slds-path__item slds-is-current slds-is-active");
            component.set("v.stagePopulatePPSA", "slds-path__item slds-is-incomplete");            
            component.set("v.stageCloseTransaction", "slds-path__item slds-is-incomplete");            
            component.set("v.stageClosed", "slds-path__item slds-is-incomplete");               
        } else if(currentStage == 'Populate PPSA'){
            component.set("v.stageEFTSetUp", "slds-path__item slds-is-complete");
            component.set("v.stageLoanSetUp", "slds-path__item slds-is-complete");
            component.set("v.stageProcessDrawdowns", "slds-path__item slds-is-complete");
            component.set("v.stagePopulatePPSA", "slds-path__item slds-is-current slds-is-active");            
            component.set("v.stageCloseTransaction", "slds-path__item slds-is-incomplete");            
            component.set("v.stageClosed", "slds-path__item slds-is-incomplete");               
        } else if(currentStage == 'Final Review'){
            component.set("v.stageEFTSetUp", "slds-path__item slds-is-complete");
            component.set("v.stageLoanSetUp", "slds-path__item slds-is-complete");
            component.set("v.stageProcessDrawdowns", "slds-path__item slds-is-complete");
            component.set("v.stagePopulatePPSA", "slds-path__item slds-is-complete");
            component.set("v.stageCloseTransaction", "slds-path__item slds-is-current slds-is-active");          
            component.set("v.stageClosed", "slds-path__item slds-is-incomplete");               
        } else if(currentStage == 'Closed'){
            component.set("v.stageEFTSetUp", "slds-path__item slds-is-complete");
            component.set("v.stageLoanSetUp", "slds-path__item slds-is-complete");
            component.set("v.stageProcessDrawdowns", "slds-path__item slds-is-complete");
            component.set("v.stagePopulatePPSA", "slds-path__item slds-is-complete");
            component.set("v.stageCloseTransaction", "slds-path__item slds-is-complete");
            component.set("v.stageClosed", "slds-path__item slds-is-current slds-is-active");
        } 

        //slds-is-current slds-is-active
        //slds-is-complete
        //slds-is-incomplete
    
	},    
    
    getPickListValues: function(component, object, field, attributeId){
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
    }    
})