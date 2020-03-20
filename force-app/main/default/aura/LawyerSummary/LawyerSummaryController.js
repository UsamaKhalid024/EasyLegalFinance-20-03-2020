({
	doInit : function(component, event, helper) {
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        //var endOfMonth = $A.localizationService.formatDate(new Date(2008, today.getMonth() + 1, 0), "YYYY-MM-DD");
        component.set("v.payOutDate", today);
        //component.set("v.endDate", endOfMonth);
        
        //search query
        let fieldSet = [];
        fieldSet.push("Id");
        fieldSet.push("Name");
        fieldSet.push("Account.Name");
        fieldSet.push("(Select id from Attachments where name like \'%List of Clients%\' and createddate = today order by createddate desc limit 1 )");
        fieldSet.push("(Select id,createddate from tasks where type='Email' and createddate = today order by createddate desc limit 1 )");
        let strQuery = "SELECT " + fieldSet.join(",");
            strQuery += " FROM Contact WHERE RecordType.Name = \'Lawyers\' ";
        component.set("v.query", strQuery);        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        helper.setDefaultDates(component);
        helper.getLawyersList(component,event);
        
	},
    searchButton: function(component, event, helper) {
        helper.getLawyersList(component,event);
    },
    sort: function(component, event, helper) {  
        
        let selectedItem = event.currentTarget;
        let field = selectedItem.dataset.field;
        let sortOrder = component.get('v.sortOrder');
        let oldField = component.get('v.sortField');
        
        sortOrder = ((sortOrder == 'DESC' && oldField == field) || oldField != field ) ? 'ASC' : 'DESC';
        
        component.set('v.sortField',field);   
        component.set('v.sortOrder',sortOrder);   
        
        helper.getLawyersList(component,event);         
	},
    checkAll:function(component, event, helper) {
        helper.checkAll(component);
    },
    check:function(component, event, helper) {
        helper.check(component);
    },
    sendToSelected: function(component, event, helper) {
        helper.sendToSelected(component);
    },
    sendAll: function(component, event, helper) {
        helper.sendAll(component);
    },
    sendToIndividual: function(component, event, helper) {
        helper.sendToIndividual(component, event);
    },
    downloadAttachment: function(component, event, helper) {
        let attachmentId = event.currentTarget.dataset.attachment;
        window.open('/servlet/servlet.FileDownload?file=' + attachmentId + '');
    },
    GenerateForAll: function(component, event, helper) {
        helper.GenerateForAll(component);
    },
    generateForSelected: function(component, event, helper) {
        helper.generateForSelected(component);
    },
})