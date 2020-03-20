({
    getCalendarMin : function(component){
        var year = new Date().getFullYear() - 5;
        var min = year+'-01-01';
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
            let defaultStartDate = dt.getFullYear() +'-'+ (dt.getMonth()) +'-01';
            try{
                component.set("v.endDate", customSetting.End_Date__c == null ? defaultEndDate : customSetting.End_Date__c);
                component.set("v.startDate", customSetting.Start_Date__c == null ? defaultStartDate : customSetting.Start_Date__c); 
                component.set("v.selectedBusinessUnitFilter", customSetting.Business_Unit__c == null ? '' : customSetting.Business_Unit__c); 
                component.set("v.selectedBusinessUnit", customSetting.Business_Unit__c == null ? '' : customSetting.Business_Unit__c); 
            	resolve(true);
            }catch(e){
                reject(new Error('Not defined.'));                
            }  
        });
    },
    
    getPaymentsGroupByProvince : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.getPaymentsGroupByProvince');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                businessUnit : component.get("v.selectedBusinessUnitFilter")
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
    
    getPartialPaymentsData : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.getPartialPayments');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                businessUnit : component.get("v.selectedBusinessUnitFilter")
            });
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    console.log('Partial Payments.');
                    console.log(response.getReturnValue());
                    resolve(response.getReturnValue());
                }else if(state === 'ERROR'){
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    setDateCustomSettings : function(component){
        console.log('+++++');
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.saveDateCustomSettings');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                businessUnit: component.get('v.selectedBusinessUnitFilter')
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
    getPickListValues : function(component, object, field, attributeId){
        return new Promise($A.getCallback(function(resolve, reject){
            
            var picklistgetter = component.get('c.getPickListValues');
            picklistgetter.setParams({
                objectType: object,
                field: field
            });
            
            
            picklistgetter.setCallback(this, function(response){
                var opts = [];
                console.log('picklist recieved with status: '+response.getState());
                if(response.getState() == 'SUCCESS')
                {
                    var allValues = response.getReturnValue();
                    console.log('picklist recieved with values: '+JSON.stringify(response.getReturnValue()));
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
                resolve(opts);
            }
        });
            $A.enqueueAction(picklistgetter);
            
        }));
        
    },
    getCustomSettings : function(component){
        //get report dates from custom setting
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.getCustomSetting');                
                action.setCallback(this,function(response){
                    let state = response.getState();
                    if(state === 'SUCCESS'){
                        console.log('1');
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
    
    calculateReportByProvinceData : function(component){
        var paymentData = component.get('v.paymentsByProvince');
        // calculate financial summary total for file and amount
        var accountTotalRhino = 0;
        var opptyTotalRhino = 0;
        var amountTotalRhino = 0;
        var opptyTotalELFI = 0;
        var accountTotalELFI = 0;
        var amountTotalELFI = 0;
            
        for(var i = 0; i < paymentData.length; i++){
            accountTotalRhino += (paymentData[i].numAccountsRhino == null) ? 0 : paymentData[i].numAccountsRhino;
            opptyTotalRhino += (paymentData[i].numOpptiesRhino == null) ? 0 : paymentData[i].numOpptiesRhino;
            amountTotalRhino += (paymentData[i].amountRhino == null) ? 0 : paymentData[i].amountRhino;
            accountTotalELFI += (paymentData[i].numAccountsELFI == null) ? 0 : paymentData[i].numAccountsELFI;
            opptyTotalELFI += (paymentData[i].numOpptiesELFI == null) ? 0 : paymentData[i].numOpptiesELFI;
            amountTotalELFI += (paymentData[i].amountELFI == null) ? 0 : paymentData[i].amountELFI;
        }
        component.set("v.accountTotalRhino", accountTotalRhino); 
        component.set("v.opptyTotalRhino", opptyTotalRhino); 
        component.set("v.amountTotalRhino", amountTotalRhino); 
        component.set("v.accountTotalELFI", accountTotalELFI); 
        component.set("v.opptyTotalELFI", opptyTotalELFI); 
        component.set("v.amountTotalELFI", amountTotalELFI); 
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