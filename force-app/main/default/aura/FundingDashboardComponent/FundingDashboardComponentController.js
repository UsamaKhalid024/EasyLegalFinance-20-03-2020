({
    doInit : function(component, event, helper) {
        
        component.set("v.spinner", true);
        
        var options = [
            { value: "ELFI", label: "ELFI" },
            { value: "Rhino", label: "Rhino" },
            { value: "Consolidated", label: "Consolidated" }
        ];
        component.set("v.businessUnitOptions", options);
        
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);

        helper.getCustomSettings(component).then($A.getCallback(
            function(result){ 
                component.set('v.customSetting', result);
                return helper.setDefaultDates(component);
                
            })).then($A.getCallback(function(result){
            return helper.getData(component);
        })).then($A.getCallback(function(result){
            
            component.set("v.spinner", false);  
            component.set('v.mainData', result);
            
                console.log('Allamount map has got');
                console.log(component.get('v.mainData.numActiveFiles'));

        })).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
                component.set("v.spinner", false);  
            }
        );
        
              
    },
    
    filterButton : function(component, event, helper){
        
        component.set("v.spinner", true);
        
        helper.setBUCustomSettings(component);
        
        helper.getData(component).then($A.getCallback(
            function(result){
                helper.setDateCustomSettings(component);
                component.set('v.mainData', result);
                component.set('v.showDetailsCard', component.get('v.showDetails'));
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
    },
    viewAllButton : function (component, event, helper) {
		        
        let newWin;
        let url = '/apex/FundingDashboardViewAll?StartDate='+component.get('v.startDate')+'&EndDate='+component.get('v.endDate')+'&BusinessUnit='+component.get('v.selectedBusinessUnitFilter');
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    printButton : function (component, event, helper) {
		        
        let newWin;
        let url = '/apex/FundingDashboardPrintReport?StartDate='+component.get('v.startDate')+'&EndDate='+component.get('v.endDate')+'&BusinessUnit='+component.get('v.selectedBusinessUnitFilter');
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    }
})