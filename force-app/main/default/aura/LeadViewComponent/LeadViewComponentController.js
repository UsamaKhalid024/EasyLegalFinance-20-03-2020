({
	doInit : function(component, event, helper) {	        
		helper.getLeadInfo(component);	
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        helper.getPickListValuesHelper(component, 'Account','ProvinceResidency__c','provinceResidencyOptions');
	},
    
    hideLookupInput : function(component, event, helper) {	
        
        component.set("v.clickSource", "none");
        component.set("v.showSaveCancelBtn",true);
        
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
    
    doCancel : function(component, event, helper){
        // Redirect to Lead Home
        var url = "/lightning/o/Lead/home"
        window.location.href = url;
    },
    
    doDelete : function(component, event, helper){
		component.set("v.spinner", true);
        
        if(confirm('Are you sure?')) {            
        	helper.deleteLead(component);
            
            // Redirect to Lead Home
            var url = "/lightning/o/Lead/home"
            window.location.href = url;            
        } else {
            component.set("v.spinner", false); 
			return false;            
        }      
	},
    
    redirectToStandardView : function (component, event, helper){
        // Redirect to the default Lead Lightning Page
        var url = "?nooverride=1"
        window.location.href = url;
    },
    
    redirectToPrintableView : function (component, event, helper){
        var recordId = component.get("v.recordId");
        var url = "/c/LeadPrintableView.app?recordId=" + recordId;
        window.location.href = url;     
    },
    
    redirectToEdit : function (component, event, helper){
        var recordId = component.get("v.recordId");
        var event = $A.get("e.force:navigateToComponent");

        event.setParams({
            componentDef: "c:LeadEditComponent"
        });
        
        event.fire(); 
    },  
    
    clone : function (component, event, helper){
        component.set("v.spinner", true);
        var recordId = component.get("v.recordId");
        
        
        var cloneEvt = component.get("c.cloneLead");
        
        cloneEvt.setParams({
            "leadId": recordId
        });
        cloneEvt.setCallback(this,function(resp){
            component.set("v.spinner", false);
            var state = resp.getState();
            if(state == 'SUCCESS')
            {
                helper.showToast('Cloned Successfully', 'Redirecting...', 'success');
                var gotoRecord = $A.get('e.force:navigateToSObject');
                gotoRecord.setParams({
                    'recordId':resp.getReturnValue(),
                    'Id':resp.getReturnValue(),
                });
                gotoRecord.fire();
            }
            else if(state =='ERROR')
            {
                var errors = resp.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.errorsHandler(errors)
                    }
                } else {
                    helper.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(cloneEvt);
    },
    
    inlineEditName : function(component,event,helper){ 
        
        
        var clickSource = event.currentTarget.dataset.source;
        // show the name edit field popup 
        component.set("v.clickSource", clickSource); 
        if(clickSource == 'Law_Firm_Name_new__c')
        {
            component.set('v.selectedLookUpLawFirm.Id','');
            component.set('v.selectedLookUpLawFirm.Name','');
            
            component.set('v.selectedLookUpLawyer.Id','');
            component.set('v.selectedLookUpLawyer.Name','');
            component.set('v.leadObj.Law_Phone__c', '');
            component.set('v.leadObj.Law_Email__c', '');
        }
        else if(clickSource == 'Lawyer_Name_new__c')
        {
            component.set('v.selectedLookUpLawyer.Id','');
            component.set('v.selectedLookUpLawyer.Name','');
            component.set('v.leadObj.Law_Phone__c', '');
            component.set('v.leadObj.Law_Email__c', '');
        }
        component.set("v.clickSource", clickSource); 
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

    closeNameBox : function (component, event, helper) {
      // on focus out, close the input section by setting the 'nameEditMode' att. as false   
        //component.set("v.nameEditMode", false); 
        component.set('v.timeout', setTimeout(function(){
            component.set("v.clickSource", 'none');
        },100));
    },
    
     onNameChange : function(component,event,helper){ 
        // if edit field value changed and field not equal to blank,
        // then show save and cancel button by set attribute to true
        component.set("v.showSaveCancelBtn",true);
         /*
         var value = event.getSource().get("v.value");
         if(value)
         {
             if(value.trim() != ''){ 
                 component.set("v.showSaveCancelBtn",true);
             }
         }*/
    },

    Save : function(component, event, helper) {
        var lead = component.get("v.leadObj");
        
        //setting lookups
        component.set("v.leadObj.Law_Firm_Name_new__c",(component.get("v.selectedLookUpFirm.Id") ?
                                                        component.get("v.selectedLookUpFirm.Id"):''));
        component.set("v.leadObj.Lawyer_Name_new__c",(component.get("v.selectedLookUpLawyer.Id") ?
                                                        component.get("v.selectedLookUpLawyer.Id"):''));
        
        // call the saveAccount apex method for update inline edit fields update 
        var action = component.get("c.saveLead");
        action.setParams({
            'lead': lead
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                // set AccountList list with return value from server.
                component.set("v.leadObj", storeResponse);
                // Hide the save and cancel buttons by setting the 'showSaveCancelBtn' false 
                component.set("v.showSaveCancelBtn",false);
                //alert('Successfully updated!');
                helper.showToast('Done','Record successfully updated!', 'SUCCESS');
                location.reload();
            }
        });
        $A.enqueueAction(action);
    },
    onTextFocus : function(component,event, handler){

        clearTimeout(component.get('v.timeout'));
        
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
    }
})