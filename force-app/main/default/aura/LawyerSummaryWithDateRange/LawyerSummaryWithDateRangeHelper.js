({
    getCalendarMin : function(component){
        var year = new Date().getFullYear() - 1;
        //var min = year+'-01-01';
        var min = '2010-01-01';
        component.set("v.calendarMin", min);                  
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 5;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    setDefaultDates : function(component){
        let dt = new Date();
        
        let defaultPayoutDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
        component.set("v.payoutDate", defaultPayoutDate);
        
        let defaultReportDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + dt.getDate() + '';
        component.set("v.reportDate", defaultReportDate); 
        
    },
    getPickListValues : function(component, object, field, attributeId){
        var picklistgetter = component.get('c.getPickListValues');
        picklistgetter.setParams({
            objectType: object,
            field: field
        });
        
        
        picklistgetter.setCallback(this, function(response){
            var opts = [];
            if(response.getState() == 'SUCCESS')
            {
                var allValues = response.getReturnValue();
 
               /*if (allValues != undefined && allValues.length > 0) {
                    opts.push({
                        class: "optionClass",
                        label: "All",
                        value: "All"
                    });
                }*/
                for (var i = 0; i < allValues.length; i++) {
                    if(allValues[i].includes('===SEPERATOR==='))
                    {
                        opts.push({
                            class: "optionClass",
                            label: allValues[i].split('===SEPERATOR===')[0],
                            value: allValues[i].split('===SEPERATOR===')[1]
                        });
                    }
                    else
                    {
                        opts.push({
                            class: "optionClass",
                            label: allValues[i],
                            value: allValues[i]
                        });
                    }
                }     
                opts.push({
                    class: "optionClass",
                    label: 'Consolidated',
                    value: 'Consolidated'
                });              
                component.set('v.'+attributeId, opts);
            }
        });
        $A.enqueueAction(picklistgetter);
    },
    /*
    getLawyersList : function(component) {
        //var recordId = component.get("v.recordId");
        var action = component.get('c.getLawyersContacts');             
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.contactsList", response.getReturnValue());                
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);        
    },
    searchButton : function(component) {
        let searchString = component.get('v.searchString');
        let endDateSearch = component.get('v.endDateSearch');
		let loanFilterValue = component.find("activeLoanFilter").get("v.value"); 
        
        var action = component.get('c.getLawyersContacts');
        action.setParams({ sortField : '', sortOrder : '', searchString : searchString, LoanFilter: loanFilterValue});
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.contactsList", response.getReturnValue());                
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);       
    },*/
    //sort : function(component, event) {
    
    formatDate : function(dateToFormat){
        var d = new Date(dateToFormat),
        month = '' + (d.getMonth() + 1),
        day = '' + d.getDate(),
        year = d.getFullYear();
    	if (month.length < 2) month = '0' + month;
    	if (day.length < 2) day = '0' + day;
        return [year,month,day].join('-')+'T00:00:00Z';
    },
    getQueryString : function(component){
        let searchString = component.get('v.searchString');
        let field = component.get('v.sortField');
        let sortOrder = component.get('v.sortOrder');
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let strQuery = component.get('v.query');        
        
        searchString = searchString ? "'%"+searchString+"%'" : "'%%'";
        sortOrder = sortOrder? sortOrder : "ASC";
        field = field ? field : "Name";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : 'ELFI';
        console.log(businessUnitFilterValue);
        strQuery += " AND (Name Like " + searchString + " OR Account.Name Like " + searchString + " ) ";
        strQuery += " AND Id in (SELECT Lawyer__c FROM Opportunity WHERE accountId !=null";
        strQuery += businessUnitFilterValue == 'Consolidated'? "" : " AND Account.Business_Unit__c = \'"+businessUnitFilterValue+"\'";
        strQuery += loanFilterValue == "Active"? " AND isClosed = true AND isWon = true AND Stage_Status__c != 'Paid Off')" : ")";
        if(component.get("v.startDate") && component.get("v.endDate")) strQuery += " AND CreatedDate >= "+this.formatDate(component.get("v.startDate"))+" AND CreatedDate <= "+this.formatDate(component.get("v.endDate"));
        strQuery += " order by " + field + " " + sortOrder + " limit 10000";
        console.log(strQuery);
        return strQuery;
    },
    
    getLawyersList : function(component, event) {
        
        component.set('v.spinner', true);
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let strQuery = this.getQueryString(component);             
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        
        var action = component.get('c.getLawyersContacts');
        action.setParams({
            strQuery : strQuery, 
            LoanFilter: loanFilterValue,
            businessUnitFilter: businessUnitFilterValue,
            startDate : component.get("v.startDate"),
            endDate : component.get("v.endDate")
        });
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            component.set('v.spinner', false);
            if (state === 'SUCCESS') {
                component.set("v.contactsList", response.getReturnValue());                
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);    
    },
    checkAll: function(component){
        
        let value = component.find("selectAllcheckbox").get("v.value");      
        let contactList = component.get("v.contactsList");
        
        for(let i=0; i<contactList.length; i++){
            contactList[i].checked = value;
        }
        
        component.set("v.contactsList",contactList);
        
    },
    check: function(component){    
        var comp = component.find("selectAllcheckbox");
        let value = comp.get("v.value");        
        if(value){
            value = false;
        }
        let contactList = component.get("v.contactsList");
        let count = 0;
        for(let i=0; i<contactList.length; i++){
            if(contactList[i].checked == true){
                count++;
            }
        }
        if(count == contactList.length){
            value = true;
        }
		comp.set("v.value", value);        
        
    },
    
    generateForSelected: function (component){
        component.set('v.spinner', true);
        let contactList = component.get("v.contactsList");
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");        
        let loanFilterValue = component.get("v.selectedLoanFilter");
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        
        let selectedIds = [];
        let conList = [];
        for(let i=0; i<contactList.length; i++){
            if(contactList[i].checked == true){
                selectedIds.push("'" + contactList[i].contact.Id + "'");
                conList.push(contactList[i].contact);
            }
        }
        if(selectedIds.length == 0){
            component.set('v.spinner', false);
            alert("Please select records.");
        }else{
            //alert("Total " + selectedIds.length);
            var action = component.get('c.generate');
            action.setParams({
                query : '', 
                selectedIds : selectedIds, 
                payoutDate : payoutDate, 
                reportDate : reportDate,
                LoanFilter: loanFilterValue,
                businessUnitFilter: businessUnitFilterValue
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
                    
                    var newWin;
                    try{
                    newWin = window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&myconductorid=' + response.getReturnValue() + '&ReturnPath=/lightning/n/Custom_Reports?0.source=alohaHeader');
                    }
                    catch(e){}
                    if(!newWin || newWin.closed || typeof newWin.closed=='undefined') 
                    { 
                        //alert();
                        this.showToast('Error', 'Pop-up is blocked please click allow in the top right corner of browser in address bar!');
                        //POPUP BLOCKED
                    }
                    //window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&&ReportId=&QueryId=a0p21000003rhuC&RecordId=&UrlFieldName=Conga_Batch_Lawyer_Summary__c&Id=a1T21000000osQc');
                } else if (state === 'ERROR') {
                    var errors = response.getError();
                    console.log(JSON.stringify(errors[0]));
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.errorsHandler(errors)
                        }
                    } else {
                        this.unknownErrorsHandler();
                    }
                }
                component.set('v.spinner', false);
            });
            $A.enqueueAction(action);
            
        }
        
    },
    
    sendToSelected: function (component){
        component.set('v.spinner', true);
        let contactList = component.get("v.contactsList");
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");
        let emailBody = component.get("v.emailBody");
		let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";        
        
        let selectedIds = [];
        let conList = [];
        for(let i=0; i<contactList.length; i++){
            if(contactList[i].checked == true){
                console.log(contactList[i]);
                console.log(contactList[i].contact);
                selectedIds.push("'" + contactList[i].contact.Id + "'");
                conList.push(contactList[i].contact);
            }
        }
        console.log(selectedIds);
        if(selectedIds.length == 0){
            component.set('v.spinner', false);
            alert("Please select records.");
        }else{
            //alert("Total " + selectedIds.length);
            var action = component.get('c.send');
            action.setParams({
                query : '', 
                selectedIds : selectedIds, 
                payoutDate : payoutDate, 
                reportDate : reportDate, 
                emailBody : emailBody,
                LoanFilter: loanFilterValue,
                businessUnitFilter: businessUnitFilterValue
            });            
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
                    var newWin;
                    try{
                        newWin = window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&myconductorid=' + response.getReturnValue() + '&ReturnPath=/lightning/n/Custom_Reports?0.source=alohaHeader');
                    }
                    catch(e){}
                    if(!newWin || newWin.closed || typeof newWin.closed=='undefined') 
                    { 
                        //alert();
                        this.showToast('Error', 'Pop-up is blocked please click allow in the top right corner of browser in address bar!');
                        //POPUP BLOCKED
                    }
                    
                } else if (state === 'ERROR') {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.errorsHandler(errors)
                        }
                    } else {
                        this.unknownErrorsHandler();
                    }
                }
                component.set('v.spinner', false);
            });
            $A.enqueueAction(action);
            
        }
        
    },

    setDefaultDates : function(component){
        let dt = new Date();
        let defaultEndDate = dt.getFullYear() +'-'+ (dt.getMonth() + 1) +'-' + new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate() + '';
        let defaultStartDate = dt.getFullYear() +'-'+ (dt.getMonth()) +'-01';
        component.set("v.endDate", defaultEndDate);
        component.set("v.startDate", defaultStartDate);  
    },
    
    sendToIndividual: function(component, event){
        component.set('v.spinner', true);
        let contactId = event.currentTarget.dataset.selected;
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");        
        let emailBody = component.get("v.emailBody");
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        
        var action = component.get('c.send');
            action.setParams({
                query : '', 
                selectedIds : "'" + contactId + "'", 
                payoutDate : payoutDate, 
                reportDate : reportDate, 
                emailBody : emailBody,
                LoanFilter: loanFilterValue,
                businessUnitFilter: businessUnitFilterValue
            });
        
            action.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === 'SUCCESS') {
                    component.set('v.spinner', false);
                    var newWin;
                    try{
                        newWin = window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&myconductorid=' + response.getReturnValue() + '&ReturnPath=/lightning/n/Custom_Reports?0.source=alohaHeader');
                    }
                    catch(e){}
                    if(!newWin || newWin.closed || typeof newWin.closed=='undefined') 
                    { 
                        //alert();
                        this.showToast('Error', 'Pop-up is blocked please click allow in the top right corner of browser in address bar!');
                        //POPUP BLOCKED
                    }
                    
                } else if (state === 'ERROR') {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.errorsHandler(errors)
                        }
                    } else {
                        this.unknownErrorsHandler();
                    }
                }
            });
            $A.enqueueAction(action);
    },
    
    GenerateForAll: function (component){
        component.set('v.spinner', true);
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");        
        let query = this.getQueryString(component);
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All";
        
        var action = component.get('c.generate');
        action.setParams({
            query : query, 
            selectedIds : [], 
            payoutDate : payoutDate, 
            reportDate : reportDate,
            LoanFilter: loanFilterValue,
            businessUnitFilter: businessUnitFilterValue
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
                
            if (state === 'SUCCESS') {
                component.set('v.spinner', false);
                var newWin;
                try{
                    newWin = window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&myconductorid=' + response.getReturnValue() + '');
                }
                catch(e){}
                if(!newWin || newWin.closed || typeof newWin.closed=='undefined') 
                { 
                    //alert();
                    this.showToast('Error', 'Pop-up is blocked please click allow in the top right corner of browser in address bar!');
                    //POPUP BLOCKED
                }
                
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
        
    },
    
    sendAll: function (component){
        component.set('v.spinner', true);
        let payoutDate = component.get("v.payoutDate");
        let reportDate = component.get("v.reportDate");        
        let query = this.getQueryString(component);
        let emailBody = component.get("v.emailBody");
        let businessUnitFilterValue = component.get("v.selectedBusinessUnitFilter");
        let loanFilterValue = component.get("v.selectedLoanFilter");
        businessUnitFilterValue = businessUnitFilterValue ? businessUnitFilterValue : "ELFI";
        loanFilterValue = loanFilterValue ? loanFilterValue : "All"; 
        
        var action = component.get('c.send');
        action.setParams({
            query : query, 
            selectedIds : [], 
            payoutDate : payoutDate, 
            reportDate : reportDate, 
            emailBody : emailBody,
            LoanFilter: loanFilterValue,
            businessUnitFilter: businessUnitFilterValue
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
                
            if (state === 'SUCCESS') {
                component.set('v.spinner', false);
                var newWin;
                try{
                    newWin = window.open('/apex/APXT_BPM__Conductor_Launch?mysid={!$Api.Session_ID}&myserverurl={!$Api.Partner_Server_URL_290}&myconductorid=' + response.getReturnValue() + '&ReturnPath=/lightning/n/Custom_Reports?0.source=alohaHeader');
                }
                catch(e){}
                if(!newWin || newWin.closed || typeof newWin.closed=='undefined') 
                { 
                    //alert();
                    this.showToast('Error', 'Pop-up is blocked please click allow in the top right corner of browser in address bar!');
                    //POPUP BLOCKED
                }
                
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.errorsHandler(errors)
                    }
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
        
    },
    errorsHandler : function(errors){
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message);
        }
    },
    
    unknownErrorsHandler : function(){
        console.log('Unknown error');
        this.showToast('Error', 'Unknown error'); 
    },       
    
    showToast : function(title, message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    setBusinessUnitFilter : function(component){
        var businessUnit = component.get("v.selectedBusinessUnitFilter");
        if(businessUnit == 'Consolidated'){
            component.set("v.pv1","ELFI");
            component.set("v.pv2","Rhino");
        }else{
            component.set("v.pv1",businessUnit);
            component.set("v.pv2","");
        }
    },
    getViewUrl : function(component){
        component.set("v.viewUrl","/apex/APXTConga4__Conga_Composer?SolMgr=1&serverUrl="+$A.get("$Label.c.Partner_API_Server_Url")+"&Id="+$A.get("$SObjectType.CurrentUser.Id")+"&QueryId=[lawyerCount]"+$A.get("$Label.c.Lawyer_Count_Query_Id")+"?pv1=\'"+component.get("v.pv1")+"\'~pv2=\'"+component.get("v.pv2")+"\'~pv3="+this.formatDate(component.get("v.startDate"))+"~pv4="+this.formatDate(component.get("v.endDate"))+"&TemplateId="+$A.get("$Label.c.Lawyer_Count_Template_Id")+"&DS7=3");
    }
})