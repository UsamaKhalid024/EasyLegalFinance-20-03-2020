({
	doInit : function(component, event, helper) {
        helper.getAccountInfo(component);	
        helper.getEnhancedNotes(component);	
        helper.getOpportunitiesList(component);
        helper.getLatestOpportunity(component);
        helper.getLatestContact(component);
        helper.getAmendmentsList(component);
        helper.getContactHistoryList(component);
        helper.getFirmHistoryList(component);
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        
        helper.getCriticalDatesList(component).then(
            $A.getCallback(function(result) {                
            }),
            $A.getCallback(function(errors) {
                if (errors[0] && errors[0].message) {
                    helper.errorsHandler(errors)
                }else {
                    helper.unknownErrorsHandler();
                }
                
            }));
        helper.getPickListValues(component, 'Critical_Date__c','Name__c','criticalDateName');
        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        helper.getPickListValues(component, 'Account','Account_Type__c','accountTypeOptions');
        helper.getPickListValues(component, 'Account','ProvinceResidency__c','provinceResidencyOptions');
        
        helper.getPickListValues(component, 'Contact','Citizenship_Status__c','citizenshipStatusOptions');
        helper.getPickListValues(component, 'Contact','Marital_Status__c','meritalStatusOptions');
        helper.getPickListValues(component, 'Contact','Any_SpousalChild_support_payment__c','spousalChildSupportPmtOptions');
        helper.getPickListValues(component, 'Contact','Have_you_ever_been_in_arrears_on_payment__c','howBeenArrearsOnPmtOptions');
        helper.getPickListValues(component, 'Contact','Do_you_have_any_dependants__c','haveAnyDependantsOptions');
        helper.getPickListValues(component, 'Contact','Have_you_ever_declared_bankruptcy__c','everDeclaredBankcrupcyOptions');
        helper.getPickListValues(component, 'Contact','Employment_status_at_time_of_accident__c','employmentStatusTimeofAccidentOptions');
        
        helper.getPickListValues(component, 'Opportunity','Did_ELF_buyout_the_Loan__c','elfiBuyoutLoanOptions');
        helper.getPickListValues(component, 'Opportunity','Existing_Litigation_Loans__c','existingLitigationLoanOptions');
        
        helper.getCurrentUser(component);
        
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set('v.paymentDate', today);
        helper.parseNavigationHash(component);
    },
    onLocationChange: function(component, event, helper) {
        helper.parseNavigationHash(component);
    },
    onfocusfirmHistoryTab: function(component, event, helper){
        helper.getFirmHistoryList(component);
    },
    onfocusApplicantInfoTab: function(component, event, helper){
        helper.getOpportunitiesList(component);
        helper.getLatestOpportunity(component);
        helper.getLatestContact(component);
    },
    onLoanOverviewTabClick : function (component,event,helper){
        component.set("v.spinner", true);
        helper.getLoanSummaryInfo(component); 
        helper.getOpportunityTransactions(component);
        
        component.set("v.paymentPayoutSearch", false);
        component.set("v.paymentMiscSearch", false);
        component.set("v.paymentSearchTypeSelected", "Payout");        
    },
    onfocusAccountTab: function(component, event, helper)
    {
        helper.getAccountInfo(component);	
        helper.getLatestContact(component);
        helper.getOpportunitiesList(component);
        helper.getLatestOpportunity(component);
    },
    onfocusOpportunityTab: function(component, event, helper)
    {
        const setTabId = !component.get('v._selectedSecondaryTabId');
        helper.getOpportunitiesList(component)
            .then(() => {
                const oppList = component.get('v.oppList');
                if (setTabId && oppList && oppList.length) {
                    component.set('v._selectedSecondaryTabId', oppList[0].Id);
                }
            });
        helper.getLatestOpportunity(component);
    },
    onPrimaryTabSelect: function(component, event, helper) {
        window.location.hash = `#/${event.getParams().id}`;
    },
    onSecondaryTabSelect: function(component, event, helper) {
        window.location.hash = `#/${component.get('v._selectedTabId')}/${event.getParams().id}`;
    },
    
    generatePayout : function(component, event, helper){
        component.set("v.spinner", true);
        helper.generatePayout(component);
    },
    
    loanSummaryTab: function(component, event, helper) {
        component.set("v.spinner", true);

        helper.clearAllTabs(component, event);        
		helper.getLoanSummaryInfo(component);         
        component.find("loanSummaryId").getElement().className = 'slds-tabs--scoped__item slds-active customClassForTab';
        component.find("loanSummaryTabDataId").getElement().className = 'slds-tabs--scoped__content slds-show customClassForTabData';         
    },
    transactionsTab: function(component, event, helper) {
        component.set("v.spinner", true);
        
        helper.clearAllTabs(component, event);
        helper.getOpportunityTransactions(component);
        component.find("transactionsId").getElement().className = 'slds-tabs--scoped__item slds-active customClassForTab';
        component.find("transactionsTabDataId").getElement().className = 'slds-tabs--scoped__content slds-show customClassForTabData';
    },
    paymentsTab: function(component, event, helper) {
        helper.clearAllTabs(component, event);
        component.find("paymentsId").getElement().className = 'slds-tabs--scoped__item slds-active customClassForTab';
        component.find("paymentsTabDataId").getElement().className = 'slds-tabs--scoped__content slds-show customClassForTabData';
    },        
    showPrintableView:function(component, event, helper) {
        var accObj = component.get('v.accountObj');
        var baseURL = accObj.Conga_Printable_Preview_URL__c;
        //var baseURL = "/apex/RDS_AccountPrintableView?Id="+component.get('v.recordId');
        $A.get("e.force:navigateToURL").setParams({ 
            "url": baseURL
        }).fire();
    },
    generatePayoutStatement: function(component, event, helper){
        var dateIsSet = component.get("v.payoutDateSet");
        if(dateIsSet){
            var accObj = component.get('v.accountObj');
            var baseURL = accObj.Conga_Payouts_URL__c;
            $A.get("e.force:navigateToURL").setParams({ 
                "url": baseURL
            }).fire();
        }
        else{
            helper.showToast('Error', 'Payout date is not set!');
        }
    },
    pdfApplicationDocument:function(component, event, helper) {
        var oppObj = component.get('v.oppObj');
        var BaseUrl = "/apex/APXTConga4__Conga_Composer?id="+oppObj.Id+"&TemplateID="+component.get('v.accountObj.CM_Application_Template_Id__c')+"&DS7=3&DefaultPDF=1&ReturnPath="+component.get('v.recordId');
        $A.get("e.force:navigateToURL").setParams({ 
            "url": BaseUrl
        }).fire();
    },
    sendApplicationDocument:function(component,event,helper)
    {
        let account = component.get('v.accountObj');
        let brandingParam = '&DocuSignBrandName='+ account.Business_Unit__c + 'Signing';
        var oppObj = component.get('v.oppObj');
        //Define the Conga URL and its parameters   
        //var BaseUrl = '/apex/APXTConga4__Conga_Composer?id={!oppSObj.id}&DS7=17&DocuSignVisible=1&QueryStringField=Docusign_Parameters_Loan_App__c&DocuSignRelatedAccountId={!oppSObj.AccountId}&DocuSignR1Id={!oppSObj.Primary_Contact__c}&DocuSignR1Type=Signer&DocuSignR1Role=Signer+1&DocuSignR1RoutingOrder=1&TemplateID={!accSObj.CM_Application_Template_Id__c}';
        var BaseUrl = '/apex/APXTConga4__Conga_Composer?SolMgr=1&id='+oppObj.Id+'&DocuSignVisible=1&QueryStringField=Docusign_Parameters_Loan_App__c&DocuSignR1Id='+oppObj.Primary_Contact__c+'&DocuSignR1Type=Signer&DocuSignR1Role=Signer+1&TemplateID='+component.get('v.accountObj.CM_Application_Template_Id__c')+'&DocuSignEndPoint=NA3&DocuSignR1RoutingOrder=1&DS7=17'+brandingParam;//&ReturnPath='+component.get('v.recordId');
        console.log(BaseUrl);
        $A.get("e.force:navigateToURL").setParams({ 
            "url": BaseUrl
        }).fire();       
    },
    
    saveAll : function(component, event, helper){
        helper.saveAccountOpptyAndContact(component);
        helper.getAccountInfo(component);
        helper.getLatestContact(component);
        /*
        var contact = component.get('v.conObj');
        var lawyer = component.get('v.lawyerObj');
        
        component.set("v.spinner", true);
        helper.saveAccountInfo(component);
        helper.saveContactInfo(component,contact);
        helper.saveOpp(component);*/
    },
    
    redirectToStandardView : function (component, event, helper){
        // Redirect to the default Lead Lightning Page
        //var url = "/"+component.get("v.accountObj").Id+"?nooverride=1";
        //window.location.href = url;
        $A.get("e.force:navigateToURL").setParams({
            "url": "/lightning/r/"+component.get("v.accountObj").Id+"/view?nooverride=1"
        }).fire();
    },
    
    doCancel : function(component, event, helper){
		window.location.reload();
    },
    
    doDelete : function(component, event, helper){
		component.set("v.spinner", true);
        
        if(confirm('Are you sure?')) {            
        	helper.deleteAccount(component);
            
            // Redirect to Account home
            var url = "/lightning/o/Account/home"
            window.location.href = url;        
        } else {
            component.set("v.spinner", false); 
			return false;            
        }      
	},
    inlineEditName : function(component,event,helper){       
        var clickSource = event.currentTarget.dataset.source;
        // show the name edit field popup 
        
        component.set("v.clickSource", clickSource); 
        if(clickSource == 'Law_Firm__c')
        {
            component.set('v.selectedLookUpLawFirm.Id','');
            component.set('v.selectedLookUpLawFirm.Name','');
            
            component.set('v.selectedLookUpLawyer.Id','');
            component.set('v.selectedLookUpLawyer.Name','');
        }
        else if(clickSource == 'Lawyer__c')
        {
            component.set('v.selectedLookUpLawyer.Id','');
            component.set('v.selectedLookUpLawyer.Name','');
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
        component.set("v.clickSource", "none");
        helper.saveAccountInfo(component);
        helper.saveOpp(component);
        helper.getAccountInfo(component);	
    },
    printReport: function(cmp, evt, hpr)
    {
        var acc = cmp.get('v.accountObj');
        var BaseUrl = acc.Conga_Transaction_Printable_Preview__c+'&DefaultPDF=1';
        $A.get("e.force:navigateToURL").setParams({ 
            "url": BaseUrl
        }).fire();  
    },
    exportToExcel: function (cmp, evt, hpr)
    {
        var acc = cmp.get('v.accountObj');
        var BaseUrl = acc.Conga_Transaction_Printable_Preview__c;
        $A.get("e.force:navigateToURL").setParams({ 
            "url": BaseUrl
        }).fire();  
    },
    newNote: function(component, event, helper){
        component.set('v.noteContent','');
        component.set('v.showNotePopup',true);
    },
    editNote: function(component, event, helper){
        component.set("v.spinner", true);
        let notes = component.get("v.notes");
        let selectedId = event.target.id;
        
        
        for(let i=0; i<notes.length; i++){            
            if(notes[i].note.Id == selectedId){
                component.set("v.noteContent",notes[i].body);
                component.set("v.selectedNoteId",notes[i].note.Id);
                component.set('v.showNotePopup',true);
                component.set("v.spinner", false);
                break;
            }
        }
        component.set("v.spinner", false);
    },
    deleteNote: function(component, event, helper){
        if(confirm('Are you sure?')) {
            try{
                component.set("v.spinner", true);
                helper.deleteNote(component, event);        
                helper.getEnhancedNotes(component);
                component.set('v.showNotePopup',false);
                component.set("v.spinner", false); 
            }catch(e){
                
            }
            //helper.getRefNotesDependantPicklistMapAsync(component, 'drawDownObj', 'referenceNotesDepPicklistMap');            
            
            
        } else {
            component.set("v.spinner", false);
        	return false;
        }        
    },
    updateNote: function(component, event, helper){
        component.set("v.spinner", true);
        helper.updateNote(component, event);
        helper.getEnhancedNotes(component);
        component.set("v.spinner", false);
    },
    closeNoteModal : function (component, event, helper) {
        component.set("v.selectedNoteId",'');
        component.set('v.showNotePopup',false);
    },
    createNote : function(component, event, helper) {
        component.set("v.createButtonDisabled", true);
        //getting the candidate information
        //var candidate = component.get("v.note");
        var candidate = component.get("v.noteContent");
        //Calling the Apex Function
        var action = component.get("c.createRecord");
        //Setting the Apex Parameter
        action.setParams({
            nt : candidate,
            PrentId : component.get("v.recordId")
        });
        //Setting the Callback
        action.setCallback(this,function(a){
            //get the response state
            var state = a.getState();
            //check if result is successfull
            if(state == "SUCCESS"){
                //Reset Form
                var newCandidate = {'sobjectType': 'ContentNote',
                                    'Title': 'N/A',
                                    'Content': ''
                                   };
                //resetting the Values in the form
                component.set("v.note",newCandidate);
                //$A.get('e.force:refreshView').fire();
                component.set('v.showNotePopup',false);
                helper.getEnhancedNotes(component);	
                component.set("v.spinner", false);
                component.set("v.createButtonDisabled", false);
            } else if(state == "ERROR"){
                var errors = a.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.errorsHandler(errors)
                    }
                } else {
                    helper.unknownErrorsHandler();
                }
                component.set("v.spinner", false);
                component.set("v.createButtonDisabled", false);
            }
        });
        
        //adds the server-side action to the queue        
        $A.enqueueAction(action);
        component.set("v.spinner", true);
    },
    accountNotesPrintView: function(component, event, helper){
        
        var acc = component.get('v.accountObj');
        var BaseUrl = acc.Conga_Account_Notes_URL__c;
        $A.get("e.force:navigateToURL").setParams({ 
            "url": BaseUrl
        }).fire();  
    },
    newOppty: function(component, event, helper){
        $A.get('e.force:refreshView').fire(); 
        component.find("oppTabs").set("v.selectedTabId","NEW");
          
    },
    formatPhone: function(component, event, helper){        
        helper.formatPhone(component, event, 'Phone', 'conObj');
    },
    formatOtherPhone: function(component, event, helper){        
        helper.formatPhone(component, event, 'OtherPhone', 'conObj');
    },
    formatLawPhone: function(component, event, helper){        
        helper.formatPhone(component, event, 'Phone', 'oppObj.Lawyer__r');
    },
    refreshOpportunityList: function (component, event, helper){
        
        helper.getOpportunitiesList(component)
        .then(function(result){
            console.log('then is called immediately');
            
            var oppList = component.get('v.oppList');
            console.log('oppties: '+JSON.stringify(oppList));
            if(oppList != null){
                component.find("oppTabs").set("v.selectedTabId",(oppList.length > 0 ? oppList[0].Id: 'NEW'));
            }
            
        });
    /*
        setTimeout(function(){
            
            var oppList = component.get('v.oppList');
            console.log('oppties: '+JSON.stringify(oppList));
            component.find("oppTabs").set("v.selectedTabId",oppList[0].Id);
        },500);
        */
	},
    refreshOptTab: function(component, event, helper){
        
        var tab = event.getSource();
        var tabIndex = parseInt(tab.get('v.id').split("-")[1]);
        var allComponents = component.find("oppIdx");

        console.log("Tab index is: " + tabIndex);
        console.log(tabIndex);
        console.log("--------------All components--------------");
        console.log(component.find("oppIdx"));
        
        if(allComponents[tabIndex] != null && allComponents[tabIndex] != undefined){
            allComponents[tabIndex].OnTabActive();
        }
    },
    SaveApplicantInfo: function(component, event, helper){
        var opportunity = component.get('v.oppObj');
        if(opportunity.Id != null){
            helper.saveAccountOpptyAndContact(component);
        }else{
            helper.showToast('Error', 'Unable to save information. Please create an opportunity first.','Info');
        }        
        component.set("v.applicantInfoEditMode", false);
    },
    editApplicantInfo: function(component, event, helper){
        component.set("v.applicantInfoEditMode", true);
    },
    runAllOptsPayout: function(component, event, helper){
        component.set("v.spinner", true);        
        var searchType = component.get("v.paymentSearchTypeSelected")
        var paymentDate = component.get("v.paymentDate");
        component.set("v.paymentAmount", null);

        if(paymentDate != null){
            if(searchType != null){
                if(searchType == 'Payout'){
                    component.set("v.paymentPayoutSearch", true);
                    component.set("v.paymentMiscSearch", false);
                } else if(searchType == 'Misc Income Payment') {
                    component.set("v.paymentMiscSearch", true);
                    component.set("v.paymentPayoutSearch", false);
                }
                helper.runAllOptsPayout(component);      
            } else {
                component.set("v.paymentPayoutSearch", false);
            	component.set("v.paymentMiscSearch", false);
                helper.showToast('Error', 'Search type needs to be populated');
                component.set("v.spinner", false);
            }
        } else {
                component.set("v.paymentPayoutSearch", false);
            	component.set("v.paymentMiscSearch", false);
                helper.showToast('Error', 'Date of payment needs to be populated');
                component.set("v.spinner", false);            
        }
    },
    calculatePayment: function(component, event, helper){
        component.set("v.spinner", true);
		helper.calculatePayment(component);
    },
    applyPartialPayment : function(component, event, helper){
        component.set("v.spinner", true);
		var oppId = event.target.getElementsByClassName('opportunity-partial-id')[0].value;           
                   
		if(confirm('Are you sure?')) { 
            helper.applyPartialPayment(component, oppId); 
        } else {
            component.set("v.spinner", false);
        	return false;
        }
    },  
    applyFullPayment : function(component, event, helper){
        component.set("v.spinner", true);
		var oppId = event.target.getElementsByClassName('opportunity-close-id')[0].value;           
                   
		if(confirm('Are you sure?')) { 
            helper.applyFullPayment(component, oppId); 
        } else {
            component.set("v.spinner", false);
        	return false;
        }
    },    
    closeAllPaidLoans : function(component, event, helper){
        component.set("v.spinner", true);         
                   
        if(confirm('Are you sure?')) { 
            helper.closePaidLoans(component); 
        } else {
            component.set("v.spinner", false);
            return false;
        }
    },    
    changeToBadDebt : function (component, event, helper){
        component.set("v.spinner", true);
		var oppId = event.target.getElementsByClassName('opportunity-debt-id')[0].value;           
                   
		if(confirm('Are you sure?')) { 
            helper.changeToBadDebt(component, oppId); 
        } else {
            component.set("v.spinner", false);
        	return false;
        }        
    },
    changeToSurplus : function (component, event, helper){
        component.set("v.spinner", true);
		var oppId = event.target.getElementsByClassName('opportunity-surplus-id')[0].value;           
                   
		if(confirm('Are you sure?')) { 
            helper.changeToSurplus(component, oppId); 
        } else {
            component.set("v.spinner", false);
        	return false;
        }        
    },
    changeToShortfall : function (component, event, helper){
        component.set("v.spinner", true);
		var oppId = event.target.getElementsByClassName('opportunity-shortfall-id')[0].value;           
                   
		if(confirm('Are you sure?')) { 
            helper.changeToShortfall(component, oppId); 
        } else {
            component.set("v.spinner", false);
        	return false;
        }        
    },    
    saveCriticalDates : function(component, event, helper){
        component.set("v.spinner", true);
        helper.validateCriticalDatesFields(component).then(
            (success) =>{
                return helper.saveCriticalDates(component);
            }
            
        ).then(
            (result) => {
                helper.showToast('SUCCESS',result,'SUCCESS');
                component.set("v.spinner", false);
                return helper.getCriticalDatesList(component, helper);
            }
        ).catch(
                (errors) => {                
                    if (errors[0] && errors[0].message) {
                		
                        helper.errorsHandler(errors)
                    }else {
                        helper.unknownErrorsHandler();
                    }
                	component.set("v.spinner", false);
                }
                );
        /*helper.saveCriticalDates(component).then($A.getCallback(
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
                );*/
        
        
    },
     addNewCriticalDate : function(component, event, helper){
        try{
			component.set("v.spinner", true);            
            helper.addNewCriticalDate(component);
			component.set("v.spinner", false);            
        }catch(e){
            component.set("v.spinner", false);
        }        
    },
    deleteCriticalDateItem : function(component, event, helper){
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
    },
    openBankAccountsList : function(component, event, helper) {  
        helper.viewBankAccountsList(component, event);
    }, 
    generateReplacementCounselDocuments: function(component, event, helper){
       window.open(component.get('v.oppObj').Replacement_Counsel_Document_Generate__c, "_parent","width=650,height=250,menubar=0");
    },
    sendReplacementCounselDocuments: function(component, event, helper){
       window.open(component.get('v.oppObj').Replacement_Counsel_Document_Send__c, "_parent","width=650,height=250,menubar=0");
    },
})