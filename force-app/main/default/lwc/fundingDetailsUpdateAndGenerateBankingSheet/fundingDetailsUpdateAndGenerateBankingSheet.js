import { LightningElement, api, track, wire } from 'lwc';
import generateBankingSheet from '@salesforce/apex/FundingDetailsComponentCtlr.generateBankingSheet';

import { showToast } from 'c/showToast';
import { generateDataTableErrors } from 'c/ldsUtils';
import {
    download,
    loadGlobalCss,
    //sendScheduledPaymentsChangedEvent,
    //updateFlattenedListFromResult,
    updateScheduledPaymentsFromDraftValues,
    //sendNeedsRefreshEvent,
    PERMISSION_CLASSES,
    combineData,
    //updateSPList,
    groupPayments
} from 'c/fundingDetailsUtils';
import fetchCustomPermissions from '@salesforce/apex/FetchCustomPermissions.fetchCustomPermissions';
import getScheduledPaymentsWithOpportunities from '@salesforce/apex/FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities';

export default class FundingDetailsUpdateAndGenerateBankingSheet extends LightningElement {
    _filters = {
        preset: 'this_week'
    }
    @api 
    get filters() {
        return this._filters;
    }
    set filters(value) {
        this._filters = value || this._filters;
        if (this.filterInitilized && this.resourcesInitialized) {
            this.refresh();
        }
    }

    @track groupedPayments;
    @track data;
    @track spList;
    @track spMap;
    @track oppList;
    @track oppMap;
    @track selectedScheduledPayment;
    @track selectedOpportunity;
    @track permissions;
    @track pageSize = 50;

    @wire(fetchCustomPermissions, {permissions: PERMISSION_CLASSES})
    setPermissions(result) {
        if (result.data) {
            this.permissions = result.data;
        }
    }

    @track flattenedList;
    @track loading = true;
    confirmed = true;
    @track bankingSheetText = 'Generate Banking Sheet';

    @track columns = [
        { label: 'Verified', fieldName: 'Verified_By__r.Name', sortable: true },
        { label: 'Can Send', fieldName: 'Can_Send_to_Bank__c', type:'boolean', sortable: true },
        { label: 'Notes', fieldName: 'Notes__c', type: 'helptext' },
        { label: 'Client Account', fieldName: 'opportunity.Account.Id', type: 'linkToId', typeAttributes: {target: '_blank', label: {fieldName: 'opportunity.Account.Name'}}, sortable: true },
        { label: 'File #', fieldName: 'opportunity.Account.Id', type: 'linkToId', typeAttributes: {target: '_blank', label: {fieldName: 'opportunity.Account.AccountNumber'}}, sortable: true },
        //{ label: 'Payment Account', fieldName: 'Current_Account_URL__c', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Current_Account_Name__c'}}, sortable: true },
        //{ label: 'Bank Account', fieldName: 'Current_Bank_Account_URL__c', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Current_Bank_Account_Name__c'}}, sortable: true },
        { label: 'Opportunity #', fieldName: 'opportunity.Id', type: 'linkToId', typeAttributes: {target: '_blank', label: {fieldName: 'opportunity.Loan_Requests__c'}}, sortable: true },
        { label: 'Payment Type', fieldName: 'Payment_Type__c', sortable: true },
        { label: 'Admin Fee', fieldName: 'Expected_Admin_Fee_Amount__c', type: 'currency', sortable: true },
        { label: 'Scheduled Date', fieldName: 'Scheduled_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'}, sortable: true },
        { label: 'Available Credit', fieldName: 'opportunity.Loan_Available_to_Drawdown__c', type: 'currency', sortable: true },
        { label: 'Payment Amount', fieldName: 'Amount__c', type: 'currency', sortable: true },
    ];
    @track errors;
    @track sortedBy = 'Scheduled_Date__c';
    @track sortedDirection = 'asc';

    filterInitilized = true;
    resourcesInitialized = false;
    dt; // dataTable reference

    connectedCallback() {
        if (!this.resourcesInitialized) {
            this.loading = true;
            loadGlobalCss(this);
            this.resourcesInitialized = true;
            if (this.filterInitilized) {
                this.refresh();
            }
        }
    }

    @api refresh() {
        this.loading = true;
        //this.selectedAll = false; // Seems to be bugging out, maybe a bug in LWC rendering?
        //this.selectAllText = 'Select All';
        let options = {
            startDate: this.filters.startDate,
            endDate: this.filters.endDate,
            workflowStage: 'generateBankingSheet',
            //dateField: 'Sent_to_Bank_Date__c'
        };
        getScheduledPaymentsWithOpportunities(options)
            .then(result => {
                this.data = result;
                combineData(this.data)
                    .then(combinedData => {
                        this.spList = combinedData.spList;
                        this.oppMap = combinedData.oppMap;
                        this.spMap = combinedData.spMap;
                        this.loading = false;
                        this.error = undefined;
                        groupPayments(this.spList)
                            .then(groupedPayments => {
                                this.groupedPayments = groupedPayments;
                                this.loading = false;
                            })
                    });
            })
            .catch(error => {
                this.loading = false;
                this.error = error;
                this.data = undefined;
                this.spList = undefined;
                this.oppList = undefined;
                this.selectedScheduledPayment = undefined;
                this.selectedOpportunity = undefined;
            });
    }

    handleFilterInitialized(event) {
        this._filters = {...event.detail};
        this.filterInitilized = true;
        if (this.resourcesInitialized) {
            this.refresh();
        }
    }

    handleChangeFilterDate(event) {
        this._filters = {...event.detail};
        this.refresh();
        let evt = new CustomEvent('filterchange', {
            detail: {...this.filters}
        });
        this.dispatchEvent(evt);
    }

    get dataTable() {
        this.dt = this.dt || this.template.querySelector('c-funding-details-datatable-wrapper');
        return this.dt;
    }

    /*
    handleSave(event) {
        this.loading = true;
        this.errors = undefined;
        updateScheduledPaymentsFromDraftValues(event.detail.draftValues)
            .then(result => {
                showToast(this, 
                    'Successfully Saved Scheduled Payments',
                    'You may now generate an updated Banking Sheet',
                    'success'
                );
                this.confirmed = true;
                this.setBankingSheetText();
                this.spList = [...updateSPList(this.spList, result)];
                //sendScheduledPaymentsChangedEvent(this, result);
                this.dataTable.draftValues = [];
                this.loading = false;
            })
            .catch(error => {
                this.loading = false;
                if (error && error.body && error.body.message) {
                    this.dataTable.generateErrors(error.body.message);
                } else {
                    showToast(this, 
                        'There was an error',
                        JSON.stringify(error),
                        'error',
                        'sticky'
                    );
                }
            });
        this.saveDraftValues = event.detail.draftValues;
    }

    handleCancel(event) {
        this.errors = undefined;
    }
    */

    setBankingSheetText() {
        if (this.confirmed) {
            this.bankingSheetText = 'Generate Banking Sheet';
        } else {
            this.bankingSheetText = 'I confirm that this data is accurate';
        }
    }

    handleBankingSheetClick(event) {
        /*
        if (this.dataTable && this.dataTable.draftValues.length) {
            showToast(this, 
                'Unsaved Changes',
                'You have unsaved changes. Please either cancel or save them before continuing.',
                'warning'
            );
        } else */
        if (!this.confirmed) {
            this.confirmed = true;
            this.setBankingSheetText();
        } else {
            this.generateBankingSheet();
        }
    }

    get datatables() {
        return this.template.querySelectorAll('c-funding-details-datatable');
    }

    @track selectedAll = false;
    @track selectAllText = "Select All"
    toggleSelectAll() {
        const dts = this.datatables;
        this.selectedAll = !this.selectedAll;
        if (this.selectedAll) {
            this.selectAllText = 'Unselect All';
            dts.forEach(dt => {
                dt.selectedRows = dt.data.map(row => row.Id);
            });
        } else {
            this.selectAllText = 'Select All';
            dts.forEach(dt => {
                dt.selectedRows = [];
            });
        }
    }

    getSelectedIds() {
        let spIds = [];
        this.datatables.forEach(dt => {
            spIds = spIds.concat(dt.selectedRows);
        });
        return spIds
    }

    generateBankingSheet() {
        this.errors = undefined;
        let spIds = this.getSelectedIds();

        if (spIds.length === 0) {
            showToast(
                this,
                'No Payments Selected',
                'Please select the payments you want included before generating the banking sheet.',
                'warning'
            )
        } else {
            this.loading = true;
            generateBankingSheet({spIds: spIds})
                .then(result => {
                    showToast(this, 
                        'Successfully generated banking sheet',
                        'The payments have been marked as \'Sent to Bank\', and can be further processed now.',
                        'success',
                    );

                    // trigger download of banking sheet file
                    download(`bankingSheet-${new Date().toISOString()}.txt`, result);

                    // call for refresh of data
                    //sendNeedsRefreshEvent(this);
                    this.refresh();
                    this.loading = false;
                })
                .catch(error => {
                    this.loading = false;
                    if (error && error.body && error.body.message) {
                        //this.dataTable.generateErrors(error.body.message);
                        //const errorsMessage = JSON.parse(error.body.message);
                        //this.datatables
                        let allData = [];
                        this.datatables.forEach(dt => {
                            allData = allData.concat(dt.data);
                        });
                        this.errors = generateDataTableErrors(JSON.parse(error.body.message), allData);
                        this.datatables.forEach(dt => {
                            dt.errors = this.errors;
                        });
                        showToast(this, 
                            'Unable to generate banking sheet',
                            this.errors.table.messages.join('\n'),
                            'error',
                            'sticky'
                        );
                    } else {
                        showToast(this, 
                            'There was an error',
                            JSON.stringify(error),
                            'error',
                            'sticky'
                        );
                    }
                });
        }
    }

    handleSendBack() {
        const spList = [];
        this.getSelectedIds().forEach(id => spList.push({
            Id: id,
            Status__c: 'Pre Send Validation',
            Banking_Verified__c: false,
            Credit_Verified__c: false,
            Documents_Verified__c: false,
            BIA_PPSA_LL_Verified__c: false
        }));

        this.loading = true;
        this.errors = undefined;
        updateScheduledPaymentsFromDraftValues(spList)
            .then(result => {
                showToast(this, 
                    'Successfully Reverted Scheduled Payments to \'Pre Send Validation\'',
                    'You may now generate an updated Banking Sheet',
                    'success'
                );
                this.refresh();
                //sendNeedsRefreshEvent(this);
            })
            .catch(error => {
                this.loading = false;
                if (error && error.body && error.body.message) {
                    //this.dataTable.generateErrors(error.body.message);
                    this.errors = generateDataTableErrors(JSON.parse(error.body.message), this.spList);
                    showToast(this, 
                        'Unable to update EFT Number',
                        this.errors.table.messages.join('\n'),
                        'error',
                        'sticky'
                    );
                } else {
                    showToast(this, 
                        'There was an error',
                        JSON.stringify(error),
                        'error',
                        'sticky'
                    );
                }
            });
    }

}