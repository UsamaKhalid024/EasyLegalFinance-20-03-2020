({
	doInit : function(component, event, helper) {
        component.set('v.spinner',true);
		helper.getCurrentUserInfo(component).then($A.getCallback(
            function(result){
                component.set('v.currentUser',result);
                return helper.getLawyerRecordData(component);
            }
        )).then(
            function(result){
                component.set('v.Lawyer',result);
                var expandedSections = component.get('v.expandedSections') || {};
                console.log(expandedSections);
                
                expandedSections['Information'] = !expandedSections['Information'];
                console.log(expandedSections['Information']);
                component.set('v.expandedSections', expandedSections);
                component.set('v.spinner',false);
            }
        ).catch(
            function(errors){
                component.set('v.spinner',false);
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
    
    updateRecord: function(component, event, helper) {
        component.set('v.spinner',true);
        helper.updateLawyerRecord(component).then($A.getCallback(
            function(result){
                
                helper.showToast('SUCCESS', 'Record Updated Successfully.', 'SUCCESS');                
                return helper.getCurrentUserInfo(component);
            }
        )).then($A.getCallback(
            function(result){
                component.set('v.currentUser',result);
                return helper.getLawyerRecordData(component);
            }            
        )).then($A.getCallback(
            function(result){
                
                component.set('v.Lawyer',result);
                component.set('v.spinner',false);
                let historyComponent = component.find("historyComponent");
                historyComponent.refreshData();
                
                let assessmentOppsComponent = component.find("assessmentOppsComponent");
                assessmentOppsComponent.refreshData();
                
                $A.get('e.force:refreshView').fire();
            }
        )).catch(
            function(errors){
                component.set('v.spinner',false);
                console.log('Errors ' + JSON.stringify(errors));
                helper.errorsHandler(errors);
            }
        );
    },
    openReferenceReport : function(component, event, helper){
        
        let newWin;
        let url = '/lightning/r/Report/00O1F000000iWziUAE/view';
        
        try{                       
            newWin = window.open(url + '?fv2=' + component.get("v.recordId"));
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    }
})