({
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
    setDefaultDates : function(component){
        return new Promise(function(resolve,reject){
            let dt = new Date();
            let customSetting = component.get('v.customSetting');            
            let defaultEndDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
            let defaultStartDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-01';
            try{
                component.set("v.sinceInception", customSetting.Since_Inception__c);
                component.set("v.endDate", customSetting.End_Date__c == null ? defaultEndDate : customSetting.End_Date__c);
                component.set("v.startDate", customSetting.Start_Date__c == null ? defaultStartDate : customSetting.Start_Date__c); 
            	resolve(true);
            }catch(e){
                reject([{message:'Failed to set default filter dates from custom settings.'}]);                
            }            
        });      
    },
    
    getCustomSettings : function(component){
        //get report dates from custom setting
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.getCustomSetting');                
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
                
                /*if (allValues != undefined && allValues.length > 0) {
                    opts.push({
                        class: "optionClass",
                        label: "All",
                        value: "All"
                    });
                }*/
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
    
    executeBatchJob : function (component){
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get('c.executeBatchJob');
                action.setParams({
                    sinceInception : component.get('v.sinceInception'),
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
    
    getFinancialReportData : function (component, businessUnit){
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get('c.getFinancialReportData');
                action.setParams({
                    startDate:component.get('v.startDate'),
                    endDate:component.get('v.endDate'),
                    BusinessUnit: businessUnit
                });
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
    
    getReportByProvinceHelper : function (component){       
        return new Promise($A.getCallback(
            function(resolve, reject) {
                let action = component.get('c.getReportDataByProvince');                
                action.setParams({
                    startDate:component.get('v.startDate'),
                    endDate:component.get('v.endDate'),
                    BusinessUnit:component.get('v.selectedBusinessUnitFilter')
                });
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
    
    calculateReportByProvinceData : function(component){
        var financeData = component.get('v.financials');
        
        var RhinofileTotal = 0;
        var RhinoOpptyTotal = 0;
        var RhinoamountTotal = 0;
        var ElfifileTotal = 0;
        var ElfiOpptyTotal = 0;
        var ElfiamountTotal = 0;
        
        for(var i = 0; i < financeData.length; i++){
            RhinofileTotal += financeData[i].rhinoFileCount;
            RhinoOpptyTotal += financeData[i].rhinoOpptyCount;
            RhinoamountTotal += financeData[i].rhinoAmount;
            ElfifileTotal += financeData[i].elfiFileCount;
            ElfiOpptyTotal += financeData[i].elfiOpptyCount;
            ElfiamountTotal += financeData[i].elfiAmount;
        }
        component.set("v.RhinofileTotal", RhinofileTotal); 
        component.set("v.RhinoOpptyTotal", RhinoOpptyTotal); 
        component.set("v.RhinoamtTotal", RhinoamountTotal);
        component.set("v.ElfifileTotal", ElfifileTotal); 
        component.set("v.ElfiOpptyTotal", ElfiOpptyTotal); 
        component.set("v.ElfiamtTotal", ElfiamountTotal);
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