({
    doInit : function(component, event, helper) {
        
        component.set("v.spinner", true);
        
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        helper.getReportCongaURL(component).then($A.getCallback(
            function(result){ 
                component.set('v.ViewAllUrl', result[0].Conga_Finance_Loan_Progression_View_All__c);
                component.set('v.PrintAllUrl', result[0].Conga_Finance_Loan_Progression_Print_All__c);
            }));
        
        helper.getCustomSettings(component).then($A.getCallback(
            function(result){ 
                component.set('v.customSetting', result);
                return helper.setDefaultDates(component);
            })
                                                ).then($A.getCallback(function(result){
            return helper.getData(component);
        })).then($A.getCallback(
            function(result){
                component.set('v.mainData', result);
                
                console.log('Allamount map has got');
                console.log(result);

                helper.GetFileTotalAndAmountTotal(component);
            }
        )).catch(
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
        
        helper.getData(component).then($A.getCallback(
            function(result){
                helper.setDateCustomSettings(component);
                component.set('v.mainData', result);
                helper.GetFileTotalAndAmountTotal(component);
            }
        )).then(
            function(){
                
                helper.getReportCongaURL(component).then($A.getCallback(
                    function(result){ 
                        component.set('v.ViewAllUrl', result[0].Conga_Finance_Loan_Progression_View_All__c);
                        component.set('v.PrintAllUrl', result[0].Conga_Finance_Loan_Progression_Print_All__c);
                   
                   })
                                                        );
                
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
    },
    sort: function(component, event, helper) {  
        
        let selectedItem = event.currentTarget;
        let field = selectedItem.dataset.field;
        let sortOrder = component.get('v.sortOrder');
        let oldField = component.get('v.sortField');
        
        sortOrder = (sortOrder == 'DESC' && oldField == field) ? 'ASC' : 'DESC';
        
        component.set('v.sortField',field);   
        component.set('v.sortOrder',sortOrder); https://easylegalfinance--qa.cs24.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage#
        
        component.set("v.spinner", true);
        
        //helper.getLawyersList(component,event);
        helper.getData(component).then($A.getCallback(
            function(result){ 
                component.set('v.mainData', result);
                
                console.log('Allamount map has got');
                console.log(result);
                
                return helper.GetFileTotalAndAmountTotal(component);
            })
                                                     ).then($A.getCallback(
            function(result){
                
                component.set("v.spinner", false);
            })
                                                           ).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );         
    }
})