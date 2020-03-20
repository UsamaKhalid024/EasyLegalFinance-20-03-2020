({
    doInit : function(component, event, helper) {
        component.set("v.spinner", true);
        
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        
        helper.getReportCongaURL(component).then($A.getCallback(
            function(result){ 
                component.set('v.ViewAllUrl', result[0].Conga_Finance_Loan_Progression_View_All__c);
                component.set('v.PrintAllUrl', result[0].Conga_Finance_Loan_Progression_Print_All__c);
            }));
        
        helper.getCustomSettings(component).then($A.getCallback(function(result){
            component.set('v.customSetting', result);
            return helper.setDefaultDates(component);
        })).then($A.getCallback(function(result){
            return helper.getFinancialProgressionData(component);
        })).then($A.getCallback(function(result){
            component.set("v.progressionReportData", result);
            return helper.calculateGrandTotal(component);
        })).then(function(){
            component.set("v.spinner", false);
        }).catch(function(error){
            console.log('error ' + error);
            component.set("v.spinner", false);
            helper.errorsHandler(errors);
            
        });
        
        component.set("v.spinner", false);
    },
    filterButton : function(component, event, helper){
        component.set("v.spinner", true);
        helper.getFinancialProgressionData(component).then(function(result){
            component.set("v.businessUnitForDesign", component.get("v.selectedBusinessUnitFilter"));
            component.set("v.progressionReportData", result);
            return helper.calculateGrandTotal(component);
            
        }).then($A.getCallback(function(){
            
            return helper.getReportCongaURL(component);
            
        })).then(function(result){
            component.set("v.spinner", false);
            component.set('v.ViewAllUrl', result[0].Conga_Finance_Loan_Progression_View_All__c);
            component.set('v.PrintAllUrl', result[0].Conga_Finance_Loan_Progression_Print_All__c);
        }).catch(function(error){
            component.set("v.spinner", false);
            console.log('error ' + error);
        });
    },    
})