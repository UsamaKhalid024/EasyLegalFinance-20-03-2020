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
	getLeadsByMonth : function(component) {
        return new Promise($A.getCallback(
            function(resolve,reject){
                let action = component.get('c.getLeadsByMonth');
                action.setParams({
                    startDate : component.get('v.startDate'),
                    endDate : component.get('v.endDate'),
                    businessUnit : component.get("v.selectedBusinessUnitFilter")
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
    
    getSampleLead : function(component) {
        let action = component.get('c.getSampleLead');
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){    
                component.set('v.sampleLead', response.getReturnValue());
            }else if(state === 'ERROR'){
                helper.errorsHandler(response.getError());
            }
        });
        $A.enqueueAction(action);
        
    },
    
    calculateTotal : function(component){
        let leads = component.get('v.LeadsByMonth');
        let totalAmountRhino = 0.00;
        let totalRecordCountRhino = 0;
        let totalConvertedLeadsRhino = 0;
        
        let totalAmountELFI = 0.00;
        let totalRecordCountELFI = 0;
        let totalConvertedLeadsELFI = 0;
        
        for(let i=0; i<leads.length; i++){
            totalAmountRhino += leads[i].SumofAmountPaidtoClientRhino;
            totalRecordCountRhino += leads[i].RecordCountRhino;
            totalConvertedLeadsRhino += leads[i].SumofConvertedLeadsRhino;
            
            totalAmountELFI += leads[i].SumofAmountPaidtoClientELFI;
            totalRecordCountELFI += leads[i].RecordCountELFI;
            totalConvertedLeadsELFI += leads[i].SumofConvertedLeadsELFI;
        }
        component.set('v.totalAmountPaidtoClientRhino',totalAmountRhino);
        component.set('v.totalRecordsRhino',totalRecordCountRhino);
        component.set('v.totalConvertedRhino',totalConvertedLeadsRhino);
        
        component.set('v.totalAmountPaidtoClientELFI',totalAmountELFI);
        component.set('v.totalRecordsELFI',totalRecordCountELFI);
        component.set('v.totalConvertedELFI',totalConvertedLeadsELFI);
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
    setCustomSettings : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.saveCustomSettings');
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
                    resolve(true);
                }else if(state === 'ERROR'){
                    console.log('The start date and end date in custom settings could not be updated.');
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    }
})