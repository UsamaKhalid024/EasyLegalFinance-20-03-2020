({
    searchButton: function(component, event, helper) {
        component.set("v.spinner", true);
        helper.setBUCustomSettings(component);
        helper.getReportCongaURL(component).then($A.getCallback(
            function(result){ 
                component.set('v.ViewAllUrl', result[0].Conga_Lawyer_Sales_Summary_View_All__c);
                component.set('v.PrintAllUrl', result[0].Conga_Lawyer_Sales_Summary_Print_All__c);
            }));
        helper.getAmountGroupByLawyer(component).then($A.getCallback(
            function(result){
                component.set('v.AmountByLawyer', result);
                helper.GetFileTotalAndAmountTotalForLawyer(component);
                //return helper.getPartialPaymentsData(component);
                let filter = component.get("v.selectedBusinessUnitFilter");
                if(filter == "Consolidated"){
                    component.set("v.design", true); 
                }else{
                    component.set("v.design", false); 
                }
                
                component.set("v.ChosenFilter", component.get("v.selectedBusinessUnitFilter"));
                component.set("v.spinner", false);
            }
        )).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        
        
    },
    doInit : function(component, event, helper) {
        
        component.set("v.spinner", true);
        
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        
        helper.getReportCongaURL(component).then($A.getCallback(
            function(result){ 
                component.set('v.ViewAllUrl', result[0].Conga_Lawyer_Sales_Summary_View_All__c);
                component.set('v.PrintAllUrl', result[0].Conga_Lawyer_Sales_Summary_Print_All__c);
            }));
        
        helper.getCustomSettings(component).then($A.getCallback(
            function(result){ 
                component.set('v.customSetting', result);
                return helper.setDefaultDates(component);
            })
                                                ).then($A.getCallback(function(result){
            return helper.getAmountGroupByLawyer(component);
        })).then($A.getCallback(
            
            function(result){
                component.set('v.AmountByLawyer', result);
                let filter = component.get("v.selectedBusinessUnitFilter");
                if(filter == "Consolidated"){
                    component.set("v.design", true); 
                }else{
                    component.set("v.design", false); 
                }
                helper.GetFileTotalAndAmountTotalForLawyer(component);
                //return helper.getPartialPaymentsData(component);
                component.set("v.spinner", false);
            }
            
        )).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        
                
    },
    
    filterButton : function(component, event, helper){
        
        component.set("v.spinner", true);
        
        helper.getAmountGroupByLawyer(component).then($A.getCallback(
            function(result){
                helper.setDateCustomSettings(component);
                component.set('v.AmountByLawyer', result);
                helper.GetFileTotalAndAmountTotalForLawyer(component);
            }
        )).then(
            function(){
                
                helper.getReportCongaURL(component).then($A.getCallback(
                    function(result){ 
                        component.set('v.ViewAllUrl', result[0].Conga_Lawyer_Sales_Summary_View_All__c);
                        component.set('v.PrintAllUrl', result[0].Conga_Lawyer_Sales_Summary_Print_All__c);
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
        component.set('v.sortOrder',sortOrder); 
        
        component.set("v.spinner", true);
        
        //helper.getLawyersList(component,event);
        helper.getAmountGroupByLawyer(component).then($A.getCallback(
            function(result){ 
                component.set('v.AmountByLawyer', result);
                return helper.GetFileTotalAndAmountTotalForLawyer(component);
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
    },
    handleViewAllButtonMenu : function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        
        let newWin;
        let url = '';
        
        
        if(selectedMenuItemValue == "ViewAll"){
            url = component.get('v.ViewAllUrl');
        }else if(selectedMenuItemValue == "PayoutViewAll"){
            url = '/apex/LawyerSalesSummaryPayoutReportVF?StartDate='+component.get('v.startDate')+'&EndDate='+component.get('v.endDate')+'&BusinessUnit='+component.get('v.selectedBusinessUnitFilter')+ '&ContentType=Excel';
        }
        
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    handleViewAllPDFButtonMenu : function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        
        let newWin;
        let url = '';
        
        
        if(selectedMenuItemValue == "ViewAll"){
            url = component.get('v.ViewAllUrl') +'%26'+'DefaultPDF=1';
        }else if(selectedMenuItemValue == "PayoutViewAll"){
            url = '/apex/LawyerSalesSummaryPayoutReportVF?StartDate='+component.get('v.startDate')+'&EndDate='+component.get('v.endDate')+'&BusinessUnit='+component.get('v.selectedBusinessUnitFilter')+ '&ContentType=PDF';
        }
        
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    }
})