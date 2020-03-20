({
    executeBatchJob : function (component){
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get('c.executeBatchJob');
                action.setParams({
                    startDate: component.get('v.startDate'),
                    endDate: component.get('v.endDate')
                });
                action.setCallback(this,function(response){
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
    validateReport : function(component) {
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.validateReport');
                action.setParams({
                    startDate:component.get('v.startDate'),
                    endDate:component.get('v.endDate')
                });
                action.setCallback(this,function(response){
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
    validateReport : function(component) {
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.validateReport');
                action.setParams({
                    startDate:component.get('v.startDate'),
                    endDate:component.get('v.endDate')
                });
                action.setCallback(this,function(response){
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
    pingForBatchJobStatus : function(component){
        let self = this;
        let intervalId = window.setInterval(
            $A.getCallback(function() { 
                $A.enqueueAction(component.get('c.setBatchJobStatus'));
                //self.getBatchJobStatus(component);
            }), 5000
        );        
        component.set('v.intervalId', intervalId);
    },
    getBatchJobStatus : function (component){        
        return new Promise($A.getCallback(
            function(resolve,reject){                
                let action = component.get('c.getBatchJobStatus');
                action.setCallback(this,function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        console.log('The batch job status is:');
                        console.log(response.getReturnValue());
                        //component.set('v.apexBatchJobOBJ', response.getReturnValue());
                        //self.updateProgress(component);
                        resolve(response.getReturnValue());
                    }else if(state === 'ERROR'){
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    },
    updateProgress : function (component){
        return new Promise(function(resolve, reject){
            let apexBatchJobOBJ = component.get('v.apexBatchJobOBJ');
            if(apexBatchJobOBJ != null){
                component.set('v.batchJobStatus',apexBatchJobOBJ.Status);
                component.set('v.batchJobProgress',0);
                component.set('v.batchJobItems', ' '+ 0 + '%'); 
                if(apexBatchJobOBJ.Status == 'Processing' || apexBatchJobOBJ.Status == 'Completed'){
                    component.set('v.batchJobProgress',(apexBatchJobOBJ.JobItemsProcessed/apexBatchJobOBJ.TotalJobItems)*100);
                    component.set('v.batchJobItems', ' '+ parseFloat((apexBatchJobOBJ.JobItemsProcessed/apexBatchJobOBJ.TotalJobItems)*100).toFixed(0) + '%');
                }                               
            }
            if(apexBatchJobOBJ.Status == 'Completed'){
                //$A.enqueueAction(component.get('c.getRecords'));                  
                resolve(true);
            }else{
                resolve(false);
            }
            
        });
    },
    getCalendarMin : function(component){
        var year = new Date().getFullYear() - 5;
        //var min = year+'-01-01';
        var min = '2010-01-01';
        component.set("v.calendarMin", min);                  
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 5;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    setDefaultDates : function(component){
        return new Promise(function(resolve,reject){
            let dt = new Date();
            let customSetting = component.get('v.customSetting');            
            let defaultEndDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
            let defaultStartDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-01';
            try{
                component.set("v.endDate", customSetting.End_Date__c == null ? defaultEndDate : customSetting.End_Date__c);
                component.set("v.startDate", customSetting.Start_Date__c == null ? defaultStartDate : customSetting.Start_Date__c); 
                resolve(true);
            }catch(e){
                reject([{message:'Failed to set default filter dates from custom settings.'}]);                
            }            
        });  
        
    },
    setDateCustomSettings : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.saveDateCustomSettings');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate')
            });
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    console.log('The start date and end date in custom settings have been updated.');
                    console.log(response.getReturnValue());
                }else if(state === 'ERROR'){
                    console.log('The start date and end date in custom settings could not be updated.');
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    setBUCustomSettings : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.saveBusinessUnitCustomSettings');
            action.setParams({
                BusinessUnit : component.get('v.selectedBusinessUnitFilter')
            });
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    console.log(response.getReturnValue());
                }else if(state === 'ERROR'){
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    getCustomSettings : function(component){
        //get report custom setting
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.getCustomSetting');                
                action.setCallback(this,function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        console.log(response.getReturnValue());
                        resolve(response.getReturnValue());
                    }else if(state === 'ERROR'){
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    },
    getPickListValues : function(component, object, field, attributeId){
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
                opts.push({
                    class: "optionClass",
                    label: 'Consolidated',
                    value: 'Consolidated'
                });                
                component.set('v.'+attributeId, opts);
            }
        });
        $A.enqueueAction(picklistgetter);
    },
    getCriticalDateNames : function(component, object, field, attributeId) {
        return new Promise($A.getCallback(
            function (resolve, reject){
                let action = component.get('c.getCriticalDateNames');
                action.setParams({startDate:component.get('v.startDate'),endDate:component.get('v.endDate'),businessUnit: component.get('v.selectedBusinessUnitFilter')});
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
    createNewNote : function(component) {
        
        return new Promise($A.getCallback(
            function (resolve, reject){
                let AccountId = component.get('v.selectedAccountId');
                let noteContent = component.get('v.noteContent');                
                let action = component.get('c.createNewNote');
                action.setParams({accountId: AccountId, note: noteContent});
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        resolve('Note created successfully!');
                    }else if(state === 'ERROR'){                        
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);                
            }
        ));
        
    },
    
    printReport : function (component){
        return new Promise($A.getCallback(
            function(resolve, reject){
                let action = component.get('c.printReport');
                action.setParams({stDate:component.get('v.startDate'),edDate:component.get('v.endDate'),businessUnit: component.get('v.selectedBusinessUnitFilter')});
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
    
    openCongaWindow : function (component,buttonId) {
        console.log('buttonId ' + buttonId);        
        return new Promise(
            function(resolve, reject){
                let pdfParameter = buttonId == 'printPDF'? '%26DefaultPDF=1' : '';
                console.log(pdfParameter);
                let newWin;
                let url = 'https://composer.congamerge.com?sessionId={!$Api.Session_ID}&serverUrl={!$Api.Partner_Server_URL_290}';
                let criticalDateObj = component.get('v.criticalDateObj');                
                if(criticalDateObj != null){
                    try{                       
                        newWin = window.open(criticalDateObj.Conga_Generate_Report__c + pdfParameter + '&ReturnPath=/lightning/n/Custom_Reports?0.source=alohaHeader');
                        resolve(true);
                    }catch(e){}
                    if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
                    {
                        reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
                    } 
                }
                else{
                    reject([{message: 'No critical date found!'}]);
                }                
            }
        );
    },
    
    getCriticalDateList : function (component){
        let self = this;
        
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.getCriticalDateList');
            action.setParams({
                startDate:component.get('v.startDate'),
                endDate:component.get('v.endDate'),
                businessUnit: component.get('v.selectedBusinessUnitFilter')
            });
            
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){         	
                    resolve(response.getReturnValue());
                }else if(state === 'ERROR'){
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));    
    },
    errorsHandler : function(errors){
        if (errors[0] && errors[0].message) {
            
            console.log(errors);
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
    },        
})