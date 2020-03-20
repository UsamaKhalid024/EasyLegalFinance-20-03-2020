({
	doInit : function(component, event, helper) {
		$A.util.toggleClass(component.find("spinner"),"slds-hide");
        helper.getLawyerInfo(component).then($A.getCallback(
            function(result){
                component.set('v.Lawyer',result);
                var expandedSections = component.get('v.expandedSections') || {};
                console.log(expandedSections);
                
                expandedSections['Information'] = !expandedSections['Information'];
                console.log(expandedSections['Information']);
                component.set('v.expandedSections', expandedSections);
                return helper.getContentNotes(component);
                
            }
        )).then(
            function(result){
                var columns = new Array();
                columns.push({label:'Detailed Notes',fieldName:'Content',type:'text'});
                columns.push({label:'Created Date',fieldName:'CreatedDate',type:'date'});
                columns.push({label:'Created By',fieldName:'CreatedBy',type:'text'});
                
                component.set("v.notes", result);
                component.set("v.notesColumns", columns);
                component.set("v.isDataTableReady", true);
                $A.util.toggleClass(component.find("spinner"),"slds-hide");
            }
        ).catch(
            function(errors){
                $A.util.toggleClass(component.find("spinner"),"slds-hide");
                console.log('Errors ' + JSON.stringify(errors));
                helper.errorsHandler(errors);
            }
        );
	},
    toggleSection : function(component, event, helper) {
        var section = event.currentTarget.getAttribute('data-section');
        var expandedSections = component.get('v.expandedSections') || {};
        expandedSections[section] = !expandedSections[section];
        component.set('v.expandedSections', expandedSections);
    },
    handleNotesSort : function(component, event, helper) {
        //Returns the field which has to be sorted
        var sortBy = event.getParam("fieldName");
        //returns the direction of sorting like asc or desc
        var sortDirection = event.getParam("sortDirection");
        //Set the sortBy and SortDirection attributes
        component.set("v.sortBy",sortBy);
        component.set("v.sortDirection",sortDirection);
        // call sortData helper function
        helper.sortNotes(component,sortBy,sortDirection);
    }
})