({
	getCalendarMin : function(component){
        var min = '2010-01-01';
        component.set("v.calendarMin", min);                  
    },
    
    getCalendarMax : function(component){
        var year = new Date().getFullYear() + 5;
        var max = year+'-12-31';
        component.set("v.calendarMax", max);                
    },
    /**
	* @description  Helper method which takes in action and creates promise around it
	* @param        action - action for which callback is set and promise is created around.
	**/
	promiseServerSideCall : function(action) {
		return new Promise(function(resolve, reject) {
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					resolve(response.getReturnValue());
				} else if (state === "ERROR") {
					var errors = response.getError();
					if (errors) {
						if (errors[0] && errors[0].message) {
							reject(Error(errors[0].message));
						}
					} else {
						reject(Error($A.get("Unknown Error")));
					}
				}
			});
			$A.enqueueAction(action);
		});
	},
	
	/**
    * @description  Fetches the records based on the filters setup
    * @param        component - component from which the attribute details are retrieved.
	**/
	fetchLawyers : function(component,currentPage,event,helper) {
        
        var action = component.get("c.getLawyersList");
		action.setParams({
			startDate : component.get("v._startDate"),
			endDate : component.get("v._endDate"),
			businessUnit : component.get("v._selectedBusinessUnit"),
            searchByName : component.get("v._lawyerOrLawFirmName"),
            field : component.get('v._sortField'),
            direction : component.get('v._sortOrder'),
            upcomingHearings : component.get("v.filterUpcomingHearings"),
            currentProceedings : component.get("v.filterCurrentProceedings"),
            orders : component.get("v.filterOrders"),
            dateReviewed : component.get("v.filterDateReviewed"),
            nextReviewDate : component.get("v.filterNextReviewDate"),
            reviewedStatus : component.get("v._selectedReviewedStatus")
            
		});
		this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
					component.set("v._currentpage",currentPage);
					component.set("v._recordsList",result['lawyers']);
                    console.log("lawyers");
                    console.log(result['lawyers']);
					component.set("v._tempRecordsList",result['lawyers']);
					component.set("v._currentUserHasPermissionToSeeLawSocietyReview",result['isCurrentUserSeeLawSocietyReviewReport']);
                    
					if(component.get("v._currentUserHasPermissionToSeeLawSocietyReview")) helper.setRecordsToDisplay(component);
					else $A.util.toggleClass(component.find("spinner"),"slds-hide");
					
				})
			).catch(
				$A.getCallback(function(error){
                    $A.util.removeClass(component.find("spinner"),"slds-hide");
					if(!$A.util.isEmpty(error)){
						$A.get("e.force:showToast").setParams({"type" : "error", "message" : error.message}).fire();
					}
			})
		);
	},
    
    /**
    * @description  Fetches the records based on the filters setup
    * @param        component - component from which the attribute details are retrieved.
	**/
	save : function(component,event,helper) {
		var action = component.get("c.saveContacts");
		action.setParams({
			contactsListJSON : JSON.stringify(component.get("v._recordsToDisplay"))
		});
		this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
                    $A.util.toggleClass(component.find("spinner"),"slds-hide");
					 $A.get("e.force:showToast").setParams({
                        "type" : "success",
                        "message": "Records updated successfully."
                    }).fire();
				})
			).catch(
				$A.getCallback(function(error){
                    $A.util.removeClass(component.find("spinner"),"slds-hide");
					if(!$A.util.isEmpty(error)){
						$A.get("e.force:showToast").setParams({"type" : "error", "message" : error.message}).fire();
					}
			})
		);
	},
	
	/**
    * @description    Method to set the recordsTodisplay attribute based on the selected page
    * @param component - The component to which the controller belongs.
	**/
	setRecordsToDisplay : function(component) {
        var recordsList = component.get("v._tempRecordsList");
        console.log("_tempRecordsList");
        console.log(recordsList);
        var totalNumberOfRecords = recordsList.length;
        var currentPage = component.get("v._currentpage");
        var selectedEntry = component.get("v._selectedEntry");
        var startIndex = 0;
        var endIndex = 0;
        var totalNumberOfPages = 0;
        if(totalNumberOfRecords == 0){
            currentPage = 0;
            startIndex = 0;
        }else{
            startIndex = ((currentPage - 1) * selectedEntry)+1;
            endIndex = (currentPage * selectedEntry) >= recordsList.length ? recordsList.length : currentPage * selectedEntry;
            totalNumberOfPages = Math.ceil(totalNumberOfRecords / selectedEntry);
        }
        component.set("v._currentpage",currentPage);
        component.set("v._startindex",startIndex);
        component.set("v._endindex",endIndex);
        component.set("v._totalnumberofrecords",totalNumberOfRecords);
        component.set("v._totalnumberofpages",totalNumberOfPages);
		// check if not empty or undefined e
		console.log('!$A.util.isUndefined(startIndex) = ' + !$A.util.isUndefined(startIndex));
        console.log('!$A.util.isUndefined(endIndex) = ' + !$A.util.isUndefined(endIndex));
        var recordsToDisplay = [];
		if(!$A.util.isUndefined(startIndex) && !$A.util.isUndefined(endIndex) && startIndex != 0){
			for(var i=(startIndex-1);i<endIndex;i++){
				recordsToDisplay.push(recordsList[i]);
			}
        }
        component.set("v._recordsToDisplay",recordsToDisplay);
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
	},
    
    /**
    * @description  Method to show the action modal
	**/
	showNewActionModal : function(component,event,helper) {
        component.set("v._selectedRecord",event.getSource().get("v.name"));
        $A.createComponents([
			["aura:html",{"tag":"div","body":'New Note for '+event.getSource().get("v.title"),"HTMLAttributes":{"class":"slds-text-align_center slds-text-title_caps","style":"font-size:1rem;color:#3E3E3C;"}}],
            ["lightning:textarea",{"value":component.getReference("v._contentNote"),"label": "New Note"}],
			["lightning:button",{"variant":"brand","label":"Save",onclick:component.getReference("c.createNote")}],
            ["lightning:button",{"variant":"neutral","label":"Cancel",onclick:component.getReference("c.closeModal")}]
		],
		function(components, status, errorMessage){
			if (status === "SUCCESS") {
				var overlayPanel = component.find('overlayLib').showCustomModal({
                    header:components[0],
                    body:components[1],
                    footer:[components[2],components[3]],
                    showCloseButton: true
                });
                component.set("v._overlayPanel",overlayPanel);
            }else if(status === "ERROR"){
                console.error(errorMessage);
            }
		});
	},
    
    /**
    * @description  Fetches the records based on the filters setup
    * @param        component - component from which the attribute details are retrieved.
	**/
	saveNewNote : function(component,event,helper) {
		var action = component.get("c.saveNewNote");
		action.setParams({
			contentNote : component.get("v._contentNote"),
            contactId : component.get("v._selectedRecord")
		});
		this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
                    $A.util.toggleClass(component.find("spinner"),"slds-hide");
                    helper.closeModal(component,event);
                    component.set("v._contentNote",'');
					$A.get("e.force:showToast").setParams({
                        "type" : "success",
                        "message": "Records updated successfully."
                    }).fire();
				})
			).catch(
				$A.getCallback(function(error){
                    $A.util.removeClass(component.find("spinner"),"slds-hide");
					if(!$A.util.isEmpty(error)){
						$A.get("e.force:showToast").setParams({"type" : "error", "message" : error.message}).fire();
					}
			})
		);
	},
    
    /**
    * @description  Fetches the notes
	**/
	getContentNotes : function(component,event,helper) {
		var action = component.get("c.getContentNotes");
		action.setParams({
            contactId : event.getSource().get("v.name")
		});
		this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
                    $A.util.toggleClass(component.find("spinner"),"slds-hide");
                    var columns = new Array();
                    columns.push({label:'Created Date',fieldName:'CreatedDate',type:'date'});
                    columns.push({label:'Detailed Notes',fieldName:'Content',type:'text'});
                    columns.push({label:'Created By',fieldName:'CreatedBy',type:'text'});
                    $A.createComponents([
                        ["aura:html",{"tag":"div","body":'Notes for '+event.getSource().get("v.title"),"HTMLAttributes":{"class":"slds-text-align_center slds-text-title_caps","style":"font-size:1rem;color:#3E3E3C;"}}],
                        ["lightning:dataTable",{"class":"notesList","columns":columns,"data":result,keyField:"Id",showRowNumberColumn:true,hideCheckboxColumn:true}],
                        ["lightning:button",{"variant":"neutral","label":"Cancel",onclick:component.getReference("c.closeModal")}]
                    ],
                    function(components, status, errorMessage){
                        if (status === "SUCCESS") {
                            var overlayPanel = component.find('overlayLib').showCustomModal({
                                header:components[0],
                                body:components[1],
                                footer:components[2],
                                showCloseButton: true,
                                cssClass: "slds-modal_large"
                            });
                            component.set("v._overlayPanel",overlayPanel);
                        }else if(status === "ERROR"){
                            console.error(errorMessage);
                        }
                    });
				})
			).catch(
				$A.getCallback(function(error){
                    $A.util.removeClass(component.find("spinner"),"slds-hide");
					if(!$A.util.isEmpty(error)){
						$A.get("e.force:showToast").setParams({"type" : "error", "message" : error.message}).fire();
					}
			})
		);
	},
    
    /**
    * @description  Method to close the action modal
	**/
	closeModal : function(component,event,helper) {
        component.get("v._overlayPanel").then(
            function (modal) {
                modal.close();
            }
        );
	},
})