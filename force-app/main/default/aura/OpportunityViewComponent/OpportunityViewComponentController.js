/* eslint-disable no-unused-expressions */
({    
    doInit : function(component, event, helper) {
        helper.getOpportunityInfo(component);
        /*helper.getCriticalDatesList(component).then(
            $A.getCallback(function(result) {                
            }),
            $A.getCallback(function(errors) {
                if (errors[0] && errors[0].message) {
                    helper.errorsHandler(errors)
                }else {
                    helper.unknownErrorsHandler();
                }
                
            }));
        helper.getPickListValues(component, 'Critical_Date__c','Name__c','criticalDateName');*/
        
        helper.getDrawdownList(component);
        helper.getDrawdownPaymentsList(component);
        helper.getServiceProvidersList(component);
        helper.getReAssessmentOpportunitiesList(component);
        helper.getCalendarMin(component);
        helper.getCalendarMax(component); 
        helper.getSingleContactHistory(component);
        helper.getPickListValues(component, 'Service_Provider_Drawdown__c','Reference_Notes__c','providerRefNotesOptions');
        helper.getPickListValues(component, 'Service_Provider_Drawdown__c','Payment_Method__c','providerPaymentMethod');
        helper.getPickListValues(component, 'Drawdown__c','Reference_Notes__c','refNotesOptions');
        helper.getPickListValues(component, 'Drawdown__c','Payment_Method__c','paymentMethod');
        helper.getPickListValues(component, 'Drawdown__c','Type__c','drawdownType');
        helper.getPickListValues(component, 'Opportunity','Loan_Status__c','LoanStatusOptions');
        helper.getPickListValues(component, 'Opportunity','Loan_Type__c','incidentTypeOptions');
        helper.getPickListValues(component, 'Opportunity','StageName','stageOptions');
        helper.getPickListValues(component, 'Opportunity','Stage_Status__c','statusOptions');
        helper.getPickListValues(component, 'Opportunity','Type_of_Loan__c','loanTypeOptions');
        helper.getPickListValues(component, 'Opportunity','Interest_Compounding_Period__c','interestCompoundingPeriod');
        helper.getPickListValues(component, 'Opportunity','Compounding_Interest__c','compoundingInterest');
        helper.getPickListValues(component, 'Opportunity','Fee_Calculation_Method__c','feeCalculationMethod');
        helper.getPickListValues(component, 'Opportunity','Minimum_Interest_Period__c','minimumInterestPeriod');
        helper.getPickListValues(component, 'Opportunity','Fixed_Amount__c','fixedAmount');
        //helper.getPickListValues(component, 'Opportunity','Scheduled_Date__c','paymentDateOptions');
        helper.getPickListValues(component, 'Opportunity','Existing_Litigation_Loans__c','paymentScheduleOptions');
        helper.getPickListValues(component, 'Opportunity','Loan_Requests__c','loanRequestOptions');
        helper.getPickListValues(component, 'Opportunity','StageName','ReAssessmentStageOptions');        
        helper.getPickListValues(component, 'Opportunity_Service_Provider__c','Status__c','treatmentStatusOptions');
        helper.getPickListValues(component, 'Opportunity', 'Interest_Deferral_Period__c', 'interestDeferralOptions');
        helper.getPickListValues(component, 'Opportunity', 'Payment_Schedule__c', 'Payment_Schedule__c_options');
        helper.getPickListValues(component, 'Opportunity', 'Payment_Schedule_Mode__c', 'Payment_Schedule_Mode__c_options');
        helper.getPickListValues(component, 'Opportunity', 'Day_of_Month__c', 'Day_of_Month__c_options');
        helper.getPickListValues(component, 'Opportunity', 'Invoice_Type__c', 'invoiceTypeOptions');
        helper.getPickListValues(component, 'Opportunity', 'Insurer_Name__c', 'insurerNameOptions');        
        
        helper.getBankAccountOptions(component);
        
        // get the fields API name and pass it to helper function  
        var controllingFieldAPI = component.get("v.controllingFieldAPI");        
        var dependingFieldAPI = component.get("v.dependingFieldAPI");
        var objDetails = component.get("v.objDetail");        
        helper.fetchPicklistValues(component,objDetails,controllingFieldAPI, dependingFieldAPI);  
        //console.log('listControllingValues' + component.get("v.listControllingValues")); 
        helper.getRefNotesDependantPicklistMap(component, 'drawDownObj', 'referenceNotesDepPicklistMap');
        helper.getRefNotesDependantPicklistMap(component, 'providerDrawDownObj', 'providerReferenceNotesDepPicklistMap'); 
        /*
        setTimeout(function(){
           // helper.fetchTreatmentRefNotesDepValues(component);
        },3000);
        */
    },
    reInitSomeData:function(component, event, helper) {
        helper.reInitSomeData(component, helper);
    },
    
    onControllerFieldChange: function(component, event, helper) { 
        
        var controllerValueKey = event.getSource().get("v.value"); // get selected controller field value
        var depnedentFieldMap = component.get("v.depnedentFieldMap");
        
        console.log(controllerValueKey);        
        if (controllerValueKey != '--- None ---') {
            var ListOfDependentFields = depnedentFieldMap[controllerValueKey];
            
            console.log(ListOfDependentFields);
            
            if(ListOfDependentFields.length > 0){
                component.set("v.bDisabledDependentFld" , false);                 
                helper.fetchDepValues(component, ListOfDependentFields, 'listDependingValues');    
            }else{
                component.set("v.bDisabledDependentFld" , true); 
                component.set("v.listDependingValues", ['--- None ---']);
            }  
            
        } else {
            component.set("v.listDependingValues", ['--- None ---']);
            component.set("v.bDisabledDependentFld" , true);
        }
    },    
    
    saveOpp : function(component, event, helper){
        var success;
        
        
        success = helper.validateRequired(component, "Name");
        if(!success)	return;
        
        success = helper.validateRequired(component, "selectedLookUpPrimaryContact");
        if(!success)	return;
        
        component.set("v.spinner", true);
        helper.saveOppty(component).then(
            $A.getCallback(function(result) {
                helper.showToast('SUCCESS','Your changes were saved!','SUCCESS');
                helper.getOpportunityInfo(component);
                helper.getReAssessmentOpportunitiesList(component);
            }),
            $A.getCallback(function(errors) {
                if (errors[0] && errors[0].message) {
                    helper.errorsHandler(errors)
                }else {
                    helper.unknownErrorsHandler();
                }
                
            }));
    } ,
    
    saveDrawdowns : function(component, event, helper){
        component.set("v.spinner", true);
        helper.saveDrawdownsAndUpdateList(component);
    },
    
    savePaymentDrawdowns : function(component, event, helper){
        component.set("v.spinner", true);
        helper.savePaymentDrawdowns(component);
    },
    
    /*saveCriticalDates : function(component, event, helper){
        component.set("v.spinner", true);
        
        helper.saveCriticalDates(component).then($A.getCallback(
            (result) => {
                helper.showToast('SUCCESS',result,'SUCCESS');
                component.set("v.spinner", false);
                return helper.getCriticalDatesList(component, helper);
            }
        )).catch(
                (errors) => {
                    if (errors[0] && errors[0].message) {
                        helper.errorsHandler(errors)
                    }else {
                        helper.unknownErrorsHandler();
                    }
                    component.set("v.spinner", false);
                }
                );
        
        
    },*/
    
    /*addNewCriticalDate : function(component, event, helper){
        try{
            component.set("v.spinner", true);            
            helper.addNewCriticalDate(component);
            component.set("v.spinner", false);            
        }catch(e){
            component.set("v.spinner", false);
        }        
    },*/
    
    addNewDrawdown : function(component, event, helper){
        try{
            component.set("v.spinner", true);
            
            helper.saveDrawdowns(component);
            helper.addNewDrawdown(component);  
        }catch(e){
            
        }
        //helper.getRefNotesDependantPicklistMapAsync(component, 'drawDownObj', 'referenceNotesDepPicklistMap');
    },
    
    addNewPaymentDrawdown : function(component, event, helper){
        try{
            component.set("v.spinner", true);
            
            helper.savePaymentDrawdowns(component);
            helper.addNewPaymentDrawdown(component);  
        }catch(e){
            
        }
        //helper.getRefNotesDependantPicklistMapAsync(component, 'drawDownObj', 'referenceNotesDepPicklistMap');
    },
    
    onTypeOfLoanChange: function(component, event, helper){
        component.set("v.spinner", true);    
        //helper.getRefNotesDependantPicklistMap(component);
        helper.getRefNotesDependantPicklistMap(component, 'drawDownObj', 'referenceNotesDepPicklistMap'); 
        component.set("v.spinner", false);    
        document.getElementsByTagName('body')[0].focus();
    },
    
   /* deleteCriticalDateItem : function(component, event, helper){
        component.set("v.spinner", true);
        let itemIndex = event.target.getElementsByClassName('criticalDate-item-index')[0].value;
        
        if(confirm('Are you sure?')) {
            try{
                helper.deleteCriticalDateItem(component, itemIndex).then($A.getCallback(
                    (result) => {
                        helper.showToast('SUCCESS',result,'SUCCESS');
                        //return helper.getCriticalDatesList(component);
                    }
                )).catch((errors) => {
                    component.set("v.spinner", false);
                    if (errors[0] && errors[0].message) {
                        helper.errorsHandler(errors)
                    }else {
                        helper.unknownErrorsHandler();
                    }
                }); 
            }catch(e){
                
            }       
            
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },*/
    
    deleteDrawdownItem : function(component, event, helper){
        component.set("v.spinner", true);
        var itemDescription = event.target.getElementsByClassName('drawdown-item-id')[0].value;           
        
        if(confirm('Are you sure?')) {
            try{
                helper.deleteDrawdownItem(component, itemDescription); 
            }catch(e){
                
            }
            //helper.getRefNotesDependantPicklistMapAsync(component, 'drawDownObj', 'referenceNotesDepPicklistMap');            
            
            
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },
    
    deleteServiceProviderDrawdownItem : function(component, event, helper){
        component.set("v.spinner", true);
        var itemDescription = event.target.getElementsByClassName('drawdown-item-id')[0].value;           
        
        if(confirm('Are you sure?')) {            
            helper.deleteServiceProviderDrawdownItem(component, itemDescription); 
            helper.fetchTreatmentRefNotesDepValuesAsync(component);
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },    
    
    deleteReassessment : function(component, event, helper){
        component.set("v.spinner", true);
        var itemDescription = event.target.getElementsByClassName('reassess-item-id')[0].value;           
        
        if(confirm('Are you sure?')) {            
            helper.deleteReassessment(component, itemDescription);            
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },

    handleInvoicesChanged : function(component, event, helper) {
        helper.getServiceProvidersList(component);
    },
    
    addNewServiceProvider : function(component, event, helper){
        var firm = component.get("v.selectedLookUpServiceProvider");
        helper.addTreatment(component, firm);
    },
    
    addNewServiceProviderDrawdown : function(component, event, helper){
        component.set("v.spinner", true);
        var itemDescription = event.target.getElementsByClassName('treatment-insert-id')[0].value; 
        helper.saveDrawdowns(component);
        helper.addNewServiceProviderDrawdown(component, itemDescription);    
        helper.fetchTreatmentRefNotesDepValuesAsync(component);
    },
    
    deleteTreatment : function(component, event, helper){
        component.set("v.spinner", true);
        var itemDescription = event.target.getElementsByClassName('treatment-delete-id')[0].value;           
        
        if(confirm('Are you sure?')) {            
            helper.deleteTreatment(component, itemDescription);            
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },    
    
    saveReassessments : function(component, event, helper){
        component.set("v.spinner", true);
        helper.saveReassessments(component);
    },

    saveServiceProvidersList : function(component, event, helper){
        component.set("v.spinner", true);
        helper.saveServiceProvidersList(component); 
        //alert('refreshing');
        //helper.fetchTreatmentRefNotesDepValuesAsync(component);
    },
    
    redirectUserToStandardView : function (component, event, helper){
        // Redirect to the default Opportunity Lightning Page
        var recordId = component.get("v.recordId");        
        var url = "/lightning/r/Opportunity/" + recordId + "/view?nooverride=1";
        window.location.href = url;
    },
    
    doCancel : function(component, event, helper){
        var accountId = component.get("v.accountId");
        var url = "/lightning/r/Account/" + accountId + "/view";
        window.location.href = url;
    },
    
    doRefresh : function(component, event, helper){
        window.location.reload();
    },
    
    doDelete : function(component, event, helper){
        component.set("v.spinner", true);
        
        if(confirm('Are you sure?')) {            
            helper.deleteOpportunity(component);
            //helper.getOpportunityInfo(component);
            // Redirect to Account Record
            //var a = component.get('c.doCancel');
            //$A.enqueueAction(a);         
        } else {
            component.set("v.spinner", false); 
            return false;            
        }      
    },
    generateLoanDocuments: function(component, event, helper)
    {
        var currentOppSObj = component.get('v.oppObj');
        if (currentOppSObj.Generate_Loan_Doc_Check__c==true){
            
            window.open(currentOppSObj.Conga_URL_Doc_Generate__c, "_parent","width=650,height=250,menubar=0");
        }
        else{
            //alert(currentOppSObj.Conga_Doc_Error__c.replace('[ButtonName]', 'Generate Loan Documents').replace(/\\n/g, '\n'));
            helper.showToast('ERROR', currentOppSObj.Conga_Doc_Error__c.replace('[ButtonName]', 'Generate Loan Documents').replace(/\\n/g, '\n'));
        }
    },
    generateReplacementCounselDocuments: function(component, event, helper)
    {
        var currentOppSObj = component.get('v.oppObj');
        if (currentOppSObj.Generate_Loan_Doc_Check__c==true){
            
            window.open(currentOppSObj.Replacement_Counsel_Document_Generate__c, "_parent","width=650,height=250,menubar=0");
        }
    },
    SendLoanDocuments: function(component, event, helper)
    {
        var currentOppSObj = component.get('v.oppObj');
        if (currentOppSObj.Send_Loan_Doc_Check__c==true){
            window.open(currentOppSObj.Conga_URL_Doc_Send__c, "_parent","width=650,height=250,menubar=0");
        }
        else{
            //alert(currentOppSObj.Conga_Doc_Error__c.replace('[ButtonName]', 'Send Loan Documents').replace(/\\n/g, '\n'));
            helper.showToast('ERROR', currentOppSObj.Conga_Doc_Error__c.replace('[ButtonName]', 'Send Loan Documents').replace(/\\n/g, '\n'));
        } 
    },
    sendReplacementCounselDocuments: function(component, event, helper)
    {
        var currentOppSObj = component.get('v.oppObj');
        if (currentOppSObj.Send_Loan_Doc_Check__c==true){
            window.open(currentOppSObj.Replacement_Counsel_Document_Send__c, "_parent","width=650,height=250,menubar=0");
        }
    },
    onPaymentMethodChange: function(component, event, helper)
    {
        var index = event.target.nextElementSibling.dataset.index;
        var newPaymentMethod = event.getSource().get("v.value");
        console.log('index:'+index);
        console.log('newPaymentMethod:'+newPaymentMethod);
        helper.fetchRefNotesDepValues(component, newPaymentMethod, index);
    },
    onPaymentMethodChangeTreatment: function(component, event, helper)
    {
        helper.fetchTreatmentRefNotesDepValues(component);
    },
    inlineEditName : function(component,event,helper){       
        var clickSource = event.currentTarget.dataset.source;
        // show the name edit field popup 
        
        component.set("v.clickSource", clickSource); 
        var selectedRecVar = event.currentTarget.dataset.recvar;
        console.log('var:'+selectedRecVar)
        if(selectedRecVar){
            component.set("v."+selectedRecVar,{});
            console.log('nullfied');
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
        console.log('hideLookupInput');
        let clickSource = component.get("v.clickSource");
        console.log('clickSource = ' + clickSource);
        component.set("v.clickSource", "none");   
        var oppObjId = component.get("v.oppObj.Id");
        if(oppObjId && clickSource != 'none'){
            console.log('call');
            component.set("v.spinner", true);
            helper.saveOppty(component).then(
                $A.getCallback(function(result) {
                    helper.showToast('SUCCESS','Your changes were saved!','SUCCESS');
                    helper.getOpportunityInfo(component);
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
    handlePaymentScheduleChange : function(component, event, helper) {  
        
    },
    handleViewPayments : function(component, event, helper) {  
        helper.viewPayments(component, event);
    },
    handlePrintPayments : function(component, event, helper) {  
        helper.printPayments(component, event);
    },
    handleNewScheduledPaymentClick : function(component, event, helper) {  
        var spTable = component.find('spTable');
        spTable.showCreateModal();
    },
    handleShowHideScheduledPaymentClick : function(component, event, helper) {  
        var spTable = component.find('spTable');
        var shown = spTable.toggleShown();
        if (shown) {
            component.set('v.spShowHideText', 'Hide');
            component.set('v.spShowHideIcon', 'utility:chevronup');
        } else {
            component.set('v.spShowHideText', 'Show');
            component.set('v.spShowHideIcon', 'utility:chevrondown');
        }
    },
    handleTreatmentActionSelect : function(component, event, helper) {  
        var action = event.getParam("value");
        var providerId = event.getSource().get("v.name");
        switch (action) {
            case 'invoice':
                var invoiceTable = document.querySelector(`c-treatment-invoice-manager.invoiceTable${providerId}`);
                invoiceTable.showCreateModal();
                break;
            case 'drawdown':
                component.set("v.spinner", true);
                helper.saveDrawdowns(component);
                helper.addNewServiceProviderDrawdown(component, providerId);    
                helper.fetchTreatmentRefNotesDepValuesAsync(component);
                break;
            case 'delete':
                component.set("v.spinner", true);
                
                if(confirm('Are you sure?')) {            
                    helper.deleteTreatment(component, providerId);            
                } else {
                    component.set("v.spinner", false);
                    return false;
                }
            default:
                break;
        }
    },
    toggleSection: function(component, event, helper){
        var section = event.currentTarget.getAttribute('data-section');
        var expandedSections = component.get('v.expandedSections') || {};
        expandedSections[section] = !expandedSections[section];
        component.set('v.expandedSections', expandedSections);
    },
    updateAmounts: function(component, event, helper) {
        helper.getUpdatedAmounts(component);
    },
    handleReverseClick: function(component, event, helper) {
        helper.showReverseModal(component, event.getParam("Id"));
    },    
    handleReverseSuccess : function(component, event, helper) {
        helper.reInitSomeData(component, event, helper);
        helper.hideReverseModal(component);
        //helper.getServiceProvidersList(component);
    },
    handleReverseCancel: function(component, event, helper) {
        //helper.reInitSomeData(component, event, helper);
        helper.hideReverseModal(component);
    },
	handleRejectSuccess : function(component, event, helper) {
        helper.reInitSomeData(component, event, helper);
        helper.hideReverseModal(component);
        //helper.getServiceProvidersList(component);
    },
    handleRejectCancel: function(component, event, helper) {
        //helper.reInitSomeData(component, event, helper);
        helper.hideReverseModal(component);
    },      
    refreshDiscountButton : function(component, event, helper){
        
        var confirm = window.confirm('Are you sure you want to apply the recent discount rate of lawyer by assessment provider?');
        if (confirm) {
            component.set("v.spinner", true);
            helper.setLatestDiscountRateLaywer(component).then(
                function(result){
                    helper.getOpportunityInfo(component);
                }
            ).then(
                function(){
                    helper.showToast('SUCCESS','New discount rate is applied successfully.','success');
                    component.set("v.spinner", false);
                }
            ).catch(
                function(errors){
                    component.set("v.spinner", false);
                    console.log('error : ' + errors);
                    helper.errorsHandler(errors);
                }
            );
        }
    },
    
    setSendToGoogleReview : function(component, event, helper) {
        
        let oppObj = component.get("v.oppObj");
        if(event.getSource().get("v.label") == 'Yes'){
			oppObj.Restrict_Communication__c = true;           
        }else{
            oppObj.Restrict_Communication__c = false;
        }
        component.set("v.oppObj", oppObj);
    }
})