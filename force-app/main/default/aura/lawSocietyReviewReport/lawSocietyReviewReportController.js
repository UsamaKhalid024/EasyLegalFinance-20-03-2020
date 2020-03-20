({
	doInit : function(component, event, helper) {
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
        var dt = new Date();
        helper.getCalendarMin(component);
        helper.getCalendarMax(component);
        
        component.set("v._startDate",dt.getFullYear()-1+'-01-01'); 
        component.set("v._endDate",dt.getFullYear() +'-'+ (dt.getMonth()+1)+'-'+new Date(dt.getFullYear(),dt.getMonth()+1,0).getDate()+'');
        helper.fetchLawyers(component,1,event,helper);
	},
    /**
    * @description Method to update the pagination when selected entry gets changed
    **/
	handleSelectedEntry : function(component, event, helper){
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
		component.set("v._currentpage",1);
		helper.setRecordsToDisplay(component);
    },
    /**
	* @description:   handle first on pagination
	**/
	handleFirst : function(component, event, helper) {
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
        component.set("v._currentpage",1);
        helper.setRecordsToDisplay(component);
	},
	/**
	* @description:   handle Previous on pagination
	**/
	handlePrevious : function(component, event, helper) {
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
		var currentPage = component.get("v._currentpage");
		// check if it not null or undefined
		if(!$A.util.isUndefinedOrNull(currentPage)){
            component.set("v._currentpage",(currentPage > 1 ? currentPage - 1 : 1));
            helper.setRecordsToDisplay(component);
		}
	},
	/**
	* @description:   handle next on pagination 
	**/
	handleNext : function(component, event, helper) {
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
		var currentPage = component.get("v._currentpage");
		var totalNumberOfPages = component.get("v._totalnumberofpages");

		// check if it not null or undefined
		if(!$A.util.isUndefinedOrNull(currentPage) && !$A.util.isUndefinedOrNull(totalNumberOfPages)){
            component.set("v._currentpage",(currentPage < totalNumberOfPages ? currentPage + 1 : totalNumberOfPages));
            helper.setRecordsToDisplay(component);
		}
	},
	/**
	* @description:   handle last on pagination 
	**/
	handleLast : function(component, event, helper) {
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
		var totalNumberOfPages = component.get("v._totalnumberofpages");

		// check if it not null or undefined
		if(!$A.util.isUndefinedOrNull(totalNumberOfPages)){
            component.set("v._currentpage",totalNumberOfPages);
            helper.setRecordsToDisplay(component);
		}
	},
    /**
	* @description:   Method to save the records 
	**/
	saveRecords : function(component, event, helper) {
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
		helper.save(component, event, helper);
	},
    /**
    * @description Method to show the new action modal
    **/
	handleNewAction : function(component, event, helper){
       helper.showNewActionModal(component, event, helper);
    },
    /**
    * @description Method to create new note
    **/
	createNote : function(component, event, helper){
       $A.util.toggleClass(component.find("spinner"),"slds-hide");
        helper.saveNewNote(component, event, helper);
    },
    /**
    * @description Method to close the modal
    **/
	closeModal : function(component, event, helper){
      	helper.closeModal(component, event);
    },
    /**
    * @description Method to show the notes
    **/
	handleShowNotes : function(component, event, helper){
       $A.util.toggleClass(component.find("spinner"),"slds-hide");
       helper.getContentNotes(component, event, helper);
    },
    /**
    * @description Method to handle filter
    **/
	handleFilter : function(component, event, helper){
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
        component.set("v.filterUpcomingHearings","");
        component.set("v.filterCurrentProceedings","");
        component.set("v.filterOrders","");
        component.set("v.filterDateReviewed",null);
        component.set("v.filterNextReviewDate",null);
        
      	component.set("v._currentpage",1);
        helper.fetchLawyers(component,1,event,helper);
	},
	/**
    * @description Method to Sort the records
    **/
	sort: function(component, event, helper) {  
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
        let selectedItem = event.currentTarget;
        let field = selectedItem.dataset.field;
        let sortOrder = component.get('v._sortOrder');
        let oldField = component.get('v._sortField');
        sortOrder = ((sortOrder == 'DESC' && oldField == field) || oldField != field ) ? 'ASC' : 'DESC';
        component.set('v._sortField',field);   
        component.set('v._sortOrder',sortOrder);
		component.set("v._currentpage",1);
        helper.fetchLawyers(component,1,event,helper);
	},
    filterChangeHandler : function(component, event, helper) {        
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
      	component.set("v._currentpage",1);
        helper.fetchLawyers(component,1,event,helper);
    },
    printReportButtnClick : function(component, event, helper) {
        let url = '/apex/LawSocietyReviewPrint?';
        url += 'startDate=' + component.get('v._startDate') + '&endDate=' + component.get('v._endDate');
        url += '&businessUnit=' + component.get('v._selectedBusinessUnit');
        url += '&searchByName=';
        url += component.get('v._lawyerOrLawFirmName') != null && component.get('v._lawyerOrLawFirmName') != undefined? component.get('v._lawyerOrLawFirmName') : '';
        url += '&upcomingHearings=' + component.get('v.filterUpcomingHearings') + '&currentProceedings=' + component.get('v.filterCurrentProceedings');
        url += '&orders=' + component.get('v.filterOrders');
        url += '&dateReviewed=';
        url += component.get('v.filterDateReviewed') != null && component.get('v.filterDateReviewed') != undefined? component.get('v.filterDateReviewed') : '';
        url += '&nextReviewDate=';
        url += component.get('v.filterNextReviewDate') != null && component.get('v.filterNextReviewDate') != undefined?component.get('v.filterNextReviewDate') : '' ;
        url += '&reviewedStatus=' + component.get('v._selectedReviewedStatus');
        
        let newWin;
        try{                       
            newWin = window.open(url);
        }catch(e){}
        if(!newWin || newWin.closed || typeof newWin.closed=='undefined')
        {
            reject([{message: 'Pop-up is blocked please click allow in the top right corner of browser in address bar!'}]);
        }
    },
    resetFilter : function(component, event, helper){
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
        var selectedvalue = event.currentTarget.dataset.value;        
        component.set("v.filter" + selectedvalue, "");
        if(selectedvalue == "DateReviewed" || selectedvalue == "NextReviewDate"){
            component.set("v.filter" + selectedvalue, null);
        }
        
      	component.set("v._currentpage",1);
        helper.fetchLawyers(component,1,event,helper);
    }
})