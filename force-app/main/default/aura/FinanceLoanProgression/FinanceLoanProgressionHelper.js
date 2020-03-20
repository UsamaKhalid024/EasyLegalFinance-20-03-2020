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
    
    setDefaultDates : function(component){
        return new Promise(function(resolve,reject){
        let dt = new Date();
        let customSetting = component.get('v.customSetting');  
        let defaultEndDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
        let defaultStartDate = dt.getFullYear() +'-'+ (dt.getMonth()) +'-01';
        try{
                component.set("v.endDate", customSetting.End_Date__c == null ? defaultEndDate : customSetting.End_Date__c);
                component.set("v.startDate", customSetting.Start_Date__c == null ? defaultStartDate : customSetting.Start_Date__c); 
            
            	resolve(true);
            }catch(e){
                reject(new Error('Not defined.'));                
            }  
        });
    },
    
    getData : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.getData');
            action.setParams({
                startDate : component.get('v.startDate'),
                endDate : component.get('v.endDate'),
                field : component.get('v.sortField'),
                direction : component.get('v.sortOrder')
            });
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    console.log('getData returns this result:');
                    console.log(response.getReturnValue());
                    resolve(response.getReturnValue());
                }else if(state === 'ERROR'){
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    },
    getReportCongaURL : function(component){
        return new Promise($A.getCallback(function(resolve, reject){
            let action = component.get('c.getDrawdownCongaURLs');
            action.setCallback(this,function(response){
                let state = response.getState();
                if(state === 'SUCCESS'){
                    console.log('drawdown report view all.');
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
    
    GetFileTotalAndAmountTotal : function(component){
        /*
        var paymentData = component.get('v.AllAmount');
        // calculate financial summary total for file and amount
        var AdvancesCount = 0;
        var AdvancesAmount = 0;
        var LossesCount = 0;
        var LossesAmount = 0;
            
        for(var i = 0; i < paymentData.length; i++){
            AdvancesCount += (paymentData[i].opportunitiesp == null) ? 0 : paymentData[i].opportunitiesp;
            AdvancesAmount += (paymentData[i].amountp == null) ? 0 : paymentData[i].amountp;
            LossesCount += (paymentData[i].opportunitiesb == null) ? 0 : paymentData[i].opportunitiesb;
            LossesAmount += (paymentData[i].amountb == null) ? 0 : paymentData[i].amountb;
        }
        component.set("v.AdvancesAmount", AdvancesAmount); 
        component.set("v.AdvancesCount", AdvancesCount); 
        component.set("v.LossesAmount", LossesAmount); 
        component.set("v.LossesCount", LossesCount);
        */
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