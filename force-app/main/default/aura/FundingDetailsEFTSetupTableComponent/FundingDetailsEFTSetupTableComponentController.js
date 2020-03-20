({
    selectAllChanged : function(component, event, helper) {
        var selected = component.get("v.selectAll");
        var spList = component.get("v.spList");
        spList = helper.setScheduledPaymentSelectionStatus(selected, spList);
        component.set("v.spList", spList);
    },

    scheduledPaymentSelectionChanged : function(component, event, helper) {
        var spList = component.get("v.spList");
        component.set("v.selectAll", helper.allScheduledPaymentsSelected(spList));
    },

    setScheduledPaymentsEFTNumbers : function(component, event, helper) {
        var spList = component.get("v.spList");
        var eftNum = component.get("v.setEFTNum");
        spList = helper.setSelectedScheduledPaymentsEFTNumbers(spList, eftNum);
        component.set("v.spList", spList);
    },

    downloadBankingSheet : function(component, event, helper) {
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
        var spList = component.get("v.spList");
        helper.downloadBankingSheet(spList);
    },

    savePaymentInformation : function(component, event, helper) {
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
        var spList = component.get("v.spList");
        helper.savePaymentInformation(spList);
    }
})