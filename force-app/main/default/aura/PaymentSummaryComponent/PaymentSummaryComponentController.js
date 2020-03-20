({
    doInit : function(component, event, helper) {
        
        component.set("v.spinner", true);
        
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        //helper.setDefaultDates(component);
        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions').then($A.getCallback(
            function(result){
                return helper.getCustomSettings(component);
        })).then($A.getCallback(
            function(result){ 
                component.set('v.customSetting', result);
                return helper.setDefaultDates(component);
            })
        ).then($A.getCallback(function(result){
            return helper.getPaymentsGroupByProvince(component);
        })).then($A.getCallback(
            function(result){
                component.set('v.paymentsByProvince',result);
                helper.calculateReportByProvinceData(component);
                return helper.getPartialPaymentsData(component);
            }
        )).then(
            $A.getCallback(
                function(result){
                    component.set('v.partialPayments',result);
                })
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        
        component.set("v.spinner", false);        
    },
    
    filterButton : function(component, event, helper){
        
        component.set("v.spinner", true);
        component.set('v.selectedBusinessUnit', component.get('v.selectedBusinessUnitFilter'));
        helper.getPaymentsGroupByProvince(component).then($A.getCallback(
            function(result){
                helper.setDateCustomSettings(component);
                component.set('v.paymentsByProvince',result);
                helper.calculateReportByProvinceData(component);
                return helper.getPartialPaymentsData(component);
            }
        )).then($A.getCallback(
            function(result){
                component.set('v.partialPayments',result);                
            }
        )).then(
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
})