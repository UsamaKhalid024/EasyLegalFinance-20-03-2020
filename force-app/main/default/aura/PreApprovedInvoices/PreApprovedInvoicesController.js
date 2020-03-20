({
	doInit : function(component, event, helper) {
        component.set("v.spinner", true);
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        component.set("v.businessUnitForDesign", "ELFI");
        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        
        helper.getPreApprovedInvoices(component).then(
            function(result){
                console.log("result");
                console.log(JSON.stringify(result));
                component.set("v.data", result);
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        
        
	},
    
    searchButton : function(component, event, helper){
        component.set("v.spinner", true);
        
        
        helper.getPreApprovedInvoices(component).then(
            function(result){
                component.set("v.data", result);
                component.set("v.businessUnitForDesign", component.get("v.selectedBusinessUnitFilter"));
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                console.log('Error ' + errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
    },
    
    sort : function(component, event, helper){
        component.set("v.spinner", true);
        let selectedItem = event.currentTarget;
        let field = selectedItem.dataset.field;
        let sortOrder = component.get('v.sortOrder');
        let oldField = component.get('v.sortField');
        sortOrder = (sortOrder == 'DESC' && oldField == field) ? 'ASC' : 'DESC';
        
        component.set('v.sortField',field);   
        component.set('v.sortOrder',sortOrder); 
        
        
        
        helper.getPreApprovedInvoices(component).then(
            function(result){
                component.set("v.data", result);
                component.set("v.businessUnitForDesign", component.get("v.selectedBusinessUnitFilter"));
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                console.log('Error ' + errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
    },
    printReportPDF: function(component, event, helper){
        
        let searchBy = '';
        if(component.get("v.searchByName") != undefined && component.get("v.searchByName") != null)
            searchBy = component.get("v.searchByName");
        
        let newWin;
        let url = '/apex/PreApprovedInvoiceVF?businessUnit=' + component.get("v.selectedBusinessUnitFilter") + "&searchByName=" + searchBy + "&ContentType=PDF";
        
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    printReportExcel: function(component, event, helper){
        
        let searchBy = '';
        if(component.get("v.searchByName") != undefined && component.get("v.searchByName") != null)
            searchBy = component.get("v.searchByName");
        
        let newWin;
        let url = '/apex/PreApprovedInvoiceVF?businessUnit=' + component.get("v.selectedBusinessUnitFilter") + "&searchByName=" + searchBy;
        
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    openLinkReport : function(component, event, helper) { 
        let assessmentProviderId = event.currentTarget.dataset.assessment;
        let lawyerId = event.currentTarget.dataset.lawyer;
        console.log('assessmentProviderId = ' + assessmentProviderId);
        console.log('lawyerId = ' + lawyerId);
        let newWin;
        let url = '/lightning/r/Report/00O0L000003n0QIUAY/view';
        
        try{                       
            newWin = window.open(url + '?fv2=' + assessmentProviderId + '&fv3=' + lawyerId);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
})