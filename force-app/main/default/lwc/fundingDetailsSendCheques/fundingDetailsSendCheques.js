import { LightningElement, api, track, wire } from 'lwc';
//import generateBankingSheet from '@salesforce/apex/FundingDetailsComponentCtlr.generateBankingSheet';

import { showToast } from 'c/showToast';
//import { generateDataTableErrors } from 'c/ldsUtils';
import {
    loadGlobalCss,
    //sendScheduledPaymentsChangedEvent,
    //sendNeedsRefreshEvent,
    //updateScheduledPaymentsFromDraftValues,
    //updateFlattenedListFromResult,
    combineData,
    groupPayments,
    PERMISSION_CLASSES,
    generateObjectFromDraftValue
} from 'c/fundingDetailsUtils';
//import generateDrawdowns from '@salesforce/apex/ScheduledPaymentHelper.generateDrawdowns';
import getScheduledPaymentsWithOpportunities from '@salesforce/apex/FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities';
import fetchCustomPermissions from '@salesforce/apex/FetchCustomPermissions.fetchCustomPermissions';
import moveToProcessStep from '@salesforce/apex/FundingDetailsComponentCtlr.moveToProcessStep';

export default class FundingDetailsSendCheques extends LightningElement {
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
    confirmed = false;
    //@track bankingSheetText = 'I confirm that this data is accurate';

    @track columns = [
        { label: 'Status', fieldName: 'Status__c', type: 'text', sortable: true },
        { label: 'File #', fieldName: 'opportunity.Account.AccountNumber', type: 'text', sortable: true },
        { label: 'Client', fieldName: '_client_account', type: 'linkWithLabel', typeAttributes: {target: '_blank'}, sortable: true },
        { label: 'Payment Account', fieldName: 'Account__c', type: 'linkWithLabel', typeAttributes: {target: '_blank'}, sortable: true },
        { label: 'Account Address', fieldName: 'account.BillingAddress', type: 'address', },
        //{ label: 'Contact Address', fieldName: 'account.Primary_Contact__r.MailingAddress', type: 'address' },
        { label: 'Opportunity #', fieldName: 'opportunity.Loan_Requests__c', type: 'text' },
        { label: 'Payment Type', fieldName: 'Payment_Type__c', sortable: true },
        { label: 'Admin Fee', fieldName: 'Expected_Admin_Fee_Amount__c', type: 'currency', sortable: true },
        { label: 'Scheduled Date', fieldName: 'Scheduled_Date__c', type: 'date-local', typeAttributes: {'time-zone': 'UTC'}, sortable: true },
        { label: 'Available Credit', fieldName: 'opportunity.Loan_Available_to_Drawdown__c', type: 'currency', sortable: true },
        { label: 'Payment Amount', fieldName: 'Amount__c', type: 'currency', sortable: true, editable: true },
        { label: 'CHQ', fieldName: 'Send_Cheque__c', type: 'boolean', sortable: true },
        { label: 'CHQ #', fieldName: 'Cheque_Number__c', type: 'text', sortable: true, editable: true },
    ];
    @track draftValues = [];
    @track errors;
    @track sortedBy = 'Sent_to_Bank_Date__c';
    @track sortedDirection = 'asc';

    @track chqNum = '';

    filterInitilized = true;
    resourcesInitialized = false;
    dt; // dataTable reference

    connectedCallback() {
        this.loading = true;
        if (!this.resourcesInitialized) {
            loadGlobalCss(this);
            this.resourcesInitialized = true;
            if (this.filterInitilized) {
                this.refresh();
            }
        }
    }

    @api refresh() {
        this.loading = true;
        let options = {
            startDate: this.filters.startDate,
            endDate: this.filters.endDate,
            workflowStage: 'sendCheques',
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
                        groupPayments(this.spList, 'Current_Account_Id__c')
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

    get datatables() {
        return this.template.querySelectorAll('c-funding-details-cheque-group');
    }

    @track selectedAll = false;
    @track selectAllText = "Select All"
    toggleSelectAll() {
        const dts = this.datatables;
        this.selectedAll = !this.selectedAll;
        if (this.selectedAll) {
            this.selectAllText = 'Unselect All';
            dts.forEach(dt => {
                dt.selectedRows = dt.getData().map(row => row.Id);
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


    handleSetCHQClick(event) {
        let _draftValues = [...this.dataTable.draftValues] || [];

        this.dataTable.selectedRows.forEach(id => {
            const idx = _draftValues.findIndex(record => {return record.Id === id});
            if (idx >= 0) {
                _draftValues[idx].Cheque_Number__c = this.chqNum;
            } else {
                _draftValues.push({Id: id, Cheque_Number__c: this.chqNum});
            }
        });
        this.draftValues = _draftValues;
        //this.dt.draftValues = this.draftValues;
    }

    handleCHQChange(event) {
        this.chqNum = event.detail.value;
    }

    /*
    handleSendBack() {
        const spList = [];
        this.dataTable.selectedRows.forEach(id => spList.push({Id: id, Status__c: 'Scheduled'}));

        this.loading = true;
        this.errors = undefined;
        updateScheduledPaymentsFromDraftValues(spList)
            .then(result => {
                showToast(this, 
                    'Successfully Reverted Scheduled Payments to \'Scheduled\'',
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
                    this.errors = generateDataTableErrors(JSON.parse(error.body.message), this.dataTable.getPaginatedData());
                    showToast(this, 
                        'Unable to generate drawdowns',
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
    */

    handleSave() {
        // validate that all selected have an Cheque_Number__c
        let _draftValues = [];
        let spList = [];
        this.errors = undefined;
        let _errors = {
            rows: {},
            table: {
                title: 'Your entry cannot be saved. Please fix the errors and try again.',
                messages: []
            }
        }

        this.datatables.forEach(dt => {
            _draftValues = _draftValues.concat(dt.draftValues);
            dt.selectedRows.forEach(id => {
                const idx = _draftValues.findIndex(record => {return record.Id === id});
                if (!(idx >= 0) || !(_draftValues[idx].Cheque_Number__c)) {
                    // Invalid
                    // Selected a row that does not have an Cheque_Number__c set
                    let rowNumber = _draftValues.findIndex(record => {return record.Id === id}) + 1;
                    _errors.rows[id] = {
                        title: `Row ${rowNumber} is invalid`,
                        messages: ['Scheduled Payment needs an CHQ # before drawdowns can be created'],
                        fieldNames: ['Cheque_Number__c']
                    };
                    _errors.table.messages.push(`Row ${rowNumber} needs an CHQ #`);
                } else {
                    // Valid
                    //selectedDraftValues[_draftValues[idx].Id] = _draftValues[idx].Cheque_Number__c;
                    spList.push(generateObjectFromDraftValue('Scheduled_Payment__c', _draftValues[idx]))
                }

                dt.errors = _errors;
            });
        })

        if (_errors.table.messages.length) {
            // Invalid
            this.errors = _errors;
        } else {
            // Valid
            // Send selectedDraftValues
            this.loading = true;
            moveToProcessStep({scheduledPayments: spList})
                .then(result => {
                    showToast(this, 
                        'Successfully moved payments to next step',
                        'The payments have been marked as \'Processed by Bank\', and can be further processed now.',
                        'success',
                    );

                    // call for refresh of data
                    this.refresh();
                    //sendNeedsRefreshEvent(this);
                    this.loading = false;
                })
                .catch(error => {
                    this.loading=false;
                    showToast(this, 
                        'Unable to move payments to next step',
                        error.body.message,
                        'error',
                        'sticky'
                    );
                });
        }
    }
}