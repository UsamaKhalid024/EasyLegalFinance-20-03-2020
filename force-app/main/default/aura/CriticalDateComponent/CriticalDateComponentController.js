({
    doInit : function(component, event, helper) {
        
        component.set("v.spinner", true);
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        
        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        
        helper.getCustomSettings(component).then($A.getCallback(
            function(result){
                console.log('Custom settings values are: ');
                console.log(result);
                component.set("v.customSetting", result);
                
                return helper.setDefaultDates(component);
            }
        )).then($A.getCallback(function(result){
            
            helper.getCriticalDateNames(component).then($A.getCallback(function(result){
                console.log(result);
                let selectedfilter = component.get('v.selectedBusinessUnitFilter');
                console.log('selectedfilter ' + selectedfilter);
                selectedfilter = selectedfilter == undefined || selectedfilter == null? 'ELFI' : selectedfilter;
                console.log('selectedfilter ' + selectedfilter);
                component.set('v.selectedBusinessUnitFilter', selectedfilter);
                component.set('v.criticalDateNamePickList', result);
                return helper.validateReport(component);
            })).then($A.getCallback(function(result){
                let customSettings = component.get('v.customSetting');
                if(result){
                    // the jobs needs to be run
                    component.set('v.showWarning',true);
                }else{
                    component.set('v.showWarning', false);
                }
                return helper.getBatchJobStatus(component);
            })).then($A.getCallback(function(result){
                component.set('v.apexBatchJobOBJ', result);
            })).catch(
                (errors) => {
                    component.set("v.spinner", false);
                    helper.errorsHandler(errors);
                });
                    
                    helper.getCriticalDateList(component).then(
                    (result) => {
                    console.log('Success');                 
                    component.set("v.criticalDateList", result);   
                }).then(
                    () => {
                    component.set("v.spinner", false);	
                }
                    ).catch(
                    (errors) => {
                    component.set("v.spinner", false);
                    helper.errorsHandler(errors);
                });
                    
                })).catch(function(errors){
                    component.set("v.spinner", false);
                    helper.errorsHandler(errors);
                });
                    
                    
                },
                    setBatchJobStatus : function(component, event, helper){
                        helper.getBatchJobStatus(component).then(function(result){
                            component.set('v.apexBatchJobOBJ', result);
                            return helper.updateProgress(component);        
                        }).then($A.getCallback(function(result){
                            if(result){
                                window.clearInterval(component.get('v.intervalId'));
                                return helper.getCustomSettings(component);                
                            }
                        })).then($A.getCallback(function(result){
                            if(result != null){
                                component.set('v.customSetting', result);
                                return helper.setDefaultDates(component);
                            }            
                        })).then($A.getCallback(function(result){
                            if(result){
                                component.set('v.showWarning', false);
                                $A.enqueueAction(component.get('c.filterButton'));
                            }            
                        })).catch(function(errors){            
                            helper.errorsHandler(errors);
                        });
                    },
                    runJobButton : function(component, event, helper) {
                        let customSetting = component.get('v.customSetting');
                        let apexBatchJobOBJ = component.get('v.apexBatchJobOBJ');
                        if(apexBatchJobOBJ != null && (apexBatchJobOBJ.Status != 'Completed' && apexBatchJobOBJ.Status != 'Aborted' && apexBatchJobOBJ.Status != 'Failed')){
                            if(confirm('Another Job is already in progress. Do you want to cancel and run a new one?')) {
                                component.set("v.spinner", true);
                                window.clearInterval(component.get('v.intervalId'));
                                helper.executeBatchJob(component).then(
                                    function(result){
                                        return helper.getBatchJobStatus(component);
                                    }
                                ).then(
                                    function(result){
                                        component.set('v.apexBatchJobOBJ', result);
                                        return helper.updateProgress(component);
                                    }).then(
                                    function(resut){
                                        return helper.pingForBatchJobStatus(component);
                                    }).then(
                                    function(){
                                        component.set("v.spinner", false);
                                    }).catch(
                                    function(errors){
                                        component.set("v.spinner", false);
                                        helper.errorsHandler(errors);
                                    });
                            }else{
                                return false;
                            }
                        }else{
                            component.set("v.spinner", true);
                            helper.executeBatchJob(component).then(
                                function(result){
                                    return helper.getBatchJobStatus(component);
                                }
                            ).then(
                                function(result){
                                    component.set('v.apexBatchJobOBJ', result);
                                    return helper.updateProgress(component);
                                }
                            ).then(
                                function(resut){
                                    return helper.pingForBatchJobStatus(component);
                                }
                            ).then(
                                function(){
                                    component.set("v.spinner", false);
                                }
                            ).catch(
                                function(errors){
                                    component.set("v.spinner", false);
                                    helper.errorsHandler(errors);
                                }
                            );
                        }        
                    },
                    filterButton : function(component, event, helper) {
                        component.set("v.spinner", true);
                        helper.setDateCustomSettings(component);
                        helper.setBUCustomSettings(component);
                        helper.getCriticalDateList(component).then(
                            (result) => {
                                console.log('Success'); 
                                component.set("v.criticalDateList", result);
                                return helper.getCriticalDateNames(component);
                            }).then($A.getCallback(function(result){
                                console.log(result);
                                component.set('v.criticalDateNamePickList', result);
                                component.set("v.spinner", false);				              
                                return helper.validateReport(component);
                            })).then(
                                function(result){
                                let customSettings = component.get('v.customSetting');                
                                if(result){
                                // the jobs needs to be run 
                                component.set('v.showWarning',true);
                            }else{
                                component.set('v.showWarning', false);
                            }
                            }).catch(
                                (errors) => {
                                console.log('error');
                                console.log(errors);
                                component.set("v.spinner", false);
                                helper.errorsHandler(errors);
                            });
                            },
                                printButton : function(component, event, helper){
                                    component.set("v.spinner", true);
                                    let buttonId = event.getSource().getLocalId();
                                    helper.printReport(component).then(
                                        (result) => {
                                            console.log('----');
                                            console.log(result);                
                                            component.set("v.criticalDateObj", result);
                                            return helper.openCongaWindow(component,buttonId);                
                                        }
                                            ).then(
                                            (success) => {
                                            console.log('success----');
                                            component.set("v.spinner", false);
                                        }).catch(
                                            (errors) => {
                                            console.log('ERROR');
                                            console.log(errors);
                                            component.set("v.spinner", false);
                                            helper.errorsHandler(errors);
                                        });
                                        },
                                            actionTaken: function(component, event, helper){           
                                                component.set('v.noteContent','');
                                                component.set('v.selectedAccountId', event.target.id);
                                                component.set('v.showNotePopup',true);
                                            },
                                            createNote: function(component, event, helper){ 
                                                component.set("v.spinner", true);
                                                helper.createNewNote(component).then(
                                                    (success) => {                            	
                                                        helper.showToast('SUCCESS',success,'SUCCESS');
                                                    }
                                                        ).then(
                                                        () => {
                                                        component.set("v.spinner", false);				              
                                                    }
                                                        ).catch(
                                                        (errors) => {
                                                        component.set("v.spinner", false);
                                                        helper.errorsHandler(errors);
                                                    }
                                                        );
                                                        component.set('v.showNotePopup',false);
                                                    },
                                                        closeNoteModal: function(component, event, helper){
                                                            component.set('v.selectedAccountId', '');
                                                            component.set('v.showNotePopup',false);
                                                        }
                                                    })