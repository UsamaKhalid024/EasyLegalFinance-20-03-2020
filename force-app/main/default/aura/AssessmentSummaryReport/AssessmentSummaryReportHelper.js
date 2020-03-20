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
                let assessmentOpps = component.get("v.data");
                let payoutDate = component.get("v.payoutDate");
                let reportDate = component.get("v.reportDate");
                let selectedRowsMap = component.get("v.selectedRowsMap");
                let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
                businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
                
                let selectedIds = [];
                let oppList = [];
                for(let i=0; i<assessmentOpps.length; i++){
                    if(assessmentOpps[i].checked == true){
                        selectedIds.push("'" + assessmentOpps[i].lawyerId + "'");
                        oppList.push(assessmentOpps[i]);
                    }
                }
                if(selectedIds.length == 0 && component.get("v.selectedRowsCount") == 0){
                    component.set('v.spinner', false);
                    alert("Please select records.");
                }else{
                    //alert("Total " + selectedIds.length);
                    var action = component.get('c.generate');
                    action.setParams({
                        selectedIds : selectedIds, 
                        payoutDate : payoutDate, 
                        reportDate : reportDate,
                        businessUnitFilter: businessUnitFilterValue,
                        selectedIdsMap : selectedRowsMap
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
                    businessUnitFilter: businessUnitFilterValue,
                    selectedIdsMap : {}
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
    pingBatchJobStatus : function (component, helper){ 
        console.log('Is pinging..');
        helper.getBatchJobStatus(component).then($A.getCallback(
            function(result){
                console.log('result ' + result);
                component.set('v.apexBatchProgressResult', result);
                helper.updateProgress(component);
                component.set("v.spinner", false);
            }
        )).catch(
            function(errors){
                console.log('ERROR --> ' + JSON.stringify(errors))
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
    },
    updateProgress : function (component){
        return new Promise(function(resolve, reject){
            let apexBatchProgressResult = component.get('v.apexBatchProgressResult');
                component.set('v.batchJobProgress',apexBatchProgressResult);
                component.set('v.batchJobItems', ' '+ parseFloat(apexBatchProgressResult).toFixed(0) + '%');
            
            if(parseFloat(apexBatchProgressResult).toFixed(0) == 100){
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
                        console.log('rr ' + response.getReturnValue());
                        resolve(response.getReturnValue());
                    }else if(state === 'ERROR'){
                        console.log('ERROR --- ' + JSON.stringify(response.getError()));
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));
    },
    setCustomSettings : function(component){
        return new Promise($A.getCallback(
            function(resolve, reject){
                let assessmentOpps = component.get("v.data");
                let payoutDate = component.get("v.payoutDate");
                let reportDate = component.get("v.reportDate");
                let countSelected = component.get("v.countSelected");
                let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
                businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
                let selectedIds = [];
                let oppList = [];
                
                if(countSelected != 0){
                    for(let i=0; i<assessmentOpps.length; i++){
                        if(assessmentOpps[i].checked == true){
                            selectedIds.push("'" + assessmentOpps[i].lawyerId + "'");
                            oppList.push(assessmentOpps[i]);
                        }
                    }
                }
                
                console.log('selectedIds ' + selectedIds);

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
    },
    getClientAccounts : function(component, lawyerIdParam){
        return new Promise($A.getCallback(
            function(resolve, reject){
                let action = component.get("c.getClientAccounts");
                let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
                businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
                action.setParams({
                    lawyerId : lawyerIdParam,
                    businessUnitFilter: businessUnitFilterValue
                });
                
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        let selectedIds = [];
                        let selectedRowsMap =  component.get("v.selectedRowsMap");
                        if(selectedRowsMap[lawyerIdParam] != undefined && selectedRowsMap[lawyerIdParam] != null){
                            selectedIds = selectedRowsMap[lawyerIdParam];
                        }
                        let result = response.getReturnValue();
                        result.forEach(function (element) {
                            element.checked = false;
                            if(selectedIds.indexOf(element.Id) > -1)
                                element.checked = true;
                            
                        });
                        resolve(result);
                    }else if (state === 'ERROR') {
                        reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            }
        ));        
    },
    resetAttributes : function(component){
        component.set("v.tempSelectedRows", []);
        component.set("v.selectedRowsMap", {});
        component.set("v.selectedLawyer", "");
        component.set("v.selectedRowsCount", 0);
        component.set("v.selectedRows", []);
    },
    filterRecords: function(component, filter) {
        component.set("v.spinner", true);
        let selectedIds = component.get("v.tempSelectedRows");
        component.set("v.selectedRows", selectedIds);
        var accData = component.get("v.accData"),
            term = filter,
            results = accData, regex;
        try {
            regex = new RegExp(term, "i");
            // filter checks each row, constructs new array where function returns true
            results = accData.filter(row=>regex.test(row.AccountNumber) || regex.test(row.Name_Formula__c));
        } catch(e) {
            // invalid regex, use full list
        }
        component.set("v.filteredData", results);
        this.setClientCheckBox(component);
        component.set("v.spinner", false);
    },
    setClientCheckBox : function(component){
        let filteredData = component.get("v.filteredData");
        var comp = component.find("selectAllClientCheckbox");
        let value = false; 
        let count = 0;
        for(let i=0; i<filteredData.length; i++){
            if(filteredData[i].checked == true){
                count++;
            }
        }
        
        if(count == filteredData.length){
            value = true;
        }
        comp.set("v.value", value);
    }
    
})