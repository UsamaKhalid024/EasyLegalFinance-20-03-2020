({
    getCalendarMin : function(component){
        var year = new Date().getFullYear() - 1;
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

        let customSettings = component.get('v.customSetting');
        console.log('customSettings ' + JSON.stringify(customSettings));
        let dt = new Date();
        
        let defaultPayoutDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
        component.set("v.payoutDate", customSettings.Payout_Date__c !=null? customSettings.Payout_Date__c: defaultPayoutDate);
        
        let defaultReportDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + dt.getDate() + '';
        component.set("v.reportDate", customSettings.Report_Date__c !=null? customSettings.Report_Date__c: defaultReportDate); 
        
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
    
    getAssessments : function(component){
    	return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get("c.getAssessmentData");
                action.setParams({
                    searchByName : component.get("v.searchByName"),
                    BusinessUnit : component.get("v.selectedBusinessUnitFilter"),
                    field : component.get('v.sortField'),
                    direction : component.get('v.sortOrder')
                });
                
                action.setCallback(this,function(response){
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
    getDrawdown : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.getDrawdown');
            
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
    
    generatePayoutBalanceForSelected: function (component){
        return new Promise($A.getCallback(
            function(resolve, reject){
                let provideList = component.get("v.providerList");
                let payoutDate = component.get("v.payoutDate");
                let reportDate = component.get("v.reportDate");
                let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
                businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
                
                let selectedIds = [];
                for(let i=0; i<provideList.length; i++){
                    if(provideList[i].checked == true){
                        selectedIds.push("'" + provideList[i].assessmentProviderId + "'");
                    }
                }
                if(selectedIds.length == 0){
                    component.set('v.spinner', false);
                    alert("Please select records.");
                }else{
                    //alert("Total " + selectedIds.length);
                    var action = component.get('c.generate');
                    action.setParams({
                        selectedIds : selectedIds, 
                        payoutDate : payoutDate, 
                        reportDate : reportDate,
                        businessUnitFilter: businessUnitFilterValue
                    });
                    action.setCallback(this, function (response) {
                        var state = response.getState();
                        
                        if (state === 'SUCCESS') {
                            component.set('v.conductorId', response.getReturnValue());
                            resolve(response.getReturnValue());
                        } else if (state === 'ERROR') {
                            reject(response.getError());
                        }                        
                    });
                    $A.enqueueAction(action);                    
                }
            }));
    },
    GeneratePayoutBalanceForAll: function (component){
        return new Promise($A.getCallback(
            function(resolve,reject){
                component.set('v.spinner', true);
                let payoutDate = component.get("v.payoutDate");
                let reportDate = component.get("v.reportDate");
                let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
                businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
                
                var action = component.get('c.generate');
                action.setParams({ 
                    selectedIds : [], 
                    payoutDate : payoutDate, 
                    reportDate : reportDate,
                    businessUnitFilter: businessUnitFilterValue
                });
                action.setCallback(this, function (response) {
                    var state = response.getState();
                    
                    if (state === 'SUCCESS') {                        
                        component.set('v.conductorId', response.getReturnValue());
                        resolve(response.getReturnValue());
                        
                    } else if (state === 'ERROR') {
                        reject(response.getError());                        
                    }
                });
                $A.enqueueAction(action);
            }));
    },
    pingBatchJobStatus : function (component, helper){ 
        console.log('pinging..');
        helper.getBatchJobStatus(component).then(
            function(result){
                component.set('v.apexBatchJobOBJ', result);
                helper.updateProgress(component);
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
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
            if(apexBatchJobOBJ != null && apexBatchJobOBJ.Status == 'Completed'){
                window.clearInterval(component.get('v.intervalId'));
                component.set("v.disablePrintButtn", false);                  
                resolve(true);
            }else{
                resolve(false);
            }
            
        });
    },
    getBatchJobStatus : function (component){        
        return new Promise($A.getCallback(
            function(resolve,reject){                
                let action = component.get('c.getBatchJobStatus');
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
    setConductorURLfield : function (component, generatePDF){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.setConductorURLfield');
            action.setParams({
                conductorId : component.get('v.conductorId'),
                setPDFfield : generatePDF
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
    setCustomSettings : function(component){
        return new Promise($A.getCallback(
            function(resolve, reject){
                let providerList = component.get("v.providerList");
                let payoutDate = component.get("v.payoutDate");
                let reportDate = component.get("v.reportDate");
                let countSelected = component.get("v.countSelected");
                let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
                businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
                let selectedIds = [];
                
                if(countSelected != 0){
                    for(let i=0; i<providerList.length; i++){
                        if(providerList[i].checked == true){
                            selectedIds.push("'" + providerList[i].assessmentProviderId + "'");
                        }
                    }
                }

                let action = component.get('c.setCustomSetting');
                action.setParams({
                    selectedIds : selectedIds, 
                    payoutDate : payoutDate, 
                    reportDate : reportDate,
                    businessUnitFilter: businessUnitFilterValue
                });
                action.setCallback(this, function (response) {
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        resolve(response.getReturnValue());
                    }else if (state === 'ERROR') {
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