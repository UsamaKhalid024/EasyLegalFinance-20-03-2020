<aura:application implements="flexipage:availableForAllPageTypes,force:appHostable,force:hasRecordId" access="global" controller="LeadViewComponentCtlr" extends="force:slds">
    
    <aura:handler name="init" value="{!this}" action="{!c.doInit}"/>
    <aura:attribute name="recordId" type="String" /> 
    <aura:attribute name="leadObj" type="Object" /> 
    
    <div style="width:70%; margin: auto;">
        <lightning:layout class="slds-m-right_xx-large slds-m-left_xx-large" verticalAlign="center">    
            <lightning:layoutItem flexibility="grow">                
                <lightning:card title="" variant="base">                    
                    <aura:set attribute="actions">
						<lightning:button class="slds-theme_neutral" iconPosition="left" variant="neutral" type="button" label="Print" onclick="{!c.doPrint}" />
                    </aura:set>                
                    
                    <!-- <<<<<<<<<< Applicant Contact Information >>>>>>>>>> -->                  
                    <div class="slds-card__body_inner slds-m-bottom_large" style="margin-top: -3%;">
                        <h1 style="font-size:1rem">Applicant Contact Information</h1>
                        <div class="slds-form-element   ">
                            <span class="slds-form-element__label">Applicant Name:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Salutation__c}&nbsp;{!v.leadObj.Name}</span>
                        </div>
                        <div class="slds-form-element   ">
                            <span class="slds-form-element__label">Have you ever changed your legal name?</span>
                            <span class="slds-form-element__static">{!v.leadObj.Have_you_ever_changed_your_legal_name__c}</span>
                        </div>
                        <div class="slds-form-element   ">
                            <span class="slds-form-element__label">If yes to the above question, please provide previous name:</span>
                            <span class="slds-form-element__static">{!v.leadObj.If_yes_please_provide_previous_name__c}</span>
                        </div>
                        <div class="slds-form-element   "><span class="slds-form-element__label">Address:</span>
                            <div class="slds-form-element__control"><span class="slds-form-element__static">{!v.leadObj.Street},
                                <br/>{!v.leadObj.City},
                                <br/>{!v.leadObj.State},
                                <br/>{!v.leadObj.PostalCode},
                                <br/>{!v.leadObj.Country}</span></div>
                        </div>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Home Phone:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Phone}</span>
                        </div>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Mobile Phone:</span>
                            <span class="slds-form-element__static">{!v.leadObj.MobilePhone}</span>
                        </div>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Fax:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Fax}</span>
                        </div>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Email:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Email}</span>
                        </div> 
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">How did you hear about us:</span>
                            <span class="slds-form-element__static">{!v.leadObj.How_did_you_hear_about_us__c}</span>
                        </div>                      
                    </div>
                    
                    <!-- <<<<<<<<<< Lawyer Information >>>>>>>>>> -->                
                    <div class="slds-card__body_inner slds-m-bottom_large">
                        <h1 style="font-size:1rem">Lawyer Information</h1>
                        <div class="slds-form-element   ">
                            <span class="slds-form-element__label">Firm Name:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Law_Firm_Name_new__r.Name}</span>
                        </div>
                        <div class="slds-form-element   ">
                            <span class="slds-form-element__label">Lawyer's / Paralegal's Name:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Lawyer_Name_new__r.Name}</span>
                        </div>
                        <div class="slds-form-element   ">
                            <span class="slds-form-element__label">Phone:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Law_Phone__c}</span>
                        </div>
                        <div class="slds-form-element   ">
                            <span class="slds-form-element__label">Email:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Law_Email__c}</span>
                        </div>
                    </div>
                    
                    <!-- <<<<<<<<<< Applicant Personal Information >>>>>>>>>> -->                
                    <div class="slds-card__body_inner slds-m-bottom_large">
                        <h1 style="font-size:1rem">Applicant Personal Information</h1>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Date of Application:</span>
                            <span class="slds-form-element__static">
                                <ui:outputDate aura:id="startDateFilter" value="{!v.leadObj.Date_of_Application__c}"/>
                            </span>
                        </div>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">ELF File No:</span>
                            <span class="slds-form-element__static">{!v.leadObj.ELF_File_No__c}</span>
                        </div>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Business Unit:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Business_Unit__c}</span>
                        </div>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">DOB:</span>
                            <span class="slds-form-element__static">
                                <ui:outputDate aura:id="startDateFilter" value="{!v.leadObj.DOB__c}"/>
                            </span>
                        </div>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Citizenship Status:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Citizenship_Status__c}</span>
                        </div>     
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Marital Status:</span>
                            <span class="slds-form-element__static">
                                <c:CheckboxUtil options="Single,Divorced,Widowed,Separated,Married/Common Law" selectedOption="{!v.leadObj.Marital_Status__c}" />
                            </span>
                        </div>   
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Province of Driver's Licence:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Province_of_Driver_s_Licence__c}</span>
                        </div>   
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Driver's Licence No:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Driver_s_Licence_No__c}</span>
                        </div>   
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Any SpousalChild support payment?</span>
                            <span class="slds-form-element__static">
                                <c:CheckboxUtil options="Yes,No" selectedOption="{!v.leadObj.Any_SpousalChild_support_payment__c}" />
                            </span>
                        </div>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">If yes to the above question, please provide amount:</span>
                            <span class="slds-form-element__static">
                                <ui:outputCurrency value="{!v.leadObj.If_yes_please_provide_amount__c}"/>                            
                            </span>
                        </div>   
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Have you ever been in arrears on payment?</span>
                            <span class="slds-form-element__static">
                                <c:CheckboxUtil options="Yes,No" selectedOption="{!v.leadObj.Have_you_ever_been_in_arrears_on_payment__c}" />
                            </span>
                        </div> 
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Do you have any dependants?</span>
                            <span class="slds-form-element__static">
                                <c:CheckboxUtil options="0,1,2,3,4,5,6,7,8,9,10" selectedOption="{!v.leadObj.Do_you_have_any_dependants__c}" />
                            </span>
                        </div> 
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Have you ever declared bankruptcy?</span>
                            <span class="slds-form-element__static">
                                <c:CheckboxUtil options="Yes,No" selectedOption="{!v.leadObj.Have_you_ever_declared_bankruptcy__c}" />
                            </span>
                        </div> 
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">If Yes to the above question, please provide details:</span>
                            <span class="slds-form-element__static">{!v.leadObj.If_Yes_please_provide_details__c}</span>
                        </div>                      
                    </div>  
                    
                    <!-- <<<<<<<<<< Incident / Accident Details >>>>>>>>>> -->                
                    <div class="slds-card__body_inner slds-m-bottom_large">
                        <h1 style="font-size:1rem">Incident / Accident Details</h1>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Date of Accident / Incident:</span>
                            <span class="slds-form-element__static">
                                <ui:outputDate aura:id="startDateFilter" value="{!v.leadObj.Date_of_Accident_Incident__c}"/>
                            </span>
                        </div>  
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Details of Accident / Incident:	</span>
                            <span class="slds-form-element__static">{!v.leadObj.what_happened__c}</span>
                        </div>  
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Injury:	</span>
                            <span class="slds-form-element__static">{!v.leadObj.Nature_of_Injury__c}</span>
                        </div>   
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">First Party Insurance Company: </span>
                            <span class="slds-form-element__static">{!v.leadObj.First_Party_Insurance_Company__c}</span>
                        </div>  
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Third Party Insurance Company: </span>
                            <span class="slds-form-element__static">{!v.leadObj.Third_Party_Insurance_Company__c}</span>
                        </div>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Status of A/B Claim (If settled, how much and when): </span>
                            <span class="slds-form-element__static">{!v.leadObj.Status_of_A_B_Claim_how_much_and_when__c}</span>
                        </div> 
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Prior Injury?</span>
                            <span class="slds-form-element__static">{!v.leadObj.Prior_Injury__c}</span>
                        </div> 
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Current Tx:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Current_Tx__c}</span>
                        </div>                     
                    </div>
                    
                    <!-- <<<<<<<<<< Employment Details >>>>>>>>>> -->                
                    <div class="slds-card__body_inner slds-m-bottom_large">
                        <h1 style="font-size:1rem">Employment Details</h1>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Occupation:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Occupation__c}</span>
                        </div>  
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Job description:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Job_description__c}</span>
                        </div>  
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Annual Income on Date of Loss:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Annual_Income_on_Date_of_Loss__c}</span>
                        </div>   
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Employment status at time of accident:</span>
                            <span class="slds-form-element__static">
                                <c:CheckboxUtil options="Full-time,Part-time,Self-employed,Unemployed" selectedOption="{!v.leadObj.Employment_status_at_time_of_accident__c}" />
                            </span>
                        </div>  
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Date Last worked? Were attempts made to RTW: Is Job still available?	</span>
                            <span class="slds-form-element__static">
                                <ui:outputDate aura:id="startDateFilter" value="{!v.leadObj.Date_Last_worked_attempts_to_RTW__c}"/>
                            </span>
                        </div>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Prior Employment: </span>
                            <span class="slds-form-element__static">{!v.leadObj.Prior_Employment__c}</span>
                        </div> 
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Collateral Benefits (If yes, how much?):</span>
                            <span class="slds-form-element__static">{!v.leadObj.Collateral_Benefits__c}</span>
                        </div>                     
                    </div>                            
                    
                    <!-- <<<<<<<<<< Funding Details >>>>>>>>>> -->                
                    <div class="slds-card__body_inner slds-m-bottom_large">
                        <h1 style="font-size:1rem">Funding Details</h1>
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Funding Requested:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Funding_Requested__c}</span>
                        </div>  
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Existing Litigation Loans:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Existing_Litigation_Loans__c}</span>
                        </div>  
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Loan Amount:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Loan_Amount__c}</span>
                        </div>   
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Name of Lender:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Name_of_Lender__c}</span>
                        </div>  
                        <div class="slds-form-element">
                            <span class="slds-form-element__label">Address:</span>
                            <span class="slds-form-element__static">{!v.leadObj.Address__c}</span>
                        </div>                  
                    </div>                 
                </lightning:card>            
            </lightning:layoutItem>
        </lightning:layout>
    </div>
</aura:application>