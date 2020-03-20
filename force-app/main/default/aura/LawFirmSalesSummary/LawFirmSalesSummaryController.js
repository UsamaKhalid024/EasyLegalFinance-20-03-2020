({
    doInit : function(component, event, helper) {
        
        component.set("v.spinner", true);
        
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        helper.getReportCongaURL(component).then($A.getCallback(
            function(result){ 
                component.set('v.ViewAllUrl', result[0].Conga_Law_Firm_Sales_Summary_View_All__c);
                component.set('v.PrintAllUrl', result[0].Conga_Law_Firm_Sales_Summary_Print_All__c);
            }));
        
        helper.getCustomSettings(component).then($A.getCallback(
            function(result){ 
                component.set('v.customSetting', result);
                console.log('customSetting:'+component.get('v.customSetting.Business_Unit__c'));
                let filter = component.get("v.selectedBusinessUnitFilter");
                if(filter == "Consolidated"){
                    component.set("v.design", true); 
                }else{
                    component.set("v.design", false); 
                }
                return helper.setDefaultDates(component);
            })).then($A.getCallback(function(result){
            		return helper.getAmountGroupByLawFirm(component);
        })).then($A.getCallback(
            function(result){
                component.set('v.AmountByLawFirm', result);
                helper.GetFileTotalAndAmountTotalForLawFirm(component);
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
        
        helper.getAmountGroupByLawFirm(component).then($A.getCallback(
            function(result){
                helper.setCustomSettings(component);
                component.set('v.AmountByLawFirm', result);
                helper.GetFileTotalAndAmountTotalForLawFirm(component);
                let filter = component.get("v.selectedBusinessUnitFilter");
                if(filter == "Consolidated"){
                    component.set("v.design", true); 
                }else{
                    component.set("v.design", false); 
                }
                
                component.set("v.ChosenFilter", component.get("v.selectedBusinessUnitFilter"));
            }
        )).then(
            function(){
                
                helper.getReportCongaURL(component).then($A.getCallback(
                    function(result){ 
                        component.set('v.ViewAllUrl', result[0].Conga_Law_Firm_Sales_Summary_View_All__c);
                        component.set('v.PrintAllUrl', result[0].Conga_Law_Firm_Sales_Summary_Print_All__c);
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
        helper.getAmountGroupByLawFirm(component).then($A.getCallback(
            function(result){ 
                component.set('v.AmountByLawFirm', result);
                return helper.GetFileTotalAndAmountTotalForLawFirm(component);
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
            url = '/apex/LawFirmSalesSummaryPayoutReportVF?StartDate='+component.get('v.startDate')+'&EndDate='+component.get('v.endDate')+'&BusinessUnit='+component.get('v.selectedBusinessUnitFilter')+ '&ContentType=Excel';
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
            url = '/apex/LawFirmSalesSummaryPayoutReportVF?StartDate='+component.get('v.startDate')+'&EndDate='+component.get('v.endDate')+'&BusinessUnit='+component.get('v.selectedBusinessUnitFilter')+ '&ContentType=PDF';
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