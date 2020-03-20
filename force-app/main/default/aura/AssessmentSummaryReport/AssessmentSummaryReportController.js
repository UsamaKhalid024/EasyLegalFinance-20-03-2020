({
	doInit : function(component, event, helper) {
		        
        component.set("v.spinner", true);
        component.set("v.countSelected",0);
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        
        helper.getPickListValues(component, 'Account','Business_Unit__c','businessUnitOptions');

        helper.getDrawdown(component).then(
            function(result){
                component.set('v.drawdown',result);
            }
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        component.set("v.spinner", true);
        helper.getCustomSettings(component).then($A.getCallback(
            function(result){ 
                component.set('v.customSetting', result);
                component.set("v.businessUnitForDesign", result.Business_Unit__c);
                component.set('v.conductorId', result.Conga_Conductor_Id__c);
                return helper.getAssessments(component);
            }
        )).then(
            function(result){
                component.set("v.data", result);
                helper.setDefaultDates(component);
                component.set("v.spinner", false);
                
                let intervalId = window.setInterval(
                    $A.getCallback(function() { 
                        helper.pingBatchJobStatus(component, helper);
                    }), 2000
                ); 
                component.set('v.intervalId', intervalId);
            }
        ).catch(
            function(errors){
                console.log(errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
	},
    searchButton : function(component, event, helper){
        component.set("v.spinner", true);
        component.set("v.countSelected",0);
        helper.resetAttributes(component);
        helper.getAssessments(component).then($A.getCallback(
            function(result){
                component.set("v.data", result);
                component.set("v.businessUnitForDesign", component.get("v.selectedBusinessUnitFilter"));
                return helper.getDrawdown(component);
            }
        )).then($A.getCallback(
            function(result){
            component.set('v.drawdown',result);
            return helper.getCustomSettings(component);
            }
        )).then(function(result){
            component.set('v.customSetting', result);
            component.find("selectAllcheckbox").set("v.value", false);
            component.set("v.spinner", false);
        }).catch(
            function(errors){
                console.log('Error ' + errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
    },
    sort: function(component, event, helper) {  
        component.set("v.countSelected",0);
        let selectedItem = event.currentTarget;
        let field = selectedItem.dataset.field;
        let sortOrder = component.get('v.sortOrder');
        let oldField = component.get('v.sortField');
        helper.resetAttributes(component);
        sortOrder = (sortOrder == 'DESC' && oldField == field) ? 'ASC' : 'DESC';
        
        component.set('v.sortField',field);   
        component.set('v.sortOrder',sortOrder); 
        
        component.set("v.spinner", true);
        
        helper.getAssessments(component).then($A.getCallback(
            function(result){
                component.set("v.data", result);
                component.set("v.businessUnitForDesign", component.get("v.selectedBusinessUnitFilter"));
                component.set("v.spinner", false);
            }
        )).catch(
            function(errors){
                console.log('Error ' + errors);
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );       
    },
    openLinkReport : function(component, event, helper) { 
        let lawyerId = event.currentTarget.dataset.attachment;
        let newWin;
        let url = '/lightning/r/Report/00O0L000003mxbcUAA/view';
        
        try{                       
            newWin = window.open(url + '?fv2=' + lawyerId);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    check : function(component, event, helper){
        let target =  event.getSource();
        let value = target.get('v.value');
        let countSelected = component.get("v.countSelected");

        if(value){
            if(countSelected >= 10){
                alert('You have selected maximum allowed records.');
                target.set('v.value', !value);
            }else{
                countSelected++;               
            }
        }else{
            countSelected--;
        }
        component.set("v.countSelected", countSelected);

    },
    printReportButtnClick : function(component, event, helper){
        component.set("v.spinner", true);
        
        helper.setCustomSettings(component).then($A.getCallback(
            function(result){
                return helper.getCustomSettings(component);
            }
        )).then($A.getCallback(
            function(result){
                component.set('v.customSetting', result);
                return helper.getDrawdown(component);
            }
        )).then(function(result){            
            component.set('v.drawdown',result);
            let url = result.Conga_Assessment_Summary_Report_Print__c;
            url += '%26'+'DefaultPDF=1';
            let newWin;
            try{                       
                newWin = window.open(url);
            }catch(e){}
            if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
            {
                reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
            }
            component.set("v.spinner", false);

        }).catch(function(errors){
            console.log('Error ' + errors);
            component.set("v.spinner", false);
            helper.errorsHandler(errors);
        });
    },
    viewAllButtnClick : function(component, event, helper){
        component.set("v.spinner", true);
        
        helper.setCustomSettings(component).then($A.getCallback(
            function(result){
                return helper.getCustomSettings(component);
            }
        )).then($A.getCallback(
            function(result){
                component.set('v.customSetting', result);
                return helper.getDrawdown(component);
            }
        )).then(function(result){            
            component.set('v.drawdown',result);
            let url = result.Conga_Assessment_Summary_Report_View_All__c;
            var selectedMenuItemValue = event.getParam("value");

            if(selectedMenuItemValue == 'ViewAllPDF'){
                url += '%26'+'DefaultPDF=1';
            }
            let newWin;
            try{                       
                newWin = window.open(url);
            }catch(e){}
            if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
            {
                reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
            }
            component.set("v.spinner", false);

        }).catch(function(errors){
            console.log('Error ' + errors);
            component.set("v.spinner", false);
            helper.errorsHandler(errors);
        });
        
    },    
    generatePayoutBalanceButtnClick : function(component, event, helper){ 
    	var selectedMenuItemValue = event.getParam("value");
        component.set('v.spinner', true);
        if(component.get("v.selectedBusinessUnitFilter") != "Consolidated" && selectedMenuItemValue == 'generatePayoutBalanceForAll'){
            helper.GeneratePayoutBalanceForAll(component).then($A.getCallback(
                function(result){
                    component.set('v.spinner', false);
                    component.set("v.disablePrintButtn", true);
                    window.clearInterval(component.get('v.intervalId'));
                    let intervalId = window.setInterval(
                        $A.getCallback(function() { 
                            helper.pingBatchJobStatus(component, helper);
                            //self.getBatchJobStatus(component);
                        }), 2000
                    ); 
                    component.set('v.intervalId', intervalId);
                }
            )).catch(
                function(errors){
                    console.log('Error ' + errors);
                    component.set("v.spinner", false);
                    helper.errorsHandler(errors);
                }
            );
        }else if(component.get("v.selectedBusinessUnitFilter") != "Consolidated" && selectedMenuItemValue == 'generatePayoutBalanceForSelected'){
            helper.generatePayoutBalanceForSelected(component).then($A.getCallback(
                function(result){
                    component.set('v.spinner', false);
                    component.set("v.disablePrintButtn", true);
                    window.clearInterval(component.get('v.intervalId'));
                    let intervalId = window.setInterval(
                        $A.getCallback(function() { 
                            helper.pingBatchJobStatus(component, helper);
                            //self.getBatchJobStatus(component);
                        }), 2000
                    ); 
                    component.set('v.intervalId', intervalId);
                }
            )).catch(
                function(errors){
                    console.log('Error ' + errors);
                    component.set("v.spinner", false);
                    helper.errorsHandler(errors);
                }
            );
        }else{
            component.set('v.spinner', false);
            alert("Can not generate payouts for selected business unit. Please select ELFI or Rhino from dropdown.");
        }
    },
    generatePayoutDocumentButtnClick : function(component, event, helper){
        component.set("v.spinner", true);
        
        let generatePDF = event.getParam("value") == 'generatePayoutPDF' ? true : false;
        helper.setConductorURLfield(component, generatePDF).then($A.getCallback(
            function(result){
                component.set("v.spinner", false);
                let url = '/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&myconductorid=' + component.get('v.conductorId');
                
                var newWin;
                try{
                    newWin = window.open( url + '&ReturnPath=/lightning/n/Assessment_Loans?0.source=alohaHeader');
                }
                catch(e){}
                if(!newWin || newWin.closed || typeof newWin.closed=='undefined') 
                { 
                    //alert();
                    this.showToast('Error', 'Pop-up is blocked please click allow in the top right corner of browser in address bar!');
                    //POPUP BLOCKED
                }
            }
        )).catch(function(errors){
            console.log('Error ' + errors);
            component.set("v.spinner", false);
            helper.errorsHandler(errors);
        });
        
    },
    downloadAttachment : function(component, event, helper){
        let attachmentId = event.currentTarget.dataset.attachment;
        window.open('/servlet/servlet.FileDownload?file=' + attachmentId + '');
    },
    openRecordSelectModal : function(component, event, helper){
        component.set("v.spinner", true);
        let selectedItem = event.currentTarget;
        let lawyerId = selectedItem.dataset.value;
        component.set("v.selectedLawyer", lawyerId);
        let data = component.get("v.data");
        
        
        
        helper.getClientAccounts(component, lawyerId).then(
            function(result){                
                component.set("v.accData", result);
                component.set("v.filteredData", result); 
                let selectedRowsMap =  component.get("v.selectedRowsMap");
                let size = 0;
                if(selectedRowsMap[lawyerId] != undefined && selectedRowsMap[lawyerId] != null){
                    size = selectedRowsMap[lawyerId].length;
                }
                component.set("v.showRecordSelectModal", true);
                if(size > 0 && size == result.length)
                    component.find("selectAllClientCheckbox").set("v.value", true);
                component.set("v.spinner", false);
            }
        ).catch(function(errors){
            console.log('Error ' + errors);
            component.set("v.spinner", false);
            helper.errorsHandler(errors);
        });
    },
    saveSelectedRows : function(component, event, helper){
        component.set("v.spinner", true);
        
        let data = component.get("v.data");
        let lawyerId = component.get("v.selectedLawyer");
        let selectedRowsMap =  component.get("v.selectedRowsMap");        
        let accData = component.get("v.accData");
        
        let selectedIds = [];
        accData.forEach(function (element){
            if(element.checked)
                selectedIds.push(element.Id)
        });
        selectedRowsMap[lawyerId] = selectedIds;
        
        //mark parent checkbox
       	
        for(let i = 0; i < data.length; i++){
            if(data[i].lawyerId == lawyerId){
                data[i].checked = selectedRowsMap[lawyerId].length > 0? true : false;
                break;
            }                
        }
        component.set("v.data", data);
        
        let count = 0;
        let lawyerSelectedCount = 0; 
        for(let key in selectedRowsMap){
            count += selectedRowsMap[key].length;
            lawyerSelectedCount++;
        }
        
        component.set("v.countSelected", lawyerSelectedCount);
        
        component.set("v.selectedRowsCount", count);
        
        component.set("v.selectedRowsMap", selectedRowsMap);
        component.set("v.spinner", false);
        component.set("v.showRecordSelectModal", false);
    },
    closeRecordSelectModal : function(component, event, helper){        
        component.set("v.spinner", false);
        component.set("v.showRecordSelectModal", false);
    },
    searchClientRecords : function (component, event, helper) {
        
        var timer = component.get('v.timer');
        clearTimeout(timer);
        
        var timer = setTimeout(function(){
            var queryTerm = component.find('enter-search').get('v.value');
            helper.filterRecords(component, queryTerm);
            component.set('v.timer', null);
        }, 300);
        
        component.set('v.timer', timer);
        
       
    },
    openConsolidatedPayoutAttachment : function(component, event, helper){
        let lawyerId = event.currentTarget.dataset.attachment;
        window.open('/apex/GenerateConsolidatedAssessmentPayout?lawyerId=' + lawyerId + '&businessUnit='+ component.get("v.selectedBusinessUnitFilter"), '_blank');
    },
    checkAll : function(component, event, helper){
        var comp = component.find("selectAllClientCheckbox");
        let value = comp.get("v.value");
        let filteredData = component.get("v.filteredData");
        for(let i=0; i<filteredData.length; i++){
            filteredData[i].checked = value;            
        }
        
        component.set("v.filteredData", filteredData);
        comp.set("v.value", value);
    },
    check : function(component, event, helper){
        helper.setClientCheckBox(component);
    }
})