/* eslint-disable no-unused-expressions */
({
    getOpportunityInfo : function(component) {
        let self = this;
        return new Promise($A.getCallback( function(resolve, reject){
            var recordId = component.get("v.recordId");
            var accountId = component.get("v.accountId");
            var action = component.get('c.getOpportunityDetails');             
            action.setParams(
                {
                    oppId : recordId,
                    accId: accountId
                });
            
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
                    component.set("v.oppObj", response.getReturnValue()); 
                    
                    //setting lookups
                    component.set("v.selectedLookUpAssignedTo.Id", component.get("v.oppObj").Assigned_To__c);
                    component.set("v.selectedLookUpAssignedTo.Name",(component.get("v.oppObj").Assigned_To__c ? 
                                                                     component.get("v.oppObj").Assigned_To__r.Name : ''));
                    
                    //setting lookups
                    component.set("v.selectedLookUpPrimaryContact.Id", component.get("v.oppObj").Primary_Contact__c);
                    component.set("v.selectedLookUpPrimaryContact.Name",(component.get("v.oppObj").Primary_Contact__c ? 
                                                                         component.get("v.oppObj").Primary_Contact__r.Name : '')); 
                    
                    //setting lookups
                    component.set("v.selectedLookUpOwner.Id", component.get("v.oppObj").OwnerId);
                    component.set("v.selectedLookUpOwner.Name",(component.get("v.oppObj").OwnerId ? 
                                                                component.get("v.oppObj").Owner.Name : ''));

                    //setting lookups
                    component.set("v.selectedLookUpAssessmentProvider.Id", component.get("v.oppObj").Assessment_Provider__c);
                    console.log('-' + component.get("v.oppObj").Assessment_Provider__c + '-');
                    component.set("v.selectedLookUpAssessmentProvider.Name",(component.get("v.oppObj").Assessment_Provider__c != null && component.get("v.oppObj").Assessment_Provider__c != ''? 
                                                                         component.get("v.oppObj").Assessment_Provider__r.Name : '')); 
                    

                                                                
                    //set restrictCommunication
                    component.set("v.restrictCommunication", component.get("v.oppObj").Restrict_Communication__c? 'Yes' : 'No');
                    
                    self.firePaymentsChangedEvent(component);
                    resolve(true);
                    
                } else if (state === 'ERROR') {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            self.errorsHandler(errors)
                        }
                    } else {
                        self.unknownErrorsHandler();
                    }
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
            
        }));
                
    },
    validateRequired : function(component, Id) {
        var inputCmp = component.find(Id);
        if(!inputCmp)
        {
            return false;
        }
        var value = inputCmp.get("v.value");
        console.log('FM: value: '+value);
        if (!value || value === "") {
            // Set error
            this.showToast('ERROR', 'Check errors on respective fields!', 'ERROR');
            try{
                inputCmp.set("v.errors", [{message:"Field is required."}]);
            }
            catch(e){}
            //inputCmp.set('v.validity', {valid:false, badInput :true, message:'Field is required.'});
            console.log('false');
            return false;
        } else {
            // Clear error
            //inputCmp.set("v.errors", null);
            //inputCmp.set('v.validity', {valid:true});
            console.log('true');
            return true;
        }
    },
    getSingleContactHistory : function(component) {
        var accountId = component.get("v.accountId");
        var action = component.get('c.getContactHistory');             
        action.setParams({ accountId : accountId});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.contactHistory", response.getReturnValue());                
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
    /*getCriticalDatesList : function(component){
        let promise = new Promise($A.getCallback( function(resolve, reject){
            
            component.set("v.spinner", true);
            
            let recordId = component.get("v.recordId");
            let action = component.get('c.getCriticalDatesList');             
            action.setParams({ accountId : component.get("v.accountId")});
			
            action.setCallback(this, function(response){
                let state = response.getState();
                if (state === 'SUCCESS'){                    
                    component.set("v.criticalDateList", response.getReturnValue());
                    component.set("v.spinner", false);
                    resolve(true);
                    
                }else if (state === 'ERROR'){
                    
                    component.set("v.spinner", false);
                    let errors = response.getError();
                    reject(errors);
                    
                }                
            });
            $A.enqueueAction(action);
        }));
        
        return promise;
    },*/
    
    getDrawdownList : function(component, fetchRefNotes) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getDrawdownList');             
        action.setParams({ oppId : recordId});

        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {                
                let drawDownList = response.getReturnValue();
                let loanType = component.get("v.oppObj").Type_of_Loan__c;
                if (loanType && loanType.startsWith('Treatment')) {
                    let nonServiceProviderDrawdowns = [];
                    drawDownList.forEach(dd => {
                        if (!dd.Opportunity_Service_Provider__c) {
                            nonServiceProviderDrawdowns.push(dd);
                        }
                    });
                    component.set("v.drawDownList", nonServiceProviderDrawdowns);
                }
                else {
                    component.set("v.drawDownList", drawDownList);                
                }
                drawDownList = component.get('v.drawDownList');
                if (fetchRefNotes === true) {
                    for(let i = 0 ; i < drawDownList.length ; i++)
                    {
                        let newPaymentMethod = drawDownList[i].Payment_Method__c;
                        this.fetchRefNotesDepValues(component, newPaymentMethod, i);
                    }
                }
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
    
    getDrawdownPaymentsList : function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getDrawdownPaymentsList');             
        action.setParams({ oppId : recordId});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.drawDownPaymentsList", response.getReturnValue());                
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
    
    updateDrawdownList : function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getDrawdownList');             
        action.setParams({ oppId : recordId});

        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {                             
                let drawdowns = component.get("v.drawDownList");
                let updatedDrawdowns = response.getReturnValue();
                drawdowns.forEach(dd => {
                    console.log(dd.Id);
					const selectedDrawdowns = updatedDrawdowns.filter(updatedDrawdown => updatedDrawdown.Id == dd.Id);
                    console.log(selectedDrawdowns);  
                    if (selectedDrawdowns.length == 1 ){                                                          
                    	dd.Can_Be_Reversed__c = selectedDrawdowns[0].Can_Be_Reversed__c;
                    	console.log(selectedDrawdowns[0].Can_Be_Reversed__c);
                	}                
                });
                component.set("v.drawDownList", drawdowns);
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
    
    saveDrawdowns : function(component) {
        var drawDowns = component.get("v.drawDownList");
        this.saveDrawdownsCallout(component, drawDowns);
    },

    saveDrawdownsAndUpdateList : function(component) {
        var drawDowns = component.get("v.drawDownList");
        this.saveDrawdownsCallout(component, drawDowns, true);
    },                    
    
    saveDrawdownsCallout : function(component, drawDowns, updateListNeeded) {
        var drawDowns = component.get("v.drawDownList");
        var action = component.get('c.saveNewDrawdownList');             
        action.setParams({ drawDownNewList : drawDowns});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                this.getOpportunityInfo(component);  
                if (updateListNeeded)
                	this.updateDrawdownList(component);
                else
                    component.set("v.spinner", false);                
                //component.set("v.drawDownList", []); 
                //this.getDrawdownList(component, true);                                
                //component.set("v.spinner", false);                
                this.showToast('SUCCESS','Your changes were successfully saved!','SUCCESS');                
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
    
    
    savePaymentDrawdowns : function(component) {
        var drawDowns = component.get("v.drawDownPaymentsList");
        var action = component.get('c.saveNewDrawdownList');             
        action.setParams({ drawDownNewList : drawDowns});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                this.getOpportunityInfo(component);
                component.set("v.spinner", false);                
                this.showToast('SUCCESS','Your changes were successfully saved!','SUCCESS');	                
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
    
    /*saveCriticalDates : function(component) {
        
        let promise = new Promise($A.getCallback(function (resolve, reject){
            let criticalDates = component.get('v.criticalDateList');
            let action = component.get('c.saveCriticalDateList');
            action.setParams({criticalDateList: criticalDates});
            
            action.setCallback(this, function(response){
                let state = response.getState();
                
                if(state === 'SUCCESS'){
                    component.set("v.spinner", false);
                    resolve('Your changes were successfully saved!');                    
                }else if(state === 'ERROR'){
                    component.set("v.spinner", false);
                	let errors = response.getError();
                    reject(errors);
                }                
            });
            $A.enqueueAction(action);                 
        }));
        
        return promise;
    },*/
    
    /*addNewCriticalDate : function(component){
        component.set("v.spinner", true);
        
        let todayDate = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        let criticalDateList = component.get('v.criticalDateList');
        criticalDateList.push({'sobjectType':'Critical_Date__c', 'Id': null, 'Date__c': todayDate, 'Account__c': component.get("v.accountId")});
        
        component.set("v.criticalDateList", criticalDateList);       
        component.set("v.spinner", false);
    },*/
    
    addNewDrawdown : function(component) {
        component.set("v.spinner", true); 
        var recordId = component.get('v.recordId');
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
            this.getRefNotesDependantPicklistMapAsync(component, 'drawDownObj', 'referenceNotesDepPicklistMap');
        });
        $A.enqueueAction(action);        
    },  

    addNewPaymentDrawdown : function(component) {
        component.set("v.spinner", true); 
        var recordId = component.get('v.recordId');
        var drawDownList = component.get('v.drawDownList');
        var action = component.get('c.insertNewPaymentDrawdown');             
        action.setParams({oppId : recordId});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {                
                this.getDrawdownPaymentsList(component);
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
            this.getRefNotesDependantPicklistMapAsync(component, 'drawDownObj', 'referenceNotesDepPicklistMap');
        });
        $A.enqueueAction(action);        
    }, 
    
    addNewServiceProviderDrawdown : function(component, itemDescription) {
        var recordId = component.get('v.recordId');
        var action = component.get('c.insertNewServiceProviderDrawdown');             
        action.setParams({ oppId : recordId, serviceId : itemDescription});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                this.getServiceProvidersList(component);
                component.set("v.spinner", false);
                //component.set("v.serviceProviderList", response.getReturnValue()); 
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
    
    /*deleteCriticalDateItem : function(component, itemIndex) {
        component.set("v.spinner", true);
        let promise = new Promise($A.getCallback(
            (resolve, reject) => {
                let criticalDateList = component.get('v.criticalDateList');
                if(criticalDateList[itemIndex].Id != null){
                	let action = component.get('c.deleteCriticalDate');
                	action.setParams({recordId: criticalDateList[itemIndex].Id});
                    action.setCallback(this, function(response){
            			let state = response.getState();
            			if(state === 'SUCCESS'){
                            
                            criticalDateList.splice(itemIndex,1);
                            component.set('v.criticalDateList',criticalDateList);
                            component.set("v.spinner", false);
                            resolve("Record is deleted successfully!");
                            
                        }else if(state === 'ERROR'){
                            component.set("v.spinner", false);
                            reject(response.getError());
                        }
        			});
        			$A.enqueueAction(action);
            
                }else{
                    criticalDateList.splice(itemIndex,1);
                    component.set('v.criticalDateList',criticalDateList);
        			resolve("Record deleted Successfully!");
        			component.set("v.spinner", false);
                }
            }
        ));
		return promise;
    },*/    
    
    deleteDrawdownItem : function(component, itemDescription) {
        var recordId = component.get('v.recordId');
        var action = component.get('c.deleteDrawdownRecord');             
        action.setParams({ drawdownId : itemDescription, oppId : recordId});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                this.reInitSomeData(component);                 
                component.set("v.spinner", false);      
                this.showToast('SUCCESS','Drawdown was successfully deleted!','SUCCESS');
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
            this.getRefNotesDependantPicklistMapAsync(component, 'drawDownObj', 'referenceNotesDepPicklistMap');
        });
        $A.enqueueAction(action);        
    }, 
    
    deleteServiceProviderDrawdownItem : function(component, itemDescription) {
        var recordId = component.get('v.recordId');
        var action = component.get('c.deleteServiceProviderDrawdownRecord');             
        action.setParams({ drawdownId : itemDescription, oppId : recordId});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                this.reInitSomeData(component); 
                //this.getOpportunityInfo(component);
                component.set("v.spinner", false); 
                //component.set("v.serviceProviderList", response.getReturnValue()); 
                this.showToast('SUCCESS','Drawdown was successfully deleted!','SUCCESS');
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
    
    saveReassessments : function(component) {
        var reassessments = component.get("v.reAssessmentOppList");
        var action = component.get('c.saveReassessmentsList');             
        action.setParams({ reAssessmentList : reassessments});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                //alert('Your changes were successfully saved!');
                this.showToast('SUCCESS','Your changes were successfully saved!','SUCCESS');
                
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
    
    deleteReassessment : function(component, itemDescription) {
        var recordId = component.get('v.recordId');
        var action = component.get('c.deleteReassessments');             
        action.setParams({ reassessmentsId : itemDescription, oppId : recordId});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.spinner", false); 
                component.set("v.reAssessmentOppList", response.getReturnValue()); 
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
    
    deleteTreatment : function(component, itemDescription) {
        var oppId = component.get('v.recordId');
        var action = component.get('c.deleteTreatmentItem');             
        action.setParams({ treatmentId : itemDescription, oppId : oppId});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                this.getOpportunityInfo(component);
                component.set("v.spinner", false); 
                component.set("v.serviceProviderList", response.getReturnValue()); 
                this.showToast('SUCCESS','Treatment provider was successfully deleted!','SUCCESS');
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
    
    
    addTreatment : function(component, firm) {
        var oppId = component.get('v.recordId');
        var action = component.get('c.addTreatmentItem');             
        action.setParams({oppId : oppId, firm : firm});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.spinner", false); 
                component.set("v.serviceProviderList", response.getReturnValue()); 
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
    
    getServiceProvidersList : function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getServiceProviders');             
        action.setParams({ oppId : recordId});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.serviceProviderList", response.getReturnValue()); 
                
                if(response.getReturnValue() != null && response.getReturnValue() != ''){
                	this.fetchTreatmentRefNotesDepValuesAsync(component);
                }
                
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
    
    saveServiceProvidersList : function(component) {
        var recordId = component.get("v.recordId");
        var serviceProviderList = component.get('v.serviceProviderList');
        
        console.log('BEFORE FOR >> ' + serviceProviderList);
        
        for (var i = 0; i < serviceProviderList.length; i++) {
            console.log('INSIDE THE FOR LOOP FOR SERVICE PROVIDER');
            var prov = serviceProviderList[i];
            prov.Drawdowns__r = this.rewriteSubquery(prov.Drawdowns__r);
            prov.Opportunity_Service_Provider_Invoices__r = this.rewriteSubquery(prov.Opportunity_Service_Provider_Invoices__r);
        }
        
        console.log('AFTER FOR >> ' + serviceProviderList);
        
        var action = component.get('c.saveProvidersList');         
        /*action.setParams({ 
            providers : serviceProviderList,
            jsonStr: JSON.stringify(serviceProviderList)
        });*/
        action.setParams({ 
            jsonStr: JSON.stringify(serviceProviderList),
            oppId: recordId
        });
        console.log(JSON.stringify(serviceProviderList));
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                component.set("v.serviceProviderList", response.getReturnValue()); 
                this.fetchTreatmentRefNotesDepValuesAsync(component);
                this.getOpportunityInfo(component);
                this.showToast('SUCCESS','Your changes were successfully saved!','SUCCESS');
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                this.getServiceProvidersList(component);
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
    rewriteSubquery: function (array) {
        if (array && !array.hasOwnProperty('records')) {
            var tempArray = array;
            array = {
                totalSize: tempArray.length,
                done: true,
                records: tempArray
            }
        }
        return array;
    },
    
    getReAssessmentOpportunitiesList : function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.getReAssessmentOpportunities');             
        action.setParams({ oppId : recordId});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.reAssessmentOppList", response.getReturnValue());         
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
    
    saveOppty : function(component) {
        console.log('saveOppty');
        var p = new Promise ($A.getCallback( function( resolve, reject){
            
            //setting lookups
            component.set("v.oppObj.Assigned_To__c",(component.get("v.selectedLookUpAssignedTo.Id") ?
                                                     component.get("v.selectedLookUpAssignedTo.Id"):''));
            
            //setting lookups
            component.set("v.oppObj.Primary_Contact__c",(component.get("v.selectedLookUpPrimaryContact.Id") ?
                                                         component.get("v.selectedLookUpPrimaryContact.Id"):''));
    
            //setting lookups
            component.set("v.oppObj.OwnerId",(component.get("v.selectedLookUpOwner.Id") ?
                                                         component.get("v.selectedLookUpOwner.Id"):''));
            
            //setting lookups
            component.set("v.oppObj.Assessment_Provider__c",(component.get("v.selectedLookUpAssessmentProvider.Id") ?
                                                         component.get("v.selectedLookUpAssessmentProvider.Id"):''));
    
            
            var oppObj = component.get('v.oppObj');
            console.log('oppObj ' + oppObj.Discount_Rate__c);
            var action = component.get('c.saveOpportunity');
            action.setParams({ opportunity : oppObj});
            console.log('saving oppty'+ oppObj.Primary_Contact__c);
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
                    
                    component.set("v.spinner", false);
                    resolve(true);
                    //if new
                    if(!oppObj.Id)
                    {
                        //var navEvt = $A.get("e.force:navigateToSObject");
                        //navEvt.setParams({
                        //   "recordId": response.getReturnValue().Id
                        //});
                        //navEvt.fire();
                        
                        //Fire the refresh view event to update Account detail view
                        $A.get('e.force:refreshView').fire();   
                        
                        var refreshOppties = component.get("v.refreshAllOppties");
                        
                        if(refreshOppties ){
                            
                            setTimeout(function(){
                                
                                $A.enqueueAction(refreshOppties);
                                
                            }, 100);
                        }
                    }
                    //var a = component.get('c.doInit');
                    //$A.enqueueAction(a);                
                } else if (state === 'ERROR') {
                    component.set("v.spinner", false);
                    var errors = response.getError();                    
                    reject(errors);
                }
            });
            $A.enqueueAction(action);
            
        }));
        return p;
        
        
    },
    /*
    saveOppty : function(component) {
        var p = new Promise ($A.getCallback( function( resolve, reject){
            
            //setting lookups
            component.set("v.oppObj.Assigned_To__c",(component.get("v.selectedLookUpAssignedTo.Id") ?
                                                     component.get("v.selectedLookUpAssignedTo.Id"):''));
            
            //setting lookups
            component.set("v.oppObj.Primary_Contact__c",(component.get("v.selectedLookUpPrimaryContact.Id") ?
                                                         component.get("v.selectedLookUpPrimaryContact.Id"):''));
    
            //setting lookups
            component.set("v.oppObj.OwnerId",(component.get("v.selectedLookUpOwner.Id") ?
                                                         component.get("v.selectedLookUpOwner.Id"):''));
            
            var oppObj = component.get('v.oppObj');
            var action = component.get('c.saveOpportunity');
            action.setParams({ opportunity : oppObj});
            console.log('saving oppty'+ oppObj.Primary_Contact__c);
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
                    
                    component.set("v.spinner", false);
                    resolve(true);
                    //if new
                    if(!oppObj.Id)
                    {
                        //var navEvt = $A.get("e.force:navigateToSObject");
                        //navEvt.setParams({
                        //   "recordId": response.getReturnValue().Id
                        //});
                        //navEvt.fire();
                        
                        //Fire the refresh view event to update Account detail view
                        $A.get('e.force:refreshView').fire();   
                        
                        var refreshOppties = component.get("v.refreshAllOppties");
                        
                        if(refreshOppties ){
                            
                            setTimeout(function(){
                                
                                $A.enqueueAction(refreshOppties);
                                
                            }, 100);
                        }
                    }
                    //var a = component.get('c.doInit');
                    //$A.enqueueAction(a);                
                } else if (state === 'ERROR') {
                    component.set("v.spinner", false);
                    var errors = response.getError();                    
                    reject(errors);
                }
            });
            $A.enqueueAction(action);
            
        }));
        return p;
        
        
    },
    /*
    saveOppty : function(component) {
        
        
        //setting lookups
        component.set("v.oppObj.Assigned_To__c",(component.get("v.selectedLookUpAssignedTo.Id") ?
                                                 component.get("v.selectedLookUpAssignedTo.Id"):''));
        
        //setting lookups
        component.set("v.oppObj.Primary_Contact__c",(component.get("v.selectedLookUpPrimaryContact.Id") ?
                                                     component.get("v.selectedLookUpPrimaryContact.Id"):''));

        //setting lookups
        component.set("v.oppObj.OwnerId",(component.get("v.selectedLookUpOwner.Id") ?
                                                     component.get("v.selectedLookUpOwner.Id"):''));
        
        var oppObj = component.get('v.oppObj');
        var action = component.get('c.saveOpportunity');
        action.setParams({ opportunity : oppObj});
        console.log('saving oppty'+ oppObj.Primary_Contact__c);
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                //component.set("v.spinner", false);
                //this.showToast('SUCCESS','Your changes were saved!','SUCCESS');
                this.getOpportunityInfo(component);
                component.set("v.spinner", false);
                this.showToast('SUCCESS','Your changes were saved!','SUCCESS');
                //if new
                if(!oppObj.Id)
                {
                    //var navEvt = $A.get("e.force:navigateToSObject");
                    //navEvt.setParams({
                    //   "recordId": response.getReturnValue().Id
                    //});
                    //navEvt.fire();
                    
                    //Fire the refresh view event to update Account detail view
                    $A.get('e.force:refreshView').fire();   
                    
                    var refreshOppties = component.get("v.refreshAllOppties");
                    
                    if(refreshOppties ){
                        
                        setTimeout(function(){
                            
                            $A.enqueueAction(refreshOppties);
                            
                        }, 100);
                    }
                }
                //var a = component.get('c.doInit');
                //$A.enqueueAction(a);                
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
    }, */   
    
    deleteOpportunity : function(component) {
        var recordId = component.get("v.recordId");
        var action = component.get('c.deleteOpp');             
        action.setParams({ oppId : recordId})
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
                component.set("v.leadObj", response.getReturnValue()); 
                $A.get('e.force:refreshView').fire();   
                
                var refreshOppties = component.get("v.refreshAllOppties");
                
                if(refreshOppties ){
                    
                    setTimeout(function(){
                        
                        $A.enqueueAction(refreshOppties);
                        
                    }, 100);
                }               
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
        var year = new Date().getFullYear() - 1;
        //var min = year+'-01-01';
        var min = '1980-01-01';
        component.set("v.calendarMin", min);                
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 5;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    
    fetchPicklistValues: function(component,objDetails,controllerField, dependentField) {
        
        // call the server side function  
        var action = component.get("c.getDependentMap");
        // pass paramerters [object definition , contrller field name ,dependent field name] -
        // to server side function 
        console.log('objDetails ' + objDetails);
        console.log('controllerField ' + controllerField);
        console.log('dependentField ' + dependentField);
        action.setParams({
            'objDetail' : objDetails,
            'contrfieldApiName': controllerField,
            'depfieldApiName': dependentField 
        });
        //set callback   
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                //store the return response from server (map<string,List<string>>)  
                var StoreResponse = response.getReturnValue();                
                // once set #StoreResponse to depnedentFieldMap attribute 
                component.set("v.depnedentFieldMap",StoreResponse);                
                
                
                // create a empty array for store map keys(@@--->which is controller picklist values) 
                var listOfkeys = []; // for store all map keys (controller picklist values)
                var ControllerField = []; // for store controller picklist value to set on lightning:select. 
                
                // play a for loop on Return map 
                // and fill the all map key on listOfkeys variable.
                for (var singlekey in StoreResponse) {
                    listOfkeys.push(singlekey);
                }
                
                //set the controller field value for lightning:select
                if (listOfkeys != undefined && listOfkeys.length > 0) {
                    ControllerField.push('--- None ---');
                }

                const set1 = new Set(['Developing', 'Closed Won', 'Closed Lost', 'Re-Assessment - In Progress', 
                                      'Re-Assessment - F/U with PC/Facility', 'Re-Assessment - Approved',
                                     'Re-Assessment - File Sent for EFT', 'Re-Assessment - Completed', 'Re-Assessment - Declined']);
                
                for (var i = 0; i < listOfkeys.length; i++) {
                    if (!set1.has(listOfkeys[i])) {
                    	ControllerField.push(listOfkeys[i]);
                    }
                }  
                console.log('***** ControllerField Values *****');   
                console.log(ControllerField);                
                // set the ControllerField variable values to country(controller picklist field)
                
                component.set("v.listControllingValues", ControllerField);                
                
                // populating dependent field for the first time
                var controllerValueKey = component.get('v.oppObj.StageName'); 
                var depnedentFieldMap = component.get("v.depnedentFieldMap");
                //var ListOfDependentFields = StoreResponse[valueKey];
                //this.fetchDepValues(component, ListOfDependentFields);
                console.log('valuecontrollerValueKeyKey' + controllerValueKey);
                
                if (controllerValueKey != '--- None ---') {
                    var ListOfDependentFields = depnedentFieldMap[controllerValueKey];
                    
                    if(ListOfDependentFields.length > 0){
                        component.set("v.bDisabledDependentFld" , false);  
                        this.fetchDepValues(component, ListOfDependentFields, 'listDependingValues');    
                    }else{
                        component.set("v.bDisabledDependentFld" , true); 
                        component.set("v.listDependingValues", ['--- None ---']);
                    }  
                    
                } else {
                    component.set("v.listDependingValues", ['--- None ---']);
                    component.set("v.bDisabledDependentFld" , true);
                }                
                
            }else{
                //alert('Something went wrong..');
                this.showToast('ERROR', 'Something went wrong..');	
            }
        });
        $A.enqueueAction(action);
        
    },
    
    fetchDepValues: function(component, ListOfDependentFields, listDependingValues) {
        // create a empty array var for store dependent picklist values for controller field  
        var dependentFields = [];
        dependentFields.push('--- None ---');
        for (var i = 0; i < ListOfDependentFields.length; i++) {
            dependentFields.push(ListOfDependentFields[i]);
        }
        // set the dependentFields variable values to store(dependent picklist field) on lightning:select
        component.set("v."+listDependingValues, dependentFields);
        
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
    getPickListValues: function(component, object, field, attributeId)
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
    fetchRefNotesDepValues: function(component, newPaymentMethod, index) {
        
        var referenceNotesDepPicklistMap = component.get("v.referenceNotesDepPicklistMap");
        var newRefNotes;
        console.log('Payment method is '+newPaymentMethod+'Notes are '+JSON.stringify(referenceNotesDepPicklistMap));
        if(newPaymentMethod in referenceNotesDepPicklistMap)
        {
            newRefNotes = referenceNotesDepPicklistMap[newPaymentMethod];
        }
        console.log('newRefNotes:'+JSON.stringify(newRefNotes));
        var newRefNotesOptions = [];
        if(newRefNotes)
        {
            newRefNotes.forEach(function(element){
                newRefNotesOptions.push({'label': element, 'value': element});
            });
        }
        var notes = [];
        var result = component.find('Reference_Notes__c');
        if(result)
        {
            console.log('FM: index: '+index);
            console.log('FM: '+result);
            
            if(result.constructor === Array )
            {
                notes = result;
            }
            else
            {
                notes.push(result);
            }
            
            if(notes[index]){
                notes[index].set("v.options",newRefNotesOptions);
            }
            
        }
    }, 
    fetchTreatmentRefNotesDepValuesAsync: function(component){
        var self = this;
        setTimeout( function(){
            self.fetchTreatmentRefNotesDepValues(component);
        }, 800);
    },
    fetchTreatmentRefNotesDepValues: function(component) {
        var treatPaymentMethodsResult = component.find('Treatment_Payment_Method__c');
        var treatPaymentElements = [];
        if(treatPaymentMethodsResult)
        {
            if(treatPaymentMethodsResult.constructor === Array )
            {
                treatPaymentElements = treatPaymentMethodsResult;
            }
            else
            {
                treatPaymentElements.push(treatPaymentMethodsResult);
            }
        }
        var notes = [];
        var result = component.find('Reference_Notes_Treatment__c');
        if(result)
        {   
            if(result.constructor === Array )
            {
                notes = result;
            }
            else
            {
                notes.push(result);
            }
        }
        var referenceNotesDepPicklistMap = component.get("v.providerReferenceNotesDepPicklistMap");
        
        
        for(var i = 0 ; i < notes.length ; i++)
        {
            if(treatPaymentElements[i])
            {
                var newPaymentMethod = treatPaymentElements[i].get('v.value');
                var newRefNotes;

                if(referenceNotesDepPicklistMap && newPaymentMethod in referenceNotesDepPicklistMap)
                {
                    newRefNotes = referenceNotesDepPicklistMap[newPaymentMethod];
                }
                var newRefNotesOptions = [];
                if(newRefNotes)
                {
                    newRefNotes.forEach(function(element){
                        newRefNotesOptions.push({'label': element, 'value': element});
                    });
                }
                notes[i].set("v.options",newRefNotesOptions);
            }
        }
    }, 
    getRefNotesDependantPicklistMap: function(component, objDetail, targetMap) {
        
        component.set("v.AsyncSpinner", true);
        // call the server side function  
        var action = component.get("c.getDependentMap");
        // pass paramerters [object definition , contrller field name ,dependent field name] -
        // to server side function 
        action.setParams({
            'objDetail' : component.get('v.'+objDetail),
            'contrfieldApiName': 'Payment_Method__c',
            'depfieldApiName': 'Reference_Notes__c' 
        });
        //set callback   
        action.setCallback(this, function(response) {
            //component.set("v.spinner", false);
            if (response.getState() == "SUCCESS") {
                //store the return response from server (map<string,List<string>>)  
                var StoreResponse = response.getReturnValue();
                console.log(StoreResponse);
                // once set #StoreResponse to referenceNotesDepPicklistMap attribute 
                component.set("v."+targetMap,StoreResponse);
                
                var notes = [];
                var result = component.find('Reference_Notes__c');
                if(result)
                {
                    if(result.constructor === Array )
                    {
                        notes = result;
                    }
                    else
                    {
                        notes.push(result);
                    }
                    
                    let loanType = component.get('v.oppObj').Type_of_Loan__c;
                    
                    let drawDownList = component.get('v.drawDownList');
                    for(let i = 0 ; i < drawDownList.length ; i++)
                    {
                        let newPaymentMethod = drawDownList[i].Payment_Method__c;
                        this.fetchRefNotesDepValues(component, newPaymentMethod, i);
                    }
                    if (loanType && loanType.startsWith('Treatment Loan')) {
                        /*let drawDownPaymentsList = component.get('v.drawDownPaymentsList');                    
                        for(let i = 0 ; i < drawDownPaymentsList.length ; i++)
                        {
                            let newPaymentMethod = drawDownPaymentsList[i].Payment_Method__c;
                            this.fetchRefNotesDepValues(component, newPaymentMethod, i);
                        }          */        
                    }
                }
                component.set("v.AsyncSpinner", false);
                
            }else{
                component.set("v.AsyncSpinner", false);
                //alert('Something went wrong..');
                this.showToast('ERROR', 'Something went wrong..');
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        //setTimeout( function(){
        $A.enqueueAction(action);
        //}, 800);
        component.set("v.AsyncSpinner", true);
    },
    getRefNotesDependantPicklistMapAsync: function(component, objDetail, targetMap) {
        component.set("v.AsyncSpinner", true);
        var self = this;
        setTimeout( function(){
            self.getRefNotesDependantPicklistMap(component, objDetail, targetMap);
        }, 800);
    },
    calculatePayments : function(component, event, helper) {  
        $A.createComponents([
            ["aura:html",{"tag":"div","body":component.get("v.oppObj.Opportunity_Long_Name__c"),"HTMLAttributes":{"class":"slds-text-align_center slds-text-title_caps","style":"font-size:1rem;color:#3E3E3C;"}}],
            ["c:createPayments",{"recordId":component.get("v.recordId")}]
        ],
        function(components, status, errorMessage){
            if (status === "SUCCESS") {
                component.find("overlayLib").showCustomModal({
                   header: components[0],
                   body: components[1],
                   showCloseButton: true,
                   closeCallback: function() {}
               }).then(function(overlay){
                    // we need to set the modal instance in an attribute to call its methods
                    component.set("v.overlayPanel",[overlay]);
               });
            }else{
                console.error(errorMessage);
            }
        });
    },
    viewPayments : function(component, event, helper) {  
        $A.createComponents([
            ["aura:html",{"tag":"div","body":component.get("v.oppObj.Opportunity_Long_Name__c"),"HTMLAttributes":{"class":"slds-text-align_center slds-text-title_caps","style":"font-size:1rem;color:#3E3E3C;"}}],
            ["c:viewPayments",{"recordId":component.get("v.recordId")}]
        ],
        function(components, status, errorMessage){
            if (status === "SUCCESS") {
                component.find("overlayLib").showCustomModal({
                   header: components[0],
                   body: components[1],
                   showCloseButton: true,
                   closeCallback: function() {}
               }).then(function(overlay){
                    // we need to set the modal instance in an attribute to call its methods
                    component.set("v.overlayPanel",[overlay]);
               });
            }else{
                console.error(errorMessage);
            }
        });
    },
    printPayments : function(component, event, helper) {  
        $A.createComponents([
            ["aura:html",{"tag":"div","body":component.get("v.oppObj.Opportunity_Long_Name__c"),"HTMLAttributes":{"class":"slds-text-align_center slds-text-title_caps","style":"font-size:1rem;color:#3E3E3C;"}}],
            ["c:printPayments",{"recordId":component.get("v.recordId")}]
        ],
        function(components, status, errorMessage){
            if (status === "SUCCESS") {
                component.find("overlayLib").showCustomModal({
                   header: components[0],
                   body: components[1],
                   showCloseButton: true,
                   closeCallback: function() {}
               }).then(function(overlay){
                    // we need to set the modal instance in an attribute to call its methods
                    component.set("v.overlayPanel",[overlay]);
               });
            }else{
                console.error(errorMessage);
            }
        });
    },
    deletePayments : function(component, event, helper) {  
        var action = component.get("c.deletePayments");
        var _this = this;
        action.setParams({
            opportunityId : component.get("v.recordId")
        });
        this.promiseServerSideCall(action).then(
                $A.getCallback(function(result){
                     $A.get("e.force:showToast").setParams({"type":"success","message":"Payments deleted successfully."}).fire();
                     _this.firePaymentsChangedEvent(component);
                })
            ).catch(
                $A.getCallback(function(error){
                    if(!$A.util.isEmpty(error)){
                        var errorMessage = $A.get("e.force:showToast");
                        errorMessage.setParams({
                            "type" : "error",
                            "message": error.message
                        });
                        errorMessage.fire();
                    }
            })
        );
    },

	firePaymentsChangedEvent: function (component) {
        let pubsub = component.find('pubsub');
        if (pubsub) {
            pubsub.fireEvent(`scheduledpaymentschanged-${component.get('v.recordId')}`);
        }
	},

	fireAmountsChangedEvent: function (component) {
        let pubsub = component.find('pubsub');
        if (pubsub) {
            pubsub.fireEvent(`amountschanged-${component.get('v.recordId')}`);
        }
	},

    /**
    * @description Helper method which takes in action and creates promise around it
    * @param      action - action for which callback is set and promise is created around.
    **/
    promiseServerSideCall: function(action) {
        return new Promise(function(resolve, reject) {
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    resolve(response.getReturnValue());
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            reject(Error(errors[0].message));
                        }
                    } else {
                        reject(Error($A.get("Unknown Error")));
                    }
                }
            });
            $A.enqueueAction(action);
        });
    },
    /**
    * @description Method to used to save the record
    * @param       component - The component to which the controller belongs.
    * @param       componentId - Aura id of the component.
    * @param       successCallback - callback to call after record saved successfully
    **/
    saveRecord : function(component,componentId,successCallback,incompleCallback,errorCallback){
        component.find(componentId).saveRecord(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                if(!$A.util.isUndefinedOrNull(successCallback))  successCallback(saveResult);
            }else if (saveResult.state === "INCOMPLETE") {  
                if(!$A.util.isUndefinedOrNull(incompleCallback))  incompleCallback(saveResult);
            }else if (saveResult.state === "ERROR") {
                if(!$A.util.isUndefinedOrNull(errorCallback))  errorCallback(saveResult);
            } else {
                $A.get("e.force:showToast").setParams({"title":"error","message":JSON.stringify(saveResult.error)}).fire();
            }
        });
    },

	getBankAccountOptions: function(component) {
		var action = component.get("c.getBankAccountOptions");
		action.setParams({
			oppId: component.get("v.recordId")
		});
		this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
					var bankAccountOptions = result.map(ba => {
						return { value: ba.Id, label: ba.Name }
					});
					component.set("v.bankAccountOptions", bankAccountOptions);
				})
			).catch( (error) => {
				$A.getCallback(function(error){
					if(!$A.util.isEmpty(error)){
						var errorMessage = $A.get("e.force:showToast");
						errorMessage.setParams({
							"type" : "error",
							"message": error.message
						});
						errorMessage.fire();
					}
                })
            }
		);
    },

	getUpdatedAmounts: function(component) {
		var action = component.get("c.getUpdatedAmounts");
		action.setParams({
			oppId: component.get("v.recordId")
		});
        let _this = this;
		this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
                    var oppObj = component.get("v.oppObj"); 
                    for(var field in result) {
                        oppObj[field] = result[field];
                    }
                    component.set("v.oppObj", oppObj);
                    _this.fireAmountsChangedEvent(component);
				})
			).catch( (error) => {
				$A.getCallback(function(error){
					if(!$A.util.isEmpty(error)){
						var errorMessage = $A.get("e.force:showToast");
						errorMessage.setParams({
							"type" : "error",
							"message": error.message
						});
						errorMessage.fire();
					}
                })
            }
		);
    },
    getReverseModalElement: function(component) {
        return component.find("reverseModal")
    },
    showReverseModal: function(component, drawdownId) {       
        console.log('Drawdwon Id: ' + drawdownId);
        $A.createComponent(
                "c:rejectedPaymentForm",
                {
                    drawdownToReverseId: drawdownId,
                    onsuccess: component.getReference("c.handleRejectSuccess"),
                    oncancel: component.getReference("c.handleRejectCancel")
                }
            ,
            function(formComponent, status, errorMessage){
                if (status === "SUCCESS") {
                    let modalPromise = component.find("overlayLib").showCustomModal({
                        body: formComponent,
                        showCloseButton: true,
                        closeCallback: function() {}
                    });
                    component.set("v.reverseModalPromise", modalPromise);
                    
                    //.then(function(overlay){
                        // we need to set the modal instance in an attribute to call its methods
                      //  component.set("v.overlayPanel",overlay);
                    
                } else {
                    console.error(errorMessage);
                }
            });        
    },
    hideReverseModal: function(component) {
        component.get("v.reverseModalPromise").then(
            function(modal) {
                modal.close();
            }
        );
        /*
        component.set("v.showReverseForm", false)
        let modal = this.getReverseModalElement(component);           
        modal.hide();
        */
    },
    reInitSomeData:function(component) {
        let initialized = component.get('v.initialized');
        if (initialized === true) {
            component.set('v.drawDownList', undefined);
            this.getOpportunityInfo(component);
            this.getDrawdownList(component, true);
            this.getDrawdownPaymentsList(component);
            this.getServiceProvidersList(component);
            this.getBankAccountOptions(component);
            let pubsub = component.find('pubsub');
            if (pubsub) {
                pubsub.fireEvent(`drawdownschanged-${component.get('v.recordId')}`);
                pubsub.fireEvent(`previousloanschanged-${component.get('v.recordId')}`);
            }
        } else {
            component.set('v.initialized', true);
        }
    },
    setLatestDiscountRateLaywer : function(component){
          return new Promise($A.getCallback(
              function(resolve, reject){
                  let oppObj = component.get('v.oppObj');
                  let action = component.get("c.setLatestDiscountRateLaywer");
                  action.setParams({
                      oppId : oppObj.Id,
                      assessmentProviderId : oppObj.Assessment_Provider__c,
                      lawyerId : oppObj.Lawyer__c
                  });
                  
                  action.setCallback(this, function(response){
                      let state = response.getState();
                      if(state == 'SUCCESS'){
                          resolve(response.getReturnValue());
                      }else if(state == 'ERROR'){
                          reject(response.getError());
                      }
                  });
                  $A.enqueueAction(action);
              }
          ));  
    }
})
