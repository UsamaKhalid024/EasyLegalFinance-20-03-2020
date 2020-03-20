({
    doInit : function(component, event, helper) {
        component.set('v.spinner', true);
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        helper.getSampleLead(component);
        helper.getPickListValues(component, 'Lead','Business_Unit__c','businessUnitOptions').then($A.getCallback(function(result){
            return helper.getCustomSettings(component);
            
        })).then($A.getCallback(function(result){
            component.set('v.customSetting', result);
            return helper.setDefaultDates(component);
            
        })).then($A.getCallback(function(result){
            return helper.getLeadsByMonth(component);
            
        })).then($A.getCallback(function(result){
            component.set("v.LeadsByMonth",result);
            console.log('result:'+JSON.stringify(result));
            return helper.calculateTotal(component);
        })).then(function(){
            
        }).then(function(){
            component.set('v.spinner', false);
        }).catch(
            (errors) => {
                helper.errorsHandler(errors);
                component.set('v.spinner', false);
            }
		);
	},
                
	filterButton: function(component, event, helper){
        component.set('v.spinner', true);
        component.set('v.selectedBusinessUnit', component.get('v.selectedBusinessUnitFilter'));
		helper.getLeadsByMonth(component).then($A.getCallback(function(result){
            component.set("v.LeadsByMonth",result);
            return helper.calculateTotal(component);
            
        })).then($A.getCallback(function(){
            return helper.setCustomSettings(component);
            
        })).then($A.getCallback(function(){
            component.set('v.spinner', false);
            helper.getSampleLead(component);
        })).catch(
            (errors) => {
                helper.errorsHandler(errors);
                component.set('v.spinner', false);
            }
		);
	}
})