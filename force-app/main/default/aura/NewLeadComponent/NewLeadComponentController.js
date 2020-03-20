({
    doInit : function(component, event, helper) {
        
        helper.getLeadInfo(component);		
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);   
        helper.getPickListValuesHelper(component, 'Account','ProvinceResidency__c','provinceResidencyOptions');
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set('v.leadObj.Date_of_Application__c', today);
        
        helper.getRecordTypes(component);
    },
    
    doCancel : function(component, event, helper){
        // Redirect to Lead Home
        var url = "/lightning/o/Lead/home"
        window.location.href = url;
    },
    
    redirectToStandardView : function (component, event, helper){
        // Redirect to the default Lead Lightning Page
        var url = "?nooverride=1"
        window.location.href = url;
    },
    
    Save : function(component, event, helper) {
        
        //validation/////////////////////
        var success = true;
        success = helper.validateCheckboxes(component, "Business_Unit__c");
        if(!success)	return;
        
        success = helper.validateRequired(component, "FirstName");
        if(!success)	return;
        
        success = helper.validateRequired(component, "LastName");
        if(!success)	return;
        
        success = helper.validateRequired(component, "Company");
        if(!success)	return;
        
        /////////////////////////////////
        //setting lookups
        component.set("v.leadObj.Law_Firm_Name_new__c",(component.get("v.selectedLookUpFirm.Id") ?
                                                        component.get("v.selectedLookUpFirm.Id"):''));
        
        component.set("v.leadObj.Lawyer_Name_new__c",(component.get("v.selectedLookUpLawyer.Id") ?
                                                      component.get("v.selectedLookUpLawyer.Id"):''));
        
        
        var lead = component.get("v.leadObj");        
        
        // call the saveAccount apex method for update inline edit fields update 
        var action = component.get("c.saveLead");
        action.setParams({
            'lead': lead
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                console.log('returning:');
                console.log(storeResponse);
                if(storeResponse.indexOf('Error') >= 0)
                {
                    helper.showToast('ERROR',storeResponse, 'ERROR');
                }
                else
                {
                    helper.showToast('Done','Lead Created Successfully!', 'SUCCESS');
                    
                    var gotoRec = $A.get('e.force:navigateToSObject');
                    gotoRec.setParams({
                        'recordId': storeResponse,
                    });
                    gotoRec.fire();
                }
            }
            else if (state === "ERROR")
            {
                var errors = response.getError();
                
                if (errors) {
                    console.log(errors[0]);
                    helper.showToast('ERROR',JSON.stringify(errors), 'ERROR');
                } else {
                    alert('Unknown error!');
                }
            }
        });
        $A.enqueueAction(action);
    },
    onNameChange: function(component, event, helper)
    {
        
    },
    closeNameBox: function(component, event, helper)
    {
        
    },
    hideLookupInput: function(component, event, helper)
    {
        
    },
    onLawyerChange: function(component, event, helper){
        console.log('lawyer change');
        var lawyer = component.get('v.selectedLookUpLawyer');
        console.log(JSON.stringify(lawyer));
        if(lawyer && lawyer.Id)
        {
            component.set('v.leadObj.Law_Phone__c', lawyer.Phone);
            component.set('v.leadObj.Law_Email__c', lawyer.Email);
        }
        else
        {
            component.set('v.leadObj.Law_Phone__c', '');
            component.set('v.leadObj.Law_Email__c', '');
        }
    },
    onFirmChange: function(component, event, helper){
        component.set('v.selectedLookUpLawyer', undefined);
        console.log('firm changed');
    },
    formatPhone: function(component, event, helper){
        
        helper.formatPhone(component, event, 'Phone');
    },
    formatMobilePhone: function(component, event, helper){
        
        helper.formatPhone(component, event, 'MobilePhone');
    },
    formatFax: function(component, event, helper){
        
        helper.formatPhone(component, event, 'Fax');
    },
    formatLaw_Phone__c: function(component, event, helper){
        
        helper.formatPhone(component, event, 'Law_Phone__c');
    },
    closeRecordTypeModal : function (component, event, helper) {
        component.set('v.showRecordTypePopup',false);
        var selectedRecordTypeId = component.get('v.selectedRecordTypeValue');
        component.set('v.leadObj.RecordTypeId', selectedRecordTypeId);
        
        var action = component.get('c.doCancel');
        $A.enqueueAction(action);
    },
    recordTypeChange: function (component, event, helper) {
        var changeValue = event.getParam("value");
        console.log(changeValue);
        component.set('v.selectedRecordTypeValue',changeValue);
    },
    nextRecordTypeModal: function (component, event, helper) {
        var selectedRecordTypeId = component.get('v.selectedRecordTypeValue');
        component.set('v.leadObj.RecordTypeId', selectedRecordTypeId);
        component.set('v.showRecordTypePopup', false);
        
    }
})