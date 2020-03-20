({
	doInit : function(component, event, helper) {
        component.set("v.spinner", true);

        helper.getPickListValues(component, 'Assessment_Provider_Schedule__c','Rebate_Period__c','listRebatePeriodValues');
        
        helper.getAssessmentProviderInfo(component).then($A.getCallback(
            function(result){
                component.set('v.assessmentProvider',result);
                component.set('v.assessmentProviderSchedule.Assessment_Provider__c',result.Id);
                component.set('v.assessmentProviderSchedule.Discount__c', 0);  
                component.set('v.assessmentProviderSchedule.Rebate_Discount__c', 0);
                component.set('v.assessmentProviderSchedule.Rebate_Period__c', '');              
                return helper.getCurrentUserInfo(component);
            }
        )).then(
            function(result){
                component.set('v.currentUser', result);
            }
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(component, errors);
            }
        );
        
        helper.getAssessmentSchedules(component).then(
            function(result){
            	//var rowActions = helper.getRowActions.bind(this, component);
                component.set('v.columns', [
                    {label: 'Lawyer', fieldName: 'linkLawyer', type: 'url', typeAttributes: {label: { fieldName: 'LawyerName' }, target: '_blank'}, sortable: true},            
                    {label: 'Deferred Revenue Rate', fieldName: 'discount', type: 'percent', typeAttributes:{minimumFractionDigits : '2'}, sortable: true},
                    {label: 'Client Rebate', fieldName: 'rebateDiscount', type: 'percent', typeAttributes:{minimumFractionDigits : '2'}, sortable: true},
                    {label: 'Rebate Period', fieldName: 'Rebate_Period__c', type: 'text', sortable: true},
                    {label: 'Created Date', fieldName: 'CreatedDate', type: 'date', cellAttributes: { alignment: 'right' }, typeAttributes:{ year : "numeric", month: "long", day:"2-digit"} ,sortable: true},
            		{label: 'Created By', fieldName: 'CreatedByName', type: 'text', sortable: true}
                    //{type: 'action', label: 'Action', typeAttributes: {rowActions: rowActions}}
                     ]);

                component.set('v.data',result);
                
            }
        ).then(
            function(){
                helper.sortData(component,component.get("v.sortBy"),component.get("v.sortDirection"));
                component.set("v.datatableIsSet", true);
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(component, errors);
            }
        );
	},
    toggleSection : function(component, event, helper){
        var section = event.currentTarget.getAttribute('data-section');
        var expandedSections = component.get('v.expandedSections') || {};
        expandedSections[section] = !expandedSections[section];
        component.set('v.expandedSections', expandedSections);
    },
    inlineEditName : function(component,event,helper){       
        var clickSource = event.currentTarget.dataset.source;
        // show the name edit field popup 
        
        component.set("v.clickSource", clickSource); 
        var selectedRecVar = event.currentTarget.dataset.recvar;
        if(selectedRecVar){
            component.set("v."+selectedRecVar,{});
        }
        
        // after the 100 millisecond set focus to input field   
        setTimeout(function(){ 
            try
            {
                component.find(clickSource).focus();
                component.find(clickSource).click();
            }
            catch(e){ }
        }, 100);
    },
    hideLookupInput : function(component, event, helper) {
        let clickSource = component.get("v.clickSource");        
        component.set("v.clickSource", "none");

        let lawFirm = component.get('v.selectedLookUpLawFirm');
        let lawyer = component.get('v.selectedLookUpLawyer');

        let lookUpId = component.get("v.selectedLookupOption") == 'Law Firm'? lawFirm.Id : lawyer.Id;
        if(clickSource != 'none' && lookUpId != null && lookUpId != ''){
            
            component.set("v.spinner", true);
            helper.isRebateAllowed(component,lookUpId).then(
                $A.getCallback(function(result) {
                    component.set("v.rebateAllowed", result);
                    component.set("v.showRebateWarning", !result);
                    component.set("v.spinner", false);
                }),
                $A.getCallback(function(errors) {
                    if (errors[0] && errors[0].message) {
                        helper.errorsHandler(errors)
                    }else {
                        helper.unknownErrorsHandler();
                    }
                    
                }));
        }
    },
    
    saveLawFirmLawyerRecord : function(component, event, helper){
        
        component.set("v.spinner", true);
        helper.createAssessmentSchedules(component).then($A.getCallback(
            function(result){
                component.set("v.spinner", false);
                component.set('v.selectedLookUpLawFirm', null);
                component.set('v.selectedLookUpLawyer', null);
                component.set('v.assessmentProviderSchedule.Discount__c', 0);
                component.set('v.assessmentProviderSchedule.Rebate_Discount__c', 0);
                component.set('v.assessmentProviderSchedule.Rebate_Period__c', '');
                component.set("v.showRebateWarning", false);
                component.set("v.rebateAllowed", false);
                
                helper.showToast(component, 'SUCCESS', 'Successfully created assessment provider schedule.', 'success');
                return helper.getAssessmentSchedules(component);
            }
        )).then(
            function(result){
                component.set('v.data',result);
            }
        ).then(
            function(){
                component.set("v.sortBy", 'CreatedDate');
                component.set("v.sortDirection", 'desc');
                helper.sortData(component,component.get("v.sortBy"),component.get("v.sortDirection"));
                component.set("v.datatableIsSet", true);
                component.set("v.spinner", false);
            }
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(component, errors);
            }
        );
    },
    
    saveRecordButton : function(component, event, helper){
        
        let aProviderObj = component.get('v.assessmentProvider');
        let lawFirm = component.get('v.selectedLookUpLawFirm');
        let lawyer = component.get('v.selectedLookUpLawyer');
        let selOption = component.get('v.selectedLookupOption');
        
        var inputField = component.find('discountRateField');
        var value = inputField.get('v.value');
        inputField.setCustomValidity('');
        inputField.reportValidity();
        
        console.log('value  ' + value);
        if(value <= 0) {
            console.log('show error');
            inputField.setCustomValidity('Discount must be greater than zero.'); //do not get any message
			inputField.reportValidity();
        }else{
            
            if(selOption == 'Law Firm'){
                if(lawFirm.Id == null || lawFirm.Id == ''){
                    helper.showToast(component, 'EROR', 'Law Firm is missing. Please select a Law Firm.', 'error');
                }else{                    
                    $A.enqueueAction(component.get("c.saveLawFirmLawyerRecord"));
                }
            }else if(selOption == 'Lawyer'){
                if(lawyer.Id == null || lawyer.Id == ''){
                    helper.showToast(component, 'EROR', 'Lawyer is missing. Please select a Lawyer.', 'error');
                }else{
                    component.set('v.assessmentProviderSchedule.Lawyer__c', lawyer.Id);
                    $A.enqueueAction(component.get("c.saveLawFirmLawyerRecord"));
                }
            }
        }
        
    },
    handleSort : function(component,event,helper){
        //Returns the field which has to be sorted
        var sortBy = event.getParam("fieldName");
        //returns the direction of sorting like asc or desc
        var sortDirection = event.getParam("sortDirection");
        //Set the sortBy and SortDirection attributes
        component.set("v.sortBy",sortBy);
        component.set("v.sortDirection",sortDirection);
        // call sortData helper function
        helper.sortData(component,sortBy,sortDirection);
    },
    handleRowAction : function(component,event, helper){
        var action = event.getParam("action"),
            row = event.getParam("row");
        
        $A.createComponent(
            "c:EditAssessmentProviderSchedule",
            {recordIdParam : row.Id},
            function(result, status){
                if (status === "SUCCESS") {
                    component.find('overlayLib').showCustomModal({
                        header: "Edit : Assessment Provider Schedule",
                        body: result, 
                        showCloseButton: true,
                        cssClass: "mymodal", 
                        closeCallback: function() {
                           component.set("v.spinner", true);
                            helper.getAssessmentSchedules(component).then(
                                function(result){
                                    component.set('v.data',result);
                                }
                            ).then(
                                function(){
                                    component.set("v.sortBy", 'CreatedDate');
                                    component.set("v.sortDirection", 'desc');
                                    helper.sortData(component,component.get("v.sortBy"),component.get("v.sortDirection"));
                                    component.set("v.datatableIsSet", true);
                                    component.set("v.spinner", false);
                                }
                            ).catch(
                                function(errors){
                                    console.log(errors);
                                    component.set("v.spinner", false);
                                    helper.errorsHandler(component, errors);
                                }
                            );
                       }
                    })
                }
            }
        );
    },
    handleLookupToggleRadio : function(component,event, helper){
        component.set("v.spinner", true);
        component.set('v.selectedLookupOption', event.getSource().get('v.value'));
        component.set("v.rebateAllowed", false);
        component.set('v.selectedLookUpLawFirm', null);
        component.set('v.selectedLookUpLawyer', null);
        component.set('v.assessmentProviderSchedule.Discount__c', 0);
        component.set('v.assessmentProviderSchedule.Rebate_Discount__c', 0);
        component.set('v.assessmentProviderSchedule.Rebate_Period__c', '');
        component.set("v.showRebateWarning", false);
        component.set("v.spinner", false);
    },
    discountRateChangeValidation :function (component,event, helper){
        var inputField = component.find('discountRateField');
        var value = inputField.get('v.value');
        if(value > 0){
            inputField.setCustomValidity(''); //do not get any message
            inputField.reportValidity();
        }
	}
})